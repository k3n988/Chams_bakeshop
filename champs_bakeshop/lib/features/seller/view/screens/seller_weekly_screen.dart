import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/seller_remittance_viewmodel.dart';

class SellerWeeklyScreen extends StatelessWidget {
  const SellerWeeklyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<SellerRemittanceViewModel>();
    final uid = context.read<AuthViewModel>().currentUser!.id;

    return RefreshIndicator(
      color: AppColors.seller,
      onRefresh: () => vm.init(uid),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _PageHeader(
            title: 'Weekly Summary',
            subtitle: 'Remittance for your selected week',
          ),
          const SizedBox(height: 16),

          // ── Week navigator ───────────────────────────────
          _WeekNav(
            weekStart: vm.weekStart, weekEnd: vm.weekEnd,
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

            // ── Take-home card (with salary) ───────────────
            _TakeHomeCard(vm: vm),
            const SizedBox(height: 14),

            // ── Daily breakdown ────────────────────────────
            const _SectionLabel('DAILY BREAKDOWN'),
            const SizedBox(height: 10),

            if (vm.sortedRemittances.isEmpty)
              const _EmptyCard(
                icon: Icons.receipt_long_outlined,
                message: 'No remittances for this week',
              )
            else
              ...vm.sortedRemittances.map((r) => _WeekDayRow(r: r)),
          ],
        ]),
      ),
    );
  }
}

// ── Week navigator ────────────────────────────────────────────
class _WeekNav extends StatelessWidget {
  final String weekStart;
  final String weekEnd;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _WeekNav({
    required this.weekStart, required this.weekEnd,
    required this.onPrev, required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.seller.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.seller.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppColors.seller, iconSize: 20, onPressed: onPrev,
          ),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.date_range_outlined,
                  size: 15, color: AppColors.seller.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text('$weekStart — $weekEnd',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryDark)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: AppColors.seller, iconSize: 20, onPressed: onNext,
          ),
        ]),
      );
}

// ── 3-stat row ────────────────────────────────────────────────
class _WeeklyStatRow extends StatelessWidget {
  final SellerRemittanceViewModel vm;
  const _WeeklyStatRow({required this.vm});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: _MiniStatCard(
          icon: Icons.sell_outlined, label: 'Pieces Sold',
          value: '${vm.totalPiecesSold}', color: AppColors.success,
        )),
        const SizedBox(width: 10),
        Expanded(child: _MiniStatCard(
          icon: Icons.undo_outlined, label: 'Returned',
          value: '${vm.totalReturns}', color: AppColors.warning,
        )),
        const SizedBox(width: 10),
        Expanded(child: _MiniStatCard(
          icon: Icons.calendar_today_outlined, label: 'Days',
          value: '${vm.daysRemitted}', color: const Color(0xFF1976D2),
        )),
      ]);
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _MiniStatCard({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500)),
        ]),
      );
}

// ── Take-home card (salary integrated) ───────────────────────
class _TakeHomeCard extends StatelessWidget {
  final SellerRemittanceViewModel vm;
  const _TakeHomeCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final totalSalary = vm.sortedRemittances.fold(0.0, (s, r) => s + r.salary);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.seller, AppColors.seller.withValues(alpha: 0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: AppColors.seller.withValues(alpha: 0.30),
          blurRadius: 14, offset: const Offset(0, 5),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.white70),
          SizedBox(width: 6),
          Text('WEEKLY REMITTANCE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                  color: Colors.white70, letterSpacing: 0.8)),
        ]),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                formatCurrency(vm.totalActualRemittance),
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              // ── Weekly salary ──────────────────────────
              if (totalSalary > 0)
                Row(children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 12, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text('Salary: ${formatCurrency(totalSalary)}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _Pill(
                label: 'Expected',
                value: formatCurrency(vm.totalAdjustedRemittance),
                bgColor: Colors.white.withValues(alpha: 0.15),
                textColor: Colors.white,
              ),
              const SizedBox(height: 4),
              _Pill(
                label: 'Variance',
                value: vm.totalVariance >= 0
                    ? '+${formatCurrency(vm.totalVariance)}'
                    : formatCurrency(vm.totalVariance),
                bgColor: vm.totalVariance >= 0
                    ? Colors.green.withValues(alpha: 0.25)
                    : Colors.red.withValues(alpha: 0.25),
                textColor: vm.totalVariance >= 0
                    ? Colors.green.shade100
                    : Colors.red.shade100,
              ),
            ]),
          ],
        ),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  final Color  bgColor;
  final Color  textColor;
  const _Pill({
    required this.label, required this.value,
    required this.bgColor, required this.textColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Text('$label: $value',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
      );
}

// ── Day row (now shows salary) ────────────────────────────────
class _WeekDayRow extends StatelessWidget {
  final dynamic r; // SellerRemittanceModel
  const _WeekDayRow({required this.r});

  Color get _varColor {
    if (r.variance > 0) return AppColors.success;
    if (r.variance < 0) return AppColors.danger;
    return AppColors.textHint;
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6, offset: const Offset(0, 1))],
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.seller.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                r.date.substring(8), // day number
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.seller),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.date,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
              Text('${r.piecesSold} sold · ${r.returnPieces} returned',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatCurrency(r.actualRemittance),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              Text(
                '${r.variance >= 0 ? '+' : ''}${formatCurrency(r.variance)}',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: _varColor),
              ),
            ]),
          ]),
          // ── Salary chip per day ───────────────────────────
          if (r.salary > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.seller.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.seller.withValues(alpha: 0.18)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Row(children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 12, color: AppColors.seller),
                  SizedBox(width: 5),
                  Text('Session Salary',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.seller)),
                ]),
                Text(formatCurrency(r.salary),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.seller)),
              ]),
            ),
          ],
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                  color: AppColors.text, letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
              color: AppColors.seller, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: AppColors.textHint, letterSpacing: 0.8)),
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
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, size: 40, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
        ]),
      );
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(
            color: AppColors.seller, strokeWidth: 2.5)),
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
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          const Icon(Icons.cloud_off_outlined, size: 36, color: AppColors.danger),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontSize: 13)),
        ]),
      );
}