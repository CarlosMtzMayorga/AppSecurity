import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/app_config.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/models/user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(authStateProvider).user;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (_isEditing) ...[
            TextButton(onPressed: _cancelEdit, child: const Text('Cancelar')),
            FilledButton(onPressed: _isLoading ? null : _saveProfile, child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar')),
          ] else
            IconButton(onPressed: () => setState(() => _isEditing = true), icon: const Icon(Icons.edit)),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No hay usuario logueado'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildAvatar(user),
                    const SizedBox(height: 24),
                    _buildBasicInfo(),
                    const SizedBox(height: 24),
                    _buildResidentInfo(user),
                    const SizedBox(height: 24),
                    _buildSecurityInfo(),
                    const SizedBox(height: 24),
                    _buildAppInfo(),
                  ],
                ),
              ),
            ),
    );
  }

  String _resolveAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null) return '';
    if (avatarUrl.startsWith('http')) return avatarUrl;
    final base = AppConfig.baseUrl.replaceAll(RegExp(r'/api/v1$'), '');
    return '$base$avatarUrl';
  }

  Widget _buildAvatar(User user) {
    final theme = Theme.of(context);
    final avatarUrl = _resolveAvatarUrl(user.avatarUrl);
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? Text(
                  user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                  style: theme.textTheme.displayLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                )
              : null,
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: _pickImage,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información Personal', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_firstNameController, 'Nombre', _isEditing)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_lastNameController, 'Apellido', _isEditing)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_phoneController, 'Teléfono', _isEditing, keyboardType: TextInputType.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool enabled, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) => v?.isEmpty == true ? '$label requerido' : null,
    );
  }

  Widget _buildResidentInfo(User user) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información Residencial', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _InfoRow(label: 'Email', value: user.email, icon: Icons.email),
            _InfoRow(label: 'Rol', value: _getRoleLabel(user.role), icon: Icons.badge),
            if (user.unit != null) ...[
              _InfoRow(label: 'Unidad', value: user.unit!.displayNumber, icon: Icons.home),
            ],
            if (user.residentStatus != null) ...[
              _InfoRow(label: 'Estado', value: _getResidentStatusLabel(user.residentStatus!), icon: Icons.info),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seguridad', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Cambiar Contraseña'),
              subtitle: const Text('Actualizar tu contraseña de acceso'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings'),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Sesiones Activas'),
              subtitle: const Text('Ver y gestionar dispositivos conectados'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Biometría'),
              subtitle: const Text('Configurar huella/rostro para acceso rápido'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aplicación', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _InfoRow(label: 'Versión', value: '1.0.0', icon: Icons.info),
            _InfoRow(label: 'Build', value: '1', icon: Icons.build),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings),
              label: const Text('Configuración Completa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _InfoRow({required String label, required String value, required IconData icon}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  void _cancelEdit() {
    _loadUserData();
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authStateProvider.notifier).updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (image == null) return;
    try {
      final bytes = await image.readAsBytes();
      final filename = image.name.split('/').last.split('\\').last;
      await ref.read(authStateProvider.notifier).uploadAvatar(bytes, filename);
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Foto de perfil actualizada')));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Administrador';
      case UserRole.resident: return 'Residente';
      case UserRole.security: return 'Seguridad';
      case UserRole.committee: return 'Comité';
    }
  }

  String _getResidentStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE': return 'Activo';
      case 'PENDING': return 'Pendiente';
      case 'INACTIVE': return 'Inactivo';
      case 'SUSPENDED': return 'Suspendido';
      default: return status;
    }
  }
}