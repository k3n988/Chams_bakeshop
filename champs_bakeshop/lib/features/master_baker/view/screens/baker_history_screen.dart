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
        const SectionHeader(title: 'My Productions', subtitle: 'Your production history'),
        if (vm.productions.isEmpty)
          const EmptyState(message: 'No productions yet')
        else
          ...vm.productions.map((prod) {
            final calc = vm.computeDaily(prod);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ── Header row ──────────────────────────────────────────
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(prod.date,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(formatCurrency(calc.totalValue),
                            style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _openEditSheet(context, vm, prod),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              size: 16, color: AppColors.primary),
                        ),
                      ),
                    ]),
                  ]),

                  const SizedBox(height: 8),

                  // ── Salary line ─────────────────────────────────────────
                  Text(
                    'Your salary: ${formatCurrency(calc.salaryPerWorker + calc.masterBonus)} '
                    '(${formatCurrency(calc.salaryPerWorker)} + ${formatCurrency(calc.masterBonus)} bonus)',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 8),

                  // ── Helpers ─────────────────────────────────────────────
                  if (prod.helperIds.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      children: prod.helperIds.map((hId) {
                        final h = vm.helpers.where((u) => u.id == hId).firstOrNull;
                        return Chip(
                          avatar: const Icon(Icons.person_outline, size: 14),
                          label: Text(h?.name ?? 'Helper', style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.primary.withOpacity(0.08),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // ── Product chips ────────────────────────────────────────
                  Wrap(
                    spacing: 6,
                    children: prod.items.map((item) {
                      final p = vm.products.where((x) => x.id == item.productId).firstOrNull;
                      return Chip(
                        label: Text('${item.sacks}x ${p?.name ?? "?"}',
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

  // Mutable working copies
  late List<_ItemEntry> _items;
  late List<String> _helperIds;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    _items = widget.prod.items
        .map((i) => _ItemEntry(
              productId: i.productId,
              controller: TextEditingController(text: i.sacks.toString()),
            ))
        .toList();

    _helperIds = List<String>.from(widget.prod.helperIds);
  }

  @override
  void dispose() {
    for (final e in _items) {
      e.controller.dispose();
    }
    _tab.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  String? _validate() {
    if (_items.isEmpty) return 'Add at least one product.';
    for (final e in _items) {
      if (e.productId == null) return 'Select a product for every row.';
      final v = int.tryParse(e.controller.text.trim());
      if (v == null || v <= 0) return 'Sacks must be a positive number.';
    }
    // Duplicate product check
    final ids = _items.map((e) => e.productId).toList();
    if (ids.toSet().length != ids.length) return 'Duplicate products found.';
    return null;
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    setState(() => _isSaving = true);

    final updatedItems = _items
        .map((e) => ProductionItem(
              productId: e.productId!,
              sacks: int.parse(e.controller.text.trim()),
            ))
        .toList();

    final updated = widget.prod.copyWith(
      items: updatedItems,
      helperIds: _helperIds,
    );

    final ok = await widget.vm.updateProduction(updated);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Production updated!' : 'Failed to update. Try again.'),
        backgroundColor: ok ? AppColors.success : Colors.red,
      ));
    }
  }

  // ── Product tab ────────────────────────────────────────────────────────────

  Widget _buildProductsTab() {
    final availableProducts = widget.vm.products;

    return Column(children: [
      Expanded(
        child: _items.isEmpty
            ? const Center(
                child: Text('No products added yet.',
                    style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final entry = _items[i];

                  // Products not already selected (except current row's own selection)
                  final usedIds = _items
                      .where((e) => e != entry && e.productId != null)
                      .map((e) => e.productId!)
                      .toSet();

                  final dropdownItems = availableProducts
                      .where((p) => !usedIds.contains(p.id))
                      .toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      // Product dropdown
                      Expanded(
                        child: DropdownButtonHideUnderline(
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
                      ),

                      const SizedBox(width: 8),

                      // − / sacks / +
                      _CounterButton(
                        icon: Icons.remove,
                        onTap: () {
                          final v = int.tryParse(entry.controller.text) ?? 0;
                          if (v > 1) setState(() => entry.controller.text = (v - 1).toString());
                        },
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: entry.controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _CounterButton(
                        icon: Icons.add,
                        onTap: () {
                          final v = int.tryParse(entry.controller.text) ?? 0;
                          setState(() => entry.controller.text = (v + 1).toString());
                        },
                      ),

                      const SizedBox(width: 8),

                      // Delete row
                      InkWell(
                        onTap: () => setState(() {
                          entry.controller.dispose();
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
                  );
                },
              ),
      ),

      // Add product row button
      if (_items.length < availableProducts.length)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _items.add(_ItemEntry(
                    productId: null,
                    controller: TextEditingController(text: '1'),
                  ))),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Product'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
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
            if (selected) {
              _helperIds.remove(helper.id);
            } else {
              _helperIds.add(helper.id);
            }
          }),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withOpacity(0.4)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: selected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.grey.shade200,
                child: Text(
                  helper.name.isNotEmpty ? helper.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: selected ? AppColors.primary : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(helper.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: selected ? AppColors.primary : Colors.black87,
                    )),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? Icon(Icons.check_circle_rounded,
                        key: const ValueKey('check'),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    // Live preview
    final previewItems = _items
        .where((e) => e.productId != null)
        .map((e) => ProductionItem(
              productId: e.productId!,
              sacks: int.tryParse(e.controller.text) ?? 0,
            ))
        .toList();
    final preview = widget.vm.previewSalary(previewItems, _helperIds.length);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      height: screenHeight * 0.82,
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
          Text('Edit Production — ${widget.prod.date}',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ]),

        const SizedBox(height: 12),

        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.inventory_2_outlined, size: 15),
                  const SizedBox(width: 6),
                  const Text('Products'),
                  if (_items.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _Badge(label: '${_items.length}'),
                  ],
                ]),
              ),
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.people_outline, size: 15),
                  const SizedBox(width: 6),
                  const Text('Helpers'),
                  if (_helperIds.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _Badge(label: '${_helperIds.length}'),
                  ],
                ]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildProductsTab(),
              _buildHelpersTab(),
            ],
          ),
        ),

        // ── Live preview ───────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PreviewStat(
                  label: 'Total Value',
                  value: formatCurrency(preview.totalValue)),
              _PreviewStat(
                  label: 'Sacks', value: '${preview.totalSacks}'),
              _PreviewStat(
                  label: 'Workers', value: '${preview.totalWorkers}'),
              _PreviewStat(
                  label: 'Your Salary',
                  value: formatCurrency(
                      preview.salaryPerWorker + preview.masterBonus),
                  highlight: true),
            ],
          ),
        ),

        // ── Action buttons ─────────────────────────────────────────────────
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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

// ═══════════════════════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Mutable entry for a product row in the edit sheet.
class _ItemEntry {
  String? productId;
  final TextEditingController controller;
  _ItemEntry({required this.productId, required this.controller});
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
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _PreviewStat(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: highlight ? AppColors.success : Colors.black87,
              )),
        ],
      );
}