import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/production_model.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/admin_production_viewmodel.dart';
import '../../viewmodel/admin_product_viewmodel.dart';
import '../../viewmodel/admin_user_viewmodel.dart';

class ProductionReportsScreen extends StatefulWidget {
  const ProductionReportsScreen({super.key});

  @override
  State<ProductionReportsScreen> createState() =>
      _ProductionReportsScreenState();
}

class _ProductionReportsScreenState
    extends State<ProductionReportsScreen> {
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedWeekStart;

  void _changeMonth(int dir) {
    setState(() {
      _selectedMonth = DateTime(
          _selectedMonth.year, _selectedMonth.month + dir);
      _selectedWeekStart = null;
    });
  }

  void _pickMonth() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'SELECT MONTH',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedMonth     = DateTime(picked.year, picked.month);
        _selectedWeekStart = null;
      });
    }
  }

  List<String> _getWeeksInMonth() {
    final year  = _selectedMonth.year;
    final month = _selectedMonth.month;
    final firstDay = DateTime(year, month, 1);
    var monday =
        firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final weeks = <String>[];
    while (monday.isBefore(DateTime(year, month + 1, 1))) {
      weeks.add(monday.toString().split(' ')[0]);
      monday = monday.add(const Duration(days: 7));
    }
    return weeks;
  }

  String _weekEnd(String weekStart) {
    final d = DateTime.parse(weekStart);
    return d.add(const Duration(days: 6)).toString().split(' ')[0];
  }

  void _changeWeek(int dir) {
    final weeks = _getWeeksInMonth();
    if (weeks.isEmpty) return;
    if (_selectedWeekStart == null) {
      setState(() => _selectedWeekStart =
          dir > 0 ? weeks.first : weeks.last);
      return;
    }
    final idx    = weeks.indexOf(_selectedWeekStart!);
    final newIdx = idx + dir;
    if (newIdx >= 0 && newIdx < weeks.length) {
      setState(() => _selectedWeekStart = weeks[newIdx]);
    }
  }

  void _showDetailSheet(
    BuildContext context,
    ProductionModel prod,
    AdminProductionViewModel prodVM,
    AdminProductViewModel productVM,
    AdminUserViewModel userVM,
  ) {
    final calc        = prodVM.computeDaily(prod, productVM.products);
    final bakerName   = userVM.getUserName(prod.masterBakerId);
    final helperNames =
        prod.helperIds.map((id) => userVM.getUserName(id)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize:     0.5,
        maxChildSize:     0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text(prod.date,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.3)),
                    const Text('Production Detail',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.success
                            .withValues(alpha: 0.2)),
                  ),
                  child: Text(
                      formatCurrency(calc.totalValue),
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ]),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _SheetCard(children: [
                    const _SheetLabel('WORKERS'),
                    const SizedBox(height: 10),
                    _SheetRow(
                      icon: Icons.star_outline,
                      label: 'Master Baker',
                      value: bakerName,
                      valueColor: AppColors.masterBaker,
                    ),
                    if (helperNames.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _SheetRow(
                        icon: Icons.people_outline,
                        label: 'Helpers',
                        value: helperNames.join(', '),
                        valueColor: AppColors.helper,
                      ),
                    ],
                    const SizedBox(height: 6),
                    _SheetRow(
                      icon: Icons.groups_outlined,
                      label: 'Total Workers',
                      value: '${calc.totalWorkers}',
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _SheetCard(children: [
                    const _SheetLabel('PRODUCTS PRODUCED'),
                    const SizedBox(height: 10),
                    ...prod.items.map((item) {
                      final p   = productVM.getById(item.productId);
                      final val =
                          (p?.pricePerSack ?? 0) *
                              item.effectiveSacks;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.sacks} sack${item.sacks != 1 ? 's' : ''}'
                              '${item.extraKg > 0 ? ' + ${item.extraKg}kg' : ''}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(p?.name ?? '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                          Text(formatCurrency(val),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.success)),
                        ]),
                      );
                    }),
                  ]),
                  const SizedBox(height: 12),
                  _SheetCard(children: [
                    const _SheetLabel('SALARY BREAKDOWN'),
                    const SizedBox(height: 10),
                    BreakdownRow(
                        label: 'Total Value',
                        value: formatCurrency(calc.totalValue),
                        color: AppColors.primary),
                    BreakdownRow(
                        label: 'Total Sacks',
                        value: calc.totalExtraKg > 0
                            ? '${calc.totalSacks} sacks + ${calc.totalExtraKg} kg'
                            : '${calc.totalSacks} sacks'),
                    BreakdownRow(
                        label: 'Per Worker (base)',
                        value: formatCurrency(
                            calc.salaryPerWorker)),
                    const Divider(height: 20),
                    const Text('BAKER INCENTIVE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                            letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                      const Text('₱100 / effective sack',
                          style: TextStyle(fontSize: 13)),
                      Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                        Text(
                            formatCurrency(calc.bakerIncentive),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                                fontSize: 13)),
                        Text(
                          '${(calc.totalSacks + calc.totalExtraKg / 25.0).toStringAsFixed(2)} eff. sacks × ₱100',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textHint),
                        ),
                      ]),
                    ]),
                    const Divider(height: 20),
                    BreakdownRow(
                        label: 'Baker Salary (est.)',
                        value: formatCurrency(
                            calc.salaryPerWorker +
                                calc.bakerIncentive),
                        color: AppColors.primaryDark),
                    const Divider(height: 20),
                    const Text('BONUS (PAID SEPARATELY)',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                            letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    BreakdownRow(
                        label: 'Master Baker Bonus',
                        value: formatCurrency(
                            calc.bonusPerWorker),
                        color: AppColors.masterBaker),
                    BreakdownRow(
                        label: 'Helper Bonus (each)',
                        value: formatCurrency(
                            calc.bonusPerWorker),
                        color: AppColors.success),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.amber.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline,
                            size: 14,
                            color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bonus is paid separately and not included in weekly payroll total.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade800),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prodVM    = context.watch<AdminProductionViewModel>();
    final productVM = context.watch<AdminProductViewModel>();
    final userVM    = context.watch<AdminUserViewModel>();

    const monthNames = [
      'January', 'February', 'March',    'April',
      'May',     'June',     'July',     'August',
      'September','October', 'November', 'December'
    ];
    final monthLabel =
        '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';
    final monthStr   =
        _selectedMonth.month.toString().padLeft(2, '0');
    final prefix     = '${_selectedMonth.year}-$monthStr';

    final monthFiltered = prodVM.productions
        .where((p) => p.date.startsWith(prefix))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final filtered = _selectedWeekStart == null
        ? monthFiltered
        : monthFiltered.where((p) {
            final d = p.date;
            return d.compareTo(_selectedWeekStart!) >= 0 &&
                d.compareTo(_weekEnd(_selectedWeekStart!)) <= 0;
          }).toList();

    double monthTotalValue = 0;
    int    monthTotalSacks = 0;
    for (final prod in monthFiltered) {
      final calc = prodVM.computeDaily(prod, productVM.products);
      monthTotalValue += calc.totalValue;
      monthTotalSacks += calc.totalSacks;
    }

    final weeks = _getWeeksInMonth();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

        // ── Header ──────────────────────────────────────
        const _PageHeader(
          title:    'Production Reports',
          subtitle: 'View daily production history',
          icon:     Icons.bar_chart_outlined,
        ),
        const SizedBox(height: 16),

        // ── Month selector ───────────────────────────────
        _MonthSelector(
          label:  monthLabel,
          onPrev: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
          onTap:  _pickMonth,
        ),
        const SizedBox(height: 10),

        // ── Week selector ────────────────────────────────
        _buildWeekSelector(weeks),
        const SizedBox(height: 14),

        // ── Month summary banner ─────────────────────────
        if (monthFiltered.isNotEmpty)
          _MonthSummaryBanner(
            days:   monthFiltered.length,
            sacks:  monthTotalSacks,
            value:  monthTotalValue,
          ),
        const SizedBox(height: 14),

        // ── Active filter chip ───────────────────────────
        if (_selectedWeekStart != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const Icon(Icons.filter_list,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    '$_selectedWeekStart — ${_weekEnd(_selectedWeekStart!)}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(
                        () => _selectedWeekStart = null),
                    child: const Icon(Icons.close,
                        size: 13,
                        color: AppColors.primary),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Text(
                '${filtered.length} record${filtered.length != 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint),
              ),
            ]),
          ),

        // ── List ─────────────────────────────────────────
        if (filtered.isEmpty)
          _EmptyReports()
        else
          ...filtered.map((prod) {
            final calc      =
                prodVM.computeDaily(prod, productVM.products);
            final bakerName =
                userVM.getUserName(prod.masterBakerId);

            return _ProductionCard(
              prod:       prod,
              calc:       calc,
              bakerName:  bakerName,
              productVM:  productVM,
              onTap: () => _showDetailSheet(
                  context, prod, prodVM, productVM, userVM),
            );
          }),
      ]),
    );
  }

  Widget _buildWeekSelector(List<String> weeks) {
    final label = _selectedWeekStart == null
        ? 'All Weeks'
        : '$_selectedWeekStart — ${_weekEnd(_selectedWeekStart!)}';
    final idx   = _selectedWeekStart == null
        ? -1
        : weeks.indexOf(_selectedWeekStart!);
    final canPrev = _selectedWeekStart != null && idx > 0;
    final canNext = _selectedWeekStart == null
        ? weeks.isNotEmpty
        : idx < weeks.length - 1;

    return Container(
      decoration: BoxDecoration(
        color: _selectedWeekStart != null
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: _selectedWeekStart != null
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.2))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.chevron_left,
              color: canPrev
                  ? AppColors.primary
                  : AppColors.textHint
                      .withValues(alpha: 0.3)),
          onPressed: canPrev ? () => _changeWeek(-1) : null,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (weeks.isEmpty) return;
              if (_selectedWeekStart == null) {
                setState(
                    () => _selectedWeekStart = weeks.first);
              } else {
                final next = idx + 1;
                setState(() => _selectedWeekStart =
                    next < weeks.length
                        ? weeks[next]
                        : null);
              }
            },
            onLongPress: () =>
                setState(() => _selectedWeekStart = null),
            child: Column(children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.date_range_outlined,
                    size: 15,
                    color: _selectedWeekStart != null
                        ? AppColors.primary
                        : AppColors.textHint),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _selectedWeekStart != null
                              ? AppColors.primary
                              : AppColors.textHint),
                      textAlign: TextAlign.center),
                ),
              ]),
              if (_selectedWeekStart == null)
                const Text('Tap to filter by week',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint)),
            ]),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right,
              color: canNext
                  ? AppColors.primary
                  : AppColors.textHint
                      .withValues(alpha: 0.3)),
          onPressed: canNext ? () => _changeWeek(1) : null,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PAGE HEADER
