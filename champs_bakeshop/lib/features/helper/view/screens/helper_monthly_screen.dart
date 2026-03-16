import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/helper_salary_viewmodel.dart';

class HelperMonthlyScreen extends StatefulWidget {
  const HelperMonthlyScreen({super.key});

  @override
  State<HelperMonthlyScreen> createState() => _HelperMonthlyScreenState();
}

class _HelperMonthlyScreenState extends State<HelperMonthlyScreen> {
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  static const _weekColors = [
    AppColors.info,
    AppColors.primary,
    AppColors.masterBaker,
    Color(0xFF8E44AD),
  ];

  String get _userId =>
      context.read<AuthViewModel>().currentUser!.id;

  void _load() {
    final vm = context.read<HelperSalaryViewModel>();
    vm.loadMonthlySummary(_userId,
        year: _selectedMonth.year, month: _selectedMonth.month);
    vm.loadPaidWeeks(_userId); // ✅ load paid status
  }

  void _changeMonth(int direction) {
    setState(() {
      _selectedMonth = DateTime(
          _selectedMonth.year, _selectedMonth.month + direction);
    });
    _load();
  }

  Future<void> _pickMonth() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:          context,
      initialDate:      _selectedMonth,
      firstDate:        DateTime(now.year - 3),
      lastDate:         DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText:         'SELECT MONTH',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.info),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(
        () => _selectedMonth = DateTime(picked.year, picked.month));
    _load();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  // ── Week preview sheet ───────────────────────────────────────
  void _showWeekPreview(
      WeeklySummary week, Color color, bool paid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize:     0.5,
        maxChildSize:     0.92,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F7F8),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: color.withValues(alpha: 0.1),
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
                          color: AppColors.textHint),
                    ),
                  ]),
                ),
                // Paid/Unpaid badge
                _PaidBadge(paid: paid),
              ]),
            ),

            const Divider(height: 20),

            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Week overview ──────────────────────
                  _PreviewCard(color: color, children: [
                    _PreviewLabel('WEEK OVERVIEW', color),
                    const SizedBox(height: 12),
                    _PreviewRow(
                      icon:  Icons.work_history_outlined,
                      label: 'Days Worked',
                      value: '${week.daysWorked} days',
                    ),
                    _PreviewRow(
                      icon:  Icons.inventory_2_outlined,
                      label: 'Total Sacks',
                      value: '${week.totalSacks} sacks',
                    ),
                    _PreviewRow(
                      icon:  Icons.payments_outlined,
                      label: 'Gross Salary',
                      value: formatCurrency(week.grossSalary),
                      valueColor: AppColors.masterBaker,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── Deductions ─────────────────────────
                  _PreviewCard(color: AppColors.danger, children: [
                    _PreviewLabel(
                        'DEDUCTIONS BREAKDOWN', AppColors.danger),
                    const SizedBox(height: 12),
                    _DeductionRow(
                        'Oven',
                        week.ovenDeduction),
                    _DeductionRow('Gas',  week.gasDeduction),
                    _DeductionRow('Vale', week.vale),
                    _DeductionRow('Wifi', week.wifi),
                    const Divider(height: 20),
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
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
                    ]),
                  ]),
                  const SizedBox(height: 12),

                  // ── Net salary ─────────────────────────
                  _PreviewCard(color: AppColors.primaryDark,
                      children: [
                    _PreviewLabel(
                        'NET SALARY', AppColors.primaryDark),
                    const SizedBox(height: 12),
                    _PreviewRow(
                      icon:  Icons.calculate_outlined,
                      label: 'Gross',
                      value: formatCurrency(week.grossSalary),
                      valueColor: AppColors.masterBaker,
                    ),
                    _PreviewRow(
                      icon:  Icons.remove_circle_outline,
                      label: 'Total Deductions',
                      value:
                          '-${formatCurrency(week.totalDeductions)}',
                      valueColor: AppColors.danger,
                    ),
                    const Divider(height: 20),
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
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
                            color: AppColors.primaryDark),
                      ),
                    ]),
                  ]),
                  const SizedBox(height: 12),

                  // ── Payment status ─────────────────────
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
    final vm         = context.watch<HelperSalaryViewModel>();
    final monthLabel =
        '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';
    final paidWeeks  = vm.paidWeekStarts;

    // Count paid weeks this month
    final paidCount = vm.monthlyWeeks
        .where((w) => paidWeeks.contains(w.weekStart))
        .length;

    return RefreshIndicator(
      color:     AppColors.info,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title:    'Monthly Summary',
              subtitle: '4-week earnings overview',
            ),

            _MonthSelector(
              label:  monthLabel,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onTap:  _pickMonth,
            ),
            const SizedBox(height: 16),

            if (vm.isLoading)
              const _LoadingCard()
            else if (vm.error != null)
              _ErrorCard(message: vm.error!, onRetry: _load)
            else ...[

              // ── Hero earnings banner ───────────────────
              _EarningsBanner(vm: vm),
              const SizedBox(height: 14),

              // ✅ Month payment summary bar
              if (vm.monthlyWeeks.isNotEmpty)
                _MonthPaymentBar(
                    paidCount:  paidCount,
                    totalWeeks: vm.monthlyWeeks.length),
              const SizedBox(height: 14),

              // ── 2×2 stat grid ──────────────────────────
              GridView.count(
                crossAxisCount:   2,
                shrinkWrap:       true,
                physics:
                    const NeverScrollableScrollPhysics(),
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
              const SizedBox(height: 16),

              // ── Weekly breakdown ───────────────────────
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel('WEEKLY BREAKDOWN'),
                  if (vm.monthlyWeeks.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.info
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(20),
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
              const SizedBox(height: 8),

              if (vm.monthlyWeeks.isEmpty)
                EmptyState(
                  icon: Icons.calendar_month_outlined,
                  message:
                      'No data for ${_monthNames[_selectedMonth.month - 1]}',
                )
              else
                ...vm.monthlyWeeks.asMap().entries.map((e) {
                  final week  = e.value;
                  final color =
                      _weekColors[e.key % _weekColors.length];
                  final paid  =
                      paidWeeks.contains(week.weekStart);
                  return _WeekExpansionTile(
                    week:  week,
                    index: e.key,
                    color: color,
                    paid:  paid,
                    onPreview: () =>
                        _showWeekPreview(week, color, paid),
                  );
                }),
              const SizedBox(height: 16),

              // ── Monthly deductions summary ─────────────
              _DeductionsSummary(vm: vm),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MONTH PAYMENT BAR  ← NEW
// ─────────────────────────────────────────────────────────────
class _MonthPaymentBar extends StatelessWidget {
  final int paidCount;
  final int totalWeeks;
  const _MonthPaymentBar(
      {required this.paidCount, required this.totalWeeks});

  @override
  Widget build(BuildContext context) {
    final allPaid   = paidCount == totalWeeks && totalWeeks > 0;
    final nonePaid  = paidCount == 0;
    final color     = allPaid
        ? AppColors.success
        : nonePaid
            ? Colors.orange
            : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
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
                  fontSize: 13,
                  color: color),
            ),
            const SizedBox(height: 3),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalWeeks > 0
                    ? paidCount / totalWeeks
                    : 0,
                backgroundColor:
                    color.withValues(alpha: 0.15),
                valueColor:
                    AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WEEK EXPANSION TILE  ← updated with paid badge + preview
// ─────────────────────────────────────────────────────────────
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: paid
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border,
            width: paid ? 1.5 : 1,
          ),
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
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('W${index + 1}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontSize: 14)),
            ),
            title: Row(children: [
              Expanded(
                child: Text(week.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
              // ✅ Paid badge in title row
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
                  fontSize: 16,
                  color: color),
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: Column(children: [
                  const Divider(),
                  _DetailRow('Gross Salary',
                      formatCurrency(week.grossSalary), null),
                  _DetailRow(
                      'Oven',
                      '-${formatCurrency(week.ovenDeduction)}',
                      AppColors.danger),
                  _DetailRow(
                      'Gas',
                      '-${formatCurrency(week.gasDeduction)}',
                      AppColors.danger),
                  _DetailRow('Vale',
                      '-${formatCurrency(week.vale)}',
                      AppColors.danger),
                  _DetailRow('Wifi',
                      '-${formatCurrency(week.wifi)}',
                      AppColors.danger),
                  const Divider(),
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                    const Text('Net Salary',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text(formatCurrency(week.finalSalary),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.primaryDark)),
                  ]),
                  const SizedBox(height: 10),
                  // ✅ View Details button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onPreview,
                      icon: const Icon(
                          Icons.open_in_new_outlined,
                          size: 15),
                      label: const Text('View Full Detail'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 12,
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
                  color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                  color: valueColor ?? AppColors.text)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  PAID BADGE  ← NEW reusable
// ─────────────────────────────────────────────────────────────
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
              ? AppColors.success.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: paid
                ? AppColors.success.withValues(alpha: 0.25)
                : Colors.orange.withValues(alpha: 0.25),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            paid ? Icons.check_circle : Icons.schedule,
            size: small ? 9 : 12,
            color: paid ? AppColors.success : Colors.orange,
          ),
          SizedBox(width: small ? 3 : 4),
          Text(
            paid ? 'Paid' : 'Unpaid',
            style: TextStyle(
                fontSize:   small ? 9 : 11,
                fontWeight: FontWeight.w700,
                color:
                    paid ? AppColors.success : Colors.orange),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  PAYMENT STATUS CARD  ← used in preview sheet
// ─────────────────────────────────────────────────────────────
class _PaymentStatusCard extends StatelessWidget {
  final bool paid;
  const _PaymentStatusCard({required this.paid});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: paid
              ? AppColors.success.withValues(alpha: 0.06)
              : Colors.orange.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: paid
                ? AppColors.success.withValues(alpha: 0.2)
                : Colors.orange.withValues(alpha: 0.2),
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: paid
                  ? AppColors.success.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
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
                    fontSize: 14,
                    color:
                        paid ? AppColors.success : Colors.orange),
              ),
              const SizedBox(height: 2),
              Text(
                paid
                    ? 'Your salary for this week has been released by admin.'
                    : 'Your salary for this week is pending admin approval.',
                style: TextStyle(
                    fontSize: 11,
                    color: paid
                        ? AppColors.success
                            .withValues(alpha: 0.8)
                        : Colors.orange.withValues(alpha: 0.8)),
              ),
            ]),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  PREVIEW SHEET SUB-WIDGETS
// ─────────────────────────────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  final List<Widget> children;
  final Color        color;
  const _PreviewCard(
      {required this.children, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withValues(alpha: 0.15)),
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

class _PreviewLabel extends StatelessWidget {
  final String text;
  final Color  color;
  const _PreviewLabel(this.text, this.color);

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
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color.withValues(alpha: 0.7),
                letterSpacing: 0.8)),
      ]);
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  const _PreviewRow({
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
                      fontSize: 13,
                      color: AppColors.textHint))),
          Text(value,
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.text)),
        ]),
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
                  color: AppColors.textSecondary)),
          Text(
            value > 0 ? '-${formatCurrency(value)}' : '—',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value > 0
                    ? AppColors.danger
                    : AppColors.textHint),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  EARNINGS BANNER
