import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/models/access.dart';
import '../../../../core/models/resident.dart';

class ResidentDetailScreen extends ConsumerStatefulWidget {
  final String residentId;
  
  const ResidentDetailScreen({super.key, required this.residentId});

  @override
  ConsumerState<ResidentDetailScreen> createState() => _ResidentDetailScreenState();
}

class _ResidentDetailScreenState extends ConsumerState<ResidentDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadResident();
  }

  Future<void> _loadResident() async {
    await ref.read(residentDetailProvider(widget.residentId).notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(residentDetailProvider(widget.residentId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle Residente'),
        actions: [
          if (state.resident != null) ...[
            IconButton(icon: const Icon(Icons.qr_code), onPressed: () => _generateQr(state.resident!)),
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(state.resident!)),
          ],
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.resident == null
              ? Center(child: Text(state.error ?? 'Residente no encontrado'))
              : _buildDetail(state.resident!),
    );
  }

  Widget _buildDetail(Resident resident) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      resident.user.firstName.isNotEmpty ? resident.user.firstName[0].toUpperCase() : 'U',
                      style: theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resident.user.fullName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(resident.unit.displayNumber),
                              avatar: const Icon(Icons.home, size: 16),
                              backgroundColor: theme.colorScheme.primaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(_getStatusLabel(resident.status)),
                              backgroundColor: _getStatusColor(resident.status).withOpacity(0.1),
                              labelStyle: TextStyle(color: _getStatusColor(resident.status)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('Información Personal', [
            _InfoRow(label: 'Email', value: resident.user.email, icon: Icons.email),
            _InfoRow(label: 'Teléfono', value: resident.user.phone ?? 'No registrado', icon: Icons.phone),
            _InfoRow(label: 'RUT/RFC', value: resident.rut ?? 'No registrado', icon: Icons.badge),
            _InfoRow(label: 'Fecha ingreso', value: DateFormat('dd/MM/yyyy').format(resident.joinedAt), icon: Icons.calendar_today),
            if (resident.approvedAt != null)
              _InfoRow(label: 'Aprobado el', value: DateFormat('dd/MM/yyyy').format(resident.approvedAt!), icon: Icons.check_circle),
          ]),
          const SizedBox(height: 16),
          if (resident.vehiclePlates.isNotEmpty) ...[
            _buildSection('Vehículos', resident.vehiclePlates.map((p) => _InfoRow(label: 'Placa', value: p, icon: Icons.directions_car)).toList()),
            const SizedBox(height: 16),
          ],
          _buildSection('Contacto de Emergencia', [
            _InfoRow(label: 'Nombre', value: resident.emergencyContactName ?? 'No registrado', icon: Icons.person),
            _InfoRow(label: 'Teléfono', value: resident.emergencyContactPhone ?? 'No registrado', icon: Icons.phone),
            _InfoRow(label: 'Relación', value: resident.emergencyContactRelation ?? 'No registrado', icon: Icons.family_restroom),
          ]),
          const SizedBox(height: 16),
          if (resident.visitors.isNotEmpty) ...[
            _buildSection('Visitantes Registrados (${resident.visitors.length})', [
              ...resident.visitors.take(5).map((v) => ListTile(
                leading: CircleAvatar(child: Text(v.firstName[0].toUpperCase())),
                title: Text(v.fullName),
                subtitle: Text(v.phone ?? 'Sin teléfono'),
                trailing: v.isRecurring ? const Chip(label: Text('Recurrente'), avatar: Icon(Icons.repeat, size: 14)) : null,
              )),
              if (resident.visitors.length > 5)
                TextButton(onPressed: () {}, child: Text('Ver ${resident.visitors.length - 5} más...')),
            ]),
            const SizedBox(height: 16),
          ],
          if (resident.accesses.isNotEmpty) ...[
            _buildSection('Últimos Accesos (${resident.accesses.length})', [
              ...resident.accesses.take(5).map((a) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getAccessStatusColor(a.status).withOpacity(0.1),
                  child: Icon(a.type == AccessType.resident ? Icons.person : Icons.person_add, color: _getAccessStatusColor(a.status), size: 20),
                ),
                title: Text(_formatDateTime(a.entryTime)),
                subtitle: Text('${a.type.name.toUpperCase()} • ${a.status.name.toUpperCase()}'),
                trailing: a.exitTime != null ? Text(_formatTime(a.exitTime!)) : const Chip(label: Text('Dentro'), backgroundColor: Colors.green),
              )),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _InfoRow({required String label, required String value, required IconData icon}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.bodyMedium),
          ])),
        ],
      ),
    );
  }

  void _generateQr(Resident resident) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generando QR...')));
  }

  void _showEditDialog(Resident resident) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edición en desarrollo')));
  }

  String _formatDateTime(DateTime? dt) => dt != null ? DateFormat('dd/MM/yyyy HH:mm').format(dt) : 'Sin fecha';
  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);
  
  Color _getStatusColor(ResidentStatus status) {
    switch (status) {
      case ResidentStatus.active: return Colors.green;
      case ResidentStatus.pending: return Colors.orange;
      case ResidentStatus.inactive: return Colors.grey;
      case ResidentStatus.suspended: return Colors.red;
    }
  }
  
  String _getStatusLabel(ResidentStatus status) {
    switch (status) {
      case ResidentStatus.active: return 'Activo';
      case ResidentStatus.pending: return 'Pendiente';
      case ResidentStatus.inactive: return 'Inactivo';
      case ResidentStatus.suspended: return 'Suspendido';
    }
  }
  
  Color _getAccessStatusColor(AccessStatus status) {
    switch (status) {
      case AccessStatus.approved: return Colors.green;
      case AccessStatus.pending: return Colors.orange;
      case AccessStatus.rejected: return Colors.red;
      case AccessStatus.completed: return Colors.blue;
      default: return Colors.grey;
    }
  }
}

final residentDetailProvider = StateNotifierProvider.family<ResidentDetailNotifier, ResidentDetailState, String>((ref, id) {
  return ResidentDetailNotifier(ref.read(residentApiProvider), id);
});

class ResidentDetailState {
  final Resident? resident;
  final bool isLoading;
  final String? error;
  
  const ResidentDetailState({this.resident, this.isLoading = false, this.error});
  
  ResidentDetailState copyWith({Resident? resident, bool? isLoading, String? error}) =>
      ResidentDetailState(resident: resident ?? this.resident, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class ResidentDetailNotifier extends StateNotifier<ResidentDetailState> {
  final ResidentApi _api;
  final String _id;
  
  ResidentDetailNotifier(this._api, this._id) : super(const ResidentDetailState()) {
    load();
  }
  
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final resident = await _api.getResident(_id);
      state = state.copyWith(isLoading: false, resident: resident);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}