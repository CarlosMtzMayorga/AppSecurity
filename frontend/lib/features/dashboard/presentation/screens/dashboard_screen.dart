import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user.dart';
import '../../../../core/providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).user;
    final isResident = user?.role == UserRole.resident;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _Header(user: user),
            const SizedBox(height: 24),
            _MenuTile(
              icon: Icons.sensors,
              title: 'Accesos',
              subtitle: 'Portones, botonera y acceso peatonal',
              onTap: () => context.push('/access'),
            ),
            _MenuTile(
              icon: Icons.campaign,
              title: 'Panel de Avisos',
              subtitle: 'Avisos y comunicados de la administración',
              onTap: () => context.push('/notices'),
            ),
            _MenuTile(
              icon: Icons.payments,
              title: 'Pago',
              subtitle: 'Ver desglose y realizar pagos',
              onTap: () => context.push('/payments'),
            ),
            _MenuTile(
              icon: Icons.history,
              title: 'Bitácora',
              subtitle: 'Reporte de accesos de la comunidad',
              onTap: () => context.push('/access'),
            ),
            _MenuTile(
              icon: Icons.group_add,
              title: 'Delegar',
              subtitle: 'Tokens y accesos para familia y visitas',
              onTap: () => context.push('/visitors'),
            ),
            if (!isResident) ...[
              const SizedBox(height: 8),
              Text('Administración', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              _MenuTile(icon: Icons.people, title: 'Residentes', subtitle: 'Administrar residentes y unidades', onTap: () => context.push('/residents')),
              _MenuTile(icon: Icons.event_seat, title: 'Reservas', subtitle: 'Reservaciones de amenidades', onTap: () => context.push('/bookings')),
              _MenuTile(icon: Icons.build, title: 'Servicios', subtitle: 'Solicitudes e incidencias', onTap: () => context.push('/services')),
              _MenuTile(icon: Icons.account_balance, title: 'Contabilidad', subtitle: 'Finanzas de la colonia', onTap: () => context.push('/accounting')),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final User? user;

  const _Header({this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            user?.firstName.isNotEmpty == true ? user!.firstName[0].toUpperCase() : 'A',
            style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¡Hola, ${user?.firstName ?? 'Usuario'}!', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                user?.email ?? '',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tokens',
          icon: const Icon(Icons.qr_code_2),
          onPressed: () => context.push('/visitors'),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Preferencias',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}