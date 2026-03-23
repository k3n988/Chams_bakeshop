import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';

import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/helper_salary_viewmodel.dart';

class HelperWeeklyScreen extends StatefulWidget {
  const HelperWeeklyScreen({super.key});

  @override
  State<HelperWeeklyScreen> createState() => _HelperWeeklyScreenState();
}

class _HelperWeeklyScreenState extends State<HelperWeeklyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentWeek());
  }

  String get _userId =>
      context.read<AuthViewModel>().currentUser!.id;

  bool get _isCurrentWeek {
    final vm = context.read<HelperSalaryViewModel>();
    return vm.weekStart == getWeekStart(DateTime.now());
  }

  void _loadCurrentWeek() {
    final vm = context.read<HelperSalaryViewModel>();
    vm.loadWeeklySalary(_userId);
    vm.loadPaidWeeks(_userId);
  }

  void _changeWeek(int dir) {
    final vm = context.read<HelperSalaryViewModel>();
    vm.changeWeek(dir, _userId);
    vm.loadPaidWeeks(_userId);
  }

  void _goToCurrentWeek() {
    final vm = context.read<HelperSalaryViewModel>();
    // Reset to current week
    final currentWeekStart = getWeekStart(DateTime.now());
    if (vm.weekStart == currentWeekStart) return;
    final diff = DateTime.parse(currentWeekStart)
            .difference(DateTime.parse(vm.weekStart))
            .inDays ~/
        7;
    for (var i = 0; i < diff.abs(); i++) {
      vm.changeWeek(diff > 0 ? 1 : -1, _userId);
    }
    vm.loadPaidWeeks(_userId);
  }

  bool _isWeekPaid(HelperSalaryViewModel vm) {
    if (vm.weekStart.isEmpty) return false;
    return vm.paidWeekStarts.contains(vm.weekStart);
  }

  void _showDayPreview(String date, double salary, bool weekPaid) {
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
            color:        Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: AppColors.info.withValues(alpha: 0.10),
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
                    ],
                  ),
                ),
                _StatusBadge(paid: weekPaid),
              ]),
            ),
            const Divider(height: 20, color: AppColors.border),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _SheetCard(children: [
                    const _SheetLabel('YOUR SALARY'),
                    const SizedBox(height: 12),
                    _SheetRow(
                      icon:       Icons.calculate_outlined,
                      label:      'Per Worker (base)',
                      value:      formatCurrency(salary),
                      valueColor: AppColors.info,
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Earnings This Day',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.text)),
                        Text(formatCurrency(salary),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                color: AppColors.primaryDark,
                                letterSpacing: -0.5)),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 12),
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
    final vm       = context.watch<HelperSalaryViewModel>();
    final weekPaid = _isWeekPaid(vm);
    final isThisWeek = _isCurrentWeek;

    return RefreshIndicator(
      color:     AppColors.info,
      onRefresh: () async => _loadCurrentWeek(),
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
                    Text('Weekly Salary',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                            letterSpacing: -0.5)),
                    SizedBox(height: 2),
                    Text('Summary for your selected week',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ],
                ),
                if (!isThisWeek)
                  GestureDetector(
                    onTap: _goToCurrentWeek,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today_outlined,
                                size: 13, color: AppColors.info),
                            SizedBox(width: 5),
                            Text('This Week',
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

            // ── Week navigator ───────────────────────────
            _WeekNavigator(
              weekStart:     vm.weekStart,
              weekEnd:       vm.weekEnd,
              isCurrentWeek: isThisWeek,
              onPrev:        () => _changeWeek(-1),
              onNext:        isThisWeek ? null : () => _changeWeek(1),
            ),
            const SizedBox(height: 16),

            // ── Content ──────────────────────────────────
            if (vm.isLoading)
              const _LoadingCard()
            else if (vm.error != null)
              _ErrorCard(message: vm.error!, onRetry: _loadCurrentWeek)
            else ...[
              _WeekStatusBanner(paid: weekPaid),
              const SizedBox(height: 14),

              // Stats row
              Row(children: [
                Expanded(child: _StatTile(
                  icon:  Icons.payments_outlined,
                  label: 'Gross',
                  value: formatCurrency(vm.grossSalary),
                  color: AppColors.masterBaker,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(
                  icon:  Icons.calendar_today_outlined,
                  label: 'Days',
                  value: '${vm.daysWorked}',
                  color: AppColors.info,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(
                  icon:  Icons.account_balance_wallet_outlined,
                  label: 'Net',
                  value: formatCurrency(vm.finalSalary),
                  color: AppColors.primary,
                )),
              ]),
              const SizedBox(height: 14),

              _DeductionsCard(vm: vm),
              const SizedBox(height: 16),

              // Daily transactions
              if (vm.weeklyDaily.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionLabel('DAILY TRANSACTIONS'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.10),
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
                const SizedBox(height: 10),

                // Week total pill
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15)),
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
                              color: AppColors.primary)),
                    ),
                    Text(
                      formatCurrency(vm.grossSalary),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.primaryDark),
                    ),
                  ]),
                ),

                ...vm.weeklyDaily.asMap().entries.map((e) =>
                    _DailyTransactionTile(
                      date:     e.value.key,
                      salary:   e.value.value,
                      index:    e.key,
                      weekPaid: weekPaid,
                      onTap:    () => _showDayPreview(
                          e.value.key, e.value.value, weekPaid),
                    )),
              ] else
                const _EmptyWeek(),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WEEK NAVIGATOR
