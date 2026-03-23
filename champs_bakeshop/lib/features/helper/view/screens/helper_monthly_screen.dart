import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';

import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/helper_salary_viewmodel.dart';

class HelperMonthlyScreen extends StatefulWidget {
  const HelperMonthlyScreen({super.key});

  @override
  State<HelperMonthlyScreen> createState() =>
      _HelperMonthlyScreenState();
}

class _HelperMonthlyScreenState extends State<HelperMonthlyScreen> {
  // Default: current month
  late DateTime _selectedMonth;

  static const _weekColors = [
    AppColors.info,
    AppColors.primary,
    AppColors.masterBaker,
    Color(0xFF8E44AD),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _userId =>
      context.read<AuthViewModel>().currentUser!.id;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  String get _monthLabel {
    const names = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December',
    ];
    return '${names[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  void _load() {
    final vm = context.read<HelperSalaryViewModel>();
    vm.loadMonthlySummary(_userId,
        year: _selectedMonth.year, month: _selectedMonth.month);
    vm.loadPaidWeeks(_userId);
  }

  void _goMonth(int dir) {
    // Block future months
    final next =
        DateTime(_selectedMonth.year, _selectedMonth.month + dir);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _selectedMonth = next);
    _load();
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
            primary:   AppColors.info,
            onSurface: AppColors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(
        () => _selectedMonth = DateTime(picked.year, picked.month));
    _load();
  }

  void _showWeekPreview(
      WeeklySummary week, Color color, bool paid) {
    showModalBottomSheet(
      context:         context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize:     0.5,
        maxChildSize:     0.92,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.date_range_outlined,
                      color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(week.label,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text),
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '${week.daysWorked} days · ${week.totalSacks} sacks',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                    ],
                  ),
                ),
                _PaidBadge(paid: paid),
              ]),
            ),
            const Divider(height: 20, color: AppColors.border),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _SheetCard(color: color, children: [
                    _SheetLabel('WEEK OVERVIEW', color),
                    const SizedBox(height: 12),
                    _SheetRow(icon: Icons.work_history_outlined,
                        label: 'Days Worked',
                        value: '${week.daysWorked} days'),
                    _SheetRow(icon: Icons.inventory_2_outlined,
                        label: 'Total Sacks',
                        value: '${week.totalSacks} sacks'),
                    _SheetRow(
                        icon:       Icons.payments_outlined,
                        label:      'Gross Salary',
                        value:      formatCurrency(week.grossSalary),
                        valueColor: AppColors.masterBaker),
                  ]),
                  const SizedBox(height: 12),
                  _SheetCard(color: AppColors.danger, children: [
                    _SheetLabel('DEDUCTIONS', AppColors.danger),
                    const SizedBox(height: 12),
                    _DeductionRow('Oven', week.ovenDeduction),
                    _DeductionRow('Gas',  week.gasDeduction),
                    _DeductionRow('Vale', week.vale),
                    _DeductionRow('Wifi', week.wifi),
                    const Divider(height: 20, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Deductions',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        Text(
                          '-${formatCurrency(week.totalDeductions)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.danger),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _SheetCard(
                    color: AppColors.primaryDark,
                    children: [
                      _SheetLabel('NET SALARY', AppColors.primaryDark),
                      const SizedBox(height: 12),
                      _SheetRow(
                          icon:       Icons.calculate_outlined,
                          label:      'Gross',
                          value:      formatCurrency(week.grossSalary),
                          valueColor: AppColors.masterBaker),
                      _SheetRow(
                          icon:       Icons.remove_circle_outline,
                          label:      'Total Deductions',
                          value:      '-${formatCurrency(week.totalDeductions)}',
                          valueColor: AppColors.danger),
                      const Divider(height: 20, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Take-Home Pay',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          Text(
                            formatCurrency(week.finalSalary),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                color: AppColors.primaryDark,
                                letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PaymentStatusCard(paid: paid),
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
    final vm        = context.watch<HelperSalaryViewModel>();
    final paidWeeks = vm.paidWeekStarts;
    final paidCount = vm.monthlyWeeks
        .where((w) => paidWeeks.contains(w.weekStart))
        .length;

    return RefreshIndicator(
      color:     AppColors.info,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Page header ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Summary',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                            letterSpacing: -0.5)),
                    SizedBox(height: 2),
                    Text('Earnings overview per month',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ],
                ),
                if (!_isCurrentMonth)
                  GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      setState(() => _selectedMonth =
                          DateTime(now.year, now.month));
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.info
                                .withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today_outlined,
                                size: 13, color: AppColors.info),
                            SizedBox(width: 5),
                            Text('This Month',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.info)),
                          ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Month navigator ──────────────────────────
            _MonthNavigator(
              label:          _monthLabel,
              isCurrentMonth: _isCurrentMonth,
              onPrev:         () => _goMonth(-1),
              onNext:         _isCurrentMonth ? null : () => _goMonth(1),
              onTap:          _pickMonth,
            ),
            const SizedBox(height: 16),

            // ── Content ──────────────────────────────────
            if (vm.isLoading)
              const _LoadingCard()
            else if (vm.error != null)
              _ErrorCard(message: vm.error!, onRetry: _load)
            else if (vm.monthlyWeeks.isEmpty)
              _NoMonthRecord(monthLabel: _monthLabel)
            else ...[
              _EarningsBanner(vm: vm),
              const SizedBox(height: 14),
              if (vm.monthlyWeeks.isNotEmpty)
                _MonthPaymentBar(
                    paidCount:  paidCount,
                    totalWeeks: vm.monthlyWeeks.length),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount:   2,
                shrinkWrap:       true,
                physics:          const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing:  10,
                childAspectRatio: 1.7,
                children: [
                  _StatTile('Gross',
                      formatCurrency(vm.monthlyGrossSalary),
                      Icons.payments_outlined,
                      AppColors.masterBaker),
                  _StatTile(
                      'Deductions',
                      '-${formatCurrency(vm.monthlyTotalDeductions)}',
                      Icons.remove_circle_outline,
                      AppColors.danger),
                  _StatTile('Net Salary',
                      formatCurrency(vm.monthlyTotalSalary),
                      Icons.account_balance_wallet_outlined,
                      const Color(0xFF43A047)),
                  _StatTile('Avg/Week',
                      formatCurrency(vm.monthlyAvgPerWeek),
                      Icons.trending_up_outlined,
                      AppColors.info),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionLabel('WEEKLY BREAKDOWN'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${vm.monthlyWeeks.length} week${vm.monthlyWeeks.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...vm.monthlyWeeks.asMap().entries.map((e) {
                final week  = e.value;
                final color = _weekColors[e.key % _weekColors.length];
                final paid  = paidWeeks.contains(week.weekStart);
                return _WeekExpansionTile(
                  week:      week,
                  index:     e.key,
                  color:     color,
                  paid:      paid,
                  onPreview: () =>
                      _showWeekPreview(week, color, paid),
                );
              }),
              const SizedBox(height: 16),
              _DeductionsSummary(vm: vm),
            ],
          ],
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
          _MBtn(icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        size:  15,
                        color: isCurrentMonth
                            ? AppColors.info
                            : AppColors.textHint),
                    const SizedBox(width: 8),
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize:   14,
                            color: isCurrentMonth
                                ? AppColors.info
                                : AppColors.text,
                            letterSpacing: -0.2)),
                    if (isCurrentMonth) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info,
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
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_drop_down,
                        size: 18, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          ),
          _MBtn(
            icon:     Icons.chevron_right,
            onTap:    onNext,
            disabled: onNext == null,
          ),
        ]),
      );
}

