part of 'baker_salary_screen.dart';

// ══════════════════════════════════════════════════════════════
//  DAILY TAB
// ══════════════════════════════════════════════════════════════
class _DailyTab extends StatelessWidget {
  final String userId;
  const _DailyTab({required this.userId});

  // ── Production Preview Bottom Sheet ────────────────────────
  void _showPreviewSheet(BuildContext context, BakerDailyEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.60,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // ── Handle ────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),

            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.masterBaker
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.masterBaker, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.date,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              letterSpacing: -0.3)),
                      const Text('Daily Production Detail',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint)),
                    ],
                  ),
                ),
                // Baker badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.masterBaker
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.masterBaker
                            .withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Text('👨‍🍳', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text('Baker',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.masterBaker)),
                  ]),
                ),
              ]),
            ),

            const Divider(height: 20, color: AppColors.border),

            // ── Content ───────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Salary breakdown card ──────────────────
                  _PreviewCard(children: [
                    const _PreviewCardLabel('SALARY BREAKDOWN'),
                    const SizedBox(height: 12),
                    _PreviewDataRow(
                      icon: Icons.people_outline,
                      label: 'Base (per worker)',
                      value: formatCurrency(entry.baseOnly),
                      valueColor: AppColors.masterBaker,
                    ),
                    if (entry.bakerIncentive > 0)
                      _PreviewDataRow(
                        icon: Icons.star_half_outlined,
                        label: 'Baker Incentive',
                        value: formatCurrency(entry.bakerIncentive),
                        valueColor: const Color(0xFF1976D2),
                      ),
                    const Divider(
                        height: 20, color: AppColors.border),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Earnings',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.text)),
                        Text(
                          formatCurrency(entry.baseSalary),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── Incentive info card (if applicable) ────
                  if (entry.bakerIncentive > 0) ...[
                    _PreviewCard(children: [
                      const _PreviewCardLabel('BAKER INCENTIVE INFO'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.masterBaker
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.masterBaker
                                  .withValues(alpha: 0.15)),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.masterBaker
                                  .withValues(alpha: 0.10),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.masterBaker),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '₱100 per effective sack — included in your salary total above.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppColors.textSecondary),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],

                  // ── Bonus card ─────────────────────────────
                  if (entry.bonus > 0) ...[
                    _PreviewCard(children: [
                      const _PreviewCardLabel(
                          'BONUS (PAID SEPARATELY)'),
                      const SizedBox(height: 12),
                      _PreviewDataRow(
                        icon: Icons.card_giftcard_outlined,
                        label: 'Sack Bonus',
                        value: formatCurrency(entry.bonus),
                        valueColor: AppColors.masterBaker,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.amber.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline,
                              size: 14,
                              color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bonus is paid separately and is not included in your take-home payroll total.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade800),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],

                  // ── Status card ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success
                          .withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.success
                              .withValues(alpha: 0.15)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                            size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Production Recorded',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.success)),
                            const SizedBox(height: 2),
                            Text(
                              'This production day has been recorded and is included in your weekly salary.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success
                                      .withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

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
              _DailySummaryCard(vm: vm),
              const SizedBox(height: 16),
              const _SectionLabel('RECORDS'),
              const SizedBox(height: 10),
              if (vm.dailyEntries.isEmpty)
                _EmptyCard(
                  icon: Icons.receipt_long_outlined,
                  message: 'No records for this period',
                )
              else
                ...vm.dailyEntries.asMap().entries.map((e) =>
                    _DailyEntryCard(
                      entry: e.value,
                      index: e.key,
                      onTap: () =>
                          _showPreviewSheet(context, e.value),
                    )),
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

// ── Daily entry card (now tappable) ──────────────────────────
class _DailyEntryCard extends StatelessWidget {
  final BakerDailyEntry entry;
  final int index;
  final VoidCallback onTap;
  const _DailyEntryCard({
    required this.entry,
    required this.index,
    required this.onTap,
  });

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
      child: GestureDetector(
        onTap: onTap,
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
                color: AppColors.masterBaker.withValues(alpha: 0.08),
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
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          AppColors.success.withValues(alpha: 0.08),
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
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 14,
                      color: AppColors.textHint
                          .withValues(alpha: 0.6)),
                ]),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PREVIEW SHEET SUB-WIDGETS
// ─────────────────────────────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  final List<Widget> children;
  const _PreviewCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            children: children),
      );
}

class _PreviewCardLabel extends StatelessWidget {
  final String text;
  const _PreviewCardLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
              color: AppColors.masterBaker,
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

class _PreviewDataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _PreviewDataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textHint)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.text)),
        ]),
      );
}