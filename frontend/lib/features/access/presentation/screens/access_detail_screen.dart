import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/models/access.dart';

class AccessDetailScreen extends ConsumerStatefulWidget {
  final String accessId;
  
  const AccessDetailScreen({super.key, required this.accessId});

  @override
  ConsumerState<AccessDetailScreen> createState() => _AccessDetailScreenState();
}

class _AccessDetailScreenState extends ConsumerState<AccessDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAccess());
  }

  Future<void> _loadAccess() async {
    await ref.read(accessDetailProvider(widget.accessId).notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accessDetailProvider(widget.accessId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Acceso')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.access == null
              ? Center(child: Text(state.error ?? 'Acceso no encontrado'))
              : _buildDetail(state.access!),
    );
  }

  Widget _buildDetail(AccessLog access) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(access.status);

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
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Icon(access.type == AccessType.resident ? Icons.person : Icons.person_add, color: statusColor, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(access.displayName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Text(access.unitDisplay, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ])),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(access.status.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, color: statusColor))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _DetailRow(label: 'Tipo', value: access.type.name.toUpperCase(), icon: Icons.category),
                  _DetailRow(label: 'Entrada', value: access.entryTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(access.entryTime!) : 'Pendiente', icon: Icons.login),
                  _DetailRow(label: 'Salida', value: access.exitTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(access.exitTime!) : 'Pendiente', icon: Icons.logout),
                  if (access.scheduledEntry != null) _DetailRow(label: 'Entrada programada', value: DateFormat('dd/MM/yyyy HH:mm').format(access.scheduledEntry!), icon: Icons.schedule),
                  if (access.scheduledExit != null) _DetailRow(label: 'Salida programada', value: DateFormat('dd/MM/yyyy HH:mm').format(access.scheduledExit!), icon: Icons.schedule),
                  _DetailRow(label: 'Método entrada', value: access.entryMethod ?? 'N/A', icon: Icons.touch_app),
                  if (access.exitMethod != null) _DetailRow(label: 'Método salida', value: access.exitMethod!, icon: Icons.touch_app),
                  if (access.plateRecognized != null) _DetailRow(label: 'Placa reconocida', value: access.plateRecognized!, icon: Icons.directions_car),
                  if (access.faceRecognized) _DetailRow(label: 'Reconocimiento facial', value: 'Sí', icon: Icons.face, valueColor: Colors.green),
                  if (access.notes != null) _DetailRow(label: 'Notas', value: access.notes!, icon: Icons.note),
                ],
              ),
            ),
          ),
          if (access.status == AccessStatus.approved && access.exitTime == null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.red.withOpacity(0.1), child: const Icon(Icons.logout, color: Colors.red)),
                title: const Text('Registrar Salida', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                subtitle: const Text('Marcar la salida de este acceso'),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red),
                onTap: () => _registerExit(access.id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _registerExit(String id) async {
    try {
      await ref.read(accessApiProvider).registerExit(id);
      await ref.read(accessDetailProvider(widget.accessId).notifier).load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salida registrada'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) {
        final s = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.contains('No hay entrada activa') ? 'No hay entrada activa' : 'No se pudo registrar la salida')));
      }
    }
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

  Color _getStatusColor(AccessStatus s) {
    switch (s) {
      case AccessStatus.approved: return Colors.green;
      case AccessStatus.pending: return Colors.orange;
      case AccessStatus.rejected: return Colors.red;
      case AccessStatus.completed: return Colors.blue;
      default: return Colors.grey;
    }
  }
}

final accessDetailProvider = StateNotifierProvider.family<AccessDetailNotifier, AccessDetailState, String>((ref, id) {
  return AccessDetailNotifier(ref.read(accessApiProvider), id);
});

class AccessDetailState {
  final AccessLog? access; final bool isLoading; final String? error;
  const AccessDetailState({this.access, this.isLoading = false, this.error});
  AccessDetailState copyWith({AccessLog? access, bool? isLoading, String? error}) =>
      AccessDetailState(access: access ?? this.access, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class AccessDetailNotifier extends StateNotifier<AccessDetailState> {
  final AccessApi _api; final String _id;
  AccessDetailNotifier(this._api, this._id) : super(const AccessDetailState()) { load(); }
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try { final access = await _api.getAccessLog(_id); state = state.copyWith(isLoading: false, access: access); }
    catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }
}