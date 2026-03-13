import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/production_model.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/baker_production_viewmodel.dart';

class BakerHistoryScreen extends StatelessWidget {
  const BakerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerProductionViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(
            title: 'My Productions', subtitle: 'Your production history'),
        if (vm.productions.isEmpty)
          const EmptyState(message: 'No productions yet')
        else
          ...vm.productions.map((prod) {
            final calc = vm.computeDaily(prod);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ────────────────────────────────────────────
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(prod.date,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            Row(children: [
                              // Total value badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  formatCurrency(calc.totalValue),
                                  style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Edit button
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () =>
                                    _openEditSheet(context, vm, prod),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.edit_outlined,
                                      size: 16, color: AppColors.primary),
                                ),
                              ),
                            ]),
                          ]),

                      const SizedBox(height: 8),

                      // ── Salary line (base + incentive, no bonus) ──────────
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'Salary: '),
                            TextSpan(
                              text: formatCurrency(calc.salaryPerWorker + calc.bakerIncentive),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87),
                            ),
                            if (calc.bakerIncentive > 0)
                              TextSpan(
                                text: ' (${formatCurrency(calc.salaryPerWorker)} + ${formatCurrency(calc.bakerIncentive)} incentive)',
                                style: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                      ),

                      // ── Bonus line (separate) ─────────────────────────────
                      if (calc.bonusPerWorker > 0) ...[
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                            children: [
                              const TextSpan(text: 'Bonus: '),
                              TextSpan(
                                text: formatCurrency(calc.bonusPerWorker),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.masterBaker),
                              ),
                              TextSpan(
                                text:
                                    ' (shared ÷ ${calc.totalWorkers} workers — paid separately)',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Sacks summary ─────────────────────────────────────
                      if (prod.totalSacks > 0 || prod.totalExtraKg > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          prod.totalExtraKg > 0
                              ? '${prod.totalSacks} sacks + ${prod.totalExtraKg} kg  •  ${prod.totalWorkers} workers'
                              : '${prod.totalSacks} sacks  •  ${prod.totalWorkers} workers',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // ── Helper chips ──────────────────────────────────────
                      if (prod.helperIds.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          children: prod.helperIds.map((hId) {
                            final h = vm.helpers
                                .where((u) => u.id == hId)
                                .firstOrNull;
                            return Chip(
                              avatar: const Icon(Icons.person_outline,
                                  size: 14),
                              label: Text(h?.name ?? 'Helper',
                                  style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.08),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // ── Product chips ─────────────────────────────────────
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: prod.items.map((item) {
                          final p = vm.products
                              .where((x) => x.id == item.productId)
                              .firstOrNull;
                          final label = item.extraKg > 0
                              ? '${item.sacks}sacks+${item.extraKg}kg ${p?.name ?? "?"}'
                              : '${item.sacks}x ${p?.name ?? "?"}';
                          return Chip(
                            label: Text(label,
                                style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ]),
              ),
            );
          }),
      ]),
    );
  }

  void _openEditSheet(
      BuildContext context, BakerProductionViewModel vm, ProductionModel prod) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProductionSheet(prod: prod, vm: vm),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EDIT SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _EditProductionSheet extends StatefulWidget {
  final ProductionModel prod;
  final BakerProductionViewModel vm;
  const _EditProductionSheet({required this.prod, required this.vm});

  @override
  State<_EditProductionSheet> createState() => _EditProductionSheetState();
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
              sacksCtrl: TextEditingController(text: i.sacks.toString()),
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
      if (s <= 0 && k <= 0) return 'Sacks or KG must be > 0 for each row.';
    }
    final ids = _items.map((e) => e.productId).toList();
    if (ids.toSet().length != ids.length) return 'Duplicate products found.';
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
              extraKg: (int.tryParse(e.kgCtrl.text.trim()) ?? 0).clamp(0, 24),
            ))
        .toList();

    final updated =
        widget.prod.copyWith(items: updatedItems, helperIds: _helperIds);
    final ok = await widget.vm.updateProduction(updated);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Production updated!' : 'Failed. Try again.'),
        backgroundColor: ok ? AppColors.success : Colors.red,
      ));
    }
  }

  // ── Products tab ───────────────────────────────────────────────────────────
  Widget _buildProductsTab() {
    final allProducts = widget.vm.products;
    return Column(children: [
      Expanded(
        child: _items.isEmpty
            ? const Center(
                child: Text('No products. Tap + Add.',
                    style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final entry = _items[i];
                  final usedIds = _items
                      .where((e) => e != entry && e.productId != null)
                      .map((e) => e.productId!)
                      .toSet();
                  final dropdownItems =
                      allProducts.where((p) => !usedIds.contains(p.id)).toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product dropdown
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: entry.productId,
                              hint: const Text('Select product',
                                  style: TextStyle(fontSize: 13)),
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
                              onChanged: (val) =>
                                  setState(() => entry.productId = val),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Sacks + KG + delete row
                          Row(children: [
                            // − sacks +
                            _CounterButton(
                              icon: Icons.remove,
                              onTap: () {
                                final v = int.tryParse(
                                        entry.sacksCtrl.text) ??
                                    0;
                                if (v > 0) {
                                  setState(() =>
                                      entry.sacksCtrl.text =
                                          (v - 1).toString());
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 46,
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
                                  labelStyle:
                                      const TextStyle(fontSize: 9),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _CounterButton(
                              icon: Icons.add,
                              onTap: () {
                                final v = int.tryParse(
                                        entry.sacksCtrl.text) ??
                                    0;
                                setState(() => entry.sacksCtrl.text =
                                    (v + 1).toString());
                              },
                            ),

                            const SizedBox(width: 10),
                            Text('+',
                                style: TextStyle(
                                    color: AppColors.textHint,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 10),

                            // KG field
                            SizedBox(
                              width: 56,
                              child: TextField(
                                controller: entry.kgCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: 'KG (0-24)',
                                  labelStyle:
                                      const TextStyle(fontSize: 9),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                                onChanged: (v) {
                                  final kg =
                                      (int.tryParse(v) ?? 0).clamp(0, 24);
                                  setState(() {});
                                  if ((int.tryParse(v) ?? 0) > 24) {
                                    entry.kgCtrl.text = '24';
                                  }
                                },
                              ),
                            ),

                            const Spacer(),

                            // Delete row
                            InkWell(
                              onTap: () => setState(() {
                                entry.dispose();
                                _items.removeAt(i);
                              }),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.delete_outline,
                                    size: 16, color: Colors.red.shade400),
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
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _items.add(_EditItemEntry(
                    productId: null,
                    sacksCtrl: TextEditingController(text: '0'),
                    kgCtrl: TextEditingController(),
                  ))),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Product'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
    ]);
  }

  // ── Helpers tab ────────────────────────────────────────────────────────────
  Widget _buildHelpersTab() {
    final allHelpers = widget.vm.helpers;
    if (allHelpers.isEmpty) {
      return const Center(
          child: Text('No helpers available.',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: allHelpers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final helper = allHelpers[i];
        final selected = _helperIds.contains(helper.id);
        return InkWell(
          onTap: () => setState(() {
            selected
                ? _helperIds.remove(helper.id)
                : _helperIds.add(helper.id);
          }),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
      child: Column(children: [
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
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
                  fontWeight: FontWeight.w700, fontSize: 15)),
        ]),

        const SizedBox(height: 12),

        // Tabs
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
                      const Icon(Icons.inventory_2_outlined, size: 15),
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
            children: [_buildProductsTab(), _buildHelpersTab()],
          ),
        ),

        // ── Live preview bar ───────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PreviewStat('Total',
                      formatCurrency(preview.totalValue)),
                  _PreviewStat(
                      'Sacks',
                      preview.totalExtraKg > 0
                          ? '${preview.totalSacks}s+${preview.totalExtraKg}kg'
                          : '${preview.totalSacks}'),
                  _PreviewStat('Workers', '${preview.totalWorkers}'),
                  _PreviewStat('Salary',
                      formatCurrency(preview.salaryPerWorker),
                      highlight: true),
                ]),
            const Divider(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star_outline,
                  size: 12, color: AppColors.masterBaker),
              const SizedBox(width: 4),
              Text(
                'Bonus per worker: ${formatCurrency(preview.bonusPerWorker)} (paid separately)',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.masterBaker,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ]),
        ),

        // ── Action buttons ─────────────────────────────────────────────────
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed:
                  _isSaving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

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
  const _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
  const _PreviewStat(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color:
                      highlight ? AppColors.success : Colors.black87)),
        ],
      );
}