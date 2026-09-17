import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/models/accounting.dart';
import '../../../../core/models/dashboard.dart';
import '../../../../core/models/user.dart';
import '../../../../core/utils/csv_download.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class AccountingScreen extends ConsumerStatefulWidget {
  const AccountingScreen({super.key});

  @override
  ConsumerState<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends ConsumerState<AccountingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contabilidad')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 64, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Acceso restringido', style: theme.textTheme.titleLarge),
              Text('Solo administradores y comité', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contabilidad'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumen', icon: Icon(Icons.dashboard)),
            Tab(text: 'Movimientos', icon: Icon(Icons.list)),
            Tab(text: 'Tendencias', icon: Icon(Icons.trending_up)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreateEntry),
          IconButton(icon: const Icon(Icons.download), onPressed: _exportReport),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SummaryTab(),
          _EntriesTab(),
          _TrendsTab(),
        ],
      ),
    );
  }

  Future<void> _showCreateEntry() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateEntryDialog(),
    );
    if (created == true) {
      ref.read(accountingSummaryProvider.notifier).load();
      ref.read(accountingEntriesProvider.notifier).load();
    }
  }

  Future<void> _exportReport() async {
    final messenger = ScaffoldMessenger.of(context);
    final entries = ref.read(accountingEntriesProvider).entries;
    if (entries.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No hay movimientos para exportar')));
      return;
    }
    try {
      final buffer = StringBuffer('Fecha,Tipo,Categoría,Subcategoría,Descripción,Referencia,Monto,Moneda\n');
      for (final e in entries) {
        buffer.writeln([
          DateFormat('yyyy-MM-dd').format(e.date),
          e.typeLabel,
          e.category,
          e.subcategory ?? '',
          '"${e.description.replaceAll('"', '""')}"',
          e.reference ?? '',
          e.amount.toStringAsFixed(2),
          e.currency,
        ].join(','));
      }
      final encodedCSV = buffer.toString();
      downloadCsv('reporte-${DateFormat('yyyyMMdd').format(DateTime.now())}.csv', encodedCSV);
      messenger.showSnackBar(const SnackBar(content: Text('Reporte exportado'), backgroundColor: Colors.green));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _CreateEntryDialog extends ConsumerStatefulWidget {
  const _CreateEntryDialog();

  @override
  ConsumerState<_CreateEntryDialog> createState() => _CreateEntryDialogState();
}

class _CreateEntryDialogState extends ConsumerState<_CreateEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _referenceController = TextEditingController();
  AccountingType _type = AccountingType.expense;
  String? _category;
  DateTime _date = DateTime.now();
  bool _submitting = false;

  static const _incomeCategories = ['Cuotas de mantenimiento', 'Cuotas extraordinarias', 'Amenidades', 'Multas', 'Rendimientos', 'Otros ingresos'];
  static const _expenseCategories = ['Mantenimiento', 'Servicios', 'Personal', 'Seguridad', 'Limpieza', 'Suministros', 'Otros gastos'];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _subcategoryController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  List<String> get _categories => _type == AccountingType.income ? _incomeCategories : _expenseCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una categoría')));
      return;
    }
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monto inválido')));
      return;
    }
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountingApiProvider).createEntry({
        'type': _type.name.toUpperCase(),
        'category': _category!,
        'subcategory': _subcategoryController.text.trim().isEmpty ? null : _subcategoryController.text.trim(),
        'amount': amount,
        'description': _descriptionController.text.trim(),
        'reference': _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
        'date': _date.toUtc().toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        messenger.showSnackBar(const SnackBar(content: Text('Movimiento registrado'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Movimiento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<AccountingType>(
                segments: const [
                  ButtonSegment(value: AccountingType.expense, label: Text('Gasto'), icon: Icon(Icons.trending_down)),
                  ButtonSegment(value: AccountingType.income, label: Text('Ingreso'), icon: Icon(Icons.trending_up)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _category = null;
                }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoría *', border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _amountController,
                label: 'Monto (MXN) *',
                hint: 'Ej: 500.00',
                prefixIcon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || v.trim().isEmpty ? 'El monto es requerido' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _descriptionController,
                label: 'Descripción *',
                hint: 'Detalle del movimiento',
                prefixIcon: Icons.receipt_long,
                validator: (v) => v == null || v.trim().isEmpty ? 'La descripción es requerida' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _subcategoryController,
                label: 'Subcategoría (opcional)',
                prefixIcon: Icons.sell_outlined,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _referenceController,
                label: 'Referencia (opcional)',
                hint: 'Folio, factura, recibo…',
                prefixIcon: Icons.tag,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: Text('Fecha: ${DateFormat('dd/MM/yyyy').format(_date)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountingSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(accountingSummaryProvider.notifier).load(),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.summary == null
              ? _EmptyState(icon: Icons.account_balance, title: 'Sin datos', subtitle: 'No hay información contable')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCards(context, state.summary!),
                      const SizedBox(height: 24),
                      _buildCategoryChart(context, state.summary!),
                      const SizedBox(height: 24),
                      _MonthlyChart(monthly: state.monthly),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBalanceCards(BuildContext context, AccountingSummary summary) {
    final cards = [
      ('Ingresos', summary.income, Colors.green, Icons.trending_up),
      ('Gastos', summary.expenses, Colors.red, Icons.trending_down),
      ('Balance', summary.balance, summary.balance >= 0 ? Colors.green : Colors.red, Icons.account_balance),
    ];

    return Row(
      children: cards.map((c) => Expanded(child: _BalanceCard(title: c.$1, amount: c.$2, color: c.$3, icon: c.$4))).toList(),
    );
  }

  Widget _buildCategoryChart(BuildContext context, AccountingSummary summary) {
    final theme = Theme.of(context);
    final incomeCategories = summary.byCategory.where((c) => c.type == AccountingType.income).toList();
    final expenseCategories = summary.byCategory.where((c) => c.type == AccountingType.expense).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por Categoría', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (incomeCategories.isNotEmpty) ...[
              Text('Ingresos', style: theme.textTheme.titleMedium?.copyWith(color: Colors.green)),
              const SizedBox(height: 8),
              ...incomeCategories.map((c) => _CategoryRow(name: c.category, amount: c.amount, color: Colors.green, total: summary.income)),
            ],
            if (expenseCategories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Gastos', style: theme.textTheme.titleMedium?.copyWith(color: Colors.red)),
              const SizedBox(height: 8),
              ...expenseCategories.map((c) => _CategoryRow(name: c.category, amount: c.amount, color: Colors.red, total: summary.expenses)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _BalanceCard({required this.title, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('\$${amount.toStringAsFixed(2)}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final double amount;
  final Color color;
  final double total;

  const _CategoryRow({required this.name, required this.amount, required this.color, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? (amount / total * 100) : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
        Text('\$${amount.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 12),
        SizedBox(width: 60, child: LinearProgressIndicator(value: percentage / 100, color: color, backgroundColor: color.withOpacity(0.1))),
        const SizedBox(width: 8),
        Text('${percentage.toStringAsFixed(1)}%', style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ]),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<MonthlyFinance> monthly;

  const _MonthlyChart({required this.monthly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Evolución Mensual', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: theme.dividerColor)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(monthly[v.toInt()].monthName, style: theme.textTheme.bodySmall),
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text('\$${(v / 1000).toStringAsFixed(0)}k', style: theme.textTheme.bodySmall),
                      reservedSize: 50,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.income)).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                  ),
                  LineChartBarData(
                    spots: monthly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.expenses)).toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountingEntriesProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.read(accountingEntriesProvider.notifier).load(),
      child: state.isLoading && state.entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.entries.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.entries.length) {
                  if (!state.isLoading && state.hasMore) {
                    final notifier = ref.read(accountingEntriesProvider.notifier);
                    WidgetsBinding.instance.addPostFrameCallback((_) => notifier.loadMore());
                  }
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                }
                final entry = state.entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: entry.type == AccountingType.income ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      child: Icon(entry.type == AccountingType.income ? Icons.arrow_downward : Icons.arrow_upward, color: entry.type == AccountingType.income ? Colors.green : Colors.red),
                    ),
                    title: Text(entry.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('${entry.category} • ${DateFormat('dd/MM/yyyy').format(entry.date)}'),
                    trailing: Text('${entry.type == AccountingType.income ? '+' : '-'}\$${entry.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w600, color: entry.type == AccountingType.income ? Colors.green : Colors.red)),
                  ),
                );
              },
            ),
    );
  }
}

class _TrendsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentTrends = ref.watch(paymentTrendsProvider);
    final accessTrends = ref.watch(accessTrendsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _TrendChart(title: 'Pagos (últimos 6 meses)', trends: paymentTrends, color1: Colors.green, color2: Colors.orange, color3: Colors.red, label1: 'Cobrado', label2: 'Pendiente', label3: 'Vencido'),
        const SizedBox(height: 24),
        _TrendChart(title: 'Accesos (últimos 30 días)', trends: accessTrends, color1: Colors.blue, color2: Colors.purple, color3: Colors.orange, label1: 'Residentes', label2: 'Visitantes', label3: 'Servicios'),
      ]),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final String title;
  final AsyncValue<List<TrendPoint>> trends;
  final Color color1, color2, color3;
  final String label1, label2, label3;

  const _TrendChart({required this.title, required this.trends, required this.color1, required this.color2, required this.color3, required this.label1, required this.label2, required this.label3});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return trends.when(data: (data) {
      if (data.isEmpty) return _EmptyState(icon: Icons.trending_up, title: title, subtitle: 'Sin datos');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: theme.dividerColor)),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          if (v.toInt() >= 0 && v.toInt() < data.length) return Text(data[v.toInt()].label, style: theme.textTheme.bodySmall);
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0), style: theme.textTheme.bodySmall),
                        reservedSize: 50,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value1)).toList(),
                      isCurved: true,
                      color: color1,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: color1.withOpacity(0.1)),
                    ),
                    if (data.first.value2 != null)
                      LineChartBarData(
                        spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value2!)).toList(),
                        isCurved: true,
                        color: color2,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: color2.withOpacity(0.1)),
                      ),
                    if (data.first.value3 != null)
                      LineChartBarData(
                        spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value3!)).toList(),
                        isCurved: true,
                        color: color3,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: color3.withOpacity(0.1)),
                      ),
                  ],
                )),
              ),
            ],
          ),
        ),
      );
    }, loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => _EmptyState(icon: Icons.error, title: title, subtitle: 'Error al cargar'));
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

