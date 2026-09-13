import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/models/access.dart';
import '../../../../core/models/resident.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class AccessScreen extends ConsumerStatefulWidget {
  const AccessScreen({super.key});

  @override
  ConsumerState<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends ConsumerState<AccessScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(accessLogsProvider.notifier).loadLogs(),
      ref.read(activeAccessesProvider.notifier).loadActive(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Accesos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activos', icon: Icon(Icons.directions_walk)),
            Tab(text: 'Historial', icon: Icon(Icons.history)),
            Tab(text: 'Visitantes', icon: Icon(Icons.person_add)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () => _scanQr()),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveAccessesTab(onRefresh: _loadData),
          _AccessLogsTab(onRefresh: _loadData, searchController: _searchController),
          const _VisitorsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEntryDialog(),
        icon: const Icon(Icons.login),
        label: const Text('Registrar Entrada'),
      ),
    );
  }

  void _showEntryDialog() {
    showDialog(context: context, builder: (context) => const _EntryDialog());
  }

  void _scanQr() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escáner QR en desarrollo')));
  }
}

class _ActiveAccessesTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  
  const _ActiveAccessesTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeAccessesProvider);
    
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.activeAccesses.isEmpty
              ? _EmptyState(icon: Icons.security, title: 'Sin accesos activos', subtitle: 'No hay residentes o visitantes dentro')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.activeAccesses.length,
                  itemBuilder: (context, index) {
                    final access = state.activeAccesses[index];
                    return _AccessCard(access: access, showExitButton: true);
                  },
                ),
    );
  }
}

class _AccessLogsTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  final TextEditingController searchController;
  
  const _AccessLogsTab({required this.onRefresh, required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accessLogsProvider);
    
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomSearchField(
              controller: searchController,
              hint: 'Buscar accesos...',
              onChanged: (_) => ref.read(accessLogsProvider.notifier).loadLogs(search: searchController.text),
              onClear: () => ref.read(accessLogsProvider.notifier).loadLogs(),
            ),
          ),
          Expanded(
            child: state.isLoading && state.logs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.logs.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.logs.length) {
                        if (!state.isLoading && state.hasMore) {
                          ref.read(accessLogsProvider.notifier).loadMore();
                        }
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                      }
                      final access = state.logs[index];
                      return _AccessCard(access: access);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _VisitorsTab extends ConsumerWidget {
  const _VisitorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myVisitorsProvider);
    
    return RefreshIndicator(
      onRefresh: () async => ref.read(myVisitorsProvider.notifier).load(),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.visitors.isEmpty
              ? _EmptyState(icon: Icons.person_add, title: 'Sin visitantes', subtitle: 'Registra tu primer visitante')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.visitors.length,
                  itemBuilder: (context, index) {
                    final visitor = state.visitors[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(visitor.firstName[0].toUpperCase())),
                        title: Text(visitor.fullName),
                        subtitle: Text('${visitor.phone ?? 'Sin teléfono'} • ${visitor.isRecurring ? 'Recurrente' : 'Único'}'),
                        trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteVisitor(visitor.id)),
                      ),
                    );
                  },
                ),
    );
  }

  void _deleteVisitor(String id) {
    // Implementation
  }
}

class _AccessCard extends ConsumerWidget {
  final AccessLog access;
  final bool showExitButton;
  
