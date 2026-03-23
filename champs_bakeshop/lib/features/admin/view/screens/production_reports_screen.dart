import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/production_model.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/admin_production_viewmodel.dart';
import '../../viewmodel/admin_product_viewmodel.dart';
import '../../viewmodel/admin_user_viewmodel.dart';

import 'production_report_packer.dart';
import 'production_report_seller.dart';

// ══════════════════════════════════════════════════════════════
//  ROOT SCREEN
// ══════════════════════════════════════════════════════════════
class ProductionReportsScreen extends StatefulWidget {
  const ProductionReportsScreen({super.key});

  @override
  State<ProductionReportsScreen> createState() =>
      _ProductionReportsScreenState();
}

class _ProductionReportsScreenState
    extends State<ProductionReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static const _tabs = ['🧁  Baked', '🥖  Pandesal', '📦  Packer'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Colors.white,
        child: Column(children: [
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
          Container(height: 1, color: AppColors.border),
        ]),
      ),
      Expanded(
        child: TabBarView(
          controller: _tab,
          children: const [
            _BakedReportsTab(),
            ProductionReportSeller(),
            ProductionReportPacker(),
          ],
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
//  BAKED TAB
// ══════════════════════════════════════════════════════════════
class _BakedReportsTab extends StatefulWidget {
  const _BakedReportsTab();

  @override
  State<_BakedReportsTab> createState() => _BakedReportsTabState();
}

class _BakedReportsTabState extends State<_BakedReportsTab> {
  // ── Default: current month & current week ────────────────────
  late DateTime _selectedMonth;
  late String?  _selectedWeekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    // Auto-select current week
    _selectedWeekStart = getWeekStart(now);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  bool get _isCurrentWeek =>
      _selectedWeekStart == getWeekStart(DateTime.now());

  String get _monthLabel {
    const names = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${names[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  void _changeMonth(int dir) {
    final next =
        DateTime(_selectedMonth.year, _selectedMonth.month + dir);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() {
      _selectedMonth     = next;
      _selectedWeekStart = null;
    });
  }

  Future<void> _pickMonth() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedMonth,
      firstDate:   DateTime(2024),
      lastDate:    now,
      helpText:    'Select Month',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onSurface: AppColors.text),
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
    final y        = _selectedMonth.year;
    final m        = _selectedMonth.month;
    final firstDay = DateTime(y, m, 1);
    var monday =
        firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final weeks = <String>[];
    while (monday.isBefore(DateTime(y, m + 1, 1))) {
      weeks.add(monday.toString().split(' ')[0]);
      monday = monday.add(const Duration(days: 7));
    }
    return weeks;
  }

  String _weekEnd(String ws) {
    final d = DateTime.parse(ws);
    return d.add(const Duration(days: 6)).toString().split(' ')[0];
  }

  String _fmtWeekLabel(String ws) {
    final currentWs = getWeekStart(DateTime.now());
    if (ws == currentWs) return 'This Week';
    final d = DateTime.parse(ws);
    final e = DateTime.parse(_weekEnd(ws));
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    if (d.month == e.month) {
      return '${m[d.month - 1]} ${d.day}–${e.day}';
    }
    return '${m[d.month - 1]} ${d.day} – ${m[e.month - 1]} ${e.day}';
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
      context:         context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize:     0.5,
        maxChildSize:     0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prod.date,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              letterSpacing: -0.3)),
                      const Text('Production Detail',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.success
                            .withValues(alpha: 0.2)),
                  ),
                  child: Text(formatCurrency(calc.totalValue),
                      style: const TextStyle(
                          color:      AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize:   14)),
                ),
              ]),
            ),

            const Divider(height: 20, color: AppColors.border),

            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // Workers
                  _SheetCard(children: [
                    const _SheetLabel('WORKERS'),
                    const SizedBox(height: 10),
                    _SheetRow(
                      icon:       Icons.star_outline,
                      label:      'Master Baker',
                      value:      bakerName,
                      valueColor: AppColors.masterBaker,
                    ),
                    if (helperNames.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _SheetRow(
                        icon:       Icons.people_outline,
                        label:      'Helpers',
                        value:      helperNames.join(', '),
                        valueColor: AppColors.helper,
                      ),
                    ],
                    const SizedBox(height: 6),
                    _SheetRow(
                      icon:  Icons.groups_outlined,
                      label: 'Total Workers',
                      value: '${calc.totalWorkers}',
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Products
                  _SheetCard(children: [
                    const _SheetLabel('PRODUCTS PRODUCED'),
                    const SizedBox(height: 10),
                    ...prod.items.map((item) {
                      final p   = productVM.getById(item.productId);
                      final val =
                          (p?.pricePerSack ?? 0) * item.effectiveSacks;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.sacks} sack${item.sacks != 1 ? 's' : ''}'
                              '${item.extraKg > 0 ? ' + ${item.extraKg}kg' : ''}',
                              style: const TextStyle(
                                  fontSize:   12,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(p?.name ?? '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize:   13)),
                          ),
                          Text(formatCurrency(val),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize:   13,
                                  color:      AppColors.success)),
                        ]),
                      );
                    }),
                  ]),
                  const SizedBox(height: 12),

                  // Salary
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
                        value: formatCurrency(calc.salaryPerWorker)),
                    const Divider(height: 20, color: AppColors.border),
                    const _SubLabel('BAKER INCENTIVE'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Incentive',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                        Text(formatCurrency(calc.bakerIncentive),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color:      AppColors.primaryDark,
                                fontSize:   13)),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    BreakdownRow(
                        label: 'Baker Salary (est.)',
                        value: formatCurrency(
                            calc.salaryPerWorker + calc.bakerIncentive),
                        color: AppColors.primaryDark),
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

    final monthStr      =
        _selectedMonth.month.toString().padLeft(2, '0');
    final prefix        = '${_selectedMonth.year}-$monthStr';

    final monthFiltered = prodVM.productions
        .where((p) => p.date.startsWith(prefix))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final filtered = _selectedWeekStart == null
        ? monthFiltered
        : monthFiltered.where((p) {
            return p.date.compareTo(_selectedWeekStart!) >= 0 &&
                p.date.compareTo(_weekEnd(_selectedWeekStart!)) <= 0;
          }).toList();

    double monthTotalValue = 0;
    int    monthTotalSacks = 0;
    for (final prod in monthFiltered) {
      final calc = prodVM.computeDaily(prod, productVM.products);
      monthTotalValue += calc.totalValue;
      monthTotalSacks += calc.totalSacks;
    }

    double weekTotalValue = 0;
    int    weekTotalSacks = 0;
    for (final prod in filtered) {
      final calc = prodVM.computeDaily(prod, productVM.products);
      weekTotalValue += calc.totalValue;
      weekTotalSacks += calc.totalSacks;
    }

    final weeks = _getWeeksInMonth();

    return ColoredBox(
      color: const Color(0xFFF8F7F5),
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async =>
    context.read<AdminProductionViewModel>().loadAllProductions(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Page header ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Baked Production',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                              letterSpacing: -0.5)),
                      SizedBox(height: 2),
                      Text('Daily baked goods records',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint)),
                    ],
                  ),
                  // This week shortcut
                  if (!_isCurrentWeek || !_isCurrentMonth)
                    GestureDetector(
                      onTap: () {
                        final now = DateTime.now();
                        setState(() {
                          _selectedMonth =
                              DateTime(now.year, now.month);
                          _selectedWeekStart = getWeekStart(now);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary
                                  .withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.today_outlined,
                                  size: 13,
                                  color: AppColors.primary),
                              SizedBox(width: 5),
                              Text('This Week',
                                  style: TextStyle(
                                      fontSize:   12,
                                      fontWeight: FontWeight.w700,
                                      color:      AppColors.primary)),
                            ]),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Month navigator ────────────────────────────
              _MonthNavigator(
                label:          _monthLabel,
                isCurrentMonth: _isCurrentMonth,
                onPrev:         () => _changeMonth(-1),
                onNext:         _isCurrentMonth
                    ? null
                    : () => _changeMonth(1),
                onTap: _pickMonth,
              ),
              const SizedBox(height: 10),

              // ── Week navigator ─────────────────────────────
              _WeekNavigator(
                selectedWeekStart: _selectedWeekStart,
                isCurrentWeek:     _isCurrentWeek,
                weeks:             weeks,
                weekEnd:           _weekEnd,
                fmtLabel:          _fmtWeekLabel,
                onPrev: () {
                  if (_selectedWeekStart == null) return;
                  final idx =
                      weeks.indexOf(_selectedWeekStart!);
                  if (idx > 0) {
                    setState(
                        () => _selectedWeekStart = weeks[idx - 1]);
                  }
                },
                onNext: () {
                  if (_selectedWeekStart == null) {
                    if (weeks.isNotEmpty) {
                      setState(
                          () => _selectedWeekStart = weeks.first);
                    }
                    return;
                  }
                  final idx =
                      weeks.indexOf(_selectedWeekStart!);
                  // Block if current week is selected
                  if (_isCurrentWeek) return;
                  if (idx < weeks.length - 1) {
                    setState(
                        () => _selectedWeekStart = weeks[idx + 1]);
                  }
                },
                onClear: () =>
                    setState(() => _selectedWeekStart = null),
                disableNext: _isCurrentWeek,
              ),
              const SizedBox(height: 16),

              // ── Summary banner ─────────────────────────────
              if (monthFiltered.isNotEmpty)
                _SummaryBanner(
                  isWeekFiltered:  _selectedWeekStart != null,
                  monthDays:       monthFiltered.length,
                  monthSacks:      monthTotalSacks,
                  monthValue:      monthTotalValue,
                  weekDays:        filtered.length,
                  weekSacks:       weekTotalSacks,
                  weekValue:       weekTotalValue,
                  weekLabel: _selectedWeekStart != null
                      ? _fmtWeekLabel(_selectedWeekStart!)
                      : '',
                ),
              const SizedBox(height: 16),

              // ── Records label ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionLabel('RECORDS'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filtered.length} record${filtered.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                          color:      AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── List ──────────────────────────────────────
              if (filtered.isEmpty)
                const _EmptyReports()
              else
                ...filtered.asMap().entries.map((e) {
                  final prod      = e.value;
                  final calc      =
                      prodVM.computeDaily(prod, productVM.products);
                  final bakerName =
                      userVM.getUserName(prod.masterBakerId);
                  return _ProductionCard(
                    prod:      prod,
                    calc:      calc,
                    bakerName: bakerName,
                    productVM: productVM,
                    index:     e.key,
                    onTap: () => _showDetailSheet(
                        context, prod, prodVM, productVM, userVM),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MONTH NAVIGATOR
// ─────────────────────────────────────────────────────────────
class _MonthNavigator extends StatelessWidget {
  final String        label;
  final bool          isCurrentMonth;
  final VoidCallback  onPrev;
  final VoidCallback? onNext;
  final VoidCallback  onTap;

  const _MonthNavigator({
    required this.label,
    required this.isCurrentMonth,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          _NavBtn(icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        size:  15,
                        color: isCurrentMonth
                            ? AppColors.primary
                            : AppColors.textHint),
                    const SizedBox(width: 8),
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize:   14,
                            color: isCurrentMonth
                                ? AppColors.primary
                                : AppColors.text,
                            letterSpacing: -0.2)),
                    if (isCurrentMonth) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('THIS MONTH',
                            style: TextStyle(
                                fontSize:   8,
                                fontWeight: FontWeight.w800,
                                color:      Colors.white,
                                letterSpacing: 0.5)),
                      ),
                    ],
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down,
                        size: 18, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          ),
          _NavBtn(
            icon:     Icons.chevron_right,
            onTap:    onNext,
            disabled: onNext == null,
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  WEEK NAVIGATOR
// ─────────────────────────────────────────────────────────────
class _WeekNavigator extends StatelessWidget {
  final String?         selectedWeekStart;
  final bool            isCurrentWeek;
  final List<String>    weeks;
  final String Function(String) weekEnd;
  final String Function(String) fmtLabel;
  final VoidCallback    onPrev;
  final VoidCallback    onNext;
  final VoidCallback    onClear;
  final bool            disableNext;

  const _WeekNavigator({
    required this.selectedWeekStart,
    required this.isCurrentWeek,
    required this.weeks,
    required this.weekEnd,
    required this.fmtLabel,
    required this.onPrev,
    required this.onNext,
    required this.onClear,
    required this.disableNext,
  });

  bool get _canPrev {
    if (selectedWeekStart == null) return false;
    final idx = weeks.indexOf(selectedWeekStart!);
    return idx > 0;
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = selectedWeekStart != null;
    final label     = hasFilter
        ? fmtLabel(selectedWeekStart!)
        : 'All Weeks';

    return Container(
      decoration: BoxDecoration(
        color: hasFilter
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFilter
              ? AppColors.primary.withValues(alpha: 0.20)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        _NavBtn(
          icon:     Icons.chevron_left,
          onTap:    _canPrev ? onPrev : null,
          disabled: !_canPrev,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!hasFilter && weeks.isNotEmpty) onNext();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.date_range_outlined,
                        size:  15,
                        color: hasFilter
                            ? AppColors.primary
                            : AppColors.textHint),
                    const SizedBox(width: 8),
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize:   13,
                            color: hasFilter
                                ? AppColors.primary
                                : AppColors.textHint,
                            letterSpacing: -0.2)),
                    if (hasFilter && isCurrentWeek) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('THIS WEEK',
                            style: TextStyle(
                                fontSize:   8,
                                fontWeight: FontWeight.w800,
                                color:      Colors.white,
                                letterSpacing: 0.5)),
                      ),
                    ],
                    if (hasFilter) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onClear,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 11, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!hasFilter)
                  const Text('Tap to filter by week',
                      style: TextStyle(
                          fontSize: 10,
                          color:    AppColors.textHint)),
              ]),
            ),
          ),
        ),
        _NavBtn(
          icon:     Icons.chevron_right,
          onTap:    disableNext ? null : onNext,
          disabled: disableNext,
        ),
      ]),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  final bool          disabled;
  const _NavBtn(
      {required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap:        disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
          child: Icon(icon,
              size:  20,
              color: disabled
                  ? AppColors.border
                  : AppColors.primary),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  SUMMARY BANNER
// ─────────────────────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  final bool   isWeekFiltered;
  final int    monthDays;
  final int    monthSacks;
  final double monthValue;
  final int    weekDays;
  final int    weekSacks;
  final double weekValue;
  final String weekLabel;

  const _SummaryBanner({
    required this.isWeekFiltered,
    required this.monthDays,
    required this.monthSacks,
    required this.monthValue,
    required this.weekDays,
    required this.weekSacks,
    required this.weekValue,
    required this.weekLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A00), Color(0xFFFFA03A)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      const Color(0xFFFF7A00).withValues(alpha: 0.28),
            blurRadius: 14,
            offset:     const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(children: [
            const Icon(Icons.bar_chart_outlined,
                size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              isWeekFiltered ? weekLabel : 'Monthly Overview',
              style: const TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w700,
                  color:      Colors.white70,
                  letterSpacing: 0.8),
            ),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BannerStat(
                icon:  Icons.calendar_today_outlined,
                label: 'Days',
                value: '${isWeekFiltered ? weekDays : monthDays}',
              ),
              _BannerDivider(),
              _BannerStat(
                icon:  Icons.inventory_2_outlined,
                label: 'Sacks',
                value: '${isWeekFiltered ? weekSacks : monthSacks}',
              ),
              _BannerDivider(),
              _BannerStat(
                icon:  Icons.attach_money,
                label: 'Value',
                value: formatCurrency(
                    isWeekFiltered ? weekValue : monthValue),
              ),
            ],
          ),
          // Month footnote when week is filtered
          if (isWeekFiltered) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 12, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  'Month total: ${formatCurrency(monthValue)}  ·  $monthDays days',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white70),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRODUCTION CARD
// ─────────────────────────────────────────────────────────────
class _ProductionCard extends StatelessWidget {
  final ProductionModel       prod;
  final dynamic               calc;
  final String                bakerName;
  final AdminProductViewModel productVM;
  final int                   index;
  final VoidCallback          onTap;

  const _ProductionCard({
    required this.prod,
    required this.calc,
    required this.bakerName,
    required this.productVM,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween:    Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 40),
      curve:    Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap:        onTap,
            borderRadius: BorderRadius.circular(18),
            child: Column(children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date row
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
                            size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(prod.date,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize:   15,
                                color:      AppColors.text,
                                letterSpacing: -0.3)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.success
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          formatCurrency(calc.totalValue),
                          style: const TextStyle(
                              color:      AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize:   13),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    // Chips
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _InfoChip(
                          icon:  Icons.star_outline,
                          label: bakerName,
                          color: AppColors.masterBaker),
                      _InfoChip(
                          icon:  Icons.groups_outlined,
                          label: '${calc.totalWorkers} workers',
                          color: AppColors.info),
                      _InfoChip(
                          icon:  Icons.inventory_2_outlined,
                          label: '${calc.totalSacks} sacks',
                          color: AppColors.primary),
                      _InfoChip(
                          icon:  Icons.calculate_outlined,
                          label:
                              '${formatCurrency(calc.salaryPerWorker)}/worker',
                          color: const Color(0xFF388E3C)),
                    ]),
                    const SizedBox(height: 8),

                    // Product tags
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: prod.items.map((item) {
                        final p =
                            productVM.getById(item.productId);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0EC),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${item.sacks}× ${p?.name ?? "?"}',
                            style: const TextStyle(
                                fontSize:   11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Footer strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18)),
                  border: Border(
                      top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('View full details',
                        style: TextStyle(
                            fontSize:   11,
                            color: AppColors.primary
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 3),
                    Icon(Icons.keyboard_arrow_down,
                        size: 14,
                        color: AppColors.primary
                            .withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                  color:      color)),
        ]),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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
                fontSize:   11,
                fontWeight: FontWeight.w800,
                color:      AppColors.textHint,
                letterSpacing: 0.8)),
      ]);
}

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize:   10,
          fontWeight: FontWeight.w700,
          color:      AppColors.textHint,
          letterSpacing: 0.6));
}

class _BannerStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _BannerStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color:      Colors.white,
                fontWeight: FontWeight.w900,
                fontSize:   14,
                letterSpacing: -0.3)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
      ]);
}

class _BannerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 36,
      color: Colors.white.withValues(alpha: 0.3));
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(18),
          border:       Border.all(color: AppColors.border),
        ),
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
                  fontSize:   15,
                  color:      AppColors.text)),
          const SizedBox(height: 6),
          const Text('No records found for this period',
              style: TextStyle(
                  fontSize: 13,
                  color:    AppColors.textSecondary)),
        ]),
      );
}

class _SheetCard extends StatelessWidget {
  final List<Widget> children;
  const _SheetCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset:     const Offset(0, 4)),
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
                fontSize:   11,
                fontWeight: FontWeight.w800,
                color:      AppColors.textHint,
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
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.text)),
        ]),
      );
}