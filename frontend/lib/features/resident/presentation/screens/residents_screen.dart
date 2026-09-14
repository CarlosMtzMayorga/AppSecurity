import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/models/resident.dart';
import '../../../../core/models/unit.dart' hide ResidentStatus;
import '../../../../shared/widgets/custom_text_field.dart';

class ResidentsScreen extends ConsumerStatefulWidget {
  const ResidentsScreen({super.key});

  @override
  ConsumerState<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends ConsumerState<ResidentsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'ALL';
  int _page = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResidents({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() { _isLoading = true; if (refresh) _page = 1; });
    
    try {
      await ref.read(residentsProvider.notifier).loadResidents(
        page: _page,
        status: _statusFilter == 'ALL' ? null : _statusFilter,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(residentsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Residentes'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddResidentDialog()),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomSearchField(
              controller: _searchController,
              hint: 'Buscar residentes...',
              onChanged: (_) => _loadResidents(refresh: true),
              onClear: () => _loadResidents(refresh: true),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadResidents(refresh: true),
              child: _isLoading && state.residents.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.residents.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.residents.length) {
                          if (!_isLoading && state.hasMore) {
                            _page++;
                            _loadResidents();
                          }
                          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                        }
                        final resident = state.residents[index];
                        return _ResidentCard(resident: resident, onTap: () => context.push('/residents/${resident.id}'));
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddResidentDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _AddResidentDialog(),
    );
    if (created == true) _loadResidents(refresh: true);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['ALL', 'ACTIVE', 'PENDING', 'INACTIVE', 'SUSPENDED'].map((status) => RadioListTile<String>(
            title: Text(_getStatusLabel(status)),
            value: status,
            groupValue: _statusFilter,
            onChanged: (value) { setState(() => _statusFilter = value!); Navigator.pop(context); _loadResidents(refresh: true); },
          )).toList(),
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ALL': return 'Todos';
      case 'ACTIVE': return 'Activos';
      case 'PENDING': return 'Pendientes';
      case 'INACTIVE': return 'Inactivos';
      case 'SUSPENDED': return 'Suspendidos';
      default: return status;
    }
  }
}

class _AddResidentDialog extends ConsumerStatefulWidget {
  const _AddResidentDialog();

  @override
  ConsumerState<_AddResidentDialog> createState() => _AddResidentDialogState();
}

class _AddResidentDialogState extends ConsumerState<_AddResidentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rutController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _vehiclePlatesController = TextEditingController();
  List<Unit> _units = [];
  bool _loadingUnits = true;
  Unit? _selectedUnit;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _loadUnits() async {
    setState(() => _loadingUnits = true);
    try {
      final response = await ref.read(unitApiProvider).getUnits(limit: 200);
      if (mounted) {
        setState(() {
          _units = response.data.where((u) => u.isActive && !u.hasResident).toList();
          _loadingUnits = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingUnits = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una unidad')));
      return;
    }
    final plates = _vehiclePlatesController.text
        .split(',')
        .map((p) => p.trim().toUpperCase())
        .where((p) => p.isNotEmpty)
        .toList();
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(residentApiProvider).createResident({
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'unitId': _selectedUnit!.id,
        'rut': _rutController.text.trim().isEmpty ? null : _rutController.text.trim(),
        if (_emergencyNameController.text.trim().isNotEmpty) 'emergencyContactName': _emergencyNameController.text.trim(),
        if (_emergencyPhoneController.text.trim().isNotEmpty) 'emergencyContactPhone': _emergencyPhoneController.text.trim(),
        if (_emergencyRelationController.text.trim().isNotEmpty) 'emergencyContactRelation': _emergencyRelationController.text.trim(),
        if (plates.isNotEmpty) 'vehiclePlates': plates,
      });
      if (mounted) {
        Navigator.pop(context, true);
        messenger.showSnackBar(const SnackBar(content: Text('Residente creado'), backgroundColor: Colors.green));
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
      title: const Text('Agregar Residente'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loadingUnits)
                const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
              else
                DropdownButtonFormField<Unit>(
                  initialValue: _selectedUnit,
                  decoration: const InputDecoration(labelText: 'Unidad *', border: OutlineInputBorder()),
                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text('${u.displayNumber}  (${u.monthlyFee.toStringAsFixed(2)}/mes)'))).toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v),
                ),
              const SizedBox(height: 12),
              CustomTextField(controller: _emailController, label: 'Email *', hint: 'correo@ejemplo.com', prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.trim().isEmpty || !v.contains('@') ? 'Email válido requerido' : null),
              const SizedBox(height: 12),
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
              CustomTextField(controller: _vehiclePlatesController, label: 'Placas (separadas por coma)', prefixIcon: Icons.directions_car,
                hint: 'ABC-123, XYZ-789'),
              const SizedBox(height: 16),
              Divider(),
              CustomTextField(controller: _emergencyNameController, label: 'Contacto de emergencia (nombre)', prefixIcon: Icons.person_outline),
              const SizedBox(height: 12),
              CustomTextField(controller: _emergencyPhoneController, label: 'Contacto de emergencia (tel)', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              CustomTextField(controller: _emergencyRelationController, label: 'Relación', prefixIcon: Icons.family_restroom,
                hint: 'Ej: Familiar'),
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
              : const Text('Crear Residente'),
        ),
      ],
    );
  }
}

class _ResidentCard extends StatelessWidget {
  final Resident resident;
  final VoidCallback onTap;

  const _ResidentCard({required this.resident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(resident.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  resident.user.firstName.isNotEmpty ? resident.user.firstName[0].toUpperCase() : 'U',
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(resident.user.fullName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(_getStatusLabel(resident.status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(resident.unit.displayNumber, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(resident.user.email, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

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
}

final residentsProvider = StateNotifierProvider<ResidentsNotifier, ResidentsState>((ref) {
  return ResidentsNotifier(ref.read(residentApiProvider));
});

class ResidentsState {
  final List<Resident> residents;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const ResidentsState({this.residents = const [], this.isLoading = false, this.hasMore = true, this.error});
  
  ResidentsState copyWith({List<Resident>? residents, bool? isLoading, bool? hasMore, String? error}) =>
      ResidentsState(residents: residents ?? this.residents, isLoading: isLoading ?? this.isLoading, hasMore: hasMore ?? this.hasMore, error: error ?? this.error);
}

class ResidentsNotifier extends StateNotifier<ResidentsState> {
  final ResidentApi _api;
  
  ResidentsNotifier(this._api) : super(const ResidentsState());

  Future<void> loadResidents({int page = 1, String? status, String? search}) async {
    if (page == 1) state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getResidents(page: page, status: status, search: search);
      final newResidents = page == 1 ? response.data : [...state.residents, ...response.data];
      state = state.copyWith(residents: newResidents, isLoading: false, hasMore: response.hasNextPage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}