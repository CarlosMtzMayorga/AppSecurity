import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/models/access.dart';
import '../../../../core/models/resident.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';
import 'access_screen.dart';

class VisitorManagementScreen extends ConsumerStatefulWidget {
  const VisitorManagementScreen({super.key});

  @override
  ConsumerState<VisitorManagementScreen> createState() => _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends ConsumerState<VisitorManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVisitors());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVisitors() async {
    await ref.read(myVisitorsProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myVisitorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Visitantes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadVisitors),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomSearchField(
              controller: _searchController,
              hint: 'Buscar visitantes...',
              onChanged: (_) => ref.read(myVisitorsProvider.notifier).load(),
              onClear: () => ref.read(myVisitorsProvider.notifier).load(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadVisitors,
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.visitors.isEmpty
                      ? _EmptyState(icon: Icons.person_add, title: 'Sin visitantes registrados', subtitle: 'Agrega tu primer visitante')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.visitors.length,
                          itemBuilder: (context, index) => _VisitorCard(visitor: state.visitors[index], onChanged: _loadVisitors),
                        ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              text: 'Registrar Nuevo Visitante',
              icon: Icons.person_add,
              onPressed: _showAddVisitorDialog,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVisitorDialog() {
    showDialog(context: context, builder: (context) => _AddVisitorDialog(onSuccess: _loadVisitors));
  }
}

class _VisitorCard extends ConsumerWidget {
  final Visitor visitor;
  final VoidCallback onChanged;

  const _VisitorCard({required this.visitor, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(visitor.firstName[0].toUpperCase())),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(visitor.fullName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (visitor.phone != null) Text(visitor.phone!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: visitor.isRecurring ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(visitor.isRecurring ? 'Recurrente' : 'Único', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: visitor.isRecurring ? Colors.blue : Colors.grey)),
                ),
              ],
            ),
            if (visitor.vehiclePlate != null) ...[
              const SizedBox(height: 12),
              Row(children: [Icon(Icons.directions_car, size: 16, color: theme.colorScheme.onSurfaceVariant), const SizedBox(width: 8), Text('Placa: ${visitor.vehiclePlate}', style: theme.textTheme.bodySmall)]),
            ],
            if (visitor.accesses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(),
              Text('Últimos accesos (${visitor.accesses.length})', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...visitor.accesses.take(3).map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Icon(a.status == AccessStatus.approved ? Icons.check_circle : Icons.cancel, size: 16, color: a.status == AccessStatus.approved ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Text('${DateFormat('dd/MM HH:mm').format(a.entryTime ?? DateTime.now())} - ${a.status.name.toUpperCase()}', style: theme.textTheme.bodySmall),
                ]),
              )),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (visitor.entryCode != null) ...[
                  TextButton.icon(onPressed: () => showVisitorTokenDialog(context, visitor), icon: const Icon(Icons.qr_code_2, size: 18), label: const Text('Token')),
                  const SizedBox(width: 8),
                ],
                TextButton.icon(onPressed: () => _editVisitor(context), icon: const Icon(Icons.edit, size: 18), label: const Text('Editar')),
                const SizedBox(width: 8),
                TextButton.icon(onPressed: () => _deleteVisitor(context, ref, visitor.id), icon: const Icon(Icons.delete, size: 18), label: const Text('Eliminar'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editVisitor(BuildContext context) {
    showDialog(context: context, builder: (context) => _EditVisitorDialog(visitor: visitor, onSuccess: onChanged));
  }

  Future<void> _deleteVisitor(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(visitorApiProvider).deleteVisitor(id);
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitante eliminado')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _AddVisitorDialog extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const _AddVisitorDialog({required this.onSuccess});

  @override
  ConsumerState<_AddVisitorDialog> createState() => _AddVisitorDialogState();
}

class _AddVisitorDialogState extends ConsumerState<_AddVisitorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _documentTypeController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isRecurring = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _documentTypeController.dispose();
    _documentNumberController.dispose();
    _vehiclePlateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Visitante'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(child: CustomTextField(controller: _firstNameController, label: 'Nombre', validator: (v) => v?.isEmpty == true ? 'Requerido' : null)),
                const SizedBox(width: 12),
                Expanded(child: CustomTextField(controller: _lastNameController, label: 'Apellido', validator: (v) => v?.isEmpty == true ? 'Requerido' : null)),
              ]),
              const SizedBox(height: 16),
              CustomTextField(controller: _phoneController, label: 'Teléfono', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              CustomTextField(controller: _emailController, label: 'Email (opcional)', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              CustomTextField(controller: _vehiclePlateController, label: 'Placa del vehículo (opcional)'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: CustomTextField(controller: _documentTypeController, label: 'Tipo documento (INE, Pasaporte, etc.)')),
                const SizedBox(width: 12),
                Expanded(child: CustomTextField(controller: _documentNumberController, label: 'Número documento')),
              ]),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Visitante recurrente'),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              CustomTextField(controller: _notesController, label: 'Notas (opcional)', maxLines: 2),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Registrar'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(visitorApiProvider).createVisitor({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'vehiclePlate': _vehiclePlateController.text.trim().isEmpty ? null : _vehiclePlateController.text.trim(),
        'documentType': _documentTypeController.text.trim().isEmpty ? null : _documentTypeController.text.trim(),
        'documentNumber': _documentNumberController.text.trim().isEmpty ? null : _documentNumberController.text.trim(),
        'isRecurring': _isRecurring,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      });
      if (mounted) { Navigator.pop(context); widget.onSuccess(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitante registrado'))); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }
}

class _EditVisitorDialog extends ConsumerStatefulWidget {
  final Visitor visitor;
  final VoidCallback onSuccess;

  const _EditVisitorDialog({required this.visitor, required this.onSuccess});

  @override
  ConsumerState<_EditVisitorDialog> createState() => _EditVisitorDialogState();
}

class _EditVisitorDialogState extends ConsumerState<_EditVisitorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(text: widget.visitor.firstName);
  late final _lastNameController = TextEditingController(text: widget.visitor.lastName);
  late final _phoneController = TextEditingController(text: widget.visitor.phone ?? '');
  late final _emailController = TextEditingController(text: widget.visitor.email ?? '');
  late final _documentTypeController = TextEditingController(text: widget.visitor.documentType ?? '');
  late final _documentNumberController = TextEditingController(text: widget.visitor.documentNumber ?? '');
  late final _vehiclePlateController = TextEditingController(text: widget.visitor.vehiclePlate ?? '');
  late final _notesController = TextEditingController(text: widget.visitor.notes ?? '');
  late bool _isRecurring = widget.visitor.isRecurring;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _documentTypeController.dispose();
    _documentNumberController.dispose();
    _vehiclePlateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Visitante'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(child: CustomTextField(controller: _firstNameController, label: 'Nombre', validator: (v) => v?.isEmpty == true ? 'Requerido' : null)),
                const SizedBox(width: 12),
                Expanded(child: CustomTextField(controller: _lastNameController, label: 'Apellido', validator: (v) => v?.isEmpty == true ? 'Requerido' : null)),
              ]),
              const SizedBox(height: 16),
              CustomTextField(controller: _phoneController, label: 'Teléfono', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              CustomTextField(controller: _emailController, label: 'Email (opcional)', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              CustomTextField(controller: _vehiclePlateController, label: 'Placa del vehículo (opcional)'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: CustomTextField(controller: _documentTypeController, label: 'Tipo documento (INE, Pasaporte, etc.)')),
                const SizedBox(width: 12),
                Expanded(child: CustomTextField(controller: _documentNumberController, label: 'Número documento')),
              ]),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Visitante recurrente'),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              CustomTextField(controller: _notesController, label: 'Notas (opcional)', maxLines: 2),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(visitorApiProvider).updateVisitor(widget.visitor.id, {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'vehiclePlate': _vehiclePlateController.text.trim().isEmpty ? null : _vehiclePlateController.text.trim(),
        'documentType': _documentTypeController.text.trim().isEmpty ? null : _documentTypeController.text.trim(),
        'documentNumber': _documentNumberController.text.trim().isEmpty ? null : _documentNumberController.text.trim(),
        'isRecurring': _isRecurring,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitante actualizado')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _isLoading = false); }
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