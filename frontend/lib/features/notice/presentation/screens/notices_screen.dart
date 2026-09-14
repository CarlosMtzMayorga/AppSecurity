import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/models/notice.dart';
import '../../../../core/models/user.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class NoticesScreen extends ConsumerStatefulWidget {
  const NoticesScreen({super.key});

  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotices() async {
    await ref.read(noticesProvider.notifier).loadNotices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final isAdmin = authState.user?.role == UserRole.admin || authState.user?.role == UserRole.committee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos y Comunicados'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNotices),
          if (isAdmin) IconButton(icon: const Icon(Icons.add), onPressed: _showCreateNotice),
        ],
      ),
      body: Column(
        children: [
          if (isAdmin) _buildUnreadBadge(),
          Expanded(child: _NoticesList(onRefresh: _loadNotices, searchController: _searchController)),
        ],
      ),
    );
  }

  Widget _buildUnreadBadge() {
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, _) {
        final unreadAsync = ref.watch(unreadNoticesProvider);
        return unreadAsync.when(
          data: (count) => count > 0
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: theme.colorScheme.primaryContainer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_email_unread, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('$count avisos sin leer', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : const SizedBox(),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        );
      },
    );
  }

  void _showCreateNotice() {
    showDialog<bool>(
      context: context,
      builder: (context) => const _CreateNoticeDialog(),
    ).then((created) {
      if (created == true) {
        _loadNotices();
        ref.invalidate(unreadNoticesProvider);
      }
    });
  }
}

class _CreateNoticeDialog extends ConsumerStatefulWidget {
  const _CreateNoticeDialog();

  @override
  ConsumerState<_CreateNoticeDialog> createState() => _CreateNoticeDialogState();
}

