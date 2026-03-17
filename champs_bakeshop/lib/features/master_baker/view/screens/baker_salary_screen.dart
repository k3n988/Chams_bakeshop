import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/baker_salary_viewmodel.dart';

// ── Internal date helper ──────────────────────────────────────
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
//  ROOT SCREEN
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

  String get _userId =>
      context.read<AuthViewModel>().currentUser!.id;

  Future<void> _init() async =>
      context.read<BakerSalaryViewModel>().init(_userId);

  Future<void> _changeWeek(int dir) async =>
      context.read<BakerSalaryViewModel>().changeWeek(dir, _userId);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Tab bar ────────────────────────────────────────────
      Container(
        color: Colors.white,
        child: Column(
          children: [
            TabBar(
              controller: _tab,
              labelColor: AppColors.masterBaker,
              unselectedLabelColor: AppColors.textHint,
              indicatorColor: AppColors.masterBaker,
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
          ],
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
//  DAILY TAB
// ══════════════════════════════════════════════════════════════
class _DailyTab extends StatelessWidget {
  final String userId;
  const _DailyTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerSalaryViewModel>();

    return RefreshIndicator(
      color: AppColors.masterBaker,
      onRefresh: () async =>
          context.read<BakerSalaryViewModel>().init(userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: 'Daily Salary',
              subtitle: 'Earnings per production day',
            ),
            const SizedBox(height: 16),
            _MonthBar(dateStr: vm.weekStart),
            const SizedBox(height: 14),
            if (vm.isLoading)
              const _Loader()
            else if (vm.error != null)
              _ErrCard(vm.error!)
            else ...[
              // Summary stats
              _DailySummaryCard(vm: vm),
              const SizedBox(height: 16),
              // Section label
              const _SectionLabel('RECORDS'),
              const SizedBox(height: 10),
              if (vm.dailyEntries.isEmpty)
                _EmptyCard(
                  icon: Icons.receipt_long_outlined,
                  message: 'No records for this period',
                )
              else
                ...vm.dailyEntries
                    .asMap()
                    .entries
                    .map((e) => _DailyEntryCard(
                        entry: e.value, index: e.key)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Daily summary card ────────────────────────────────────────
class _DailySummaryCard extends StatelessWidget {
  final BakerSalaryViewModel vm;
  const _DailySummaryCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SummaryCell(
            icon: Icons.calendar_today_outlined,
            value: '${vm.daysWorked}',
            label: 'Days Worked',
            color: const Color(0xFF1976D2),
          ),
          Container(width: 1, height: 44, color: AppColors.border),
          _SummaryCell(
            icon: Icons.payments_outlined,
            value: formatCurrency(vm.grossSalary),
            label: 'Total Earned',
            color: AppColors.masterBaker,
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _SummaryCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint)),
        ],
      );
}

// ── Daily entry card ──────────────────────────────────────────
class _DailyEntryCard extends StatelessWidget {
  final BakerDailyEntry entry;
  final int index;
  const _DailyEntryCard({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 55),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child:
            Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  AppColors.masterBaker.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_outlined,
                color: AppColors.masterBaker, size: 20),
          ),
          const SizedBox(width: 12),
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
                      ? '${formatCurrency(entry.baseOnly)} base + ${formatCurrency(entry.bakerIncentive)} incentive'
                      : 'Base: ${formatCurrency(entry.baseSalary)}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary),
                ),
                if (entry.bonus > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Bonus: ${formatCurrency(entry.bonus)} (separate)',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.warning),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCurrency(entry.baseSalary),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.primaryDark)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.success
                          .withValues(alpha: 0.15)),
                ),
                child: const Text('Earned',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  WEEKLY TAB
// ══════════════════════════════════════════════════════════════
class _WeeklyTab extends StatelessWidget {
  final Future<void> Function(int) onChangeWeek;
  const _WeeklyTab({required this.onChangeWeek});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerSalaryViewModel>();

    return RefreshIndicator(
      color: AppColors.masterBaker,
      onRefresh: () async {
        final uid =
            context.read<AuthViewModel>().currentUser!.id;
        await context.read<BakerSalaryViewModel>().init(uid);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: 'Weekly Salary',
              subtitle: 'Summary for your selected week',
            ),
            const SizedBox(height: 16),
            _MonthBar(dateStr: vm.weekStart),
            const SizedBox(height: 10),
            _WeekNav(
              weekStart: vm.weekStart,
              weekEnd: vm.weekEnd,
              onPrev: () => onChangeWeek(-1),
              onNext: () => onChangeWeek(1),
            ),
            const SizedBox(height: 16),
            if (vm.isLoading)
              const _Loader()
            else if (vm.error != null)
              _ErrCard(vm.error!)
            else ...[
              _WeeklyStatRow(vm: vm),
              const SizedBox(height: 14),
              _DeductionsCard(vm: vm),
              const SizedBox(height: 14),
              _TakeHomeCard(vm: vm),
              if (vm.bonusTotal > 0) ...[
                const SizedBox(height: 14),
                _BonusBanner(bonus: vm.bonusTotal),
              ],
            ],
          ],
        ),
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
          child: _MiniStatCard(
            icon: Icons.wallet_outlined,
            value: formatCurrency(vm.grossSalary),
            label: 'Gross',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.calendar_today_outlined,
            value: '${vm.daysWorked}',
            label: 'Days',
            color: const Color(0xFF1976D2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.price_check_outlined,
            value: formatCurrency(vm.finalSalary),
            label: 'Net',
            color: AppColors.masterBaker,
          ),
        ),
      ]);
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
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
            _DeducRow(label: 'Gas', value: vm.gasDeduction),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(
                value > 0
                    ? Icons.remove_circle_outline
                    : Icons.remove_outlined,
                size: 14,
                color: value > 0
                    ? AppColors.danger
                    : AppColors.textHint,
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary)),
            ]),
            Text(
              value > 0 ? '-${formatCurrency(value)}' : '—',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: value > 0
                      ? AppColors.danger
                      : AppColors.textHint),
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5A8F3E), Color(0xFF7DB85C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.masterBaker.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              const Text('TAKE-HOME PAY',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 0.8)),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  formatCurrency(vm.finalSalary),
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _TakeHomePill(
                      label: 'Gross',
                      value: formatCurrency(vm.grossSalary),
                      bgColor:
                          Colors.white.withValues(alpha: 0.15),
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    _TakeHomePill(
                      label: '-Deductions',
                      value: vm.totalDeductions > 0
                          ? formatCurrency(vm.totalDeductions)
                          : '₱0.00',
                      bgColor:
                          Colors.red.withValues(alpha: 0.25),
                      textColor:
                          Colors.red.shade100,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
}

class _TakeHomePill extends StatelessWidget {
  final String label;
  final String value;
  final Color bgColor;
  final Color textColor;
  const _TakeHomePill({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$label: $value',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor),
        ),
      );
}

// ── Bonus banner ──────────────────────────────────────────────
class _BonusBanner extends StatelessWidget {
  final double bonus;
  const _BonusBanner({required this.bonus});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star_outline,
                size: 18, color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sack Bonus',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warning)),
                const SizedBox(height: 2),
                Text(
                  '${formatCurrency(bonus)} — paid separately, not in take-home.',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  MONTHLY TAB
// ══════════════════════════════════════════════════════════════
class _MonthlyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerSalaryViewModel>();
    final avgPerWeek =
        vm.daysWorked > 0 ? vm.finalSalary / 6 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            title: 'Monthly Summary',
            subtitle: '4-week earnings overview',
          ),
          const SizedBox(height: 16),
          _MonthBar(dateStr: vm.weekStart),
          const SizedBox(height: 16),
          if (vm.isLoading)
            const _Loader()
          else if (vm.error != null)
            _ErrCard(vm.error!)
          else ...[
            _MonthlyHeroCard(
              total: vm.grossSalary,
              daysWorked: vm.daysWorked,
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: [
                _GridStat(
                    icon: Icons.wallet_outlined,
                    label: 'Gross',
                    value: formatCurrency(vm.grossSalary),
                    color: AppColors.success),
                _GridStat(
                    icon: Icons.remove_circle_outline,
                    label: 'Deductions',
                    value:
                        '-${formatCurrency(vm.totalDeductions)}',
                    color: AppColors.danger),
                _GridStat(
                    icon: Icons.price_check,
                    label: 'Net Salary',
                    value: formatCurrency(vm.finalSalary),
                    color: AppColors.masterBaker),
                _GridStat(
                    icon: Icons.trending_up_outlined,
                    label: 'Avg/Week',
                    value: formatCurrency(avgPerWeek),
                    color: const Color(0xFF1976D2)),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionLabel('WEEKLY BREAKDOWN'),
            const SizedBox(height: 12),
            _WeeklyBreakdown(vm: vm),
          ],
        ],
      ),
    );
  }
}

