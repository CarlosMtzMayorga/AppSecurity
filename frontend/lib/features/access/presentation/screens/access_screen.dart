import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/models/access.dart';
import '../../../../core/models/resident.dart';
import '../../../../core/models/user.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class AccessScreen extends ConsumerStatefulWidget {
  const AccessScreen({super.key});

  @override
  ConsumerState<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends ConsumerState<AccessScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  bool get _isResident => ref.read(authStateProvider).user?.role == UserRole.resident;
  int get _tabCount => _isResident ? 4 : 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(accessLogsProvider.notifier).loadLogs(),
      ref.read(activeAccessesProvider.notifier).loadActive(),
      ref.read(vehicleBlockProvider.notifier).load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isResident = _isResident;

    final tabs = <Tab>[
      if (isResident) const Tab(text: 'Control', icon: Icon(Icons.sensors, size: 20)),
      const Tab(text: 'Activos', icon: Icon(Icons.directions_walk, size: 20)),
      const Tab(text: 'Historial', icon: Icon(Icons.history, size: 20)),
      const Tab(text: 'Visitantes', icon: Icon(Icons.person_add, size: 20)),
    ];

    final children = <Widget>[
      if (isResident) _GateControlTab(onRefresh: _loadData),
      _ActiveAccessesTab(onRefresh: _loadData),
      _AccessLogsTab(onRefresh: _loadData, searchController: _searchController),
      const _VisitorsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Accesos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () => _scanQr()),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: children,
      ),
    );
  }

  void _scanQr() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escáner QR en desarrollo')));
  }
}

class _GateControlTab extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _GateControlTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final block = ref.watch(vehicleBlockProvider);
    final vehicleBlocked = block?.status == VehicleBlockStatus.blocked;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        if (vehicleBlocked) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.no_crash, color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    block?.message ??
                        'Cuota del mes pendiente. Acceso vehicular suspendido.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mantén presionado el botón durante 2 segundos para abrir',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _GateButton(
          label: 'Entrada',
          subtitle: vehicleBlocked ? 'Suspendida por cuota pendiente' : 'Puerta vehicular principal',
          icon: Icons.login_rounded,
          color: const Color(0xFF16A34A),
          enabled: !vehicleBlocked,
          onActivate: () => _gateEntry(context, ref),
        ),
        const SizedBox(height: 14),
        _GateButton(
          label: 'Salida',
          subtitle: vehicleBlocked ? 'Suspendida por cuota pendiente' : 'Puerta vehicular de salida',
          icon: Icons.logout_rounded,
          color: const Color(0xFFDC2626),
          enabled: !vehicleBlocked,
          onActivate: () => _gateExit(context, ref),
        ),
        const SizedBox(height: 14),
        _GateButton(
          label: 'Peatonal',
          subtitle: 'Puerta peatonal',
          icon: Icons.directions_walk_rounded,
          color: const Color(0xFF4F46E5),
          onActivate: () => _gatePeatonal(context, ref),
        ),
        const SizedBox(height: 14),
        _GateButton(
          label: 'Botonera',
          subtitle: 'Activa la botonera de la caseta',
          icon: Icons.doorbell_rounded,
          color: const Color(0xFFEA580C),
          onActivate: () => _gateBotonera(context, ref),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Actualizar accesos'),
          ),
        ),
      ],
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action, String okMessage) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(okMessage), backgroundColor: Colors.green));
      }
      ref.read(activeAccessesProvider.notifier).loadActive();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_gateError(e))));
      }
    }
  }

  String _gateError(dynamic e) {
    final s = e.toString();
    if (s.contains('No hay entrada activa')) return 'No hay entrada activa para registrar salida';
    if (s.contains('Solo residentes')) return 'Acción disponible solo para residentes';
    return 'No se pudo completar la acción';
  }

  Future<void> _gateEntry(BuildContext context, WidgetRef ref) =>
      _run(context, ref, () => ref.read(accessApiProvider).residentEntry().then((_) {}), 'Entrada registrada');

  Future<void> _gateExit(BuildContext context, WidgetRef ref) =>
      _run(context, ref, () => ref.read(accessApiProvider).residentExit().then((_) {}), 'Salida registrada');

  Future<void> _gatePeatonal(BuildContext context, WidgetRef ref) =>
      _run(context, ref, () => ref.read(accessApiProvider).peatonalEntry().then((_) {}), 'Puerta peatonal abierta');

  Future<void> _gateBotonera(BuildContext context, WidgetRef ref) =>
      _run(context, ref, () => ref.read(accessApiProvider).openBotonera(), 'Botonera activada');
}

