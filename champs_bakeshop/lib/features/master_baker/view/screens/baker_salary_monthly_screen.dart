part of 'baker_salary_screen.dart';

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
              color:
                  AppColors.masterBaker.withValues(alpha: 0.28),
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