  const _AccessCard({required this.access, this.showExitButton = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(access.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(access.type == AccessType.resident ? Icons.person : Icons.person_add, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(access.displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(access.unitDisplay, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(access.status.name.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(icon: Icons.access_time, label: 'Entrada', value: access.entryTime != null ? DateFormat('HH:mm').format(access.entryTime!) : 'Pendiente'),
                _InfoChip(icon: Icons.access_time, label: 'Salida', value: access.exitTime != null ? DateFormat('HH:mm').format(access.exitTime!) : 'Pendiente'),
                _InfoChip(icon: Icons.directions, label: 'Método', value: access.entryMethod ?? 'N/A'),
              ],
            ),
            if (showExitButton && access.status == AccessStatus.approved && access.exitTime == null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _registerExit(access.id),
                  icon: const Icon(Icons.logout),
                  label: const Text('Registrar Salida'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _registerExit(String id) {
    // Implementation
  }
  
  Color _getStatusColor(AccessStatus status) {
    switch (status) {
      case AccessStatus.approved: return Colors.green;
      case AccessStatus.pending: return Colors.orange;
      case AccessStatus.rejected: return Colors.red;
      case AccessStatus.completed: return Colors.blue;
      default: return Colors.grey;
    }
  }
}

class _EntryDialog extends ConsumerStatefulWidget {
  const _EntryDialog();

  @override
  ConsumerState<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends ConsumerState<_EntryDialog> {
  String _type = 'VISITOR';
  final _visitorController = TextEditingController();
  final _plateController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _visitorController.dispose();
    _plateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Entrada'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'VISITOR', label: Text('Visitante'), icon: Icon(Icons.person_add)),
                ButtonSegment(value: 'SERVICE', label: Text('Servicio'), icon: Icon(Icons.build)),
                ButtonSegment(value: 'DELIVERY', label: Text('Entrega'), icon: Icon(Icons.local_shipping)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            if (_type == 'VISITOR') ...[
              TextField(controller: _visitorController, decoration: const InputDecoration(labelText: 'Nombre del visitante', border: OutlineInputBorder())),
              const SizedBox(height: 12),
            ],
            TextField(controller: _plateController, decoration: const InputDecoration(labelText: 'Placa del vehículo (opcional)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notas (opcional)', border: OutlineInputBorder()), maxLines: 2),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _isLoading ? null : _register,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Registrar'),
        ),
      ],
    );
  }

  Future<void> _register() async {
    // Implementation
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _InfoChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

final accessLogsProvider = StateNotifierProvider<AccessLogsNotifier, AccessLogsState>((ref) {
  return AccessLogsNotifier(ref.read(accessApiProvider));
});

class AccessLogsState {
  final List<AccessLog> logs;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  
  const AccessLogsState({this.logs = const [], this.isLoading = false, this.hasMore = true, this.error});
  
  AccessLogsState copyWith({List<AccessLog>? logs, bool? isLoading, bool? hasMore, String? error}) =>
      AccessLogsState(logs: logs ?? this.logs, isLoading: isLoading ?? this.isLoading, hasMore: hasMore ?? this.hasMore, error: error ?? this.error);
}

class AccessLogsNotifier extends StateNotifier<AccessLogsState> {
  final AccessApi _api;
  int _page = 1;
  String? _search;
  
  AccessLogsNotifier(this._api) : super(const AccessLogsState());

  Future<void> loadLogs({int page = 1, String? search, String? status}) async {
    if (page == 1) state = state.copyWith(isLoading: true, error: null);
    _search = search;
    try {
      final response = await _api.getAccessLogs(page: page, search: search, status: status);
      final newLogs = page == 1 ? response.data : [...state.logs, ...response.data];
      state = state.copyWith(logs: newLogs, isLoading: false, hasMore: response.hasNextPage);
      _page = page;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    await loadLogs(page: _page + 1, search: _search);
  }
}

final activeAccessesProvider = StateNotifierProvider<ActiveAccessesNotifier, ActiveAccessesState>((ref) {
  return ActiveAccessesNotifier(ref.read(accessApiProvider));
});

class ActiveAccessesState {
  final List<AccessLog> activeAccesses;
  final bool isLoading;
  final String? error;
  
  const ActiveAccessesState({this.activeAccesses = const [], this.isLoading = false, this.error});
  
  ActiveAccessesState copyWith({List<AccessLog>? activeAccesses, bool? isLoading, String? error}) =>
      ActiveAccessesState(activeAccesses: activeAccesses ?? this.activeAccesses, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class ActiveAccessesNotifier extends StateNotifier<ActiveAccessesState> {
  final AccessApi _api;
  
  ActiveAccessesNotifier(this._api) : super(const ActiveAccessesState()) {
    loadActive();
  }
  
  Future<void> loadActive() async {
    state = state.copyWith(isLoading: true);
    try {
      final accesses = await _api.getActiveAccesses();
      state = state.copyWith(isLoading: false, activeAccesses: accesses);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final myVisitorsProvider = StateNotifierProvider<MyVisitorsNotifier, MyVisitorsState>((ref) {
  return MyVisitorsNotifier(ref.read(visitorApiProvider));
});

class MyVisitorsState {
  final List<Visitor> visitors;
  final bool isLoading;
  final String? error;
  
  const MyVisitorsState({this.visitors = const [], this.isLoading = false, this.error});
  
  MyVisitorsState copyWith({List<Visitor>? visitors, bool? isLoading, String? error}) =>
      MyVisitorsState(visitors: visitors ?? this.visitors, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class MyVisitorsNotifier extends StateNotifier<MyVisitorsState> {
  final VisitorApi _api;
  
  MyVisitorsNotifier(this._api) : super(const MyVisitorsState()) {
    load();
  }
  
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final visitors = await _api.getMyVisitors();
      state = state.copyWith(isLoading: false, visitors: visitors);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}