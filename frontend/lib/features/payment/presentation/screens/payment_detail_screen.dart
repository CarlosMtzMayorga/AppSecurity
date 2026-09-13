import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/models/payment.dart';

class PaymentDetailScreen extends ConsumerStatefulWidget {
  final String paymentId;
  
  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends ConsumerState<PaymentDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    await ref.read(paymentDetailProvider(widget.paymentId).notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(paymentDetailProvider(widget.paymentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Pago')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.payment == null
              ? Center(child: Text(state.error ?? 'Pago no encontrado'))
              : _buildDetail(state.payment!),
    );
  }

  Widget _buildDetail(Payment payment) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(payment.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(payment.description, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Text(payment.unit?.displayNumber ?? 'N/A', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(payment.formattedAmount, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: statusColor)),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Text(_getStatusLabel(payment.status), style: TextStyle(fontWeight: FontWeight.w600, color: statusColor))),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(label: 'Tipo', value: payment.type.name, icon: Icons.category),
                  _DetailRow(label: 'Fecha de vencimiento', value: DateFormat('dd/MM/yyyy').format(payment.dueDate), icon: Icons.calendar_today),
                  if (payment.periodStart != null) _DetailRow(label: 'Periodo', value: '${DateFormat('dd/MM/yyyy').format(payment.periodStart!)} - ${DateFormat('dd/MM/yyyy').format(payment.periodEnd!)}', icon: Icons.date_range),
                  if (payment.paidAt != null) _DetailRow(label: 'Pagado el', value: DateFormat('dd/MM/yyyy HH:mm').format(payment.paidAt!), icon: Icons.check_circle, valueColor: Colors.green),
                  if (payment.reference != null) _DetailRow(label: 'Referencia', value: payment.reference!, icon: Icons.receipt, monospace: true),
                  if (payment.notes != null) _DetailRow(label: 'Notas', value: payment.notes!, icon: Icons.note),
                ],
              ),
            ),
          ),
          if (payment.status == PaymentStatus.pending || payment.status == PaymentStatus.overdue) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _payNow(payment),
                icon: const Icon(Icons.payment),
                label: const Text('Pagar Ahora'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ],
          if (payment.receiptUrl != null) ...[
            const SizedBox(height: 16),
            Card(child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Ver Comprobante'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {},
            )),
          ],
        ],
      ),
    );
  }

  void _payNow(Payment payment) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando pago...')));
  }

  Widget _DetailRow({required String label, required String value, required IconData icon, Color? valueColor, bool monospace = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, fontFamily: monospace ? 'monospace' : null, color: valueColor)),
              ],
            ),
          ),
        ],
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

final paymentDetailProvider = StateNotifierProvider.family<PaymentDetailNotifier, PaymentDetailState, String>((ref, id) {
  return PaymentDetailNotifier(ref.read(paymentApiProvider), id);
});

class PaymentDetailState {
  final Payment? payment; final bool isLoading; final String? error;
  const PaymentDetailState({this.payment, this.isLoading = false, this.error});
  PaymentDetailState copyWith({Payment? payment, bool? isLoading, String? error}) =>
      PaymentDetailState(payment: payment ?? this.payment, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class PaymentDetailNotifier extends StateNotifier<PaymentDetailState> {
  final PaymentApi _api; final String _id;
  PaymentDetailNotifier(this._api, this._id) : super(const PaymentDetailState()) { load(); }
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try { final payment = await _api.getPayment(_id); state = state.copyWith(isLoading: false, payment: payment); }
    catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }
}