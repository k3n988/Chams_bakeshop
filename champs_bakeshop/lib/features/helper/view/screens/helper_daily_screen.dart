import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/helper_salary_viewmodel.dart';

class HelperDailyScreen extends StatefulWidget {
  const HelperDailyScreen({super.key});

  @override
  State<HelperDailyScreen> createState() => _HelperDailyScreenState();
}

class _HelperDailyScreenState extends State<HelperDailyScreen> {
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  String get _userId =>
      context.read<AuthViewModel>().currentUser!.id;

  void _load() {
    final vm = context.read<HelperSalaryViewModel>();
    vm.loadDailyRecordsForMonth(
        _userId, _selectedMonth.year, _selectedMonth.month);
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

  // ── Paid week check ──────────────────────────────────────────
  String _weekStartOf(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return '';
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return monday.toString().split(' ')[0];
  }

  bool _isPaid(String date, Set<String> paidWeeks) =>
      paidWeeks.contains(_weekStartOf(date));

  // ── Preview sheet ────────────────────────────────────────────
  void _showPreview(HelperDailyRecord rec, bool paid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize:     0.4,
        maxChildSize:     0.88,
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
                  child: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.info, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(rec.date,
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
                // ✅ Paid/Unpaid badge
                Container(
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
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(
                      paid ? Icons.check_circle : Icons.schedule,
                      size: 14,
                      color: paid
                          ? AppColors.success
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      paid ? 'Paid' : 'Unpaid',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: paid
                              ? AppColors.success
                              : Colors.orange),
                    ),
                  ]),
                ),
              ]),
            ),

            const Divider(height: 20),

            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Production summary ─────────────────
                  _PreviewCard(children: [
                    _PreviewLabel('PRODUCTION SUMMARY'),
                    const SizedBox(height: 12),
                    _PreviewRow(
                      icon:  Icons.groups_outlined,
                      label: 'Total Workers',
                      value: '${rec.totalWorkers}',
                    ),
                    _PreviewRow(
                      icon:  Icons.inventory_2_outlined,
                      label: 'Total Sacks',
                      value: '${rec.totalSacks} sacks',
                    ),
                    _PreviewRow(
                      icon:  Icons.attach_money,
                      label: 'Batch Value',
                      value: formatCurrency(rec.totalValue),
                      valueColor: AppColors.info,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── Salary breakdown ───────────────────
                  _PreviewCard(children: [
                    _PreviewLabel('SALARY BREAKDOWN'),
                    const SizedBox(height: 12),
                    _PreviewRow(
                      icon:  Icons.calculate_outlined,
                      label: 'Per Worker (base)',
                      value: formatCurrency(rec.salary),
                      valueColor: AppColors.info,
                    ),
                    const Divider(height: 20),
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                      const Text('Your Earnings',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      Text(
                        formatCurrency(rec.salary),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: AppColors.primaryDark),
                      ),
                    ]),
                  ]),
                  const SizedBox(height: 12),

                  // ── Payment status card ────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: paid
                          ? AppColors.success
                              .withValues(alpha: 0.06)
                          : Colors.orange.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: paid
                            ? AppColors.success
                                .withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: paid
                              ? AppColors.success
                                  .withValues(alpha: 0.1)
                              : Colors.orange
                                  .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Icon(
                          paid
                              ? Icons.check_circle_outline
                              : Icons.schedule_outlined,
                          color: paid
                              ? AppColors.success
                              : Colors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Text(
                            paid
                                ? 'Salary Paid'
                                : 'Pending Payment',
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
                                    ? AppColors.success
                                        .withValues(alpha: 0.8)
                                    : Colors.orange
                                        .withValues(alpha: 0.8)),
                          ),
                        ]),
                      ),
                    ]),
                  ),
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
    final records    = vm.dailyRecords;
    final monthTotal = records.fold(0.0, (s, r) => s + r.salary);
    final monthSacks = records.fold(0, (s, r) => s + r.totalSacks);
    final paidWeeks  = vm.paidWeekStarts;

    return RefreshIndicator(
      color:     AppColors.info,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title:    'Daily Salary',
              subtitle: 'Earnings per production day',
            ),
            _MonthSelector(
              label:  monthLabel,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onTap:  _pickMonth,
            ),
            const SizedBox(height: 12),

            if (vm.isLoading)
              const _LoadingCard()
            else if (vm.error != null)
              _ErrorCard(message: vm.error!, onRetry: _load)
            else if (records.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                message:
                    'No records for ${_monthNames[_selectedMonth.month - 1]}',
              )
            else ...[
              _MonthlySummaryBar(
                days:   records.length,
                sacks:  monthSacks,
                total:  monthTotal,
              ),
              const SizedBox(height: 12),
              ...records.asMap().entries.map((entry) {
                final rec  = entry.value;
                final paid = _isPaid(rec.date, paidWeeks);
                return _DailyCard(
                  record: rec,
                  index:  entry.key,
                  paid:   paid,
                  onTap:  () => _showPreview(rec, paid),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MONTH SUMMARY BAR
// ─────────────────────────────────────────────────────────────
class _MonthlySummaryBar extends StatelessWidget {
  final int    days;
  final int    sacks;
  final double total;
  const _MonthlySummaryBar(
      {required this.days, required this.sacks, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color:        AppColors.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.info.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(
              icon: Icons.work_history_outlined,
              label: 'Days',
              value: '$days'),
          _VertDivider(),
          _MiniStat(
              icon: Icons.inventory_2_outlined,
              label: 'Sacks',
              value: '$sacks'),
          _VertDivider(),
          _MiniStat(
              icon: Icons.payments_outlined,
              label: 'Total',
              value: formatCurrency(total)),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: AppColors.info.withValues(alpha: 0.2));
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _MiniStat(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, size: 18, color: AppColors.info),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize:   14,
                color:      AppColors.text)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textHint)),
      ]);
}

