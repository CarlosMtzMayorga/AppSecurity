import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/user.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isAdmin = authState.user?.role == UserRole.admin || authState.user?.role == UserRole.committee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Servicio'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mis Solicitudes', icon: Icon(Icons.person)),
            Tab(text: 'Todas', icon: Icon(Icons.list)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(servicesProvider.notifier).load()),
          if (isAdmin) IconButton(icon: const Icon(Icons.add), onPressed: _showCreateService),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyServicesTab(),
          _AllServicesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateService,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Solicitud'),
      ),
    );
  }

  Future<void> _showCreateService() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateServiceDialog(),
    );
    if (created == true) {
      ref.read(myServicesProvider.notifier).load();
      ref.read(servicesProvider.notifier).load();
    }
  }
}

class _CreateServiceDialog extends ConsumerStatefulWidget {
  const _CreateServiceDialog();

  @override
  ConsumerState<_CreateServiceDialog> createState() => _CreateServiceDialogState();
}

class _CreateServiceDialogState extends ConsumerState<_CreateServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'general';
  String _priority = 'medium';
  bool _submitting = false;

  static const _categories = ['general', 'plumbing', 'electrical', 'cleaning', 'security', 'appliances', 'other'];
  static const _priorities = ['low', 'medium', 'high', 'urgent'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Solicitud'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Título',
                hint: 'Ej: Reparación de grifo',
                prefixIcon: Icons.title,
                validator: (v) => v == null || v.trim().isEmpty ? 'El título es requerido' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _descriptionController,
                label: 'Descripción',
                hint: 'Describe el problema en detalle',
                prefixIcon: Icons.description,
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty ? 'La descripción es requerida' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown('Categoría', _categories, _category, (v) => setState(() => _category = v!)),
              const SizedBox(height: 12),
              _buildDropdown('Prioridad', _priorities, _priority, (v) => setState(() => _priority = v!)),
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
              : const Text('Crear Solicitud'),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(serviceApiProvider).createServiceRequest({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'priority': _priority,
      });
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud creada')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _MyServicesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myServicesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(myServicesProvider.notifier).load(),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.requests.isEmpty
              ? _EmptyState(icon: Icons.build, title: 'Sin solicitudes', subtitle: 'Reporta tu primera incidencia')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.requests.length,
                  itemBuilder: (context, index) => _ServiceCard(request: state.requests[index]),
                ),
    );
  }
}

class _AllServicesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(servicesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(servicesProvider.notifier).load(),
      child: state.isLoading && state.requests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.requests.length) {
                  if (!state.isLoading && state.hasMore) ref.read(servicesProvider.notifier).loadMore();
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                }
                return _ServiceCard(request: state.requests[index]);
              },
            ),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  final ServiceRequest request;

  const _ServiceCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(request.status);
    final priorityColor = _getPriorityColor(request.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(request.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text('Unidad ${request.unit.displayNumber}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(request.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor))),
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(request.priorityLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: priorityColor))),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.description, style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(icon: Icons.category, label: 'Categoría', value: request.category),
                _InfoChip(icon: Icons.calendar_today, label: 'Creado', value: DateFormat('dd/MM/yyyy').format(request.createdAt)),
                if (request.assignee != null) _InfoChip(icon: Icons.person, label: 'Asignado', value: request.assignee!.fullName),
              ],
            ),
            if (request.status == ServiceRequestStatus.resolved && request.rating == null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: () => _rateService(context, ref, request.id), icon: const Icon(Icons.star), label: const Text('Calificar Servicio')),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _rateService(BuildContext context, WidgetRef ref, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<int>(
      context: context,
      builder: (context) => const _RateServiceDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(serviceApiProvider).rateService(id, rating: result);
      messenger.showSnackBar(const SnackBar(content: Text('Gracias por tu calificación'), backgroundColor: Colors.green));
      ref.read(myServicesProvider.notifier).load();
      ref.read(servicesProvider.notifier).load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Color _getStatusColor(ServiceRequestStatus s) {
    switch (s) {
      case ServiceRequestStatus.open: return Colors.blue;
      case ServiceRequestStatus.inProgress: return Colors.orange;
      case ServiceRequestStatus.resolved: return Colors.green;
      case ServiceRequestStatus.closed: return Colors.grey;
      case ServiceRequestStatus.rejected: return Colors.red;
    }
  }

  Color _getPriorityColor(ServiceRequestPriority p) {
    switch (p) {
      case ServiceRequestPriority.low: return Colors.green;
      case ServiceRequestPriority.medium: return Colors.blue;
      case ServiceRequestPriority.high: return Colors.orange;
      case ServiceRequestPriority.urgent: return Colors.red;
    }
  }
}

class _RateServiceDialog extends StatefulWidget {
  const _RateServiceDialog();

  @override
  State<_RateServiceDialog> createState() => _RateServiceDialogState();
}

class _RateServiceDialogState extends State<_RateServiceDialog> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calificar Servicio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('¿Cómo calificas el servicio recibido?'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => IconButton(
              iconSize: 36,
              icon: Icon(i < _rating ? Icons.star : Icons.star_border, color: Colors.amber),
              onPressed: () => setState(() => _rating = i + 1),
            )),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, _rating), child: const Text('Enviar')),
      ],
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

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoChip({required this.icon, required this.label, required this.value});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(child: Container(padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant), Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)), Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))])));
  }
}

final servicesProvider = StateNotifierProvider<ServicesNotifier, ServicesState>((ref) {
  return ServicesNotifier(ref.read(serviceApiProvider));
});

class ServicesState {
  final List<ServiceRequest> requests; final bool isLoading; final bool hasMore; final String? error;
  const ServicesState({this.requests = const [], this.isLoading = false, this.hasMore = true, this.error});
  ServicesState copyWith({List<ServiceRequest>? requests, bool? isLoading, bool? hasMore, String? error}) =>
      ServicesState(requests: requests ?? this.requests, isLoading: isLoading ?? this.isLoading, hasMore: hasMore ?? this.hasMore, error: error ?? this.error);
}

class ServicesNotifier extends StateNotifier<ServicesState> {
  final ServiceApi _api; int _page = 1;
  ServicesNotifier(this._api) : super(const ServicesState()) { load(); }
  Future<void> load({int page = 1}) async {
    if (page == 1) state = state.copyWith(isLoading: true, error: null);
    try { final response = await _api.getServiceRequests(page: page); final newRequests = page == 1 ? response.data : [...state.requests, ...response.data]; state = state.copyWith(requests: newRequests, isLoading: false, hasMore: response.hasNextPage); _page = page; }
    catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }
  Future<void> loadMore() async => load(page: _page + 1);
}

final myServicesProvider = StateNotifierProvider<MyServicesNotifier, MyServicesState>((ref) {
  return MyServicesNotifier(ref.read(serviceApiProvider));
});

class MyServicesState {
  final List<ServiceRequest> requests; final bool isLoading; final String? error;
  const MyServicesState({this.requests = const [], this.isLoading = false, this.error});
  MyServicesState copyWith({List<ServiceRequest>? requests, bool? isLoading, String? error}) =>
      MyServicesState(requests: requests ?? this.requests, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class MyServicesNotifier extends StateNotifier<MyServicesState> {
  final ServiceApi _api;
  MyServicesNotifier(this._api) : super(const MyServicesState()) { load(); }
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try { final requests = await _api.getMyRequests(); state = state.copyWith(isLoading: false, requests: requests); }
    catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }
}