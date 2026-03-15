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

class _ProductionReportsScreenState extends State<ProductionReportsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedWeekStart; // null = show all weeks in month

  // ── Month helpers ──────────────────────────────────────────────────────────

  void _changeMonth(int dir) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + dir,
      );
      _selectedWeekStart = null; // reset week when month changes
    });
  }

  void _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'SELECT MONTH',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _selectedWeekStart = null;
      });
    }
  }

  // ── Week helpers ───────────────────────────────────────────────────────────

  /// Returns all Monday-dates for weeks that overlap with [_selectedMonth].
  List<String> _getWeeksInMonth() {
    final year  = _selectedMonth.year;
    final month = _selectedMonth.month;

    // Start from the Monday of the week containing the 1st of the month
    final firstDay = DateTime(year, month, 1);
    var monday = firstDay.subtract(Duration(days: firstDay.weekday - 1));

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

    final idx = weeks.indexOf(_selectedWeekStart!);
    final newIdx = idx + dir;
    if (newIdx >= 0 && newIdx < weeks.length) {
      setState(() => _selectedWeekStart = weeks[newIdx]);
    }
  }

  // ── Detail sheet ───────────────────────────────────────────────────────────

  void _showDetailSheet(
    BuildContext context,
    ProductionModel prod,
    AdminProductionViewModel prodVM,
    AdminProductViewModel productVM,
    AdminUserViewModel userVM,
  ) {
    final calc        = prodVM.computeDaily(prod, productVM.products);
    final bakerName   = userVM.getUserName(prod.masterBakerId);
    final helperNames = prod.helperIds
        .map((id) => userVM.getUserName(id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F7F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                      ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(formatCurrency(calc.totalValue),
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _SheetCard(children: [
                    _SheetSectionLabel('WORKERS'),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.star_outline,
                      label: 'Master Baker',
                      value: bakerName,
                      valueColor: AppColors.masterBaker,
                    ),
                    if (helperNames.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _DetailRow(
                        icon: Icons.people_outline,
                        label: 'Helpers',
                        value: helperNames.join(', '),
                        valueColor: AppColors.helper,
                      ),
                    ],
                    const SizedBox(height: 6),
                    _DetailRow(
                      icon: Icons.groups_outlined,
                      label: 'Total Workers',
                      value: '${calc.totalWorkers}',
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _SheetCard(children: [
                    _SheetSectionLabel('PRODUCTS PRODUCED'),
                    const SizedBox(height: 10),
                    ...prod.items.map((item) {
                      final p   = productVM.getById(item.productId);
                      final val = (p?.pricePerSack ?? 0) * item.effectiveSacks;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
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
                    _SheetSectionLabel('SALARY BREAKDOWN'),
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
                    const Divider(height: 20),
                    const Text('BAKER INCENTIVE (IN SALARY)',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                            letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('₱100 / effective sack',
                              style: TextStyle(fontSize: 13)),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatCurrency(calc.bakerIncentive),
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
                            calc.salaryPerWorker + calc.bakerIncentive),
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
                        value: formatCurrency(calc.bonusPerWorker),
                        color: AppColors.masterBaker),
                    BreakdownRow(
                        label: 'Helper Bonus (each)',
                        value: formatCurrency(calc.bonusPerWorker),
                        color: AppColors.success),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bonus is paid separately and is not included in the weekly/monthly payroll total.',
                            style: TextStyle(
                                fontSize: 11, color: Colors.amber.shade800),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final prodVM    = context.watch<AdminProductionViewModel>();
    final productVM = context.watch<AdminProductViewModel>();
    final userVM    = context.watch<AdminUserViewModel>();

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthLabel =
        '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

    final monthStr = _selectedMonth.month.toString().padLeft(2, '0');
    final prefix   = '${_selectedMonth.year}-$monthStr';

    // All productions in selected month
    final monthFiltered = prodVM.productions
        .where((p) => p.date.startsWith(prefix))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Further filter by selected week if one is chosen
    final filtered = _selectedWeekStart == null
        ? monthFiltered
        : monthFiltered.where((p) {
            final d = p.date;
            return d.compareTo(_selectedWeekStart!) >= 0 &&
                d.compareTo(_weekEnd(_selectedWeekStart!)) <= 0;
          }).toList();

    // Month-level summary (always full month)
    double monthTotalValue = 0;
    int    monthTotalSacks = 0;
    for (final prod in monthFiltered) {
      final calc = prodVM.computeDaily(prod, productVM.products);
      monthTotalValue += calc.totalValue;
      monthTotalSacks += calc.totalSacks;
    }

    final weeks = _getWeeksInMonth();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(
            title: 'Production Reports',
            subtitle: 'View daily production history'),

        // ── Month selector ─────────────────────────────────────
        _buildMonthSelector(monthLabel),
        const SizedBox(height: 10),

        // ── Week selector ──────────────────────────────────────
        _buildWeekSelector(weeks),
        const SizedBox(height: 14),

        // ── Month summary (always full month) ──────────────────
        if (monthFiltered.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withValues(alpha: 0.06),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Days', '${monthFiltered.length}',
                    Icons.calendar_today),
                _miniStat('Sacks', '$monthTotalSacks',
                    Icons.inventory_2),
                _miniStat('Value', formatCurrency(monthTotalValue),
                    Icons.attach_money),
              ],
            ),
          ),
        const SizedBox(height: 14),

        // ── Active filter label ────────────────────────────────
        if (_selectedWeekStart != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.filter_list,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    '$_selectedWeekStart — ${_weekEnd(_selectedWeekStart!)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _selectedWeekStart = null),
                    child: const Icon(Icons.close,
                        size: 13, color: AppColors.primary),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Text('${filtered.length} record${filtered.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint)),
            ]),
          ),

        // ── Production list ────────────────────────────────────
        if (filtered.isEmpty)
          const EmptyState(
              message: 'No production records for this period')
        else
          ...filtered.map((prod) {
            final calc      = prodVM.computeDaily(prod, productVM.products);
            final bakerName = userVM.getUserName(prod.masterBakerId);

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showDetailSheet(
                    context, prod, prodVM, productVM, userVM),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(prod.date,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.success
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(formatCurrency(calc.totalValue),
                                style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Wrap(spacing: 20, runSpacing: 6, children: [
                          InfoChip(label: 'Baker', value: bakerName),
                          InfoChip(
                              label: 'Workers',
                              value: '${calc.totalWorkers}'),
                          InfoChip(
                              label: 'Sacks',
                              value: '${calc.totalSacks}'),
                          InfoChip(
                              label: 'Per Worker',
                              value: formatCurrency(calc.salaryPerWorker)),
                        ]),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: prod.items.map((item) {
                            final p   = productVM.getById(item.productId);
                            final val = (p?.pricePerSack ?? 0) * item.sacks;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                '${item.sacks}x ${p?.name ?? "?"} = ${formatCurrency(val)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Tap to view details',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.7),
                                      fontStyle: FontStyle.italic)),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right,
                                  size: 14,
                                  color: AppColors.primary
                                      .withValues(alpha: 0.7)),
                            ]),
                      ]),
                ),
              ),
            );
          }),
      ]),
    );
  }

  // ── Selectors ──────────────────────────────────────────────────────────────

  Widget _buildMonthSelector(String monthLabel) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            onPressed: () => _changeMonth(-1),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickMonth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(monthLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: () => _changeMonth(1),
          ),
        ]),
      ),
    );
  }

  Widget _buildWeekSelector(List<String> weeks) {
    final label = _selectedWeekStart == null
        ? 'All Weeks'
        : '$_selectedWeekStart — ${_weekEnd(_selectedWeekStart!)}';

    // Check if prev/next week navigation is possible
    final idx = _selectedWeekStart == null
        ? -1
        : weeks.indexOf(_selectedWeekStart!);
    final canPrev = _selectedWeekStart != null && idx > 0;
    final canNext = _selectedWeekStart == null
        ? weeks.isNotEmpty
        : idx < weeks.length - 1;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: _selectedWeekStart != null
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border),
      ),
      color: _selectedWeekStart != null
          ? AppColors.primary.withValues(alpha: 0.04)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          IconButton(
            icon: Icon(Icons.chevron_left,
                color: canPrev ? AppColors.primary : AppColors.border),
            onPressed: canPrev ? () => _changeWeek(-1) : null,
          ),
          Expanded(
            child: GestureDetector(
              // Tap cycles through weeks, long press resets to all
              onTap: () {
                if (weeks.isEmpty) return;
                if (_selectedWeekStart == null) {
                  setState(() => _selectedWeekStart = weeks.first);
                } else {
                  final next = idx + 1;
                  setState(() => _selectedWeekStart =
                      next < weeks.length ? weeks[next] : null);
                }
              },
              onLongPress: () =>
                  setState(() => _selectedWeekStart = null),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.date_range,
                      size: 18,
                      color: _selectedWeekStart != null
                          ? AppColors.primary
                          : AppColors.textHint),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _selectedWeekStart != null
                                ? AppColors.primary
                                : AppColors.textHint)),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: canNext ? AppColors.primary : AppColors.border),
            onPressed: canNext ? () => _changeWeek(1) : null,
          ),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14)),
      Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textHint)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────
//  BOTTOM SHEET SUB-WIDGETS
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
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );
}

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 13,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
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
      ]);
}