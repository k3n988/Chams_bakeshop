import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/production_model.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/baker_production_viewmodel.dart';

class BakerProductionInputScreen extends StatefulWidget {
  const BakerProductionInputScreen({super.key});
  @override
  State<BakerProductionInputScreen> createState() =>
      _BakerProductionInputScreenState();
}

// ─── Item row state ───────────────────────────────────────────────────────────

class _ItemData {
  String? productId;
  int     sacks   = 0;
  int     extraKg = 0;
  final TextEditingController sacksCtrl = TextEditingController(text: '0');
  final TextEditingController kgCtrl    = TextEditingController(text: '0');

  void dispose() {
    sacksCtrl.dispose();
    kgCtrl.dispose();
  }
}

// ─── Screen state ─────────────────────────────────────────────────────────────

class _BakerProductionInputScreenState
    extends State<BakerProductionInputScreen> {
  String         _date            = DateTime.now().toString().split(' ')[0];
  final Set<String> _selectedHelpers = {};
  final List<_ItemData> _items    = [_ItemData()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<BakerProductionViewModel>().loadData(user.id);
      }
    });
  }

  @override
  void dispose() {
    for (final item in _items) item.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _toggleHelper(String id) => setState(() {
        _selectedHelpers.contains(id)
            ? _selectedHelpers.remove(id)
            : _selectedHelpers.add(id);
      });

  void _addItem() => setState(() => _items.add(_ItemData()));

  void _removeItem(int i) {
    if (_items.length > 1) {
      setState(() {
        _items[i].dispose();
        _items.removeAt(i);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_date),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _date = picked.toString().split(' ')[0]);
    }
  }

  List<ProductionItem> get _validItems => _items
      .where((i) => i.productId != null && (i.sacks > 0 || i.extraKg > 0))
      .map((i) => ProductionItem(
            productId: i.productId!,
            sacks:     i.sacks,
            extraKg:   i.extraKg,
          ))
      .toList();

  // ─── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_selectedHelpers.isEmpty) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Select at least one helper'),
          backgroundColor: AppColors.danger));
      return;
    }
    if (_validItems.isEmpty) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Add at least one product with sacks or kg > 0'),
          backgroundColor: AppColors.danger));
      return;
    }

    final user   = context.read<AuthViewModel>().currentUser!;
    final result = await context.read<BakerProductionViewModel>().addProduction(
          date:          _date,
          masterBakerId: user.id,
          helperIds:     _selectedHelpers.toList(),
          items:         _validItems,
        );

    if (!mounted) return;

    if (result == true) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Production saved!'),
          backgroundColor: AppColors.success));
      setState(() {
        _selectedHelpers.clear();
        for (final item in _items) item.dispose();
        _items
          ..clear()
          ..add(_ItemData());
      });
    } else if (result == false) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Production already exists for this date'),
          backgroundColor: AppColors.danger));
    } else {
      messenger.showSnackBar(const SnackBar(
          content: Text('Failed to save. Check connection and try again.'),
          backgroundColor: AppColors.danger));
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm      = context.watch<BakerProductionViewModel>();
    // FIX: always compute preview from _validItems so values are real numbers
    final preview = vm.previewSalary(_validItems, _selectedHelpers.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(
            title: 'Add Production',
            subtitle: 'Record daily bakery production'),

        // ── Date ──────────────────────────────────────────────────────────────
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today, color: AppColors.primary),
            title: Text(_date, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Production Date'),
            trailing: OutlinedButton(
                onPressed: _pickDate, child: const Text('Change')),
          ),
        ),
        const SizedBox(height: 16),

        // ── Helpers ───────────────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SELECT HELPERS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                      letterSpacing: 0.8)),
              const SizedBox(height: 12),
              if (vm.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (vm.helpers.isEmpty)
                const Text('No helpers found',
                    style: TextStyle(color: AppColors.textHint))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: vm.helpers.map((h) {
                    final sel = _selectedHelpers.contains(h.id);
                    return FilterChip(
                      selected: sel,
                      label: Text(h.name),
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textSecondary),
                      selectedColor: AppColors.success,
                      checkmarkColor: Colors.white,
                      backgroundColor: AppColors.surface,
                      // FIX: withOpacity → withValues()
                      side: BorderSide(
                          color: sel
                              ? AppColors.success
                              : AppColors.border),
                      onSelected: (_) => _toggleHelper(h.id),
                    );
                  }).toList(),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── Products ──────────────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('PRODUCTS PRODUCED',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                        letterSpacing: 0.8)),
                TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+ Add')),
              ]),

              // Column headers
              Padding(
                padding: const EdgeInsets.only(bottom: 4, top: 2),
                child: Row(children: [
                  const Expanded(flex: 3, child: SizedBox()),
                  Expanded(
                    flex: 2,
                    child: Row(children: const [
                      Expanded(
                          child: Text('Sacks',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint))),
                      SizedBox(width: 6),
                      Expanded(
                          child: Text('+ KG',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint))),
                    ]),
                  ),
                  const SizedBox(width: 40),
                ]),
              ),

              ...List.generate(_items.length, (i) {
                final item = _items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Product dropdown
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: item.productId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                                hintText: 'Select product',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10)),
                            items: vm.products
                                .map((p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(
                                        '${p.name} (${formatCurrency(p.pricePerSack)})',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => item.productId = v),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Sacks counter
                        SizedBox(
                          width: 90,
                          child: Row(children: [
                            _CounterBtn(
                              icon: Icons.remove,
                              isLeft: true,
                              onTap: () {
                                if (item.sacks > 0) {
                                  setState(() {
                                    item.sacks--;
                                    item.sacksCtrl.text =
                                        item.sacks.toString();
                                  });
                                }
                              },
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: TextField(
                                  controller: item.sacksCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide:
                                          BorderSide(color: AppColors.border),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  onChanged: (v) => setState(
                                      () => item.sacks = int.tryParse(v) ?? 0),
                                ),
                              ),
                            ),
                            _CounterBtn(
                              icon: Icons.add,
                              isLeft: false,
                              onTap: () {
                                setState(() {
                                  item.sacks++;
                                  item.sacksCtrl.text = item.sacks.toString();
                                });
                              },
                            ),
                          ]),
                        ),
                        const SizedBox(width: 6),

                        // KG input
                        Expanded(
                          child: TextField(
                            controller: item.kgCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '0',
                              suffixText: 'kg',
                              suffixStyle: const TextStyle(
                                  fontSize: 10, color: AppColors.textHint),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (v) {
                              final parsed = int.tryParse(v) ?? 0;
                              final clamped = parsed.clamp(0, 24);
                              setState(() => item.extraKg = clamped);
                              if (parsed > 24) {
                                item.kgCtrl
                                  ..text = '24'
                                  ..selection = TextSelection.fromPosition(
                                      const TextPosition(offset: 2));
                              }
                            },
                          ),
                        ),

                        // Delete
                        if (_items.length > 1) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.danger, size: 22),
                            onPressed: () => _removeItem(i),
                          ),
                        ] else
                          const SizedBox(width: 40),
                      ]),
                );
              }),

              const SizedBox(height: 4),
              const Text(
                '1 sack = 25 kg  •  e.g. 3 sacks + 10 kg = 3.4 effective sacks',
                style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── Production Preview ────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PRODUCTION PREVIEW',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                      letterSpacing: 0.8)),
              const SizedBox(height: 14),

              // FIX: was using string templates that weren't interpolating.
              // Now uses direct property access on DailySalaryResult.
              BreakdownRow(
                  label: 'Total Value',
                  value: formatCurrency(preview.totalValue),
                  color: AppColors.primary),
              BreakdownRow(
                  label: 'Total Sacks',
                  value: preview.totalExtraKg > 0
                      ? '${preview.totalSacks} sacks + ${preview.totalExtraKg} kg'
                      : '${preview.totalSacks} sacks'),
              BreakdownRow(
                  label: 'Total Workers',
                  value: '${preview.totalWorkers}'),
              BreakdownRow(
                  label: 'Per Worker (base)',
                  value: formatCurrency(preview.salaryPerWorker)),

              const Divider(height: 20),

              // Baker incentive section
              const Text('BAKER INCENTIVE (IN SALARY)',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                      letterSpacing: 0.6)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('₱100 / effective sack',
                    style: TextStyle(fontSize: 13)),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    formatCurrency(preview.bakerIncentive),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                        fontSize: 13),
                  ),
                  Text(
                    '${(preview.totalSacks + preview.totalExtraKg / 25.0).toStringAsFixed(2)} eff. sacks × ₱100',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint),
                  ),
                ]),
              ]),

              const Divider(height: 20),
              BreakdownRow(
                  label: 'Your Salary (est.)',
                  value: formatCurrency(
                      preview.salaryPerWorker + preview.bakerIncentive),
                  color: AppColors.primaryDark),

              const Divider(height: 20),

              // Bonus section — paid separately, NOT in payroll total
              const Text('BONUS (PAID SEPARATELY)',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                      letterSpacing: 0.6)),
              const SizedBox(height: 8),
              BreakdownRow(
                  label: 'Master Baker Bonus',
                  value: formatCurrency(preview.bonusPerWorker),
                  color: AppColors.masterBaker),
              BreakdownRow(
                  label: 'Helper Bonus (each)',
                  value: formatCurrency(preview.bonusPerWorker),
                  color: AppColors.success),

              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // FIX: withOpacity → withValues()
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bonus is paid separately and is not included in the weekly/monthly payroll total.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.amber.shade800),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 20),

        // ── Save button ───────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: vm.isLoading ? null : _submit,
            icon: const Icon(Icons.check),
            label: const Text('Save Production',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// ─── Counter button ──────────────────────────────────────────────────────────

class _CounterBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  final bool         isLeft;
  const _CounterBtn(
      {required this.icon, required this.onTap, required this.isLeft});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.horizontal(
              left:  isLeft ? const Radius.circular(8) : Radius.zero,
              right: isLeft ? Radius.zero : const Radius.circular(8),
            ),
            color: AppColors.surface,
          ),
          child: Icon(icon, size: 14, color: AppColors.textSecondary),
        ),
      );
}