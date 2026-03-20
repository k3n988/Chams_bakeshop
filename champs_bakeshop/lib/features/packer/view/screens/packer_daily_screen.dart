import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/utils/constants.dart';
import '../../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/packer_salary_viewmodel.dart';

class PackerDailyScreen extends StatelessWidget {
  const PackerDailyScreen({super.key});

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
              title: 'Daily Salary',
              subtitle: 'Earnings per production day',
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
              // ── Summary ────────────────────────────────────
              _DailySummaryRow(vm: vm),
              const SizedBox(height: 16),

              // ── Daily records ──────────────────────────────
              const _SectionLabel('DAILY RECORDS'),
              const SizedBox(height: 10),

              if (vm.dailyEntries.isEmpty)
                _EmptyCard(
                  icon: Icons.receipt_long_outlined,
                  message: 'No records for this week',
                )
              else
                ...vm.dailyEntries.asMap().entries.map(
                      (e) => _DailyEntryCard(
                        entry: e.value,
                        index: e.key,
                      ),
                    ),
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

// ── Daily summary row ─────────────────────────────────────────
class _DailySummaryRow extends StatelessWidget {
  final PackerSalaryViewModel vm;
  const _DailySummaryRow({required this.vm});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: _MiniStat(
            icon:  Icons.inventory_2_outlined,
            label: 'Total Bundles',
            value: '${vm.totalBundles}',
            color: AppColors.packer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon:  Icons.calendar_today_outlined,
            label: 'Days Worked',
            value: '${vm.daysWorked}',
            color: const Color(0xFF1976D2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon:  Icons.payments_outlined,
            label: 'Gross Salary',
            value: formatCurrency(vm.grossSalary),
            color: AppColors.success,
          ),
        ),
      ]);
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _MiniStat({
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

// ── Daily entry card ──────────────────────────────────────────
class _DailyEntryCard extends StatelessWidget {
  final PackerDailyEntry entry;
  final int              index;
  const _DailyEntryCard({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 55),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(0, 10 * (1 - v)), child: child),
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
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.packer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.packer, size: 20),
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
                  Text('${entry.productions.length} entries',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatCurrency(entry.salary),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.primaryDark)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.packer.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${entry.totalBundles} bundles',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.packer)),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 10),
          // Product breakdown
          ...entry.productions.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  const SizedBox(width: 4),
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: AppColors.packer,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.productName,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ),
                  Text('${p.bundleCount} bundles',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.packer)),
                  const SizedBox(width: 8),
                  Text(p.timestamp.length >= 16
                      ? p.timestamp.substring(11, 16)
                      : '',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                ]),
              )),
        ]),
      ),
    );
  }
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