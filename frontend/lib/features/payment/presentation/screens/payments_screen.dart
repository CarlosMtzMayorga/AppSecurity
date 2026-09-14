import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/models/payment.dart';
import '../../../../core/models/user.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    await ref.read(paymentsProvider.notifier).loadPayments(
      status: _statusFilter == 'ALL' ? null : _statusFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isAdmin = authState.user?.role == UserRole.admin || authState.user?.role == UserRole.committee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mis Pagos', icon: Icon(Icons.person)),
            Tab(text: 'Todos', icon: Icon(Icons.list)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilter),
          if (isAdmin) IconButton(icon: const Icon(Icons.add), onPressed: _showCreatePayment),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyPaymentsTab(onRefresh: _loadPayments),
          _AllPaymentsTab(onRefresh: _loadPayments, searchController: _searchController),
        ],
      ),
    );
  }

  void _showFilter() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Filtrar por estado'),
      content: Column(mainAxisSize: MainAxisSize.min, children: ['ALL', 'PENDING', 'COMPLETED', 'OVERDUE', 'FAILED'].map((s) => RadioListTile<String>(
        title: Text(_getStatusLabel(s)), value: s, groupValue: _statusFilter,
        onChanged: (v) { setState(() => _statusFilter = v!); Navigator.pop(context); _loadPayments(); },
      )).toList()),
    ));
  }

  void _showCreatePayment() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crear pago en desarrollo')));
  }

  String _getStatusLabel(String s) {
    switch (s) {
      case 'ALL': return 'Todos';
      case 'PENDING': return 'Pendientes';
      case 'COMPLETED': return 'Pagados';
      case 'OVERDUE': return 'Vencidos';
      case 'FAILED': return 'Fallidos';
      default: return s;
    }
  }
}

class _MyPaymentsTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _MyPaymentsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myPaymentsProvider);
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.payments.isEmpty
              ? _EmptyState(icon: Icons.receipt_long, title: 'Sin pagos', subtitle: 'No tienes pagos registrados')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.payments.length,
                  itemBuilder: (context, index) => _PaymentCard(payment: state.payments[index], onTap: () => context.push('/payments/${state.payments[index].id}')),
                ),
    );
  }
}

class _AllPaymentsTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  final TextEditingController searchController;
  const _AllPaymentsTab({required this.onRefresh, required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentsProvider);
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16), child: CustomSearchField(
            controller: searchController,
            hint: 'Buscar pagos...',
            onChanged: (_) => ref.read(paymentsProvider.notifier).loadPayments(search: searchController.text),
            onClear: () => ref.read(paymentsProvider.notifier).loadPayments(),
          )),
          Expanded(
            child: state.isLoading && state.payments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.payments.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.payments.length) {
                        if (!state.isLoading && state.hasMore) ref.read(paymentsProvider.notifier).loadMore();
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                      }
                      return _PaymentCard(payment: state.payments[index], onTap: () => context.push('/payments/${state.payments[index].id}'));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends ConsumerWidget {
  final Payment payment;
  final VoidCallback onTap;
  const _PaymentCard({required this.payment, required this.onTap});

  Future<void> _payNow(BuildContext context, WidgetRef ref, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(paymentApiProvider).payPayment(id);
      messenger.showSnackBar(const SnackBar(content: Text('Pago completado'), backgroundColor: Colors.green));
      ref.read(myPaymentsProvider.notifier).load();
      ref.read(paymentsProvider.notifier).loadPayments();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(payment.status);
    final isOverdue = payment.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(payment.description, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(payment.unit?.displayNumber ?? 'N/A', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(payment.formattedAmount, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: statusColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(_getStatusLabel(payment.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(icon: Icons.calendar_today, label: 'Vence', value: DateFormat('dd/MM/yyyy').format(payment.dueDate), isOverdue: isOverdue),
                  _InfoChip(icon: Icons.category, label: 'Tipo', value: payment.type.name),
                  if (payment.paidAt != null) _InfoChip(icon: Icons.check_circle, label: 'Pagado', value: DateFormat('dd/MM/yyyy').format(payment.paidAt!)),
                ],
              ),
              if (payment.status == PaymentStatus.pending || payment.status == PaymentStatus.overdue) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _payNow(context, ref, payment.id),
                    icon: const Icon(Icons.payment),
                    label: const Text('Pagar Ahora'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.completed: return Colors.green;
      case PaymentStatus.pending: return Colors.orange;
      case PaymentStatus.overdue: return Colors.red;
      case PaymentStatus.failed: return Colors.red;
      case PaymentStatus.refunded: return Colors.grey;
    }
  }

  String _getStatusLabel(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.completed: return 'Pagado';
      case PaymentStatus.pending: return 'Pendiente';
      case PaymentStatus.overdue: return 'Vencido';
      case PaymentStatus.failed: return 'Fallido';
      case PaymentStatus.refunded: return 'Reembolsado';
    }
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

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label; final String value; final bool isOverdue;
  const _InfoChip({required this.icon, required this.label, required this.value, this.isOverdue = false});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(child: Container(
      padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Icon(icon, size: 16, color: isOverdue ? Colors.red : theme.colorScheme.onSurfaceVariant),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: isOverdue ? Colors.red : null)),
      ]),
    ));
  }
}

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, PaymentsState>((ref) {
  return PaymentsNotifier(ref.read(paymentApiProvider));
});

class PaymentsState {
  final List<Payment> payments; final bool isLoading; final bool hasMore; final String? error;
  const PaymentsState({this.payments = const [], this.isLoading = false, this.hasMore = true, this.error});
  PaymentsState copyWith({List<Payment>? payments, bool? isLoading, bool? hasMore, String? error}) =>
      PaymentsState(payments: payments ?? this.payments, isLoading: isLoading ?? this.isLoading, hasMore: hasMore ?? this.hasMore, error: error ?? this.error);
}

class PaymentsNotifier extends StateNotifier<PaymentsState> {
  final PaymentApi _api; int _page = 1; String? _status; String? _search;
  PaymentsNotifier(this._api) : super(const PaymentsState());

  Future<void> loadPayments({int page = 1, String? status, String? search}) async {
    if (page == 1) state = state.copyWith(isLoading: true, error: null);
    _status = status; _search = search;
    try {
      final response = await _api.getPayments(page: page, status: status, search: search);
      final newPayments = page == 1 ? response.data : [...state.payments, ...response.data];
      state = state.copyWith(payments: newPayments, isLoading: false, hasMore: response.hasNextPage);
      _page = page;
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  Future<void> loadMore() async => loadPayments(page: _page + 1, status: _status, search: _search);
}

final myPaymentsProvider = StateNotifierProvider<MyPaymentsNotifier, MyPaymentsState>((ref) {
  return MyPaymentsNotifier(ref.read(paymentApiProvider));
});

class MyPaymentsState {
  final List<Payment> payments; final bool isLoading; final String? error;
  const MyPaymentsState({this.payments = const [], this.isLoading = false, this.error});
  MyPaymentsState copyWith({List<Payment>? payments, bool? isLoading, String? error}) =>
      MyPaymentsState(payments: payments ?? this.payments, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class MyPaymentsNotifier extends StateNotifier<MyPaymentsState> {
  final PaymentApi _api;
  MyPaymentsNotifier(this._api) : super(const MyPaymentsState()) { load(); }
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try { final payments = await _api.getMyPayments(); state = state.copyWith(isLoading: false, payments: payments); }
    catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }
}