import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/production_model.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/baker_production_viewmodel.dart';

// ─── Item row state ───────────────────────────────────────────────────────────
class _ItemData {
  String? productId;
  int sacks = 0;
  int extraKg = 0;
  final TextEditingController sacksCtrl =
      TextEditingController(text: '0');
  final TextEditingController kgCtrl =
      TextEditingController(text: '0');

  void dispose() {
    sacksCtrl.dispose();
    kgCtrl.dispose();
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class BakerProductionInputScreen extends StatefulWidget {
  const BakerProductionInputScreen({super.key});
  @override
  State<BakerProductionInputScreen> createState() =>
      _BakerProductionInputScreenState();
}

class _BakerProductionInputScreenState
    extends State<BakerProductionInputScreen> {
  String _date = DateTime.now().toString().split(' ')[0];
  final Set<String> _selectedHelpers = {};
  String? _ovenHelperId;
  final List<_ItemData> _items = [_ItemData()];

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

  void _toggleHelper(String id) => setState(() {
        if (_selectedHelpers.contains(id)) {
          _selectedHelpers.remove(id);
          if (_ovenHelperId == id) _ovenHelperId = null;
        } else {
          _selectedHelpers.add(id);
        }
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
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_date),
      firstDate: DateTime(today.year - 2, 1, 1),
      lastDate: today,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.masterBaker,
            onSurface: AppColors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = picked.toString().split(' ')[0]);
    }
  }