// ── Monthly hero card ─────────────────────────────────────────
class _MonthlyHeroCard extends StatelessWidget {
  final double total;
  final int daysWorked;
  const _MonthlyHeroCard(
      {required this.total, required this.daysWorked});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5A8F3E), Color(0xFF7DB85C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.masterBaker.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(children: [
          const Text('TOTAL MONTHLY EARNINGS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(
            formatCurrency(total),
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.white70),
                const SizedBox(width: 6),
                Text('$daysWorked days worked',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 14),
                const Icon(Icons.calendar_view_week_outlined,
                    size: 13, color: Colors.white70),
                const SizedBox(width: 6),
                const Text('4 weeks',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ]),
      );
}

// ── Grid stat tile ────────────────────────────────────────────
class _GridStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _GridStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      );
}

// ── Weekly breakdown ──────────────────────────────────────────
class _WeeklyBreakdown extends StatelessWidget {
  final BakerSalaryViewModel vm;
  const _WeeklyBreakdown({required this.vm});

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(4, (i) {
          final isCurrentWeek = i == 3;
          return _WeekRow(
            weekNum: i + 1,
            isCurrent: isCurrentWeek,
            daysWorked: isCurrentWeek ? vm.daysWorked : 0,
            salary: isCurrentWeek ? vm.grossSalary : 0,
            weekStart: isCurrentWeek ? vm.weekStart : '',
            weekEnd: isCurrentWeek ? vm.weekEnd : '',
          );
        }),
      );
}

