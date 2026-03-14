// lib/features/master_baker/view/screens/baker_salary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/baker_salary_viewmodel.dart';

// ── Internal date helpers ─────────────────────────────────────
String _monthLabel(String dateStr) {
  if (dateStr.isEmpty) return '—';
  try {
    final d = DateTime.parse(dateStr);
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${names[d.month - 1]} ${d.year}';
  } catch (_) {
    return '—';
  }
}

// ─────────────────────────────────────────────────────────────
//  ROOT SCREEN — keeps same 3-tab structure
// ─────────────────────────────────────────────────────────────
class BakerSalaryScreen extends StatefulWidget {
  const BakerSalaryScreen({super.key});

  @override
  State<BakerSalaryScreen> createState() => _BakerSalaryScreenState();
}

class _BakerSalaryScreenState extends State<BakerSalaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _tabs = ['Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this, initialIndex: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _userId => context.read<AuthViewModel>().currentUser!.id;

  Future<void> _init() async {
    await context.read<BakerSalaryViewModel>().init(_userId);
  }

  Future<void> _changeWeek(int dir) async {
    await context.read<BakerSalaryViewModel>().changeWeek(dir, _userId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Tab bar ───────────────────────────────────────────
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tab,
          children: [
            _DailyTab(userId: _userId),
            _WeeklyTab(onChangeWeek: _changeWeek),
            _MonthlyTab(),
          ],
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
//  DAILY TAB  ── matches Image 1
// ══════════════════════════════════════════════════════════════
class _DailyTab extends StatelessWidget {
  final String userId;
  const _DailyTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerSalaryViewModel>();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async =>
          context.read<BakerSalaryViewModel>().init(userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Page title
          const Text('Daily Salary',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark)),
          const SizedBox(height: 3),
          const Text('Earnings per production day',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          // Month navigator (display only)
          _MonthBar(dateStr: vm.weekStart),
          const SizedBox(height: 14),

          if (vm.isLoading)
            const _Loader()
          else if (vm.error != null)
            _ErrCard(vm.error!)
          else ...[
            // Summary stats card
            _DailySummaryCard(vm: vm),
            const SizedBox(height: 16),

            // Entry list
            if (vm.dailyEntries.isEmpty)
              const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'No records for this period')
            else
              ...vm.dailyEntries
                  .map((e) => _DailyEntryCard(entry: e)),
          ],
        ]),
      ),
    );
  }
}

// ── Daily summary card (Days | Total) ────────────────────────
class _DailySummaryCard extends StatelessWidget {
  final BakerSalaryViewModel vm;
  const _DailySummaryCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SummaryCell(
              icon: Icons.calendar_today_outlined,
              value: '${vm.daysWorked}',
              label: 'Days'),
          _VDivider(),
          _SummaryCell(
              icon: Icons.payments_outlined,
              value: formatCurrency(vm.grossSalary),
              label: 'Total'),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _SummaryCell(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint)),
        ],
      );
}

// ── Daily entry card (one per day) ───────────────────────────
class _DailyEntryCard extends StatelessWidget {
  final BakerDailyEntry entry;
  const _DailyEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        // Left icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_outlined,
              color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.date,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.text)),
                const SizedBox(height: 3),
                Text(
                  entry.bakerIncentive > 0
                      ? '${formatCurrency(entry.baseOnly)} base + '
                        '${formatCurrency(entry.bakerIncentive)} incentive'
                      : 'Base: ${formatCurrency(entry.baseSalary)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (entry.bonus > 0)
                  Text(
                    'Bonus: ${formatCurrency(entry.bonus)} (separate)',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.warning),
                  ),
              ]),
        ),
        // Right: amount + badge
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatCurrency(entry.baseSalary),
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.primaryDark)),
          const SizedBox(height: 5),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Earned',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success)),
          ),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  WEEKLY TAB  ── matches Image 2
