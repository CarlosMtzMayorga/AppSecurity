import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/models/service.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String serviceId;
  
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    await ref.read(serviceDetailProvider(widget.serviceId).notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(serviceDetailProvider(widget.serviceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Solicitud')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.request == null
              ? Center(child: Text(state.error ?? 'Solicitud no encontrada'))
              : _buildDetail(state.request!),
    );
  }

  Widget _buildDetail(ServiceRequest request) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(request.status);
    final priorityColor = _getPriorityColor(request.priority);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(request.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Text('Unidad ${request.unit.displayNumber}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Text(request.statusLabel, style: TextStyle(fontWeight: FontWeight.w600, color: statusColor))),
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Text(request.priorityLabel, style: TextStyle(fontWeight: FontWeight.w600, color: priorityColor))),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(label: 'Categoría', value: request.category, icon: Icons.category),
                  _DetailRow(label: 'Reportado por', value: request.user.fullName, icon: Icons.person),
                  _DetailRow(label: 'Fecha de reporte', value: DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt), icon: Icons.calendar_today),
                  if (request.assignee != null) _DetailRow(label: 'Asignado a', value: request.assignee!.fullName, icon: Icons.assignment_ind),
                  if (request.scheduledAt != null) _DetailRow(label: 'Programado para', value: DateFormat('dd/MM/yyyy HH:mm').format(request.scheduledAt!), icon: Icons.schedule),
                  if (request.startedAt != null) _DetailRow(label: 'Iniciado el', value: DateFormat('dd/MM/yyyy HH:mm').format(request.startedAt!), icon: Icons.play_circle, valueColor: Colors.blue),
                  if (request.resolvedAt != null) _DetailRow(label: 'Resuelto el', value: DateFormat('dd/MM/yyyy HH:mm').format(request.resolvedAt!), icon: Icons.check_circle, valueColor: Colors.green),
                  if (request.estimatedCost != null) _DetailRow(label: 'Costo estimado', value: '\$${request.estimatedCost!.toStringAsFixed(2)}', icon: Icons.attach_money),
                  if (request.actualCost != null) _DetailRow(label: 'Costo real', value: '\$${request.actualCost!.toStringAsFixed(2)}', icon: Icons.receipt, valueColor: Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Descripción', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(request.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
                ],
              ),
            ),
          ),
          if (request.images.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Imágenes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: request.images.length,
                        itemBuilder: (context, index) => Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(request.images[index]), fit: BoxFit.cover)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (request.resolutionNotes != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notas de Resolución', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(request.resolutionNotes!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
          if (request.rating != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 32),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tu Calificación', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Row(children: List.generate(5, (i) => Icon(i < request.rating! ? Icons.star : Icons.star_border, color: Colors.amber, size: 24))),
                    ]),
                    if (request.feedback != null) ...[
                      const Spacer(),
                      Expanded(child: Text('"${request.feedback}"', style: theme.textTheme.bodyMedium)),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (request.status == ServiceRequestStatus.resolved && request.rating == null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calificar Servicio', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _RatingWidget(onRate: (rating) => _submitRating(request.id, rating)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _submitRating(String id, int rating) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calificación: $rating estrellas')));
  }

  Widget _DetailRow({required String label, required String value, required IconData icon, Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: valueColor)),
      ])),
    ]));
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

class _RatingWidget extends StatefulWidget {
  final Function(int) onRate;
  const _RatingWidget({required this.onRate});
  @override State<_RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<_RatingWidget> {
  int _rating = 0;
  final _feedbackController = TextEditingController();
  
  @override void dispose() { _feedbackController.dispose(); super.dispose(); }
  
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
          icon: Icon(i < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
          onPressed: () => setState(() => _rating = i + 1),
        ))),
        const SizedBox(height: 16),
        TextField(controller: _feedbackController, decoration: const InputDecoration(labelText: 'Comentario (opcional)', border: OutlineInputBorder()), maxLines: 3),
        const SizedBox(height: 16),
        FilledButton(onPressed: _rating > 0 ? () => widget.onRate(_rating) : null, child: const Text('Enviar Calificación')),
      ],
    );
  }
}

final serviceDetailProvider = StateNotifierProvider.family<ServiceDetailNotifier, ServiceDetailState, String>((ref, id) {
  return ServiceDetailNotifier(ref.read(serviceApiProvider), id);
});

class ServiceDetailState {
  final ServiceRequest? request; final bool isLoading; final String? error;
  const ServiceDetailState({this.request, this.isLoading = false, this.error});
  ServiceDetailState copyWith({ServiceRequest? request, bool? isLoading, String? error}) =>
      ServiceDetailState(request: request ?? this.request, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class ServiceDetailNotifier extends StateNotifier<ServiceDetailState> {
  final ServiceApi _api; final String _id;
  ServiceDetailNotifier(this._api, this._id) : super(const ServiceDetailState()) { load(); }
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try { final request = await _api.getServiceRequest(_id); state = state.copyWith(isLoading: false, request: request); }
    catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }
}