class _MBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  final bool          disabled;
  const _MBtn(
      {required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap:        disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          child: Icon(icon,
              size:  20,
              color: disabled ? AppColors.border : AppColors.info),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _NoMonthRecord extends StatelessWidget {
  final String monthLabel;
  const _NoMonthRecord({required this.monthLabel});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: AppColors.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_outlined,
                size: 36, color: AppColors.info),
          ),
          const SizedBox(height: 14),
          Text('No data for $monthLabel',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize:   15,
                  color:      AppColors.text)),
          const SizedBox(height: 4),
          const Text('No productions were recorded this month',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textHint)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  ALL REMAINING WIDGETS (same as original, cleaned up)
// ─────────────────────────────────────────────────────────────
class _MonthPaymentBar extends StatelessWidget {
  final int paidCount;
  final int totalWeeks;
  const _MonthPaymentBar(
      {required this.paidCount, required this.totalWeeks});

  @override
  Widget build(BuildContext context) {
    final allPaid  = paidCount == totalWeeks && totalWeeks > 0;
    final nonePaid = paidCount == 0;
    final color = allPaid
        ? AppColors.success
        : nonePaid ? Colors.orange : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset:     const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            allPaid
                ? Icons.check_circle_outline
                : Icons.schedule_outlined,
            color: color, size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                allPaid
                    ? 'All weeks paid this month'
                    : nonePaid
                        ? 'No weeks paid yet'
                        : '$paidCount of $totalWeeks weeks paid',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize:   13,
                    color:      color),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:           totalWeeks > 0
                      ? paidCount / totalWeeks
                      : 0,
                  backgroundColor:
                      color.withValues(alpha: 0.15),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(color),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _WeekExpansionTile extends StatelessWidget {
  final WeeklySummary week;
  final int           index;
  final Color         color;
  final bool          paid;
  final VoidCallback  onPreview;

  const _WeekExpansionTile({
    required this.week,
    required this.index,
    required this.color,
    required this.paid,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: paid
              ? Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                  width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset:     const Offset(0, 8),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context)
              .copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('W${index + 1}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color:      color,
                      fontSize:   14)),
            ),
            title: Row(children: [
              Expanded(
                child: Text(week.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:   13),
                    overflow: TextOverflow.ellipsis),
              ),
              _PaidBadge(paid: paid, small: true),
            ]),
            subtitle: Text(
              '${week.daysWorked} days · ${week.totalSacks} sacks',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint),
            ),
            trailing: Text(
              formatCurrency(week.finalSalary),
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize:   16,
                  color:      color),
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: Column(children: [
                  const Divider(color: AppColors.border),
                  _DetailRow('Gross Salary',
                      formatCurrency(week.grossSalary), null),
                  _DetailRow('Oven',
                      '-${formatCurrency(week.ovenDeduction)}',
                      AppColors.danger),
                  _DetailRow('Gas',
                      '-${formatCurrency(week.gasDeduction)}',
                      AppColors.danger),
                  _DetailRow('Vale',
                      '-${formatCurrency(week.vale)}',
                      AppColors.danger),
                  _DetailRow('Wifi',
                      '-${formatCurrency(week.wifi)}',
                      AppColors.danger),
                  const Divider(color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Salary',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text(formatCurrency(week.finalSalary),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize:   16,
                              color:      AppColors.primaryDark)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onPreview,
                      icon:  const Icon(
                          Icons.open_in_new_outlined, size: 15),
                      label: const Text('View Full Detail'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side:  BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                        textStyle: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final String  label;
  final String  value;
  final Color?  valueColor;
  const _DetailRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color:    AppColors.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:   13,
                    color: valueColor ?? AppColors.text)),
          ],
        ),
      );
}