// ══════════════════════════════════════════════════════════════
class _WeeklyTab extends StatelessWidget {
  final Future<void> Function(int) onChangeWeek;
  const _WeeklyTab({required this.onChangeWeek});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerSalaryViewModel>();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final uid = context.read<AuthViewModel>().currentUser!.id;
        await context.read<BakerSalaryViewModel>().init(uid);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Page title
          const Text('Weekly Salary',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark)),
          const SizedBox(height: 3),
          const Text('Summary for your selected week',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          // Month navigator
          _MonthBar(dateStr: vm.weekStart),
          const SizedBox(height: 10),

          // Week navigator
          _WeekNav(
            weekStart: vm.weekStart,
            weekEnd:   vm.weekEnd,
            onPrev:    () => onChangeWeek(-1),
            onNext:    () => onChangeWeek(1),
          ),
          const SizedBox(height: 16),

          if (vm.isLoading)
            const _Loader()
          else if (vm.error != null)
            _ErrCard(vm.error!)
          else ...[
            // Gross | Days | Net — 3 horizontal stat cards
            _WeeklyStatRow(vm: vm),
            const SizedBox(height: 14),

            // Deductions breakdown
            _DeductionsCard(vm: vm),
            const SizedBox(height: 14),

            // Take-home pay
            _TakeHomeCard(vm: vm),

            // Sack bonus banner
            if (vm.bonusTotal > 0) ...[
              const SizedBox(height: 14),
              _BonusBanner(bonus: vm.bonusTotal),
            ],
          ],
        ]),
      ),
    );
  }
}

// ── Weekly 3-stat row ─────────────────────────────────────────
class _WeeklyStatRow extends StatelessWidget {
  final BakerSalaryViewModel vm;
  const _WeeklyStatRow({required this.vm});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: _StatCard(
            icon:  Icons.wallet_outlined,
            value: formatCurrency(vm.grossSalary),
            label: 'Gross',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon:  Icons.calendar_today_outlined,
            value: '${vm.daysWorked}',
            label: 'Days',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon:  Icons.price_check_outlined,
            value: formatCurrency(vm.finalSalary),
            label: 'Net',
            color: AppColors.primary,
          ),
        ),
      ]);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   value;
  final String   label;
  final Color    color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            FittedBox(
              fit:       BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w800,
                      color:      color)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color:    AppColors.textHint,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

// ── Deductions card ───────────────────────────────────────────
class _DeductionsCard extends StatelessWidget {
  final BakerSalaryViewModel vm;
  const _DeductionsCard({required this.vm});

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('DEDUCTIONS BREAKDOWN'),
            const SizedBox(height: 14),
            _DeducRow(label: 'Gas',  value: vm.gasDeduction),
            _DeducRow(label: 'Vale', value: vm.valeDeduction),
            _DeducRow(label: 'Wifi', value: vm.wifiDeduction),
          ],
        ),
      );
}

class _DeducRow extends StatelessWidget {
  final String label;
  final double value;
  const _DeducRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
            Text(
              value > 0 ? '-${formatCurrency(value)}' : '—',
              style: TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  color:
                      value > 0 ? AppColors.danger : AppColors.textHint),
            ),
          ],
        ),
      );
}

// ── Take-home card ────────────────────────────────────────────
class _TakeHomeCard extends StatelessWidget {
  final BakerSalaryViewModel vm;
  const _TakeHomeCard({required this.vm});

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('TAKE-HOME PAY'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  formatCurrency(vm.finalSalary),
                  style: const TextStyle(
                      fontSize:   30,
                      fontWeight: FontWeight.w900,
                      color:      AppColors.primaryDark),
                ),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MiniChip(
                        label: 'Gross',
                        value: formatCurrency(vm.grossSalary),
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 4),
                      _MiniChip(
                        label: 'Deductions',
                        value: vm.totalDeductions > 0
                            ? '-${formatCurrency(vm.totalDeductions)}'
                            : '-₱0.00',
                        color: AppColors.danger,
                      ),
                    ]),
              ],
            ),
          ],
        ),
      );
}

// ── Bonus banner ──────────────────────────────────────────────
class _BonusBanner extends StatelessWidget {
  final double bonus;
  const _BonusBanner({required this.bonus});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.star_outline,
              size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize:   13,
                    color:      AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'Sack Bonus '),
                  TextSpan(
                      text: formatCurrency(bonus),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color:      AppColors.warning)),
                  const TextSpan(
                      text:
                          ' — paid separately, not included in take-home.'),
                ],
              ),
            ),
          ),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  MONTHLY TAB  ── matches Image 3
