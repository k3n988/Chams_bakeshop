import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/seller_remittance_viewmodel.dart';

class SellerMonthlyScreen extends StatefulWidget {
  const SellerMonthlyScreen({super.key});

  @override
  State<SellerMonthlyScreen> createState() =>
      _SellerMonthlyScreenState();
}

class _SellerMonthlyScreenState extends State<SellerMonthlyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthViewModel>().currentUser!.id;
      context.read<SellerRemittanceViewModel>().loadMonthly(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<SellerRemittanceViewModel>();
    final uid = context.read<AuthViewModel>().currentUser!.id;

    return RefreshIndicator(
      color: AppColors.seller,
      onRefresh: () => vm.loadMonthly(uid),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: 'Monthly Summary',
              subtitle: '4-week pandesal sales overview',
            ),
            const SizedBox(height: 16),

            if (vm.isLoading)
              const _Loader()
            else if (vm.error != null)
              _ErrCard(vm.error!)
            else ...[
              // ── Hero card ──────────────────────────────────
              _MonthlyHeroCard(vm: vm),
              const SizedBox(height: 14),

              // ── Grid stats ─────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.9,
                children: [
                  _GridStat(
                      icon: Icons.sell_outlined,
                      label: 'Total Sold',
                      value: '${vm.totalPiecesSold} pcs',
                      color: AppColors.success),
                  _GridStat(
                      icon: Icons.undo_outlined,
                      label: 'Total Returns',
                      value: '${vm.totalReturns} pcs',
                      color: AppColors.warning),
                  _GridStat(
                      icon: Icons.payments_outlined,
                      label: 'Remitted',
                      value: formatCurrency(vm.totalActualRemittance),
                      color: AppColors.seller),
                  _GridStat(
                      icon: Icons.calendar_today_outlined,
                      label: 'Days Active',
                      value: '${vm.daysRemitted} days',
                      color: const Color(0xFF1976D2)),
                ],
              ),

              const SizedBox(height: 16),
              const _SectionLabel('WEEKLY BREAKDOWN'),
              const SizedBox(height: 12),

              // ── 4-week breakdown ───────────────────────────
              ...vm.weeklySummaries.asMap().entries.map((e) =>
                  _WeekSummaryRow(
                    index:   e.key,
                    summary: e.value,
                    isLast:  e.key == vm.weeklySummaries.length - 1,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Monthly hero ──────────────────────────────────────────────
class _MonthlyHeroCard extends StatelessWidget {
  final SellerRemittanceViewModel vm;
  const _MonthlyHeroCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.seller,
              AppColors.seller.withValues(alpha: 0.70),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.seller.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(children: [
          const Text('TOTAL MONTHLY REMITTANCE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(
            formatCurrency(vm.totalActualRemittance),
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
                const Icon(Icons.sell_outlined,
                    size: 13, color: Colors.white70),
                const SizedBox(width: 6),
                Text('${vm.totalPiecesSold} pieces sold',
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

// ── Grid stat ─────────────────────────────────────────────────
class _GridStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _GridStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
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

// ── Week summary row ──────────────────────────────────────────
class _WeekSummaryRow extends StatelessWidget {
  final int    index;
  final dynamic summary; // _WeeklySummary
  final bool   isLast;
  const _WeekSummaryRow({
    required this.index,
    required this.summary,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLast
                ? AppColors.seller.withValues(alpha: 0.20)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isLast
                  ? AppColors.seller.withValues(alpha: 0.10)
                  : AppColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text('W${index + 1}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isLast
                        ? AppColors.seller
                        : AppColors.textHint)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.weekStart.isNotEmpty
                      ? '${summary.weekStart} – ${summary.weekEnd}'
                      : '— –– —',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text),
                ),
                if (summary.days > 0)
                  Text(
                    '${summary.days} days · ${summary.piecesSold} pieces sold',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
              ],
            ),
          ),
          Text(
            summary.totalRemittance > 0
                ? formatCurrency(summary.totalRemittance)
                : '₱0.00',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: summary.totalRemittance > 0
                    ? AppColors.primaryDark
                    : AppColors.textHint),
          ),
        ]),
      );
}

// ── Shared widgets ─────────────────────────────────────────────
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
              color: AppColors.seller,
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

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.seller, strokeWidth: 2.5),
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