class _GateButton extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final Future<void> Function() onActivate;

  const _GateButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.enabled = true,
    required this.onActivate,
  });

  @override
  State<_GateButton> createState() => _GateButtonState();
}

class _GateButtonState extends State<_GateButton> with SingleTickerProviderStateMixin {
  static const _holdMs = 2000;

  Timer? _timer;
  final Stopwatch _hold = Stopwatch();
  double _progress = 0;
  bool _loading = false;
  bool _pressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  void _onHoldStart() {
    if (_loading || !widget.enabled) return;
    _hold
      ..reset()
      ..start();
    setState(() {
      _progress = 0;
      _pressed = true;
    });
    _scaleController.forward();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (t) {
      final p = _hold.elapsedMilliseconds / _holdMs;
      setState(() => _progress = p.clamp(0.0, 1.0));
      if (p >= 1.0) {
        t.cancel();
        _activate();
      }
    });
  }

  void _onHoldEnd() {
    _hold..stop()..reset();
    _timer?.cancel();
    _scaleController.reverse();
    if (!_loading && mounted) setState(() {
      _progress = 0;
      _pressed = false;
    });
  }

  Future<void> _activate() async {
    _hold..stop()..reset();
    _timer?.cancel();
    _scaleController.reverse();
    setState(() {
      _loading = true;
      _pressed = false;
    });
    try {
      await widget.onActivate();
    } finally {
      if (mounted) setState(() {
        _loading = false;
        _progress = 0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isActive = _progress > 0 && !_loading;
    final disabled = !widget.enabled;

    return GestureDetector(
      onTapDown: (_) => _onHoldStart(),
      onTapUp: (_) => _onHoldEnd(),
      onTapCancel: _onHoldEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: _pressed
                ? widget.color.withValues(alpha: 0.12)
                : isActive
                    ? widget.color.withValues(alpha: 0.08)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? widget.color.withValues(alpha: 0.4)
                  : cs.outlineVariant.withValues(alpha: 0.4),
              width: isActive ? 2 : 1,
            ),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              if (isActive)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(widget.color.withValues(alpha: 0.15)),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _loading
                            ? widget.color
                            : widget.color.withValues(alpha: _pressed ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _loading
                          ? Padding(
                              padding: const EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: cs.surface,
                              ),
                            )
                          : Icon(widget.icon, color: disabled ? cs.onSurfaceVariant.withValues(alpha: 0.6) : widget.color, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _pressed ? widget.color : cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_loading)
                      const SizedBox()
                    else if (isActive)
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          value: _progress,
                          color: widget.color,
                          backgroundColor: widget.color.withValues(alpha: 0.15),
                        ),
                      )
else if (disabled)
                    Icon(
                      Icons.lock_outline_rounded,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      size: 22,
                    )
                  else
                    Icon(
                      Icons.touch_app_rounded,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveAccessesTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  
  const _ActiveAccessesTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeAccessesProvider);
    
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.activeAccesses.isEmpty
              ? _EmptyState(icon: Icons.security, title: 'Sin accesos activos', subtitle: 'No hay residentes o visitantes dentro')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.activeAccesses.length,
                  itemBuilder: (context, index) {
                    final access = state.activeAccesses[index];
                    return _AccessCard(access: access, showExitButton: true, onRefresh: onRefresh);
                  },
                ),
    );
  }
}

