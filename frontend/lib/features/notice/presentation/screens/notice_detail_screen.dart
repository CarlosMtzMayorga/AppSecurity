import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/models/notice.dart';
import 'notices_screen.dart';

class NoticeDetailScreen extends ConsumerStatefulWidget {
  final String noticeId;
  
  const NoticeDetailScreen({super.key, required this.noticeId});

  @override
  ConsumerState<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends ConsumerState<NoticeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotice());
  }

  Future<void> _loadNotice() async {
    await ref.read(noticeDetailProvider(widget.noticeId).notifier).load();
    // Mark as read
    await ref.read(noticesProvider.notifier).markAsRead(widget.noticeId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(noticeDetailProvider(widget.noticeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Aviso'),
        actions: [
          if (state.notice != null && (theme.brightness == Brightness.light))
            IconButton(icon: const Icon(Icons.share), onPressed: _shareNotice),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.notice == null
              ? Center(child: Text(state.error ?? 'Aviso no encontrado'))
              : _buildDetail(state.notice!),
    );
  }

  Widget _buildDetail(Notice notice) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (notice.isPinned) ...[
                Icon(Icons.push_pin, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
              ],
              _NoticeTypeChip(type: notice.type),
              const Spacer(),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(notice.publishAt), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          Text(notice.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(child: Text(notice.author.firstName[0].toUpperCase())),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Publicado por', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text(notice.author.fullName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              ]),
            ],
          ),
          if (notice.expiresAt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.event_busy, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Text('Expira el ${DateFormat('dd/MM/yyyy HH:mm').format(notice.expiresAt!)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Divider(),
          const SizedBox(height: 16),
          Text(notice.content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
          if (notice.attachmentUrls.isNotEmpty) ...[
            const SizedBox(height: 24),
            Divider(),
            const SizedBox(height: 16),
            Text('Adjuntos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...notice.attachmentUrls.map((url) => ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(url.split('/').last),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {},
            )),
          ],
        ],
      ),
    );
  }

  void _shareNotice() {}
}

class _NoticeTypeChip extends StatelessWidget {
  final NoticeType type;
  const _NoticeTypeChip({required this.type});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color; IconData icon;
    switch (type) {
      case NoticeType.urgent: color = Colors.red; icon = Icons.warning; break;
      case NoticeType.maintenance: color = Colors.blue; icon = Icons.build; break;
      case NoticeType.event: color = Colors.purple; icon = Icons.event; break;
      case NoticeType.security: color = Colors.orange; icon = Icons.security; break;
      case NoticeType.financial: color = Colors.green; icon = Icons.attach_money; break;
      default: color = theme.colorScheme.primary; icon = Icons.info;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 6), Text(type.name.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))]));
  }
}

final noticeDetailProvider = StateNotifierProvider.family<NoticeDetailNotifier, NoticeDetailState, String>((ref, id) {
  return NoticeDetailNotifier(ref.read(noticeApiProvider), id);
});

class NoticeDetailState {
  final Notice? notice; final bool isLoading; final String? error;
  const NoticeDetailState({this.notice, this.isLoading = false, this.error});
  NoticeDetailState copyWith({Notice? notice, bool? isLoading, String? error}) =>
      NoticeDetailState(notice: notice ?? this.notice, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class NoticeDetailNotifier extends StateNotifier<NoticeDetailState> {
  final NoticeApi _api; final String _id;
  NoticeDetailNotifier(this._api, this._id) : super(const NoticeDetailState()) { load(); }
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try { final notice = await _api.getNotice(_id); state = state.copyWith(isLoading: false, notice: notice); }
    catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }
}