import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/models/user.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final isAdmin = authState.user?.role == UserRole.admin || authState.user?.role == UserRole.committee;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Cuenta', [
            _SettingsTile(icon: Icons.person, title: 'Mi Perfil', subtitle: 'Editar información personal', onTap: () => context.push('/profile')),
            _SettingsTile(icon: Icons.lock, title: 'Cambiar Contraseña', subtitle: 'Actualizar credenciales', onTap: _showChangePassword),
            _SettingsTile(icon: Icons.notifications, title: 'Notificaciones', subtitle: 'Configurar alertas', onTap: () {}),
            _SettingsTile(icon: Icons.language, title: 'Idioma', subtitle: 'Español', onTap: () {}),
          ]),
          if (isAdmin) ...[
            const SizedBox(height: 24),
            _buildSection('Administración', [
              _SettingsTile(icon: Icons.apartment, title: 'Datos del Fraccionamiento', subtitle: 'Nombre, dirección, contacto', onTap: _editComplexInfo),
              _SettingsTile(icon: Icons.security, title: 'Control de Accesos', subtitle: 'Configurar caseta, horarios, requerimientos', onTap: _editAccessConfig),
              _SettingsTile(icon: Icons.settings, title: 'Configuración General', subtitle: 'Cuotas, multas, notificaciones', onTap: _editSettings),
              _SettingsTile(icon: Icons.payment, title: 'Stripe / Pagos', subtitle: 'Claves API, webhooks', onTap: _editStripeConfig),
              _SettingsTile(icon: Icons.home, title: 'Unidades', subtitle: 'Gestionar casas/departamentos', onTap: () {}),
              _SettingsTile(icon: Icons.meeting_room, title: 'Amenidades', subtitle: 'Crear y configurar espacios', onTap: () {}),
            ]),
          ],
          const SizedBox(height: 24),
          _buildSection('Acerca de', [
            _SettingsTile(icon: Icons.info, title: 'Versión de la App', subtitle: '1.0.0', onTap: () {}),
            _SettingsTile(icon: Icons.help, title: 'Ayuda y Soporte', subtitle: 'Preguntas frecuentes, contacto', onTap: () {}),
            _SettingsTile(icon: Icons.privacy_tip, title: 'Política de Privacidad', subtitle: 'Términos y condiciones', onTap: () {}),
          ]),
          const SizedBox(height: 32),
          FilledButton.tonalIcon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
            style: FilledButton.styleFrom(foregroundColor: theme.colorScheme.error),
          ),
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

  void _showChangePassword() {
    showDialog(context: context, builder: (context) => _ChangePasswordDialog());
  }

  void _editComplexInfo() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En desarrollo')));
  }

  void _editAccessConfig() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En desarrollo')));
  }

  void _editSettings() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En desarrollo')));
  }

  void _editStripeConfig() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En desarrollo')));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Cerrar Sesión'),
      content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar Sesión')),
      ],
    ));
    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  @override ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override void dispose() { _currentController.dispose(); _newController.dispose(); _confirmController.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar Contraseña'),
      content: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: _currentController, decoration: const InputDecoration(labelText: 'Contraseña actual'), obscureText: true, validator: (v) => v?.isEmpty == true ? 'Requerido' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _newController, decoration: const InputDecoration(labelText: 'Nueva contraseña'), obscureText: true, validator: (v) => v != null && v.length < 8 ? 'Mínimo 8 caracteres' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _confirmController, decoration: const InputDecoration(labelText: 'Confirmar nueva'), obscureText: true, validator: (v) => v != _newController.text ? 'No coinciden' : null),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _isLoading ? null : _changePassword, child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Cambiar')),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authStateProvider.notifier).changePassword(_currentController.text, _newController.text);
      if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña cambiada. Inicia sesión nuevamente.'))); }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }
}