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

class _ItemData {
  String? productId;
  int sacks = 0;
}

class _BakerProductionInputScreenState
    extends State<BakerProductionInputScreen> {
  String _date = DateTime.now().toString().split(' ')[0];
  final Set<String> _selectedHelpers = {};
  final List<_ItemData> _items = [_ItemData()];

  void _toggleHelper(String id) => setState(() {
        _selectedHelpers.contains(id)
            ? _selectedHelpers.remove(id)
            : _selectedHelpers.add(id);
      });

  void _addItem() => setState(() => _items.add(_ItemData()));
  void _removeItem(int i) {
    if (_items.length > 1) setState(() => _items.removeAt(i));
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
      .where((i) => i.productId != null && i.sacks > 0)
      .map((i) => ProductionItem(productId: i.productId!, sacks: i.sacks))
      .toList();

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
          content: Text('Add at least one product with sacks > 0'),
          backgroundColor: AppColors.danger));
      return;
    }

    final user = context.read<AuthViewModel>().currentUser!;
    final ok = await context.read<BakerProductionViewModel>().addProduction(
          date: _date,
          masterBakerId: user.id,
          helperIds: _selectedHelpers.toList(),
          items: _validItems,
        );

    if (!mounted) return;

    if (ok) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Production saved!'),
          backgroundColor: AppColors.success));
      setState(() {
        _selectedHelpers.clear();
        _items.clear();
        _items.add(_ItemData());
      });
    } else {
      messenger.showSnackBar(const SnackBar(
          content: Text('Production already exists for this date'),
          backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerProductionViewModel>();
    final preview = vm.previewSalary(_validItems, _selectedHelpers.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(
            title: 'Add Production',
            subtitle: 'Record daily bakery production'),

        // ── Date ──
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today, color: AppColors.primary),
            title: Text(_date,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Production Date'),
            trailing: OutlinedButton(
                onPressed: _pickDate, child: const Text('Change')),
          ),
        ),
        const SizedBox(height: 16),

        // ── Helpers ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SELECT HELPERS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  if (vm.helpers.isEmpty)
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
                          side: BorderSide(
                              color: sel ? AppColors.success : AppColors.border),
                          onSelected: (_) => _toggleHelper(h.id),
                        );
                      }).toList(),
                    ),
                ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── Products ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PRODUCTS PRODUCED',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHint,
                                letterSpacing: 0.8)),
                        TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add')),
                      ]),
                  ...List.generate(_items.length, (i) {
                    final item = _items[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            // FIX: value → initialValue
                            initialValue: item.productId,
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
                            onChanged: (v) =>
                                setState(() => item.productId = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                hintText: 'Sacks',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10)),
                            onChanged: (v) => setState(
                                () => item.sacks = int.tryParse(v) ?? 0),
                          ),
                        ),
                        if (_items.length > 1) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.danger, size: 22),
                            onPressed: () => _removeItem(i),
                          ),
                        ],
                      ]),
                    );
                  }),
                ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── Preview ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRODUCTION PREVIEW',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 14),
                  BreakdownRow(
                      label: 'Total Value',
                      value: formatCurrency(preview.totalValue),
                      color: AppColors.primary),
                  BreakdownRow(
                      label: 'Total Sacks',
                      value: '${preview.totalSacks}'),
                  BreakdownRow(
                      label: 'Total Workers',
                      value: '${preview.totalWorkers}'),
                  BreakdownRow(
                      label: 'Per Worker',
                      value: formatCurrency(preview.salaryPerWorker)),
                  BreakdownRow(
                      label: 'Master Bonus',
                      value: formatCurrency(preview.masterBonus),
                      color: AppColors.masterBaker),
                  const Divider(height: 20),
                  BreakdownRow(
                      label: 'Your Salary (est.)',
                      value: formatCurrency(
                          preview.salaryPerWorker + preview.masterBonus),
                      color: AppColors.primaryDark),
                ]),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submit,
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