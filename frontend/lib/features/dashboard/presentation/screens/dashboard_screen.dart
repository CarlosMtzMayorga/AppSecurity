import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/models/dashboard.dart';
import '../../../shared/widgets/custom_button.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await ref.read(dashboardProvider.notifier).loadOverview();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final dashboardState = ref.watch(dashboardProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Control'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notices')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: dashboardState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(authState.user),
                    const SizedBox(height: 24),
                    _buildStatsGrid(dashboardState.overview),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(dashboardState.recentActivity),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeCard(User? user) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user?.firstName.isNotEmpty == true ? user!.firstName[0].toUpperCase() : 'U',
                style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${user?.firstName ?? 'Usuario'}!',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    user?.unit != null ? 'Unidad ${user!.unit!.displayNumber}' : 'Sin unidad asignada',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            CustomButton(text: 'Mi Acceso', icon: Icons.directions_walk, onPressed: () => context.push('/access')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardOverview? overview) {
    final theme = Theme.of(context);
    if (overview == null) return const SizedBox();

    final stats = [
      ('Residentes', '${overview.residents.active}/${overview.residents.total}', Icons.people, theme.colorScheme.primary),
      ('Unidades', '${overview.units.occupied}/${overview.units.total}', Icons.home, theme.colorScheme.secondary),
      ('Pagos Pendientes', '${overview.payments.pending}', Icons.payments, theme.colorScheme.tertiary),
      ('Servicios Abiertos', '${overview.services.open}', Icons.build, Colors.orange),
      ('Accesos Activos', '${overview.activeAccesses}', Icons.security, Colors.purple),
      ('Balance', '\$${overview.finances.balance.toStringAsFixed(0)}', Icons.account_balance, overview.finances.balance >= 0 ? Colors.green : Colors.red),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final (title, value, icon, color) = stats[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),
                Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Accesos Rápidos', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionCard(icon: Icons.directions_walk, label: 'Entrada/Salida', color: Colors.blue, onTap: () => context.push('/access')),
            _QuickActionCard(icon: Icons.person_add, label: 'Registrar Visitante', color: Colors.green, onTap: () => context.push('/visitors')),
            _QuickActionCard(icon: Icons.payment, label: 'Ver Pagos', color: Colors.orange, onTap: () => context.push('/payments')),
            _QuickActionCard(icon: Icons.event_seat, label: 'Reservar Amenidad', color: Colors.purple, onTap: () => context.push('/bookings')),
            _QuickActionCard(icon: Icons.build, label: 'Reportar Incidencia', color: Colors.red, onTap: () => context.push('/services')),
            _QuickActionCard(icon: Icons.announcement, label: 'Ver Avisos', color: Colors.teal, onTap: () => context.push('/notices')),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(RecentActivity? activity) {
    final theme = Theme.of(context);
    if (activity == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Actividad Reciente', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            TextButton(onPressed: () {}, child: const Text('Ver todo')),
          ],
        ),
        const SizedBox(height: 12),
        if (activity.recentAccesses.isNotEmpty) ...[
          Text('Accesos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ...activity.recentAccesses.take(3).map((a) => _ActivityTile(
            icon: a.type == AccessType.resident ? Icons.person : Icons.person_add,
            title: a.displayName,
            subtitle: '${a.unitDisplay} • ${_formatTime(a.entryTime)}',
            status: _getStatusColor(a.status),
          )),
        ],
      ],
    );
  }

  Widget _ActivityTile({required IconData icon, required String title, required String subtitle, required Color status}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: status.withOpacity(0.1), child: Icon(icon, color: status, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: Container(width: 10, height: 10, decoration: BoxDecoration(color: status, shape: BoxShape.circle)),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Sin hora';
    return DateFormat('HH:mm').format(time);
  }

  Color _getStatusColor(AccessStatus status) {
    switch (status) {
      case AccessStatus.approved: return Colors.green;
      case AccessStatus.pending: return Colors.orange;
      case AccessStatus.rejected: return Colors.red;
      case AccessStatus.completed: return Colors.blue;
      default: return Colors.grey;
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.read(dashboardApiProvider));
});

class DashboardState {
  final bool isLoading;
  final DashboardOverview? overview;
  final RecentActivity? recentActivity;
  final String? error;

  const DashboardState({this.isLoading = false, this.overview, this.recentActivity, this.error});
  
  DashboardState copyWith({bool? isLoading, DashboardOverview? overview, RecentActivity? recentActivity, String? error}) =>
      DashboardState(isLoading: isLoading ?? this.isLoading, overview: overview ?? this.overview, recentActivity: recentActivity ?? this.recentActivity, error: error ?? this.error);
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardApi _api;
  
  DashboardNotifier(this._api) : super(const DashboardState());

  Future<void> loadOverview() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final [overview, activity] = await Future.wait([
        _api.getOverview(),
        _api.getRecentActivity(),
      ]);
      state = state.copyWith(isLoading: false, overview: overview, recentActivity: activity);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}