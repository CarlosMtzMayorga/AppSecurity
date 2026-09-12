import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/models/booking.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final isAdmin = authState.user?.role == UserRole.admin || authState.user?.role == UserRole.committee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas de Amenidades'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mis Reservas', icon: Icon(Icons.person)),
            Tab(text: 'Todas', icon: Icon(Icons.list)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _showCalendar()),
          if (isAdmin) IconButton(icon: const Icon(Icons.add), onPressed: _showCreateBooking),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyBookingsTab(),
          _AllBookingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBooking,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Reserva'),
      ),
    );
  }

  void _showCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calendario en desarrollo')));
  }

  void _showCreateBooking() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crear reserva en desarrollo')));
  }
}

class _MyBookingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myBookingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(myBookingsProvider.notifier).load(),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.bookings.isEmpty
              ? _EmptyState(icon: Icons.event_seat, title: 'Sin reservas', subtitle: 'Reserva tu primera amenidad')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.bookings.length,
                  itemBuilder: (context, index) => _BookingCard(booking: state.bookings[index]),
                ),
    );
  }
}

class _AllBookingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(bookingsProvider.notifier).load(),
      child: state.isLoading && state.bookings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.bookings.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.bookings.length) {
                  if (!state.isLoading && state.hasMore) ref.read(bookingsProvider.notifier).loadMore();
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                }
                return _BookingCard(booking: state.bookings[index]);
              },
            ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.meeting_room, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(booking.amenity.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                  Text('Unidad ${booking.unit.displayNumber}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getStatusLabel(booking.status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(icon: Icons.calendar_today, label: 'Fecha', value: DateFormat('dd/MM/yyyy').format(booking.startTime)),
                  _InfoChip(icon: Icons.access_time, label: 'Inicio', value: DateFormat('HH:mm').format(booking.startTime)),
                  _InfoChip(icon: Icons.access_time, label: 'Fin', value: DateFormat('HH:mm').format(booking.endTime)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(icon: Icons.people, label: 'Invitados', value: '${booking.guestsCount}'),
                  _InfoChip(icon: Icons.attach_money, label: 'Total', value: booking.formattedPrice),
                ],
              ),
              if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (booking.canCancel) ...[
                      Expanded(child: OutlinedButton.icon(onPressed: () => _cancelBooking(booking.id), icon: const Icon(Icons.cancel), label: const Text('Cancelar'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red))),
                      const SizedBox(width: 12),
                    ],
                    if (booking.status == BookingStatus.confirmed)
                      Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.edit), label: const Text('Modificar'))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _cancelBooking(String id) {}

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
  final IconData icon; final String label; final String value;
  const _InfoChip({required this.icon, required this.label, required this.value});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(child: Container(padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant), Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)), Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))])));
  }
}

final bookingsProvider = StateNotifierProvider<BookingsNotifier, BookingsState>((ref) {
  return BookingsNotifier(ref.read(bookingApiProvider));
});

class BookingsState {
  final List<Booking> bookings; final bool isLoading; final bool hasMore; final String? error;
  const BookingsState({this.bookings = const [], this.isLoading = false, this.hasMore = true, this.error});
  BookingsState copyWith({List<Booking>? bookings, bool? isLoading, bool? hasMore, String? error}) =>
      BookingsState(bookings: bookings ?? this.bookings, isLoading: isLoading ?? this.isLoading, hasMore: hasMore ?? this.hasMore, error: error ?? this.error);
}

class BookingsNotifier extends StateNotifier<BookingsState> {
  final BookingApi _api; int _page = 1;
  BookingsNotifier(this._api) : super(const BookingsState()) { load(); }
  Future<void> load({int page = 1}) async {
    if (page == 1) state = state.copyWith(isLoading: true, error: null);
    try { final response = await _api.getBookings(page: page); final newBookings = page == 1 ? response.data : [...state.bookings, ...response.data]; state = state.copyWith(bookings: newBookings, isLoading: false, hasMore: response.hasNextPage); _page = page; }
    catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }
  Future<void> loadMore() async => load(page: _page + 1);
}

final myBookingsProvider = StateNotifierProvider<MyBookingsNotifier, MyBookingsState>((ref) {
  return MyBookingsNotifier(ref.read(bookingApiProvider));
});

class MyBookingsState {
  final List<Booking> bookings; final bool isLoading; final String? error;
  const MyBookingsState({this.bookings = const [], this.isLoading = false, this.error});
  MyBookingsState copyWith({List<Booking>? bookings, bool? isLoading, String? error}) =>
      MyBookingsState(bookings: bookings ?? this.bookings, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class MyBookingsNotifier extends StateNotifier<MyBookingsState> {
  final BookingApi _api;
  MyBookingsNotifier(this._api) : super(const MyBookingsState()) { load(); }
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try { final bookings = await _api.getMyBookings(); state = state.copyWith(isLoading: false, bookings: bookings); }
    catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }
}