// ─────────────────────────────────────────────────────────────
class _EarningsBanner extends StatelessWidget {
  final HelperSalaryViewModel vm;
  const _EarningsBanner({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.primaryLight
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
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
                    color:      Colors.white,
                    fontSize:   36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1),
              ),
            ),
            const SizedBox(height: 12),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              _BannerChip(
                  icon:  Icons.work_history_outlined,
                  label: '${vm.monthlyTotalDays} days'),
              const SizedBox(width: 16),
              _BannerChip(
                  icon:  Icons.inventory_2_outlined,
                  label: '${vm.monthlyTotalSacks} sacks'),
              const SizedBox(width: 16),
              _BannerChip(
                  icon:  Icons.calendar_view_week_outlined,
                  label: '${vm.monthlyWeeks.length} weeks'),
            ]),
          ],
        ),
      );
}

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _BannerChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12)),
      ]);
}

// ─────────────────────────────────────────────────────────────
//  STAT TILE
// ─────────────────────────────────────────────────────────────
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
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

// ─────────────────────────────────────────────────────────────
//  MONTHLY DEDUCTIONS SUMMARY
// ─────────────────────────────────────────────────────────────
class _DeductionsSummary extends StatelessWidget {
  final HelperSalaryViewModel vm;
  const _DeductionsSummary({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('MONTHLY DEDUCTIONS TOTAL'),
            const SizedBox(height: 14),
            _DedRow('Oven',  vm.monthlyOvenTotal),
            _DedRow('Gas',   vm.monthlyGasTotal),
            _DedRow('Vale',  vm.monthlyValeTotal),
            _DedRow('Wifi',  vm.monthlyWifiTotal),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Deductions',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(
                  '-${formatCurrency(vm.monthlyTotalDeductions)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize:   16,
                      color:      AppColors.danger),
                ),
              ],
            ),
            const Divider(height: 24),
            // ✅ Monthly net summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monthly Gross',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary)),
                Text(formatCurrency(vm.monthlyGrossSalary),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.masterBaker)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark
                    .withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primaryDark
                        .withValues(alpha: 0.12)),
              ),
              child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                const Text('Monthly Take-Home',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(
                  formatCurrency(vm.monthlyTotalSalary),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize:   20,
                      color:      AppColors.primaryDark),
                ),
              ]),
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
                  color: AppColors.textSecondary)),
          Text(
            value > 0 ? '-${formatCurrency(value)}' : '—',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value > 0
                    ? AppColors.danger
                    : AppColors.textHint),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  SHARED HELPERS
// ─────────────────────────────────────────────────────────────
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
          border: Border.all(
              color: AppColors.info.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          IconButton(
              icon:      const Icon(Icons.chevron_left),
              color:     AppColors.info,
              onPressed: onPrev),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize:   15,
                          color:      AppColors.info)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down,
                      size: 18, color: AppColors.info),
                ],
              ),
            ),
          ),
          IconButton(
              icon:      const Icon(Icons.chevron_right),
              color:     AppColors.info,
              onPressed: onNext),
        ]),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize:      11,
          fontWeight:    FontWeight.w800,
          color:         AppColors.textHint,
          letterSpacing: 0.8));
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.info, strokeWidth: 2.5)),
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
          color: AppColors.danger.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
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