class _PaidBadge extends StatelessWidget {
  final bool paid;
  final bool small;
  const _PaidBadge({required this.paid, this.small = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 6 : 8,
            vertical:   small ? 2 : 4),
        decoration: BoxDecoration(
          color: paid
              ? AppColors.success.withValues(alpha: 0.10)
              : Colors.orange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: paid
                ? AppColors.success.withValues(alpha: 0.2)
                : Colors.orange.withValues(alpha: 0.2),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            paid ? Icons.check_circle : Icons.schedule,
            size:  small ? 9 : 12,
            color: paid ? AppColors.success : Colors.orange,
          ),
          SizedBox(width: small ? 3 : 4),
          Text(
            paid ? 'Paid' : 'Unpaid',
            style: TextStyle(
                fontSize:   small ? 9 : 11,
                fontWeight: FontWeight.w700,
                color: paid ? AppColors.success : Colors.orange),
          ),
        ]),
      );
}

class _PaymentStatusCard extends StatelessWidget {
  final bool paid;
  const _PaymentStatusCard({required this.paid});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: paid
              ? AppColors.success.withValues(alpha: 0.05)
              : Colors.orange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: paid
                ? AppColors.success.withValues(alpha: 0.15)
                : Colors.orange.withValues(alpha: 0.15),
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: paid
                  ? AppColors.success.withValues(alpha: 0.10)
                  : Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              paid
                  ? Icons.check_circle_outline
                  : Icons.schedule_outlined,
              color: paid ? AppColors.success : Colors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paid ? 'Salary Paid' : 'Pending Payment',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize:   14,
                      color: paid ? AppColors.success : Colors.orange),
                ),
                const SizedBox(height: 2),
                Text(
                  paid
                      ? 'Your salary for this week has been released by admin.'
                      : 'Your salary for this week is pending admin approval.',
                  style: TextStyle(
                      fontSize: 11,
                      color:    paid
                          ? AppColors.success.withValues(alpha: 0.8)
                          : Colors.orange.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ]),
      );
}

