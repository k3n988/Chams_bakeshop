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

  // ── Data loading ──────────────────────────────────────────────

  String get _userId => context.read<AuthViewModel>().currentUser!.id;

  void _load() {
    context.read<HelperSalaryViewModel>().loadDailyRecordsForMonth(
          _userId,
          _selectedMonth.year,
          _selectedMonth.month,
        );
  }

  void _changeMonth(int direction) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + direction,
      );
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
          colorScheme: const ColorScheme.light(primary: AppColors.info),
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

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm          = context.watch<HelperSalaryViewModel>();
    final monthLabel  =
        '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';
    final records     = vm.dailyRecords;
    final monthTotal  = records.fold(0.0, (s, r) => s + r.salary);
    final monthSacks  = records.fold(0,   (s, r) => s + r.totalSacks);

    return RefreshIndicator(
      color: AppColors.info,
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

            // ── Month selector ──
            _MonthSelector(
              label:    monthLabel,
              onPrev:   () => _changeMonth(-1),
              onNext:   () => _changeMonth(1),
              onTap:    _pickMonth,
            ),
            const SizedBox(height: 12),

            // ── Loading / Error ──
            if (vm.isLoading)
              const _LoadingCard()
            else if (vm.error != null)
              _ErrorCard(message: vm.error!, onRetry: _load)
            else if (records.isEmpty)
              EmptyState(
                icon:    Icons.receipt_long_outlined,
                message: 'No records for ${_monthNames[_selectedMonth.month - 1]}',
              )
            else ...[
              // ── Month summary bar ──
              _MonthlySummaryBar(
                days:       records.length,
                sacks:      monthSacks,
                total:      monthTotal,
              ),
              const SizedBox(height: 12),

              // ── Daily record cards ──
              ...records.asMap().entries.map((entry) =>
                  _DailyCard(record: entry.value, index: entry.key)),
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
        border:       Border.all(color: AppColors.info.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(icon: Icons.work_history_outlined,  label: 'Days',  value: '$days'),
          _Divider(),
          _MiniStat(icon: Icons.inventory_2_outlined,   label: 'Sacks', value: '$sacks'),
          _Divider(),
          _MiniStat(icon: Icons.payments_outlined,      label: 'Total', value: formatCurrency(total)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: AppColors.info.withValues(alpha: 0.2));
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _MiniStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, size: 18, color: AppColors.info),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize:   14,
              color:      AppColors.text)),
      Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  DAILY RECORD CARD
// ─────────────────────────────────────────────────────────────
class _DailyCard extends StatelessWidget {
  final HelperDailyRecord record;
  final int               index;
  const _DailyCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    // Subtle staggered animation
    return TweenAnimationBuilder<double>(
      tween:    Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 40),
      curve:    Curves.easeOut,
      builder:  (_, v, child) => Opacity(
        opacity:   v,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - v)),
          child:  child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color:  Colors.black.withValues(alpha: 0.04),
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
              width:  46,
              height: 46,
              decoration: BoxDecoration(
                color:        AppColors.info.withValues(alpha: 0.1),
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
                ],
              ),
            ),

            // Salary
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                formatCurrency(record.salary),
                style: const TextStyle(
                    fontSize:   17,
                    fontWeight: FontWeight.w900,
                    color:      AppColors.primaryDark),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color:        AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Earned',
                  style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w700,
                      color:      AppColors.success),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MONTH SELECTOR  (shared look across all 3 screens)
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
        border:       Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        IconButton(
          icon:     const Icon(Icons.chevron_left),
          color:    AppColors.info,
          onPressed: onPrev,
        ),
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
          onPressed: onNext,
        ),
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
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child:   Center(
          child: CircularProgressIndicator(
              color:       AppColors.info,
              strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
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
            side:            const BorderSide(color: AppColors.danger),
          ),
        ),
      ]),
    );
  }
}