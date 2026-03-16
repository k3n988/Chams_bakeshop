import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/helper_salary_viewmodel.dart';

class HelperWeeklyScreen extends StatefulWidget {
  const HelperWeeklyScreen({super.key});

  @override
  State<HelperWeeklyScreen> createState() => _HelperWeeklyScreenState();
}

class _HelperWeeklyScreenState extends State<HelperWeeklyScreen> {
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  String get _userId =>
      context.read<AuthViewModel>().currentUser!.id;

  void _loadForMonth() {
    final vm = context.read<HelperSalaryViewModel>();
    vm.loadWeeklySalaryForMonth(
        _userId, _selectedMonth.year, _selectedMonth.month);
    vm.loadPaidWeeks(_userId); // ✅ load paid status
  }

  void _changeMonth(int direction) {
    setState(() {
      _selectedMonth = DateTime(
          _selectedMonth.year, _selectedMonth.month + direction);
    });
    _loadForMonth();
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
    _loadForMonth();
  }

  void _changeWeek(int dir) {
    final vm = context.read<HelperSalaryViewModel>();
    vm.changeWeek(dir, _userId);
    vm.loadPaidWeeks(_userId);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadForMonth());
  }

  // ── Paid check ───────────────────────────────────────────────
  bool _isWeekPaid(HelperSalaryViewModel vm) {
    if (vm.weekStart.isEmpty) return false;
    return vm.paidWeekStarts.contains(vm.weekStart);
  }

  // ── Preview sheet ────────────────────────────────────────────
  void _showDayPreview(
      String date, double salary, bool weekPaid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize:     0.4,
        maxChildSize:     0.85,
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
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.today_outlined,
                      color: AppColors.info, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(date,
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
                // ✅ Paid / Unpaid badge
                _StatusBadge(paid: weekPaid),
              ]),
            ),

            const Divider(height: 20),

            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Salary breakdown ───────────────────
                  _PreviewCard(children: [
                    _PreviewLabel('YOUR SALARY'),
                    const SizedBox(height: 12),
                    _PreviewRow(
                      icon:  Icons.calculate_outlined,
                      label: 'Per Worker (base)',
                      value: formatCurrency(salary),
                      valueColor: AppColors.info,
                    ),
                    const Divider(height: 20),
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                      const Text('Earnings This Day',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      Text(formatCurrency(salary),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: AppColors.primaryDark)),
                    ]),
                  ]),
                  const SizedBox(height: 12),

                  // ── Payment status ─────────────────────
                  _PaymentStatusCard(paid: weekPaid),
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
    final weekPaid   = _isWeekPaid(vm);

    return RefreshIndicator(
      color:     AppColors.info,
      onRefresh: () async => _loadForMonth(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title:    'Weekly Salary',
              subtitle: 'Summary for your selected week',
            ),

            _MonthSelector(
              label:  monthLabel,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onTap:  _pickMonth,
            ),
            const SizedBox(height: 10),

            WeekSelector(
              weekStart: vm.weekStart,
              weekEnd:   vm.weekEnd,
              onPrev:    () => _changeWeek(-1),
              onNext:    () => _changeWeek(1),
            ),
            const SizedBox(height: 14),

            if (vm.isLoading)
              const _LoadingCard()
            else if (vm.error != null)
              _ErrorCard(message: vm.error!, onRetry: _loadForMonth)
            else ...[

              // ✅ Week paid/unpaid banner
              _WeekStatusBanner(paid: weekPaid),
              const SizedBox(height: 14),

              // ── Stats row ──────────────────────────────
              Row(children: [
                Expanded(
                    child: _StatTile(
                  icon:  Icons.payments_outlined,
                  label: 'Gross',
                  value: formatCurrency(vm.grossSalary),
                  color: AppColors.masterBaker,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatTile(
                  icon:  Icons.calendar_today_outlined,
                  label: 'Days',
                  value: '${vm.daysWorked}',
                  color: AppColors.info,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatTile(
                  icon:  Icons.account_balance_wallet_outlined,
                  label: 'Net',
                  value: formatCurrency(vm.finalSalary),
                  color: AppColors.primary,
                )),
              ]),
              const SizedBox(height: 14),

              // ── Deductions card ────────────────────────
              _DeductionsCard(vm: vm),
              const SizedBox(height: 14),

              // ── Daily transactions ─────────────────────
              if (vm.weeklyDaily.isNotEmpty) ...[
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionLabel('DAILY TRANSACTIONS'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.info
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${vm.weeklyDaily.length} record${vm.weeklyDaily.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.info),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ✅ Weekly total row
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary
                            .withValues(alpha: 0.15)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.summarize_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                        child: Text('Week Total (Gross)',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary))),
                    Text(
                      formatCurrency(vm.grossSalary),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.primaryDark),
                    ),
                  ]),
                ),

                // ✅ Each daily transaction — tappable
                ...vm.weeklyDaily.map((d) =>
                    _DailyTransactionTile(
                      date:     d.key,
                      salary:   d.value,
                      weekPaid: weekPaid,
                      onTap: () =>
                          _showDayPreview(d.key, d.value, weekPaid),
                    )),
              ] else
                EmptyState(
                  icon:    Icons.today_outlined,
                  message: 'No records for this week',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WEEK STATUS BANNER  ← NEW
// ─────────────────────────────────────────────────────────────
class _WeekStatusBanner extends StatelessWidget {
  final bool paid;
  const _WeekStatusBanner({required this.paid});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: paid
              ? AppColors.success.withValues(alpha: 0.07)
              : Colors.orange.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: paid
                ? AppColors.success.withValues(alpha: 0.25)
                : Colors.orange.withValues(alpha: 0.25),
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: paid
                  ? AppColors.success.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              paid
                  ? Icons.check_circle_outline
                  : Icons.schedule_outlined,
              color: paid ? AppColors.success : Colors.orange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                paid
                    ? 'Week Salary Released'
                    : 'Week Salary Pending',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: paid
                        ? AppColors.success
                        : Colors.orange),
              ),
              const SizedBox(height: 2),
              Text(
                paid
                    ? 'Admin has released your salary for this week.'
                    : 'Your salary for this week is pending admin approval.',
                style: TextStyle(
                    fontSize: 11,
                    color: paid
                        ? AppColors.success.withValues(alpha: 0.8)
                        : Colors.orange.withValues(alpha: 0.8)),
              ),
            ]),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  DAILY TRANSACTION TILE  ← NEW (replaces _DailyBreakdownTile)
