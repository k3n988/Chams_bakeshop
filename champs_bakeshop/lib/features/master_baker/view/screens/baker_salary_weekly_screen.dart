part of 'baker_salary_screen.dart';

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
            colors: [Color(0xFFFF7A00), Color(0xFFFFA03A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF7A00).withValues(alpha: 0.30),
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
                      textColor: Colors.red.shade100,
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