// ─────────────────────────────────────────────────────────────
//  DAILY RECORD CARD  ← updated with paid badge + tap
// ─────────────────────────────────────────────────────────────
class _DailyCard extends StatelessWidget {
  final HelperDailyRecord record;
  final int               index;
  final bool              paid;
  final VoidCallback      onTap;

  const _DailyCard({
    required this.record,
    required this.index,
    required this.paid,
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
            offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              // Icon
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.info, size: 22),
              ),
              const SizedBox(width: 14),

              // Date + meta
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(record.date,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize:   15,
                          color:      AppColors.text)),
                  const SizedBox(height: 4),
                  Text(
                    '${record.totalWorkers} workers  ·  ${record.totalSacks} sacks',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Batch total: ${formatCurrency(record.totalValue)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ]),
              ),

              // Right: salary + badges
              Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                Text(
                  formatCurrency(record.salary),
                  style: const TextStyle(
                      fontSize:   17,
                      fontWeight: FontWeight.w900,
                      color:      AppColors.primaryDark),
                ),
                const SizedBox(height: 4),
                // ✅ Paid / Unpaid badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: paid
                        ? AppColors.success.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: paid
                          ? AppColors.success
                              .withValues(alpha: 0.25)
                          : Colors.orange.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(
                      paid ? Icons.check_circle : Icons.schedule,
                      size: 10,
                      color:
                          paid ? AppColors.success : Colors.orange,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      paid ? 'Paid' : 'Unpaid',
                      style: TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.w700,
                          color: paid
                              ? AppColors.success
                              : Colors.orange),
                    ),
                  ]),
                ),
                const SizedBox(height: 3),
                // ✅ Tap hint
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Details',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.info
                              .withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic)),
                  Icon(Icons.chevron_right,
                      size: 12,
                      color:
                          AppColors.info.withValues(alpha: 0.7)),
                ]),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
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
                    fontSize: 13, color: AppColors.textHint)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.text)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  MONTH SELECTOR
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
  Widget build(BuildContext context) {
    return Container(
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
                const SizedBox(width: 6),
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
}

// ─────────────────────────────────────────────────────────────
//  LOADING + ERROR CARDS
// ─────────────────────────────────────────────────────────────
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