// ─────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final String   title;
  final String   subtitle;
  final IconData icon;
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: const Color(0xFFFF7A00), size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint)),
        ]),
      ]);
}

// ─────────────────────────────────────────────────────────
//  MONTH SELECTOR
// ─────────────────────────────────────────────────────────
class _MonthSelector extends StatelessWidget {
  final String       label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;
  const _MonthSelector({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.chevron_left,
                  color: AppColors.primary),
              onPressed: onPrev),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Icon(Icons.calendar_month,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primary)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down,
                    size: 18, color: AppColors.primary),
              ]),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right,
                  color: AppColors.primary),
              onPressed: onNext),
        ]),
      );
}

// ─────────────────────────────────────────────────────────
//  MONTH SUMMARY BANNER
// ─────────────────────────────────────────────────────────
class _MonthSummaryBanner extends StatelessWidget {
  final int    days;
  final int    sacks;
  final double value;
  const _MonthSummaryBanner({
    required this.days,
    required this.sacks,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A00), Color(0xFFFFA03A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A00)
                  .withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
          _BannerStat(
              icon: Icons.calendar_today_outlined,
              label: 'Days',
              value: '$days'),
          _BannerDivider(),
          _BannerStat(
              icon: Icons.inventory_2_outlined,
              label: 'Sacks',
              value: '$sacks'),
          _BannerDivider(),
          _BannerStat(
              icon: Icons.attach_money,
              label: 'Value',
              value: formatCurrency(value)),
        ]),
      );
}

