import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/production_model.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';

import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/baker_production_viewmodel.dart';

class BakerHistoryScreen extends StatefulWidget {
  const BakerHistoryScreen({super.key});

  @override
  State<BakerHistoryScreen> createState() => _BakerHistoryScreenState();
}

class _BakerHistoryScreenState extends State<BakerHistoryScreen> {
  String _search      = '';
  int    _visibleCount = 20;

  static const int _pageSize = 20;

  Future<void> _deleteRecord(
      BakerProductionViewModel vm, String productionId) async {
    final userId =
        context.read<AuthViewModel>().currentUser?.id ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Production?',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text(
            'This will permanently remove the production record and its bonus entries.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await vm.deleteProduction(productionId, userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(ok ? Icons.check_circle : Icons.error_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(ok ? 'Record deleted.' : 'Delete failed. Try again.'),
        ]),
        backgroundColor: ok ? AppColors.danger : AppColors.textHint,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerProductionViewModel>();

    final filtered = vm.productions.where((p) {
      if (_search.isEmpty) return true;
      return p.date.contains(_search);
    }).toList();

    final visible = filtered.take(_visibleCount).toList();

    return ColoredBox(
      color: const Color(0xFFF8F7F5),
      child: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Production History',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(
                  '${vm.productions.length} total records',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 12),
                // Search bar
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (v) =>
                        setState(() { _search = v; _visibleCount = _pageSize; }),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search by date (e.g. 2026-03)',
                      hintStyle: TextStyle(
                          fontSize: 13, color: AppColors.textHint),
                      prefixIcon: Icon(Icons.search,
                          size: 18, color: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: vm.productions.isEmpty
                ? _EmptyHistory()
                : filtered.isEmpty
                    ? _NoResults(query: _search)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            14, 14, 14, 32),
                        itemCount: visible.length +
                            (filtered.length > _visibleCount ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == visible.length) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: TextButton(
                                onPressed: () => setState(() =>
                                    _visibleCount += _pageSize),
                                child: Text(
                                  'Load more (${filtered.length - _visibleCount} remaining)',
                                  style: const TextStyle(
                                      color: AppColors.masterBaker,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            );
                          }
                          final prod = visible[i];
                          final calc = vm.computeDaily(prod);
                          return _HistoryCard(
                            prod: prod,
                            calc: calc,
                            vm: vm,
                            index: i,
                            onDelete: () =>
                                _deleteRecord(vm, prod.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  HISTORY CARD
// ─────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final ProductionModel prod;
  final dynamic calc;
  final BakerProductionViewModel vm;
  final int index;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.prod,
    required this.calc,
    required this.vm,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalEarnings =
        (calc.salaryPerWorker as double) + (calc.bakerIncentive as double);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 40),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(0, 16 * (1 - v)), child: child),
      ),
      child: GestureDetector(
        onTap: () => _showPreviewSheet(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Card header ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(children: [
                  // Date icon block
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.masterBaker
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bakery_dining_outlined,
                        color: AppColors.masterBaker, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(prod.date,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.text,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text(
                          '${prod.totalWorkers} workers  ·  ${prod.totalSacks} sacks'
                          '${prod.totalExtraKg > 0 ? ' + ${prod.totalExtraKg} kg' : ''}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                  // Edit button
                  _IconBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    onTap: () => _openEditSheet(context),
                  ),
                  const SizedBox(width: 6),
                  // Delete button
                  _IconBtn(
                    icon: Icons.delete_outline,
                    color: AppColors.danger,
                    onTap: onDelete,
                  ),
                ]),
              ),

              // ── Divider ─────────────────────────────────────
              const Divider(height: 1, color: Color(0xFFF0EDE8)),

              // ── Stats row ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(children: [
                  _StatPill(
                    label: 'Value',
                    value: formatCurrency(calc.totalValue as double),
                    color: AppColors.masterBaker,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    label: 'Incentive',
                    value: formatCurrency(calc.bakerIncentive as double),
                    color: const Color(0xFF1976D2),
                  ),
                  const Spacer(),
                  // Earnings highlight
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Your Earnings',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 1),
                      Text(
                        formatCurrency(totalEarnings),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.primaryDark,
                            letterSpacing: -0.4),
                      ),
                    ],
                  ),
                ]),
              ),

              // ── Helper chips ─────────────────────────────────
              if (prod.helperIds.isNotEmpty) ...[
                const Divider(height: 1, color: Color(0xFFF0EDE8)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(children: [
                    const Icon(Icons.people_outline,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: prod.helperIds.map((hId) {
                          final h = vm.helpers
                              .where((u) => u.id == hId)
                              .firstOrNull;
                          return _HelperChip(
                              name: h?.name ?? 'Helper');
                        }).toList(),
                      ),
                    ),
                  ]),
                ),
              ],

              // ── Tap hint ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.masterBaker
                      .withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('View full details',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.masterBaker
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 3),
                    Icon(Icons.keyboard_arrow_down,
                        size: 14,
                        color: AppColors.masterBaker
                            .withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProductionSheet(prod: prod, vm: vm),
    );
  }

  void _showPreviewSheet(BuildContext context) {
    final totalEarnings =
        (calc.salaryPerWorker as double) + (calc.bakerIncentive as double);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),

            // Header
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
                      Text(prod.date,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              letterSpacing: -0.3)),
                      const Text('Production Detail',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint)),
                    ],
                  ),
                ),
                // Edit shortcut
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _openEditSheet(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary
                              .withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 13, color: AppColors.primary),
                          SizedBox(width: 5),
                          Text('Edit',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ]),
                  ),
                ),
              ]),
            ),

            const Divider(height: 20, color: AppColors.border),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [

                  // Production Summary
                  _SheetCard(children: [
                    const _SheetLabel('PRODUCTION SUMMARY'),
                    const SizedBox(height: 12),
                    _SheetRow(
                      icon: Icons.groups_outlined,
                      label: 'Total Workers',
                      value: '${prod.totalWorkers}',
                    ),
                    _SheetRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Total Sacks',
                      value: prod.totalExtraKg > 0
                          ? '${prod.totalSacks} sacks + ${prod.totalExtraKg} kg'
                          : '${prod.totalSacks} sacks',
                    ),
                    _SheetRow(
                      icon: Icons.attach_money,
                      label: 'Batch Value',
                      value: formatCurrency(calc.totalValue as double),
                      valueColor: AppColors.masterBaker,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Salary Breakdown
                  _SheetCard(children: [
                    const _SheetLabel('SALARY BREAKDOWN'),
                    const SizedBox(height: 12),
                    _SheetRow(
                      icon: Icons.people_outline,
                      label: 'Per Worker (base)',
                      value: formatCurrency(
                          calc.salaryPerWorker as double),
                    ),
                    if ((calc.bakerIncentive as double) > 0)
                      _SheetRow(
                        icon: Icons.star_outline,
                        label: 'Baker Incentive',
                        value: formatCurrency(
                            calc.bakerIncentive as double),
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
                          formatCurrency(totalEarnings),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: AppColors.primaryDark,
                              letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Helpers
                  if (prod.helperIds.isNotEmpty) ...[
                    _SheetCard(children: [
                      const _SheetLabel('HELPERS ASSIGNED'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: prod.helperIds.map((hId) {
                          final h = vm.helpers
                              .where((u) => u.id == hId)
                              .firstOrNull;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.07),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.15)),
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                      Icons.person_outline,
                                      size: 13,
                                      color: AppColors.primary),
                                  const SizedBox(width: 5),
                                  Text(h?.name ?? 'Helper',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600,
                                          color:
                                              AppColors.primary)),
                                ]),
                          );
                        }).toList(),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],

                  // Products breakdown
                  _SheetCard(children: [
                    const _SheetLabel('PRODUCTS PRODUCED'),
                    const SizedBox(height: 12),
                    ...prod.items.map((item) {
                      final p = vm.products
                          .where((x) => x.id == item.productId)
                          .firstOrNull;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.masterBaker
                                  .withValues(alpha: 0.07),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.bakery_dining_outlined,
                                size: 14,
                                color: AppColors.masterBaker),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              p?.name ?? 'Unknown Product',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.masterBaker
                                  .withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.extraKg > 0
                                  ? '${item.sacks} sacks + ${item.extraKg} kg'
                                  : '${item.sacks} sacks',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.masterBaker),
                            ),
                          ),
                        ]),
                      );
                    }),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
            const SizedBox(height: 1),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      );
}