// ══════════════════════════════════════════════════════════════
class _MonthlyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerSalaryViewModel>();

    // Avg per week: finalSalary / 6 (approx 4-week month displayed as 6 slots)
    final avgPerWeek =
        vm.daysWorked > 0 ? vm.finalSalary / 6 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Page title
        const Text('Monthly Summary',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark)),
        const SizedBox(height: 3),
        const Text('4-week earnings overview',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 16),

        // Month navigator
        _MonthBar(dateStr: vm.weekStart),
        const SizedBox(height: 16),

        if (vm.isLoading)
          const _Loader()
        else if (vm.error != null)
          _ErrCard(vm.error!)
        else ...[
          // Big orange total card
          _MonthlyHeroCard(
            total:      vm.grossSalary,
            daysWorked: vm.daysWorked,
          ),
          const SizedBox(height: 14),

          // 2×2 stat grid
          GridView.count(
            crossAxisCount:   2,
            shrinkWrap:       true,
            physics:          const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing:  10,
            childAspectRatio: 1.9,
            children: [
              _GridStat(
                  icon:  Icons.wallet_outlined,
                  label: 'Gross',
                  value: formatCurrency(vm.grossSalary),
                  color: AppColors.success),
              _GridStat(
                  icon:  Icons.remove_circle_outline,
                  label: 'Deductions',
                  value: '-${formatCurrency(vm.totalDeductions)}',
                  color: AppColors.danger),
              _GridStat(
                  icon:  Icons.price_check,
                  label: 'Net Salary',
                  value: formatCurrency(vm.finalSalary),
                  color: AppColors.success),
              _GridStat(
                  icon:  Icons.trending_up_outlined,
                  label: 'Avg/Week',
                  value: formatCurrency(avgPerWeek),
                  color: AppColors.info),
            ],
          ),
          const SizedBox(height: 16),

          // Weekly breakdown section
          const _SectionLabel('WEEKLY BREAKDOWN'),
          const SizedBox(height: 12),
          _WeeklyBreakdown(vm: vm),
        ],
      ]),
    );
  }
}

// ── Monthly hero card ─────────────────────────────────────────
class _MonthlyHeroCard extends StatelessWidget {
  final double total;
  final int    daysWorked;
  const _MonthlyHeroCard(
      {required this.total, required this.daysWorked});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC4722F), Color(0xFFE8A960)],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color:     AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 14,
                offset:    const Offset(0, 5))
          ],
        ),
        child: Column(children: [
          const Text('TOTAL MONTHLY EARNINGS',
              style: TextStyle(
                  fontSize:      11,
                  fontWeight:    FontWeight.w700,
                  color:         Colors.white70,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            formatCurrency(total),
            style: const TextStyle(
                fontSize:   34,
                fontWeight: FontWeight.w900,
                color:      Colors.white),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _HeroMeta(
                icon: Icons.calendar_today_outlined,
                text: '$daysWorked days'),
            const SizedBox(width: 16),
            const _HeroMeta(
                icon: Icons.layers_outlined, text: '—'),
            const SizedBox(width: 16),
            const _HeroMeta(
                icon: Icons.calendar_view_week_outlined,
                text: '4 weeks'),
          ]),
        ]),
      );
}

class _HeroMeta extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _HeroMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 12, color: Colors.white70)),
      ]);
}

// ── 2×2 grid stat tile ────────────────────────────────────────
class _GridStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _GridStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const Spacer(),
            FittedBox(
              fit:       BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w800,
                      color:      color)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      );
}

// ── Weekly breakdown rows ─────────────────────────────────────
class _WeeklyBreakdown extends StatelessWidget {
  final BakerSalaryViewModel vm;
  const _WeeklyBreakdown({required this.vm});