class _EarningsBanner extends StatelessWidget {
  final HelperSalaryViewModel vm;
  const _EarningsBanner({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A00), Color(0xFFFFA03A)],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color:      const Color(0xFFFF7A00).withValues(alpha: 0.3),
              blurRadius: 16,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('TOTAL MONTHLY EARNINGS',
                style: TextStyle(
                    color:         Colors.white70,
                    fontSize:      11,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 1.2)),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                formatCurrency(vm.monthlyTotalSalary),
                style: const TextStyle(
                    color:         Colors.white,
                    fontSize:      36,
                    fontWeight:    FontWeight.w900,
                    letterSpacing: -1),
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
              _BannerChip(Icons.work_history_outlined,
                  '${vm.monthlyTotalDays} days'),
              const SizedBox(width: 16),
              _BannerChip(Icons.inventory_2_outlined,
                  '${vm.monthlyTotalSacks} sacks'),
              const SizedBox(width: 16),
              _BannerChip(Icons.calendar_view_week_outlined,
                  '${vm.monthlyWeeks.length} weeks'),
            ]),
          ],
        ),
      );
}

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _BannerChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12)),
      ]);
}

class _StatTile extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  const _StatTile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset:     const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit:       BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w800,
                      color:      color)),
            ),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      );
}

class _DeductionsSummary extends StatelessWidget {
  final HelperSalaryViewModel vm;
  const _DeductionsSummary({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset:     const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('MONTHLY DEDUCTIONS TOTAL'),
            const SizedBox(height: 14),
            _DedRow('Oven',  vm.monthlyOvenTotal),
            _DedRow('Gas',   vm.monthlyGasTotal),
            _DedRow('Vale',  vm.monthlyValeTotal),
            _DedRow('Wifi',  vm.monthlyWifiTotal),
            const Divider(height: 24, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Deductions',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:   14)),
                Text(
                  '-${formatCurrency(vm.monthlyTotalDeductions)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize:   16,
                      color:      AppColors.danger),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monthly Gross',
                    style: TextStyle(
                        fontSize: 13,
                        color:    AppColors.textSecondary)),
                Text(formatCurrency(vm.monthlyGrossSalary),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:   13,
                        color:      AppColors.masterBaker)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFFA03A)],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:      const Color(0xFFFF7A00)
                        .withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset:     const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Take-Home',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize:   14,
                          color:      Colors.white)),
                  Text(
                    formatCurrency(vm.monthlyTotalSalary),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize:   20,
                        color:      Colors.white,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DedRow extends StatelessWidget {
  final String label;
  final double value;
  const _DedRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color:    AppColors.textSecondary)),
            Text(
              value > 0 ? '-${formatCurrency(value)}' : '—',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: value > 0
                      ? AppColors.danger
                      : AppColors.textHint),
            ),
          ],
        ),
      );
}

class _DeductionRow extends StatelessWidget {
  final String label;
  final double value;
  const _DeductionRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color:    AppColors.textSecondary)),
            Text(
              value > 0 ? '-${formatCurrency(value)}' : '—',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: value > 0
                      ? AppColors.danger
                      : AppColors.textHint),
            ),
          ],
        ),
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
              color: AppColors.info,
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

class _SheetCard extends StatelessWidget {
  final List<Widget> children;
  final Color        color;
  const _SheetCard({required this.children, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: color.withValues(alpha: 0.12)),
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
  final Color  color;
  const _SheetLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w800,
                color:      color.withValues(alpha: 0.7),
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textHint))),
          Text(value,
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.text)),
        ]),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.info, strokeWidth: 2.5),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:        AppColors.danger.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(
              color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          const Icon(Icons.cloud_off_outlined,
              size: 36, color: AppColors.danger),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.danger, fontSize: 13)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon:  const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ]),
      );
}