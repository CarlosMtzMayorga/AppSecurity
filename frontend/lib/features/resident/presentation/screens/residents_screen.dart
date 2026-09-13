import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/models/resident.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';

class ResidentsScreen extends ConsumerStatefulWidget {
  const ResidentsScreen({super.key});

  @override
  ConsumerState<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends ConsumerState<ResidentsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'ALL';
  int _page = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResidents({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() { _isLoading = true; if (refresh) _page = 1; });
    
    try {
      await ref.read(residentsProvider.notifier).loadResidents(
        page: _page,
        status: _statusFilter == 'ALL' ? null : _statusFilter,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(residentsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Residentes'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddResidentDialog()),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomSearchField(
              controller: _searchController,
              hint: 'Buscar residentes...',
              onChanged: (_) => _loadResidents(refresh: true),
              onClear: () => _loadResidents(refresh: true),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadResidents(refresh: true),
              child: _isLoading && state.residents.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.residents.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.residents.length) {
                          if (!_isLoading && state.hasMore) {
                            _page++;
                            _loadResidents();
                          }
                          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                        }
                        final resident = state.residents[index];
                        return _ResidentCard(resident: resident, onTap: () => context.push('/residents/${resident.id}'));
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddResidentDialog() {
    // Implementation for adding resident
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función en desarrollo')));
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['ALL', 'ACTIVE', 'PENDING', 'INACTIVE', 'SUSPENDED'].map((status) => RadioListTile<String>(
            title: Text(_getStatusLabel(status)),
            value: status,
            groupValue: _statusFilter,
            onChanged: (value) { setState(() => _statusFilter = value!); Navigator.pop(context); _loadResidents(refresh: true); },
          )).toList(),
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ALL': return 'Todos';
      case 'ACTIVE': return 'Activos';
      case 'PENDING': return 'Pendientes';
      case 'INACTIVE': return 'Inactivos';
      case 'SUSPENDED': return 'Suspendidos';
      default: return status;
    }
  }
}

class _ResidentCard extends StatelessWidget {
  final Resident resident;
  final VoidCallback onTap;

  const _ResidentCard({required this.resident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(resident.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  resident.user.firstName.isNotEmpty ? resident.user.firstName[0].toUpperCase() : 'U',
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(resident.user.fullName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(_getStatusLabel(resident.status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(resident.unit.displayNumber, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(resident.user.email, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ResidentStatus status) {
    switch (status) {
      case ResidentStatus.active: return Colors.green;
      case ResidentStatus.pending: return Colors.orange;
      case ResidentStatus.inactive: return Colors.grey;
      case ResidentStatus.suspended: return Colors.red;
    }
  }

  String _getStatusLabel(ResidentStatus status) {
    switch (status) {
      case ResidentStatus.active: return 'Activo';
      case ResidentStatus.pending: return 'Pendiente';
      case ResidentStatus.inactive: return 'Inactivo';
      case ResidentStatus.suspended: return 'Suspendido';
    }
  }
}

final residentsProvider = StateNotifierProvider<ResidentsNotifier, ResidentsState>((ref) {
  return ResidentsNotifier(ref.read(residentApiProvider));
});

class ResidentsState {
  final List<Resident> residents;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const ResidentsState({this.residents = const [], this.isLoading = false, this.hasMore = true, this.error});
  
  ResidentsState copyWith({List<Resident>? residents, bool? isLoading, bool? hasMore, String? error}) =>
      ResidentsState(residents: residents ?? this.residents, isLoading: isLoading ?? this.isLoading, hasMore: hasMore ?? this.hasMore, error: error ?? this.error);
}

class ResidentsNotifier extends StateNotifier<ResidentsState> {
  final ResidentApi _api;
  
  ResidentsNotifier(this._api) : super(const ResidentsState());

  Future<void> loadResidents({int page = 1, String? status, String? search}) async {
    if (page == 1) state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getResidents(page: page, status: status, search: search);
      final newResidents = page == 1 ? response.data : [...state.residents, ...response.data];
      state = state.copyWith(residents: newResidents, isLoading: false, hasMore: response.hasNextPage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}