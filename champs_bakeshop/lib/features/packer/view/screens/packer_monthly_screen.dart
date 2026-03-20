import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/packer_salary_viewmodel.dart';

class PackerMonthlyScreen extends StatefulWidget {
  const PackerMonthlyScreen({super.key});

  @override
  State<PackerMonthlyScreen> createState() =>
      _PackerMonthlyScreenState();
}

class _PackerMonthlyScreenState extends State<PackerMonthlyScreen> {
  /// Which week index is expanded (null = none)
  int? _expandedWeek;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthViewModel>().currentUser!.id;
      context.read<PackerSalaryViewModel>().loadMonthly(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<PackerSalaryViewModel>();
    final uid = context.read<AuthViewModel>().currentUser!.id;

    return RefreshIndicator(
      color: AppColors.packer,
      onRefresh: () async {
        setState(() => _expandedWeek = null);
        await vm.loadMonthly(uid);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: 'Monthly Summary',
              subtitle: '4-week earnings overview',
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
                      icon:  Icons.inventory_2_outlined,
                      label: 'Total Bundles',
                      value: '${vm.totalBundles}',
                      color: AppColors.packer),
                  _GridStat(
                      icon:  Icons.calendar_today_outlined,
                      label: 'Days Worked',
                      value: '${vm.daysWorked}',
                      color: const Color(0xFF1976D2)),
                  _GridStat(
                      icon:  Icons.wallet_outlined,
                      label: 'Gross Salary',
                      value: formatCurrency(vm.grossSalary),
                      color: AppColors.success),
                  _GridStat(
                      icon:  Icons.remove_circle_outline,
                      label: 'Vale Deduction',
                      value: '-${formatCurrency(vm.valeDeduction)}',
                      color: AppColors.danger),
                ],
              ),

              const SizedBox(height: 16),
              const _SectionLabel('WEEKLY BREAKDOWN'),
              const SizedBox(height: 4),
              Text(
                'Tap a week to see details',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 10),

              // ── 4-week expandable rows ─────────────────────
              ...vm.weeklySummaries.asMap().entries.map((e) =>
                  _ExpandableWeekRow(
                    index:      e.key,
                    summary:    e.value,
                    isExpanded: _expandedWeek == e.key,
                    onTap: () => setState(() {
                      _expandedWeek =
                          _expandedWeek == e.key ? null : e.key;
                    }),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  EXPANDABLE WEEK ROW
// ══════════════════════════════════════════════════════════════
class _ExpandableWeekRow extends StatelessWidget {
  final int                index;
  final PackerWeeklySummary summary;
  final bool               isExpanded;
  final VoidCallback       onTap;

  const _ExpandableWeekRow({
    required this.index,
    required this.summary,
    required this.isExpanded,
    required this.onTap,
  });

  /// Group daily entries by product → {productName: totalBundles}
  Map<String, int> get _byProduct {
    final map = <String, int>{};
    for (final day in summary.dailyEntries) {
      for (final prod in day.productions) {
        map[prod.productName] =
            (map[prod.productName] ?? 0) + prod.bundleCount;
      }
    }
    return map;
  }

  bool get _hasData => summary.grossSalary > 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? AppColors.packer.withValues(alpha: 0.40)
              : _hasData
                  ? AppColors.packer.withValues(alpha: 0.15)
                  : AppColors.border,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: isExpanded
                  ? AppColors.packer.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ─────────────────────────────────────
          InkWell(
            onTap: _hasData ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              child: Row(children: [
                // Week badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? AppColors.packer
                        : _hasData
                            ? AppColors.packer.withValues(alpha: 0.10)
                            : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text('W${index + 1}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isExpanded
                              ? Colors.white
                              : _hasData
                                  ? AppColors.packer
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
                      if (_hasData)
                        Text(
                          '${summary.days} days · ${summary.bundles} bundles',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _hasData
                          ? formatCurrency(summary.grossSalary)
                          : '₱0.00',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _hasData
                              ? AppColors.primaryDark
                              : AppColors.textHint),
                    ),
                    if (_hasData) ...[
                      const SizedBox(height: 4),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.packer,
                      ),
                    ],
                  ],
                ),
              ]),
            ),
          ),

          // ── Expanded content ───────────────────────────────
          if (isExpanded && _hasData) ...[
            Container(
                height: 1,
                color: AppColors.packer.withValues(alpha: 0.12)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Product breakdown ────────────────────
                  Row(children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 13, color: AppColors.packer),
                    const SizedBox(width: 6),
                    Text('PRODUCT BREAKDOWN',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.packer
                                .withValues(alpha: 0.8),
                            letterSpacing: 0.8)),
                  ]),
                  const SizedBox(height: 10),

                  if (_byProduct.isEmpty)
                    const Text('No product data',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint))
                  else
                    ..._byProduct.entries.map((e) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.packer
                                .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.packer
                                    .withValues(alpha: 0.12)),
                          ),
                          child: Row(children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: AppColors.packer,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(e.key,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text)),
                            ),
                            Text('${e.value} bundles',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.packer)),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(e.value * 4.0),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success),
                            ),
                          ]),
                        )),

                  const SizedBox(height: 10),
                  Container(
                      height: 1,
                      color: AppColors.packer.withValues(alpha: 0.10)),
                  const SizedBox(height: 10),

                  // ── Weekly total card ────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.packer,
                          AppColors.packer.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Week Total',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '${summary.bundles} bundles × ₱4.00',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70),
                            ),
                          ],
                        ),
                        Text(
                          formatCurrency(summary.grossSalary),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Per-day breakdown ────────────────────
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text('DAILY BREAKDOWN',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHint
                                .withValues(alpha: 0.8),
                            letterSpacing: 0.8)),
                  ]),
                  const SizedBox(height: 8),

                  ...summary.dailyEntries.map((day) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F4F0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.packer
                                  .withValues(alpha: 0.10),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              day.date.substring(8),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.packer),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(_formatDate(day.date),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text)),
                                Text(
                                    '${day.totalBundles} bundles',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color:
                                            AppColors.textHint)),
                              ],
                            ),
                          ),
                          Text(formatCurrency(day.salary),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark)),
                        ]),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ── Monthly hero ──────────────────────────────────────────────
class _MonthlyHeroCard extends StatelessWidget {
  final PackerSalaryViewModel vm;
  const _MonthlyHeroCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.packer,
              AppColors.packer.withValues(alpha: 0.70),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.packer.withValues(alpha: 0.28),
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
            formatCurrency(vm.grossSalary),
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
                const Icon(Icons.inventory_2_outlined,
                    size: 13, color: Colors.white70),
                const SizedBox(width: 6),
                Text('${vm.totalBundles} total bundles',
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