class _CreateNoticeDialogState extends ConsumerState<_CreateNoticeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  NoticeType _type = NoticeType.general;
  bool _isPinned = false;
  DateTime? _expiresAt;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Aviso'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Título',
                hint: 'Título del comunicado',
                prefixIcon: Icons.title,
                validator: (v) => v == null || v.trim().isEmpty ? 'El título es requerido' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _contentController,
                label: 'Contenido',
                hint: 'Redacta el aviso…',
                prefixIcon: Icons.description,
                maxLines: 5,
                validator: (v) => v == null || v.trim().isEmpty ? 'El contenido es requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NoticeType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                items: NoticeType.values.map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t)))).toList(),
                onChanged: (v) => setState(() => _type = v ?? NoticeType.general),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _isPinned,
                onChanged: (v) => setState(() => _isPinned = v ?? false),
                title: const Text('Fijar aviso'),
                subtitle: const Text('Mostrar al inicio de la lista'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_busy),
                title: Text(_expiresAt == null ? 'Sin fecha de expiración' : 'Expira: ${DateFormat('dd/MM/yyyy').format(_expiresAt!)}'),
                subtitle: const Text('Opcional'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickExpiry(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Publicar'),
        ),
      ],
    );
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(noticeApiProvider).createNotice({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'type': _type.name.toUpperCase(),
        'isPinned': _isPinned,
        if (_expiresAt != null) 'expiresAt': _expiresAt!.toUtc().toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        messenger.showSnackBar(const SnackBar(content: Text('Aviso publicado'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _typeLabel(NoticeType t) {
    switch (t) {
      case NoticeType.general: return 'General';
      case NoticeType.urgent: return 'Urgente';
      case NoticeType.maintenance: return 'Mantenimiento';
      case NoticeType.event: return 'Evento';
      case NoticeType.security: return 'Seguridad';
      case NoticeType.financial: return 'Financiero';
    }
  }
}

class _NoticesList extends ConsumerWidget {
  final VoidCallback onRefresh;
  final TextEditingController searchController;

  const _NoticesList({required this.onRefresh, required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noticesProvider);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomSearchField(
              controller: searchController,
              hint: 'Buscar avisos...',
              onChanged: (_) => ref.read(noticesProvider.notifier).loadNotices(search: searchController.text),
              onClear: () => ref.read(noticesProvider.notifier).loadNotices(),
            ),
          ),
          Expanded(
            child: state.isLoading && state.notices.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.notices.isEmpty
                    ? _EmptyState(icon: Icons.announcement, title: 'Sin avisos', subtitle: 'No hay comunicados publicados')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.notices.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.notices.length) {
                            if (!state.isLoading && state.hasMore) ref.read(noticesProvider.notifier).loadMore();
                            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                          }
                          final notice = state.notices[index];
                          return _NoticeCard(notice: notice, onTap: () => context.push('/notices/${notice.id}'));
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends ConsumerWidget {
  final Notice notice;
  final VoidCallback onTap;

  const _NoticeCard({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUnread = !notice.isRead;
    final isPinned = notice.isPinned;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUnread ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
      child: InkWell(
        onTap: () {
          if (isUnread) ref.read(noticesProvider.notifier).markAsRead(notice.id);
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isPinned) ...[
                    Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                  ],
                  _NoticeTypeChip(type: notice.type),
                  const Spacer(),
                  if (isUnread)
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(height: 8),
              Text(notice.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500)),
              const SizedBox(height: 4),
              Text(notice.content, style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(notice.publishAt), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  if (notice.expiresAt != null) ...[
                    const SizedBox(width: 16),
                    Text('Expira: ${DateFormat('dd/MM/yyyy').format(notice.expiresAt!)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  const Spacer(),
                  Text('por ${notice.author.fullName}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeTypeChip extends StatelessWidget {
  final NoticeType type;

  const _NoticeTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    IconData icon;

    switch (type) {
      case NoticeType.urgent: color = Colors.red; icon = Icons.warning; break;
      case NoticeType.maintenance: color = Colors.blue; icon = Icons.build; break;
      case NoticeType.event: color = Colors.purple; icon = Icons.event; break;
      case NoticeType.security: color = Colors.orange; icon = Icons.security; break;
      case NoticeType.financial: color = Colors.green; icon = Icons.attach_money; break;
      default: color = theme.colorScheme.primary; icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(type.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
      const SizedBox(height: 16),
      Text(title, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]));
  }
}

final noticesProvider = StateNotifierProvider<NoticesNotifier, NoticesState>((ref) {
  return NoticesNotifier(ref.read(noticeApiProvider));
});

class NoticesState {
  final List<Notice> notices;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  const NoticesState({this.notices = const [], this.isLoading = false, this.hasMore = true, this.error});
  NoticesState copyWith({List<Notice>? notices, bool? isLoading, bool? hasMore, String? error}) =>
      NoticesState(notices: notices ?? this.notices, isLoading: isLoading ?? this.isLoading, hasMore: hasMore ?? this.hasMore, error: error ?? this.error);
}

class NoticesNotifier extends StateNotifier<NoticesState> {
  final NoticeApi _api;
  int _page = 1;
  String? _search;

  NoticesNotifier(this._api) : super(const NoticesState()) { loadNotices(); }

  Future<void> loadNotices({int page = 1, String? search}) async {
    if (page == 1) state = state.copyWith(isLoading: true, error: null);
    _search = search;
    try {
      final response = await _api.getNotices(page: page, search: search);
      final newNotices = page == 1 ? response.data : [...state.notices, ...response.data];
      state = state.copyWith(notices: newNotices, isLoading: false, hasMore: response.hasNextPage);
      _page = page;
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  Future<void> loadMore() async => loadNotices(page: _page + 1, search: _search);

  Future<void> markAsRead(String id) async {
    try {
      await _api.markAsRead(id);
      state = state.copyWith(notices: state.notices.map((n) => n.id == id ? n.copyWith(readBy: n.readBy.isEmpty ? ['me'] : n.readBy) : n).toList());
    } catch (e) {}
  }
}

final unreadNoticesProvider = FutureProvider<int>((ref) async {
  return await ref.read(noticeApiProvider).getUnreadCount();
});