// ─────────────────────────────────────────────────────────────
class _WeekNavigator extends StatelessWidget {
  final String       weekStart;
  final String       weekEnd;
  final bool         isCurrentWeek;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _WeekNavigator({
    required this.weekStart,
    required this.weekEnd,
    required this.isCurrentWeek,
    required this.onPrev,
    required this.onNext,
  });

  String _fmt(String dateStr) {
    if (dateStr.isEmpty) return '—';
    try {
      final d = DateTime.parse(dateStr);
      const m = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${m[d.month - 1]} ${d.day}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = weekStart.isEmpty
        ? '—'
        : '${_fmt(weekStart)} – ${_fmt(weekEnd)}';

    return Container(
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
        _WkBtn(icon: Icons.chevron_left, onTap: onPrev),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.date_range_outlined,
                    size: 15,
                    color: isCurrentWeek
                        ? AppColors.info
                        : AppColors.textHint),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize:   13,
                        color: isCurrentWeek
                            ? AppColors.info
                            : AppColors.primaryDark,
                        letterSpacing: -0.2)),
                if (isCurrentWeek) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.info,
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
              ],
            ),
          ),
        ),
        _WkBtn(
          icon:     Icons.chevron_right,
          onTap:    onNext,
          disabled: onNext == null,
        ),
      ]),
    );
  }
}

class _WkBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  final bool          disabled;
  const _WkBtn(
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
//  WEEK STATUS BANNER
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
                  ? AppColors.success.withValues(alpha: 0.10)
                  : Colors.orange.withValues(alpha: 0.10),
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
                  paid ? 'Week Salary Released' : 'Week Salary Pending',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize:   13,
                      color: paid ? AppColors.success : Colors.orange),
                ),
                const SizedBox(height: 2),
                Text(
                  paid
                      ? 'Admin has released your salary for this week.'
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

// ─────────────────────────────────────────────────────────────
//  DAILY TRANSACTION TILE
// ─────────────────────────────────────────────────────────────
class _DailyTransactionTile extends StatelessWidget {
  final String       date;
  final double       salary;
  final int          index;
  final bool         weekPaid;
  final VoidCallback onTap;

  const _DailyTransactionTile({
    required this.date,
    required this.salary,
    required this.index,
    required this.weekPaid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween:    Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 50),
      curve:    Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset:     const Offset(0, 2)),
            ],
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.today_outlined,
                      color: AppColors.primary, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize:   14,
                              color:      AppColors.text,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 3),
                      Text('Base salary',
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColors.textHint)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatCurrency(salary),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize:   15,
                            color:      AppColors.primaryDark,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 5),
                    _PaidBadge(paid: weekPaid),
                  ],
                ),
              ]),
            ),
            // Footer strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
                border: Border(
                    top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View breakdown',
                      style: TextStyle(
                          fontSize:   11,
                          color: AppColors.info.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 3),
                  Icon(Icons.keyboard_arrow_down,
                      size:  14,
                      color: AppColors.info.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _EmptyWeek extends StatelessWidget {
  const _EmptyWeek();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.today_outlined,
                size: 36, color: AppColors.info),
          ),
          const SizedBox(height: 14),
          const Text('No records for this week',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize:   15,
                  color:      AppColors.text)),
          const SizedBox(height: 4),
          const Text('No productions were recorded this week',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textHint)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────
class _PaidBadge extends StatelessWidget {
  final bool paid;
  const _PaidBadge({required this.paid});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: paid
              ? AppColors.success.withValues(alpha: 0.10)
              : Colors.orange.withValues(alpha: 0.10),
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
            size:  10,
            color: paid ? AppColors.success : Colors.orange,
          ),
          const SizedBox(width: 3),
          Text(
            paid ? 'Paid' : 'Unpaid',
            style: TextStyle(
                fontSize:   10,
                fontWeight: FontWeight.w700,
                color: paid ? AppColors.success : Colors.orange),
          ),
        ]),
      );
}

class _StatusBadge extends StatelessWidget {
  final bool paid;
  const _StatusBadge({required this.paid});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: paid
              ? AppColors.success.withValues(alpha: 0.10)
              : Colors.orange.withValues(alpha: 0.10),
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
            size:  14,
            color: paid ? AppColors.success : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            paid ? 'Paid' : 'Unpaid',
            style: TextStyle(
                fontSize:   12,
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
                ? AppColors.success.withValues(alpha: 0.2)
                : Colors.orange.withValues(alpha: 0.2),
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
                      ? 'Your salary for this week has been released.'
                      : 'Pending admin approval for this week.',
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
                blurRadius: 8,
                offset:     const Offset(0, 2)),
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
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
                color:      color.withValues(alpha: 0.06),
                blurRadius: 8,
                offset:     const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.10),
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
                offset:     const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('DEDUCTIONS BREAKDOWN'),
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
                            color:      AppColors.primaryDark,
                            letterSpacing: -0.5)),
                  ],
                ),
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
                        value: '-${formatCurrency(vm.totalDeductions)}',
                        color: AppColors.danger),
                  ],
                ),
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
                        color:    AppColors.textSecondary))),
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

class _NetChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _NetChip({
    required this.label,
    required this.value,
    required this.color,
  });

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