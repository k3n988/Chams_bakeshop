import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/packer_salary_viewmodel.dart';

class PackerWeeklyScreen extends StatelessWidget {
  const PackerWeeklyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<PackerSalaryViewModel>();
    final uid = context.read<AuthViewModel>().currentUser!.id;

    return RefreshIndicator(
      color: AppColors.packer,
      onRefresh: () => vm.init(uid),
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

            // ── Week navigator ─────────────────────────────────
            _WeekNav(
              weekStart: vm.weekStart,
              weekEnd:   vm.weekEnd,
              onPrev: () => vm.changeWeek(-1, uid),
              onNext: () => vm.changeWeek(1, uid),
            ),
            const SizedBox(height: 16),

            if (vm.isLoading)
              const _Loader()
            else if (vm.error != null)
              _ErrCard(vm.error!)
            else ...[
              // ── 3-stat row ─────────────────────────────────
              _WeeklyStatRow(vm: vm),
              const SizedBox(height: 14),

              // ── Deductions card ────────────────────────────
              _DeductionsCard(vm: vm),
              const SizedBox(height: 14),

              // ── Take-home card ─────────────────────────────
              _TakeHomeCard(vm: vm),
              const SizedBox(height: 14),

              // ── Daily breakdown ────────────────────────────
              const _SectionLabel('DAILY BREAKDOWN'),
              const SizedBox(height: 10),

              if (vm.dailyEntries.isEmpty)
                _EmptyCard(
                  icon: Icons.receipt_long_outlined,
                  message: 'No records for this week',
                )
              else
                ...vm.dailyEntries.map((e) => _WeekDayRow(entry: e)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Week navigator ────────────────────────────────────────────
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
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.packer.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.packer.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppColors.packer,
            iconSize: 20,
            onPressed: onPrev,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.date_range_outlined,
                    size: 15,
                    color: AppColors.packer.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text('$weekStart — $weekEnd',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primaryDark)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: AppColors.packer,
            iconSize: 20,
            onPressed: onNext,
          ),
        ]),
      );
}

// ── 3-stat row ────────────────────────────────────────────────
class _WeeklyStatRow extends StatelessWidget {
  final PackerSalaryViewModel vm;
  const _WeeklyStatRow({required this.vm});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: _MiniStatCard(
            icon:  Icons.inventory_2_outlined,
            label: 'Bundles',
            value: '${vm.totalBundles}',
            color: AppColors.packer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon:  Icons.calendar_today_outlined,
            label: 'Days',
            value: '${vm.daysWorked}',
            color: const Color(0xFF1976D2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon:  Icons.wallet_outlined,
            label: 'Gross',
            value: formatCurrency(vm.grossSalary),
            color: AppColors.success,
          ),
        ),
      ]);
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
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
  final PackerSalaryViewModel vm;
  const _DeductionsCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('DEDUCTIONS'),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(
                    vm.valeDeduction > 0
                        ? Icons.remove_circle_outline
                        : Icons.remove_outlined,
                    size: 14,
                    color: vm.valeDeduction > 0
                        ? AppColors.danger
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: 8),
                  const Text('Vale',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary)),
                ]),
                Text(
                  vm.valeDeduction > 0
                      ? '-${formatCurrency(vm.valeDeduction)}'
                      : '—',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: vm.valeDeduction > 0
                          ? AppColors.danger
                          : AppColors.textHint),
                ),
              ],
            ),
          ],
        ),
      );
}

// ── Take-home card ────────────────────────────────────────────
class _TakeHomeCard extends StatelessWidget {
  final PackerSalaryViewModel vm;
  const _TakeHomeCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.packer,
              AppColors.packer.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.packer.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 14, color: Colors.white70),
              SizedBox(width: 6),
              Text('TAKE-HOME PAY',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 0.8)),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  formatCurrency(vm.netSalary),
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Pill(
                      label: 'Gross',
                      value: formatCurrency(vm.grossSalary),
                      bgColor: Colors.white.withValues(alpha: 0.15),
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    _Pill(
                      label: '-Vale',
                      value: vm.valeDeduction > 0
                          ? formatCurrency(vm.valeDeduction)
                          : '₱0.00',
                      bgColor: Colors.red.withValues(alpha: 0.25),
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

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  final Color  bgColor;
  final Color  textColor;
  const _Pill({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('$label: $value',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor)),
      );
}

// ── Day row ───────────────────────────────────────────────────
class _WeekDayRow extends StatelessWidget {
  final PackerDailyEntry entry;
  const _WeekDayRow({required this.entry});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.packer.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              entry.date.substring(8),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.packer),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.date,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
                Text('${entry.totalBundles} bundles',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          Text(formatCurrency(entry.salary),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark)),
        ]),
      );
}

// ── Shared widgets ────────────────────────────────────────────
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
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
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
              color: AppColors.packer,
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

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String   message;
  const _EmptyCard({required this.icon, required this.message});

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

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.packer, strokeWidth: 2.5),
        ),
      );
}

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