class _WeekRow extends StatelessWidget {
  final int weekNum;
  final bool isCurrent;
  final int daysWorked;
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
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? AppColors.masterBaker.withValues(alpha: 0.20)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.masterBaker.withValues(alpha: 0.10)
                : AppColors.border,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text('W$weekNum',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isCurrent
                      ? AppColors.masterBaker
                      : AppColors.textHint)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rangeLabel,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              if (daysWorked > 0)
                Text('$daysWorked days',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint)),
            ],
          ),
        ),
        Text(
          salary > 0 ? formatCurrency(salary) : '₱0.00',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: salary > 0
                  ? AppColors.primaryDark
                  : AppColors.textHint),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary)),
        ],
      );
}

/// White card with border + shadow
class _WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _WhiteCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}

/// Month bar — display only
class _MonthBar extends StatelessWidget {
  final String dateStr;
  const _MonthBar({required this.dateStr});

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 4),
        child: Row(children: [
          const Icon(Icons.chevron_left,
              color: AppColors.textHint),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 15,
                    color: AppColors.masterBaker),
                const SizedBox(width: 8),
                Text(
                  _monthLabel(dateStr),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primaryDark),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down,
                    size: 18,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.textHint),
        ]),
      );
}

/// Week range navigator
class _WeekNav extends StatelessWidget {
  final String weekStart;
  final String weekEnd;
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
        color:
            AppColors.masterBaker.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.masterBaker
                .withValues(alpha: 0.20)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          color: AppColors.masterBaker,
          iconSize: 20,
          onPressed: onPrev,
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.date_range_outlined,
                  size: 15,
                  color: AppColors.masterBaker
                      .withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primaryDark)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          color: AppColors.masterBaker,
          iconSize: 20,
          onPressed: onNext,
        ),
      ]),
    );
  }
}

/// Section label with left accent bar
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: AppColors.masterBaker,
            borderRadius: BorderRadius.circular(2),
          ),
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

/// Empty state card
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard(
      {required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, size: 40, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 14)),
        ]),
      );
}

/// Loading spinner
class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.masterBaker,
              strokeWidth: 2.5),
        ),
      );
}

/// Error state
class _ErrCard extends StatelessWidget {
  final String message;
  const _ErrCard(this.message);

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
        ]),
      );
}