// ─────────────────────────────────────────────────────────────
class _DailyTransactionTile extends StatelessWidget {
  final String date;
  final double salary;
  final bool   weekPaid;
  final VoidCallback onTap;

  const _DailyTransactionTile({
    required this.date,
    required this.salary,
    required this.weekPaid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: weekPaid
                  ? AppColors.success.withValues(alpha: 0.25)
                  : AppColors.border,
              width: weekPaid ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.today_outlined,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(date,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.text)),
                const SizedBox(height: 2),
                Row(children: [
                  // ✅ Paid badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: weekPaid
                          ? AppColors.success
                              .withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: weekPaid
                            ? AppColors.success
                                .withValues(alpha: 0.25)
                            : Colors.orange
                                .withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Icon(
                        weekPaid
                            ? Icons.check_circle
                            : Icons.schedule,
                        size: 9,
                        color: weekPaid
                            ? AppColors.success
                            : Colors.orange,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        weekPaid ? 'Paid' : 'Unpaid',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: weekPaid
                                ? AppColors.success
                                : Colors.orange),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 6),
                  Text('Tap to view details',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.info
                              .withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic)),
                ]),
              ]),
            ),

            Column(crossAxisAlignment: CrossAxisAlignment.end,
                children: [
              Text(formatCurrency(salary),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.primaryDark)),
              const SizedBox(height: 2),
              Icon(Icons.chevron_right,
                  size: 16,
                  color: AppColors.info.withValues(alpha: 0.5)),
            ]),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  STATUS BADGE (used in preview sheet header)
// ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool paid;
  const _StatusBadge({required this.paid});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: paid
              ? AppColors.success.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: paid
                ? AppColors.success.withValues(alpha: 0.3)
                : Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            paid ? Icons.check_circle : Icons.schedule,
            size: 14,
            color: paid ? AppColors.success : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            paid ? 'Paid' : 'Unpaid',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: paid ? AppColors.success : Colors.orange),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  PAYMENT STATUS CARD (used in preview sheet)
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
                    color: paid
                        ? AppColors.success
                        : Colors.orange),
              ),
              const SizedBox(height: 2),
              Text(
                paid
                    ? 'Your salary for this week has been released by admin.'
                    : 'Your salary for this week is pending admin approval.',
                style: TextStyle(
                    fontSize: 11,
                    color: paid
                        ? AppColors.success.withValues(alpha: 0.8)
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
  const _PreviewCard({required this.children});

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

class _PreviewLabel extends StatelessWidget {
  final String text;
  const _PreviewLabel(this.text);

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
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
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

// ─────────────────────────────────────────────────────────────
//  STAT TILE
// ─────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
                color:      color.withValues(alpha: 0.06),
                blurRadius: 8,
                offset:     const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit:       BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize:   16,
                      color:      color)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  DEDUCTIONS CARD
// ─────────────────────────────────────────────────────────────
class _DeductionsCard extends StatelessWidget {
  final HelperSalaryViewModel vm;
  const _DeductionsCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset:     const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('DEDUCTIONS BREAKDOWN'),
            const SizedBox(height: 14),
            _DedRow(
              label: 'Oven  (₱${AppConstants.helperOvenDeductionPerDay.toStringAsFixed(0)}/day × ${vm.daysWorked}d)',
              value: vm.ovenDeduction,
            ),
            _DedRow(label: 'Gas',  value: vm.gasDeduction),
            _DedRow(label: 'Vale', value: vm.valeDeduction),
            _DedRow(label: 'Wifi', value: vm.wifiDeduction),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('TAKE-HOME PAY',
                      style: TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.w800,
                          color:      AppColors.textHint,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text(formatCurrency(vm.finalSalary),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize:   26,
                          color:      AppColors.primaryDark)),
                ]),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                  _NetChip(
                      label: 'Gross',
                      value: formatCurrency(vm.grossSalary),
                      color: AppColors.masterBaker),
                  const SizedBox(height: 4),
                  _NetChip(
                      label: 'Deductions',
                      value:
                          '-${formatCurrency(vm.totalDeductions)}',
                      color: AppColors.danger),
                ]),
              ],
            ),
          ],
        ),
      );
}

class _DedRow extends StatelessWidget {
  final String label;
  final double value;
  const _DedRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Flexible(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary))),
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

class _NetChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _NetChip(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontFamily: 'Roboto'),
            children: [
              TextSpan(
                  text:  '$label: ',
                  style: TextStyle(fontSize: 11, color: color)),
              TextSpan(
                  text:  value,
                  style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w800,
                      color:      color)),
            ],
          ),
        ),
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
          color:        Colors.white,
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