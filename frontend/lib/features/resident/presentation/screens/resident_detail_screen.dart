import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/models/access.dart';
import '../../../../core/models/resident.dart';
import '../../../../shared/widgets/custom_text_field.dart';

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

  Future<void> _generateQr(Resident resident) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(residentApiProvider).generateQrCode(resident.id);
      messenger.showSnackBar(const SnackBar(content: Text('QR generado')));
      await ref.read(residentDetailProvider(widget.residentId).notifier).load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showEditDialog(Resident resident) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _EditResidentDialog(resident: resident),
    );
    if (updated == true) {
      await ref.read(residentDetailProvider(widget.residentId).notifier).load();
    }
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

class _EditResidentDialog extends ConsumerStatefulWidget {
  final Resident resident;
  const _EditResidentDialog({required this.resident});

  @override
  ConsumerState<_EditResidentDialog> createState() => _EditResidentDialogState();
}

class _EditResidentDialogState extends ConsumerState<_EditResidentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(text: widget.resident.user.firstName);
  late final _lastNameController = TextEditingController(text: widget.resident.user.lastName);
  late final _phoneController = TextEditingController(text: widget.resident.user.phone ?? '');
  late final _rutController = TextEditingController(text: widget.resident.rut ?? '');
  late final _emergencyNameController = TextEditingController(text: widget.resident.emergencyContactName ?? '');
  late final _emergencyPhoneController = TextEditingController(text: widget.resident.emergencyContactPhone ?? '');
  late final _emergencyRelationController = TextEditingController(text: widget.resident.emergencyContactRelation ?? '');
  late final _vehiclePlatesController = TextEditingController(text: widget.resident.vehiclePlates.join(', '));
  late ResidentStatus _status = widget.resident.status;
  bool _submitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _rutController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _vehiclePlatesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final plates = _vehiclePlatesController.text
        .split(',')
        .map((p) => p.trim().toUpperCase())
        .where((p) => p.isNotEmpty && p != widget.resident.vehiclePlates.join(', '))
        .toList();
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(residentApiProvider).updateResident(widget.resident.id, {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'rut': _rutController.text.trim().isEmpty ? null : _rutController.text.trim(),
        'emergencyContactName': _emergencyNameController.text.trim().isEmpty ? null : _emergencyNameController.text.trim(),
        'emergencyContactPhone': _emergencyPhoneController.text.trim().isEmpty ? null : _emergencyPhoneController.text.trim(),
        'emergencyContactRelation': _emergencyRelationController.text.trim().isEmpty ? null : _emergencyRelationController.text.trim(),
        'vehiclePlates': plates,
        'status': _status.name.toUpperCase(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        messenger.showSnackBar(const SnackBar(content: Text('Residente actualizado'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar ${widget.resident.user.fullName}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(child: CustomTextField(controller: _firstNameController, label: 'Nombre *', prefixIcon: Icons.person,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null)),
                const SizedBox(width: 12),
                Expanded(child: CustomTextField(controller: _lastNameController, label: 'Apellido *', validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null)),
              ]),
              const SizedBox(height: 12),
              CustomTextField(controller: _phoneController, label: 'Teléfono', prefixIcon: Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              CustomTextField(controller: _rutController, label: 'RUT/RFC', prefixIcon: Icons.badge),
              const SizedBox(height: 12),
              CustomTextField(controller: _vehiclePlatesController, label: 'Placas (separadas por coma)', prefixIcon: Icons.directions_car),
              const SizedBox(height: 16),
              DropdownButtonFormField<ResidentStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                items: ResidentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s)))).toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 16),
              const Divider(),
              CustomTextField(controller: _emergencyNameController, label: 'Contacto de emergencia (nombre)', prefixIcon: Icons.person_outline),
              const SizedBox(height: 12),
              CustomTextField(controller: _emergencyPhoneController, label: 'Contacto de emergencia (tel)', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              CustomTextField(controller: _emergencyRelationController, label: 'Relación', prefixIcon: Icons.family_restroom),
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
              : const Text('Guardar'),
        ),
      ],
    );
  }

  String _statusLabel(ResidentStatus s) {
    switch (s) {
      case ResidentStatus.active: return 'Activo';
      case ResidentStatus.pending: return 'Pendiente';
      case ResidentStatus.inactive: return 'Inactivo';
      case ResidentStatus.suspended: return 'Suspendido';
    }
  }
}

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