class _BannerStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _BannerStat(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
      ]);
}

class _BannerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.3));
}

// ─────────────────────────────────────────────────────────
//  EMPTY REPORTS STATE
// ─────────────────────────────────────────────────────────
class _EmptyReports extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bar_chart_outlined,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No production records',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('No records found for this period.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────
//  PRODUCTION CARD
// ─────────────────────────────────────────────────────────
class _ProductionCard extends StatelessWidget {
  final ProductionModel      prod;
  final dynamic              calc;
  final String               bakerName;
  final AdminProductViewModel productVM;
  final VoidCallback         onTap;

  const _ProductionCard({
    required this.prod,
    required this.calc,
    required this.bakerName,
    required this.productVM,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                // ── Date + value ────────────────────────
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(prod.date,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF1A1A1A))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.success
                              .withValues(alpha: 0.2)),
                    ),
                    child: Text(
                        formatCurrency(calc.totalValue),
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ]),
                const SizedBox(height: 12),

                // ── Info chips ──────────────────────────
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _InfoChip(
                      icon: Icons.star_outline,
                      label: bakerName,
                      color: AppColors.masterBaker),
                  _InfoChip(
                      icon: Icons.groups_outlined,
                      label: '${calc.totalWorkers} workers',
                      color: AppColors.info),
                  _InfoChip(
                      icon: Icons.inventory_2_outlined,
                      label: '${calc.totalSacks} sacks',
                      color: AppColors.primary),
                  _InfoChip(
                      icon: Icons.calculate_outlined,
                      label: '${formatCurrency(calc.salaryPerWorker)}/worker',
                      color: const Color(0xFF388E3C)),
                ]),
                const SizedBox(height: 10),

                // ── Product pills ───────────────────────
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: prod.items.map((item) {
                    final p   = productVM.getById(item.productId);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${item.sacks}× ${p?.name ?? "?"}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // ── Tap hint ────────────────────────────
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                  Text('View details',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary
                              .withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic)),
                  const SizedBox(width: 3),
                  Icon(Icons.chevron_right,
                      size: 14,
                      color: AppColors.primary
                          .withValues(alpha: 0.7)),
                ]),
              ]),
            ),
          ),
        ),
      );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _InfoChip(
      {required this.icon,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────
//  DETAIL SHEET WIDGETS
// ─────────────────────────────────────────────────────────
class _SheetCard extends StatelessWidget {
  final List<Widget> children;
  const _SheetCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
                letterSpacing: 0.8)),
      ]);
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 15, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textHint)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.text)),
        ]),
      );
}