  @override
  Widget build(BuildContext context) {
    // Show 4 week slots; slot 4 (current week) gets real data
    return Column(
      children: List.generate(4, (i) {
        final isCurrentWeek = i == 3;
        return _WeekRow(
          weekNum:        i + 1,
          isCurrent:      isCurrentWeek,
          daysWorked:     isCurrentWeek ? vm.daysWorked : 0,
          salary:         isCurrentWeek ? vm.grossSalary : 0,
          weekStart:      isCurrentWeek ? vm.weekStart : '',
          weekEnd:        isCurrentWeek ? vm.weekEnd : '',
        );
      }),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final int    weekNum;
  final bool   isCurrent;
  final int    daysWorked;
  final double salary;
  final String weekStart;
  final String weekEnd;
  const _WeekRow({
    required this.weekNum,
    required this.isCurrent,
    required this.daysWorked,
    required this.salary,
    required this.weekStart,
    required this.weekEnd,
  });

  @override
  Widget build(BuildContext context) {
    final rangeLabel = weekStart.isNotEmpty
        ? '$weekStart – $weekEnd'
        : '— –– —';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset:     const Offset(0, 1))
        ],
      ),
      child: Row(children: [
        // Week badge
        Container(
          width:  36,
          height: 36,
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.border,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text('W$weekNum',
              style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w800,
                  color:      isCurrent
                      ? AppColors.primary
                      : AppColors.textHint)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rangeLabel,
                    style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      AppColors.text)),
                if (daysWorked > 0)
                  Text('$daysWorked days',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
              ]),
        ),
        Text(
          salary > 0 ? formatCurrency(salary) : '₱0.00',
          style: TextStyle(
              fontSize:   14,
              fontWeight: FontWeight.w700,
              color:
                  salary > 0 ? AppColors.primaryDark : AppColors.textHint),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════

/// White card with shadow — base container used throughout
class _WhiteCard extends StatelessWidget {
  final Widget  child;
  final EdgeInsetsGeometry? padding;
  const _WhiteCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset:     const Offset(0, 2))
          ],
        ),
        child: child,
      );
}

/// Month bar — displays current month with chevrons (display only)
class _MonthBar extends StatelessWidget {
  final String dateStr;
  const _MonthBar({required this.dateStr});

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(children: [
          const Icon(Icons.chevron_left, color: AppColors.textHint),
          Expanded(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    _monthLabel(dateStr),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:   14,
                        color:      AppColors.primaryDark),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down,
                      size: 18, color: AppColors.textSecondary),
                ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ]),
      );
}

/// Week range navigator with orange tint
class _WeekNav extends StatelessWidget {
  final String       weekStart;
  final String       weekEnd;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _WeekNav({
    required this.weekStart,
    required this.weekEnd,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        weekStart.isEmpty ? '—' : '$weekStart — $weekEnd';

    return Container(
      decoration: BoxDecoration(
        color:        AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Row(children: [
        IconButton(
          icon:      const Icon(Icons.chevron_left),
          color:     AppColors.primary,
          iconSize:  20,
          onPressed: onPrev,
        ),
        Expanded(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.date_range_outlined,
                    size:  15,
                    color: AppColors.primary.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:   13,
                        color:      AppColors.primaryDark)),
              ]),
        ),
        IconButton(
          icon:      const Icon(Icons.chevron_right),
          color:     AppColors.primary,
          iconSize:  20,
          onPressed: onNext,
        ),
      ]),
    );
  }
}

/// Small section title with left bar accent
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width:  3,
          height: 13,
          decoration: BoxDecoration(
              color:        AppColors.primary,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize:      11,
                fontWeight:    FontWeight.w800,
                color:         AppColors.textHint,
                letterSpacing: 0.8)),
      ]);
}

/// Chip: "Label: value"
class _MiniChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _MiniChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$label: $value',
          style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w700,
              color:      color),
        ),
      );
}

/// Vertical divider used in summary cells
class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: AppColors.border);
}

/// Loading spinner
class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2.5),
        ),
      );
}

/// Error state card
class _ErrCard extends StatelessWidget {
  final String message;
  const _ErrCard(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:        AppColors.danger.withValues(alpha: 0.05),
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
        ]),
      );
}