final accountingSummaryProvider = StateNotifierProvider<AccountingSummaryNotifier, AccountingSummaryState>((ref) {
  return AccountingSummaryNotifier(ref.read(accountingApiProvider), ref.read(dashboardApiProvider));
});

class AccountingSummaryState {
  final AccountingSummary? summary;
  final List<MonthlyFinance> monthly;
  final bool isLoading;
  final String? error;

  const AccountingSummaryState({this.summary, this.monthly = const [], this.isLoading = false, this.error});

  AccountingSummaryState copyWith({AccountingSummary? summary, List<MonthlyFinance>? monthly, bool? isLoading, String? error}) =>
      AccountingSummaryState(summary: summary ?? this.summary, monthly: monthly ?? this.monthly, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class AccountingSummaryNotifier extends StateNotifier<AccountingSummaryState> {
  final AccountingApi _api;
  final DashboardApi _dashboardApi;

  AccountingSummaryNotifier(this._api, this._dashboardApi) : super(const AccountingSummaryState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final summaryFuture = _api.getSummary();
      final monthlyFuture = _api.getMonthly(DateTime.now().year);
      final summary = await summaryFuture;
      final monthly = await monthlyFuture;
      state = state.copyWith(isLoading: false, summary: summary, monthly: monthly);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final accountingEntriesProvider = StateNotifierProvider<AccountingEntriesNotifier, AccountingEntriesState>((ref) {
  return AccountingEntriesNotifier(ref.read(accountingApiProvider));
});

class AccountingEntriesState {
  final List<AccountingEntry> entries;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const AccountingEntriesState({this.entries = const [], this.isLoading = false, this.hasMore = true, this.error});

  AccountingEntriesState copyWith({List<AccountingEntry>? entries, bool? isLoading, bool? hasMore, String? error}) =>
      AccountingEntriesState(entries: entries ?? this.entries, isLoading: isLoading ?? this.isLoading, hasMore: hasMore ?? this.hasMore, error: error ?? this.error);
}

class AccountingEntriesNotifier extends StateNotifier<AccountingEntriesState> {
  final AccountingApi _api;
  int _page = 1;

  AccountingEntriesNotifier(this._api) : super(const AccountingEntriesState()) {
    load();
  }

  Future<void> load({int page = 1}) async {
    if (page == 1) state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getEntries(page: page);
      final newEntries = page == 1 ? response.data : [...state.entries, ...response.data];
      state = state.copyWith(entries: newEntries, isLoading: false, hasMore: response.hasNextPage);
      _page = page;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async => load(page: _page + 1);
}

final paymentTrendsProvider = FutureProvider<List<TrendPoint>>((ref) async => await ref.read(dashboardApiProvider).getPaymentTrends());
final accessTrendsProvider = FutureProvider<List<TrendPoint>>((ref) async => await ref.read(dashboardApiProvider).getAccessTrends());