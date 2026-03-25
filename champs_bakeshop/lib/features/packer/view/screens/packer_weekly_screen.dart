import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/packer_salary_viewmodel.dart';

class PackerWeeklyScreen extends StatefulWidget {
  const PackerWeeklyScreen({super.key});

  @override
  State<PackerWeeklyScreen> createState() => _PackerWeeklyScreenState();
}

class _PackerWeeklyScreenState extends State<PackerWeeklyScreen> {
  String? _expandedDate;

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<PackerSalaryViewModel>();
    final uid = context.read<AuthViewModel>().currentUser!.id;

    return RefreshIndicator(
      color: AppColors.packer,
      onRefresh: () async {
        setState(() => _expandedDate = null);
        await vm.init(uid);
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

            // ── Week navigator ─────────────────────────────────
            _WeekNav(
              weekStartDisplay: vm.weekStartDisplay,
              weekEndDisplay:   vm.weekEndDisplay,
              todayDisplay:     vm.todayDisplay,
              isCurrentWeek:    vm.isCurrentWeek,
              onPrev: () {
                setState(() => _expandedDate = null);
                vm.changeWeek(-1, uid);
              },
              onNext: () {
                setState(() => _expandedDate = null);
                vm.changeWeek(1, uid);
              },
              onPickDate: (picked) {
                setState(() => _expandedDate = null);
                vm.goToDate(picked, uid);
              },
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
              const SizedBox(height: 14),
              const _SectionLabel('DAILY BREAKDOWN'),
              const SizedBox(height: 4),
              Text(
                'Tap a day to see product details',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 10),
              if (vm.dailyEntries.isEmpty)
                _EmptyCard(
                  icon: Icons.receipt_long_outlined,
                  message: 'No records for this week',
                )
              else
                ...vm.dailyEntries.map((e) => _ExpandableDayCard(
                      entry:      e,
                      isExpanded: _expandedDate == e.date,
                      onTap: () => setState(() {
                        _expandedDate =
                            _expandedDate == e.date ? null : e.date;
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
//  WEEK NAVIGATOR  (single pill — prev | 📅 date | next)
// ══════════════════════════════════════════════════════════════
class _WeekNav extends StatelessWidget {
  final String              weekStartDisplay;
  final String              weekEndDisplay;
  final String              todayDisplay;
  final bool                isCurrentWeek;
  final VoidCallback        onPrev;
  final VoidCallback        onNext;
  final ValueChanged<DateTime>? onPickDate;

  const _WeekNav({
    required this.weekStartDisplay,
    required this.weekEndDisplay,
    required this.todayDisplay,
    required this.isCurrentWeek,
    required this.onPrev,
    required this.onNext,
    this.onPickDate,
  });

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: DateTime.now(),
      firstDate:   DateTime(2020),
      lastDate:    DateTime(2099),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary:   AppColors.packer,
            onPrimary: Colors.white,
            surface:   Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPickDate?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Single pill: [ < | 📅 date range | > ] ─────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.packer.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.packer.withValues(alpha: 0.25),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color:      AppColors.packer.withValues(alpha: 0.05),
                blurRadius: 8,
                offset:     const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ◀ Prev
              _PillArrow(icon: Icons.chevron_left_rounded, onTap: onPrev),

              // Divider
              Container(
                width: 1, height: 24,
                color: AppColors.packer.withValues(alpha: 0.15),
              ),

              // Centre — tappable to open date picker
              Expanded(
                child: GestureDetector(
                  onTap: () => _openPicker(context),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size:  15,
                          color: AppColors.packer.withValues(alpha: 0.80),
                        ),
                        const SizedBox(width: 7),
                        // "THIS WEEK" badge when on current week
                        if (isCurrentWeek) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.packer
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'THIS WEEK',
                              style: TextStyle(
                                fontSize:   8,
                                fontWeight: FontWeight.w800,
                                color:      AppColors.packer,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '$weekStartDisplay — $weekEndDisplay',
                          style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                            color:      AppColors.packer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Divider
              Container(
                width: 1, height: 24,
                color: AppColors.packer.withValues(alpha: 0.15),
              ),

              // ▶ Next
              _PillArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Arrow inside the pill ─────────────────────────────────────
class _PillArrow extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _PillArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width:  44,
          height: 44,
          child: Icon(icon, size: 20, color: AppColors.packer),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  EXPANDABLE DAY CARD
// ══════════════════════════════════════════════════════════════
class _ExpandableDayCard extends StatelessWidget {
  final PackerDailyEntry entry;
  final bool             isExpanded;
  final VoidCallback     onTap;

  const _ExpandableDayCard({
    required this.entry,
    required this.isExpanded,
    required this.onTap,
  });

  Map<String, int> get _byProduct {
    final map = <String, int>{};
    for (final p in entry.productions) {
      map[p.productName] = (map[p.productName] ?? 0) + p.bundleCount;
    }
    return map;
  }

  String _formatTime(String ts) {
    try {
      final dt = DateTime.parse(ts);
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts.length >= 16 ? ts.substring(11, 16) : '';
    }
  }

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
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? AppColors.packer
                        : AppColors.packer.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.date.substring(8),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isExpanded
                            ? Colors.white
                            : AppColors.packer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${entry.productions.length} entr${entry.productions.length == 1 ? 'y' : 'ies'} · ${entry.totalBundles} bundles',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(entry.salary),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.packer,
                    ),
                  ],
                ),
              ]),
            ),
          ),

          if (isExpanded) ...[
            Container(
              height: 1,
              color: AppColors.packer.withValues(alpha: 0.12),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 13, color: AppColors.packer),
                    const SizedBox(width: 6),
                    Text(
                      'PRODUCT BREAKDOWN',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.packer.withValues(alpha: 0.8),
                          letterSpacing: 0.8),
                    ),
                  ]),
                  const SizedBox(height: 10),

                  ..._byProduct.entries.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.packer.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.packer
                                  .withValues(alpha: 0.12)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: AppColors.packer,
                                shape: BoxShape.circle),
                          ),
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

                  const SizedBox(height: 8),
                  Container(height: 1,
                      color: AppColors.packer.withValues(alpha: 0.10)),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.packer,
                          AppColors.packer.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Daily Total',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '${entry.totalBundles} bundles × ₱4.00',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                        Text(
                          formatCurrency(entry.salary),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(children: [
                    const Icon(Icons.access_time,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(
                      'ENTRY LOG',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHint.withValues(alpha: 0.8),
                          letterSpacing: 0.8),
                    ),
                  ]),
                  const SizedBox(height: 8),

                  ...entry.productions.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          const SizedBox(width: 4),
                          const Icon(Icons.fiber_manual_record,
                              size: 6, color: AppColors.textHint),
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
                          const SizedBox(width: 10),
                          Text(
                            _formatTime(p.timestamp),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint),
                          ),
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
                      label:     'Gross',
                      value:     formatCurrency(vm.grossSalary),
                      bgColor:   Colors.white.withValues(alpha: 0.15),
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    _Pill(
                      label:     '-Vale',
                      value:     vm.valeDeduction > 0
                          ? formatCurrency(vm.valeDeduction)
                          : '₱0.00',
                      bgColor:   Colors.red.withValues(alpha: 0.25),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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