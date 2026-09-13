import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/models/booking.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    await ref.read(bookingDetailProvider(widget.bookingId).notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(bookingDetailProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Reserva')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.booking == null
              ? Center(child: Text(state.error ?? 'Reserva no encontrada'))
              : _buildDetail(state.booking!),
    );
  }

  Widget _buildDetail(Booking booking) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(booking.status);

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
                        Text(booking.amenity.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Text('Unidad ${booking.unit.displayNumber}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(booking.formattedPrice, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: statusColor)),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Text(_getStatusLabel(booking.status), style: TextStyle(fontWeight: FontWeight.w600, color: statusColor))),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(label: 'Fecha', value: DateFormat('EEEE, dd/MM/yyyy', 'es').format(booking.startTime), icon: Icons.calendar_today),
                  _DetailRow(label: 'Horario', value: '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}', icon: Icons.access_time),
                  _DetailRow(label: 'Duración', value: '${booking.durationHours.toStringAsFixed(1)} horas', icon: Icons.timer),
                  _DetailRow(label: 'Invitados', value: '${booking.guestsCount}', icon: Icons.people),
                  if (booking.notes != null) _DetailRow(label: 'Notas', value: booking.notes!, icon: Icons.note),
                  if (booking.rejectionReason != null) _DetailRow(label: 'Motivo de rechazo', value: booking.rejectionReason!, icon: Icons.block, valueColor: Colors.red),
                  if (booking.approvedAt != null) _DetailRow(label: 'Aprobado el', value: DateFormat('dd/MM/yyyy HH:mm').format(booking.approvedAt!), icon: Icons.check_circle, valueColor: Colors.green),
                ],
              ),
            ),
          ),
          if (booking.amenity.rules != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.rule, color: theme.colorScheme.primary), const SizedBox(width: 8), Text('Reglas de la Amenidad', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))]),
                    const SizedBox(height: 12),
                    Text(booking.amenity.rules!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
          if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (booking.canCancel) ...[
                  Expanded(child: OutlinedButton.icon(onPressed: () => _cancelBooking(booking.id), icon: const Icon(Icons.cancel), label: const Text('Cancelar Reserva'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14)))),
                  const SizedBox(width: 12),
                ],
                if (booking.status == BookingStatus.confirmed)
                  Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.edit), label: const Text('Modificar'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _cancelBooking(String id) {}

  Widget _DetailRow({required String label, required String value, required IconData icon, Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: valueColor)),
      ])),
    ]));
  }

  Color _getStatusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed: return Colors.green;
      case BookingStatus.pending: return Colors.orange;
      case BookingStatus.cancelled: return Colors.grey;
      case BookingStatus.completed: return Colors.blue;
      case BookingStatus.rejected: return Colors.red;
    }
  }

  String _getStatusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed: return 'Confirmada';
      case BookingStatus.pending: return 'Pendiente';
      case BookingStatus.cancelled: return 'Cancelada';
      case BookingStatus.completed: return 'Completada';
      case BookingStatus.rejected: return 'Rechazada';
    }
  }
}

final bookingDetailProvider = StateNotifierProvider.family<BookingDetailNotifier, BookingDetailState, String>((ref, id) {
  return BookingDetailNotifier(ref.read(bookingApiProvider), id);
});

class BookingDetailState {
  final Booking? booking; final bool isLoading; final String? error;
  const BookingDetailState({this.booking, this.isLoading = false, this.error});
  BookingDetailState copyWith({Booking? booking, bool? isLoading, String? error}) =>
      BookingDetailState(booking: booking ?? this.booking, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class BookingDetailNotifier extends StateNotifier<BookingDetailState> {
  final BookingApi _api; final String _id;
  BookingDetailNotifier(this._api, this._id) : super(const BookingDetailState()) { load(); }
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try { final booking = await _api.getBooking(_id); state = state.copyWith(isLoading: false, booking: booking); }
    catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }
}