class _AccessLogsTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  final TextEditingController searchController;
  
  const _AccessLogsTab({required this.onRefresh, required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accessLogsProvider);
    
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomSearchField(
              controller: searchController,
              hint: 'Buscar accesos...',
              onChanged: (_) => ref.read(accessLogsProvider.notifier).loadLogs(search: searchController.text),
              onClear: () => ref.read(accessLogsProvider.notifier).loadLogs(),
            ),
          ),
          Expanded(
            child: state.isLoading && state.logs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.logs.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.logs.length) {
                        if (!state.isLoading && state.hasMore) {
                          final notifier = ref.read(accessLogsProvider.notifier);
                          WidgetsBinding.instance.addPostFrameCallback((_) => notifier.loadMore());
                        }
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                      }
                      final access = state.logs[index];
                      return _AccessCard(access: access);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _VisitorsTab extends ConsumerWidget {
  const _VisitorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myVisitorsProvider);
    
    return RefreshIndicator(
      onRefresh: () async => ref.read(myVisitorsProvider.notifier).load(),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.visitors.isEmpty
              ? _EmptyState(icon: Icons.person_add, title: 'Sin visitantes', subtitle: 'Registra tu primer visitante')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.visitors.length,
                  itemBuilder: (context, index) {
                    final visitor = state.visitors[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(visitor.firstName[0].toUpperCase())),
                        title: Text(visitor.fullName),
                        subtitle: Text('${visitor.phone ?? 'Sin teléfono'} • ${visitor.isRecurring ? 'Recurrente' : 'Único'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (visitor.entryCode != null)
                              IconButton(icon: const Icon(Icons.qr_code_2), tooltip: 'Token de acceso', onPressed: () => showVisitorTokenDialog(context, visitor)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteVisitor(context, ref, visitor.id)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _deleteVisitor(BuildContext context, WidgetRef ref, String id) {
    try {
      ref.read(visitorApiProvider).deleteVisitor(id);
      ref.read(myVisitorsProvider.notifier).load();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitante eliminado')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _AccessCard extends ConsumerWidget {
  final AccessLog access;
  final bool showExitButton;
  final VoidCallback? onRefresh;
  
  const _AccessCard({required this.access, this.showExitButton = false, this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(access.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(access.type == AccessType.resident ? Icons.person : Icons.person_add, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(access.displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(access.unitDisplay, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(access.status.name.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(icon: Icons.access_time, label: 'Entrada', value: access.entryTime != null ? DateFormat('HH:mm').format(access.entryTime!) : 'Pendiente'),
                _InfoChip(icon: Icons.access_time, label: 'Salida', value: access.exitTime != null ? DateFormat('HH:mm').format(access.exitTime!) : 'Pendiente'),
                _InfoChip(icon: Icons.directions, label: 'Método', value: access.entryMethod ?? 'N/A'),
              ],
            ),
            if (showExitButton && access.status == AccessStatus.approved && access.exitTime == null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _registerExit(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('Registrar Salida'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _registerExit(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(accessApiProvider).registerExit(access.id);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salida registrada'), backgroundColor: Colors.green));
      onRefresh?.call();
    } catch (e) {
      if (context.mounted) {
        final s = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.contains('No hay entrada activa') ? 'No hay entrada activa' : 'No se pudo registrar la salida')));
      }
    }
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

void showVisitorTokenDialog(BuildContext context, Visitor visitor) {
  final code = visitor.entryCode;
  if (code == null || code.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este visitante no tiene token de acceso')));
    return;
  }
  showDialog(context: context, builder: (_) => _VisitorTokenDialog(visitor: visitor, code: code));
}

class _VisitorTokenDialog extends StatelessWidget {
  final Visitor visitor;
  final String code;

  const _VisitorTokenDialog({required this.visitor, required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Token de acceso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Muestra este código en la caseta para permitir la entrada de ${visitor.fullName}',
              textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          QrImageView(data: code, version: QrVersions.auto, size: 180),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(code, style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 5, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _InfoChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

final accessLogsProvider = StateNotifierProvider<AccessLogsNotifier, AccessLogsState>((ref) {
  return AccessLogsNotifier(ref.read(accessApiProvider));
});

class AccessLogsState {
  final List<AccessLog> logs;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  
  const AccessLogsState({this.logs = const [], this.isLoading = false, this.hasMore = true, this.error});
  
  AccessLogsState copyWith({List<AccessLog>? logs, bool? isLoading, bool? hasMore, String? error}) =>
      AccessLogsState(logs: logs ?? this.logs, isLoading: isLoading ?? this.isLoading, hasMore: hasMore ?? this.hasMore, error: error ?? this.error);
}

class AccessLogsNotifier extends StateNotifier<AccessLogsState> {
  final AccessApi _api;
  int _page = 1;
  String? _search;
  
  AccessLogsNotifier(this._api) : super(const AccessLogsState());

  Future<void> loadLogs({int page = 1, String? search, String? status}) async {
    if (page == 1) state = state.copyWith(isLoading: true, error: null);
    _search = search;
    try {
      final response = await _api.getAccessLogs(page: page, search: search, status: status);
      final newLogs = page == 1 ? response.data : [...state.logs, ...response.data];
      state = state.copyWith(logs: newLogs, isLoading: false, hasMore: response.hasNextPage);
      _page = page;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    await loadLogs(page: _page + 1, search: _search);
  }
}

final activeAccessesProvider = StateNotifierProvider<ActiveAccessesNotifier, ActiveAccessesState>((ref) {
  return ActiveAccessesNotifier(ref.read(accessApiProvider));
});

class ActiveAccessesState {
  final List<AccessLog> activeAccesses;
  final bool isLoading;
  final String? error;
  
  const ActiveAccessesState({this.activeAccesses = const [], this.isLoading = false, this.error});
  
  ActiveAccessesState copyWith({List<AccessLog>? activeAccesses, bool? isLoading, String? error}) =>
      ActiveAccessesState(activeAccesses: activeAccesses ?? this.activeAccesses, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class ActiveAccessesNotifier extends StateNotifier<ActiveAccessesState> {
  final AccessApi _api;
  
  ActiveAccessesNotifier(this._api) : super(const ActiveAccessesState()) {
    loadActive();
  }
  
  Future<void> loadActive() async {
    state = state.copyWith(isLoading: true);
    try {
      final accesses = await _api.getActiveAccesses();
      state = state.copyWith(isLoading: false, activeAccesses: accesses);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final myVisitorsProvider = StateNotifierProvider<MyVisitorsNotifier, MyVisitorsState>((ref) {
  return MyVisitorsNotifier(ref.read(visitorApiProvider));
});

class MyVisitorsState {
  final List<Visitor> visitors;
  final bool isLoading;
  final String? error;
  
  const MyVisitorsState({this.visitors = const [], this.isLoading = false, this.error});
  
  MyVisitorsState copyWith({List<Visitor>? visitors, bool? isLoading, String? error}) =>
      MyVisitorsState(visitors: visitors ?? this.visitors, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class MyVisitorsNotifier extends StateNotifier<MyVisitorsState> {
  final VisitorApi _api;
  
  MyVisitorsNotifier(this._api) : super(const MyVisitorsState()) {
    load();
  }
  
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final visitors = await _api.getMyVisitors();
      state = state.copyWith(isLoading: false, visitors: visitors);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final vehicleBlockProvider = StateNotifierProvider<VehicleBlockNotifier, VehicleBlockResult?>((ref) {
  return VehicleBlockNotifier(ref.read(accessApiProvider));
});

class VehicleBlockNotifier extends StateNotifier<VehicleBlockResult?> {
  final AccessApi _api;
  VehicleBlockNotifier(this._api) : super(null);

  Future<void> load() async {
    try {
      state = await _api.getVehicleBlock();
    } catch (_) {
      state = null;
    }
  }
}