  List<ProductionItem> get _validItems => _items
      .where((i) => i.productId != null && (i.sacks > 0 || i.extraKg > 0))
      .map((i) => ProductionItem(
            productId: i.productId!,
            sacks: i.sacks,
            extraKg: i.extraKg,
          ))
      .toList();

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_selectedHelpers.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Select at least one helper'),
        ]),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      return;
    }
    if (_validItems.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(
              child:
                  Text('Add at least one product with sacks or kg > 0')),
        ]),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      return;
    }

    final user = context.read<AuthViewModel>().currentUser!;
    final result =
        await context.read<BakerProductionViewModel>().addProduction(
              date: _date,
              masterBakerId: user.id,
              helperIds: _selectedHelpers.toList(),
              items: _validItems,
              ovenHelperId: _ovenHelperId,
            );

    if (!mounted) return;

    if (result == true) {
      messenger.showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Production saved successfully!'),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      setState(() {
        _selectedHelpers.clear();
        _ovenHelperId = null;
        for (final item in _items) {
          item.dispose();
        }
        _items
          ..clear()
          ..add(_ItemData());
      });
    } else if (result == false) {
      messenger.showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.error_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Production already exists for this date'),
        ]),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.cloud_off_outlined, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Failed to save. Check connection.'),
        ]),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerProductionViewModel>();
    final preview =
        vm.previewSalary(_validItems, _selectedHelpers.length);

    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Page Header ──────────────────────────────────────
            const Text('Add Production',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -0.5)),
            const SizedBox(height: 3),
            const Text('Record your daily bakery production',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            // ── Date ─────────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('PRODUCTION DATE'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.masterBaker
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today_outlined,
                          color: AppColors.masterBaker, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_date,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.text)),
                          const Text('Selected date',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _pickDate,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.masterBaker,
                        side: BorderSide(
                            color: AppColors.masterBaker
                                .withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Change',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Helpers ──────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionLabel('SELECT HELPERS'),
                      if (_selectedHelpers.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_selectedHelpers.length} selected',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (vm.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(
                            color: AppColors.masterBaker,
                            strokeWidth: 2.5),
                      ),
                    )
                  else if (vm.helpers.isEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      child: const Row(children: [
                        Icon(Icons.person_off_outlined,
                            size: 16, color: AppColors.textHint),
                        SizedBox(width: 8),
                        Text('No helpers found',
                            style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 13)),
                      ]),
                    )
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
                              fontSize: 13,
                              color: sel
                                  ? Colors.white
                                  : AppColors.textSecondary),
                          selectedColor: AppColors.success,
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: sel
                                ? AppColors.success
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          onSelected: (_) => _toggleHelper(h.id),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Oven Helper ──────────────────────────────────────
            if (_selectedHelpers.isNotEmpty)
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionLabel('WHO DID THE OVEN?'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Exempt from ₱15 deduction',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select the helper who cooked the tinpay. They will not be charged the oven deduction for this day.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // "None" option
                        ChoiceChip(
                          selected: _ovenHelperId == null,
                          label: const Text('None'),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _ovenHelperId == null
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          selectedColor: AppColors.textSecondary,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: _ovenHelperId == null
                                ? AppColors.textSecondary
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          onSelected: (_) =>
                              setState(() => _ovenHelperId = null),
                        ),
                        ...vm.helpers
                            .where((h) => _selectedHelpers.contains(h.id))
                            .map((h) {
                          final sel = _ovenHelperId == h.id;
                          return ChoiceChip(
                            selected: sel,
                            label: Text(h.name),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: sel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            selectedColor: AppColors.warning,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: sel
                                  ? AppColors.warning
                                  : AppColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            onSelected: (_) =>
                                setState(() => _ovenHelperId = h.id),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            if (_selectedHelpers.isNotEmpty) const SizedBox(height: 14),

            // ── Products ─────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionLabel('PRODUCTS PRODUCED'),
                      GestureDetector(
                        onTap: _addItem,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.masterBaker
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add,
                                    size: 14,
                                    color: AppColors.masterBaker),
                                SizedBox(width: 4),
                                Text('Add Item',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.masterBaker)),
                              ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Column headers
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
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
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textHint,
                                    letterSpacing: 0.4)),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text('+ KG',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textHint,
                                    letterSpacing: 0.4)),
                          ),
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
                          crossAxisAlignment:
                              CrossAxisAlignment.center,
                          children: [
                            // Product dropdown
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: item.productId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: 'Select product',
                                  hintStyle: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHint),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppColors.masterBaker,
                                        width: 1.5),
                                  ),
                                ),
                                items: vm.products
                                    .map((p) => DropdownMenuItem(
                                          value: p.id,
                                          child: Text(
                                            '${p.name} (${formatCurrency(p.pricePerSack)})',
                                            style: const TextStyle(
                                                fontSize: 12),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(
                                    () => item.productId = v),
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
                                    height: 38,
                                    child: TextField(
                                      controller: item.sacksCtrl,
                                      keyboardType:
                                          TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w700),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.zero,
                                          borderSide: BorderSide(
                                              color: AppColors.border),
                                        ),
                                        enabledBorder:
                                            OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.zero,
                                          borderSide: BorderSide(
                                              color: AppColors.border),
                                        ),
                                        focusedBorder:
                                            OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.zero,
                                          borderSide:
                                              const BorderSide(
                                                  color: AppColors
                                                      .masterBaker,
                                                  width: 1.5),
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                      ),
                                      onChanged: (v) => setState(() =>
                                          item.sacks =
                                              int.tryParse(v) ?? 0),
                                    ),
                                  ),
                                ),
                                _CounterBtn(
                                  icon: Icons.add,
                                  isLeft: false,
                                  onTap: () {
                                    setState(() {
                                      item.sacks++;
                                      item.sacksCtrl.text =
                                          item.sacks.toString();
                                    });
                                  },
                                ),
                              ]),
                            ),
                            const SizedBox(width: 6),

                            // KG input
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: TextField(
                                  controller: item.kgCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style:
                                      const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    suffixText: 'kg',
                                    suffixStyle: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textHint),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: AppColors.masterBaker,
                                          width: 1.5),
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: (v) {
                                    final parsed =
                                        int.tryParse(v) ?? 0;
                                    final clamped =
                                        parsed.clamp(0, 24);
                                    setState(
                                        () => item.extraKg = clamped);
                                    if (parsed > 24) {
                                      item.kgCtrl
                                        ..text = '24'
                                        ..selection =
                                            TextSelection.fromPosition(
                                                const TextPosition(
                                                    offset: 2));
                                    }
                                  },
                                ),
                              ),
                            ),

                            // Delete
                            if (_items.length > 1) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _removeItem(i),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger
                                        .withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                      Icons.remove_circle_outline,
                                      color: AppColors.danger,
                                      size: 18),
                                ),
                              ),
                            ] else
                              const SizedBox(width: 40),
                          ]),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Production Preview ───────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('PRODUCTION PREVIEW'),
                  const SizedBox(height: 16),

                  // Summary rows
                  _PreviewRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Total Value',
                    value: formatCurrency(preview.totalValue),
                    valueColor: AppColors.masterBaker,
                  ),
                  _PreviewRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Total Sacks',
                    value: preview.totalExtraKg > 0
                        ? '${preview.totalSacks} sacks + ${preview.totalExtraKg} kg'
                        : '${preview.totalSacks} sacks',
                  ),
                  _PreviewRow(
                    icon: Icons.groups_outlined,
                    label: 'Total Workers',
                    value: '${preview.totalWorkers}',
                  ),
                  _PreviewRow(
                    icon: Icons.calculate_outlined,
                    label: 'Per Worker (base)',
                    value: formatCurrency(preview.salaryPerWorker),
                    valueColor: AppColors.primaryDark,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child:
                        Divider(color: AppColors.border, height: 1),
                  ),

                  // Baker incentive block
                  const _SectionLabel('BAKER INCENTIVE'),
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
                    child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Baker Incentive',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                          Text(
                            formatCurrency(preview.bakerIncentive),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                fontSize: 14),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 12),

                  // Your salary total
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark
                          .withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primaryDark
                              .withValues(alpha: 0.12)),
                    ),
                    child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your Salary (est.)',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.text)),
                          Text(
                            formatCurrency(preview.salaryPerWorker +
                                preview.bakerIncentive),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: AppColors.primaryDark),
                          ),
                        ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Save Button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: vm.isLoading ? null : _submit,
                icon: vm.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  vm.isLoading ? 'Saving...' : 'Save Production',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.masterBaker,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

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
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: AppColors.masterBaker,
            borderRadius: BorderRadius.circular(2),
          ),
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

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.text)),
        ]),
      );
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLeft;
  const _CounterBtn(
      {required this.icon,
      required this.onTap,
      required this.isLeft});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(8) : Radius.zero,
          right: isLeft ? Radius.zero : const Radius.circular(8),
        ),
        child: Container(
          width: 28,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.masterBaker.withValues(alpha: 0.06),
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? const Radius.circular(8) : Radius.zero,
              right: isLeft ? Radius.zero : const Radius.circular(8),
            ),
          ),
          child:
              Icon(icon, size: 14, color: AppColors.masterBaker),
        ),
      );
}