class _HelperChip extends StatelessWidget {
  final String name;
  const _HelperChip({required this.name});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Text(name,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  SHEET SUB-WIDGETS
// ─────────────────────────────────────────────────────────

class _SheetCard extends StatelessWidget {
  final List<Widget> children;
  const _SheetCard({required this.children});

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

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
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

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _SheetRow({
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

// ─────────────────────────────────────────────────────────
//  EMPTY STATES
// ─────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.masterBaker.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined,
                  size: 44, color: AppColors.masterBaker),
            ),
            const SizedBox(height: 16),
            const Text('No productions yet',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.text)),
            const SizedBox(height: 6),
            const Text('Your production records will appear here',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textHint)),
          ],
        ),
      );
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined,
                size: 44, color: AppColors.textHint),
            const SizedBox(height: 14),
            Text('No results for "$query"',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.text)),
            const SizedBox(height: 6),
            const Text('Try a different date format',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textHint)),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EDIT SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _EditProductionSheet extends StatefulWidget {
  final ProductionModel prod;
  final BakerProductionViewModel vm;
  const _EditProductionSheet(
      {required this.prod, required this.vm});

  @override
  State<_EditProductionSheet> createState() =>
      _EditProductionSheetState();
}

class _EditProductionSheetState extends State<_EditProductionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late List<_EditItemEntry> _items;
  late List<String> _helperIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _items = widget.prod.items
        .map((i) => _EditItemEntry(
              productId: i.productId,
              sacksCtrl: TextEditingController(
                  text: i.sacks.toString()),
              kgCtrl: TextEditingController(
                  text: i.extraKg > 0 ? i.extraKg.toString() : ''),
            ))
        .toList();
    _helperIds = List<String>.from(widget.prod.helperIds);
  }

  @override
  void dispose() {
    for (final e in _items) {
      e.dispose();
    }
    _tab.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_items.isEmpty) return 'Add at least one product.';
    for (final e in _items) {
      if (e.productId == null) return 'Select a product for every row.';
      final s = int.tryParse(e.sacksCtrl.text.trim()) ?? 0;
      final k = int.tryParse(e.kgCtrl.text.trim()) ?? 0;
      if (s <= 0 && k <= 0)
        return 'Sacks or KG must be > 0 for each row.';
    }
    final ids = _items.map((e) => e.productId).toList();
    if (ids.toSet().length != ids.length)
      return 'Duplicate products found.';
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _isSaving = true);
    final updatedItems = _items
        .map((e) => ProductionItem(
              productId: e.productId!,
              sacks: int.tryParse(e.sacksCtrl.text.trim()) ?? 0,
              extraKg: (int.tryParse(e.kgCtrl.text.trim()) ?? 0)
                  .clamp(0, 24),
            ))
        .toList();
    final updated = widget.prod
        .copyWith(items: updatedItems, helperIds: _helperIds);
    final ok = await widget.vm.updateProduction(updated);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
              ok ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 18),
          const SizedBox(width: 8),
          Text(ok ? 'Production updated!' : 'Failed. Try again.'),
        ]),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  Widget _buildProductsTab() {
    final allProducts = widget.vm.products;
    return Column(children: [
      Expanded(
        child: _items.isEmpty
            ? const Center(
                child: Text('No products. Tap + Add.',
                    style: TextStyle(
                        color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final entry = _items[i];
                  final usedIds = _items
                      .where((e) => e != entry && e.productId != null)
                      .map((e) => e.productId!)
                      .toSet();
                  final dropdownItems = allProducts
                      .where((p) => !usedIds.contains(p.id))
                      .toList();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: entry.productId,
                              hint: const Text('Select product',
                                  style:
                                      TextStyle(fontSize: 13)),
                              isExpanded: true,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500),
                              items: dropdownItems
                                  .map((p) => DropdownMenuItem(
                                        value: p.id,
                                        child: Text(p.name),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(
                                  () => entry.productId = val),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            _CounterButton(
                              icon: Icons.remove,
                              onTap: () {
                                final v = int.tryParse(
                                        entry.sacksCtrl.text) ??
                                    0;
                                if (v > 0)
                                  setState(() => entry
                                      .sacksCtrl.text =
                                      (v - 1).toString());
                              },
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 52,
                              child: TextField(
                                controller: entry.sacksCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: 'Sacks',
                                  labelStyle: const TextStyle(
                                      fontSize: 9),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              8)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _CounterButton(
                              icon: Icons.add,
                              onTap: () {
                                final v = int.tryParse(
                                        entry.sacksCtrl.text) ??
                                    0;
                                setState(() => entry.sacksCtrl
                                    .text = (v + 1).toString());
                              },
                            ),
                            const SizedBox(width: 12),
                            Text('+',
                                style: TextStyle(
                                    color: AppColors.textHint,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 62,
                              child: TextField(
                                controller: entry.kgCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: 'KG (0–24)',
                                  labelStyle: const TextStyle(
                                      fontSize: 9),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              8)),
                                ),
                                onChanged: (v) {
                                  if ((int.tryParse(v) ?? 0) > 24)
                                    entry.kgCtrl.text = '24';
                                  setState(() {});
                                },
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() {
                                entry.dispose();
                                _items.removeAt(i);
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.red.shade400),
                              ),
                            ),
                          ]),
                        ]),
                  );
                },
              ),
      ),
      if (_items.length < allProducts.length)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(
                  () => _items.add(_EditItemEntry(
                        productId: null,
                        sacksCtrl:
                            TextEditingController(text: '0'),
                        kgCtrl: TextEditingController(),
                      ))),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Product'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color:
                        AppColors.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _buildHelpersTab() {
    final allHelpers = widget.vm.helpers;
    if (allHelpers.isEmpty) {
      return const Center(
          child: Text('No helpers available.',
              style:
                  TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: allHelpers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final helper = allHelpers[i];
        final selected = _helperIds.contains(helper.id);
        return InkWell(
          onTap: () => setState(() => selected
              ? _helperIds.remove(helper.id)
              : _helperIds.add(helper.id)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: selected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.grey.shade200,
                child: Text(
                  helper.name.isNotEmpty
                      ? helper.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: selected
                          ? AppColors.primary
                          : Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(helper.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selected
                              ? AppColors.primary
                              : Colors.black87))),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? const Icon(Icons.check_circle_rounded,
                        key: ValueKey('chk'),
                        color: AppColors.primary,
                        size: 22)
                    : Icon(Icons.radio_button_unchecked,
                        key: const ValueKey('empty'),
                        color: Colors.grey.shade400,
                        size: 22),
              ),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;

    final previewItems = _items
        .where((e) => e.productId != null)
        .map((e) => ProductionItem(
              productId: e.productId!,
              sacks: int.tryParse(e.sacksCtrl.text) ?? 0,
              extraKg:
                  (int.tryParse(e.kgCtrl.text) ?? 0).clamp(0, 24),
            ))
        .toList();
    final preview =
        widget.vm.previewSalary(previewItems, _helperIds.length);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      height: screenH * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding:
          EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
      child: Column(children: [
        // Handle
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),

        // Title
        Row(children: [
          const Icon(Icons.edit_calendar_outlined,
              size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Edit — ${widget.prod.date}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
        const SizedBox(height: 12),

        // Tab bar
        Container(
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10)),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8)),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 15),
                      const SizedBox(width: 6),
                      const Text('Products'),
                      if (_items.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _Badge('${_items.length}'),
                      ],
                    ]),
              ),
              Tab(
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 15),
                      const SizedBox(width: 6),
                      const Text('Helpers'),
                      if (_helperIds.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _Badge('${_helperIds.length}'),
                      ],
                    ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildProductsTab(),
              _buildHelpersTab()
            ],
          ),
        ),

        // Live preview bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                _PreviewStat(
                    'Total Value',
                    formatCurrency(preview.totalValue)),
                _Divider(),
                _PreviewStat('Sacks',
                    '${preview.totalSacks}${preview.totalExtraKg > 0 ? '+${preview.totalExtraKg}kg' : ''}'),
                _Divider(),
                _PreviewStat(
                    'Workers', '${preview.totalWorkers}'),
                _Divider(),
                _PreviewStat(
                    'Your Salary',
                    formatCurrency(preview.salaryPerWorker +
                        preview.bakerIncentive),
                    highlight: true),
              ]),
        ),

        // Action buttons
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white))
                  : const Text('Save Changes',
                      style: TextStyle(
                          fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  EDIT SHEET HELPERS
// ─────────────────────────────────────────────────────────

class _EditItemEntry {
  String? productId;
  final TextEditingController sacksCtrl;
  final TextEditingController kgCtrl;

  _EditItemEntry({
    required this.productId,
    required this.sacksCtrl,
    required this.kgCtrl,
  });

  void dispose() {
    sacksCtrl.dispose();
    kgCtrl.dispose();
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CounterButton(
      {required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Icon(icon, size: 15, color: AppColors.primary),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _PreviewStat(this.label, this.value,
      {this.highlight = false});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: highlight
                    ? AppColors.success
                    : Colors.black87)),
      ]);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 30, color: AppColors.border);
}