import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/production_model.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../../admin/viewmodel/admin_user_viewmodel.dart';
import '../../viewmodel/baker_production_viewmodel.dart';
import 'baker_history_screen.dart';

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
  final bool adminMode;
  final String? initialMasterBakerId;

  const BakerProductionInputScreen({
    super.key,
    this.adminMode = false,
    this.initialMasterBakerId,
  });

  @override
  State<BakerProductionInputScreen> createState() =>
      _BakerProductionInputScreenState();
}

class _BakerProductionInputScreenState
    extends State<BakerProductionInputScreen> {
  String _date = DateTime.now().toString().split(' ')[0];
  String? _selectedMasterBakerId;
  final Set<String> _selectedHelpers = {};
  String? _ovenHelperId;
  final _ovenRateCtrl = TextEditingController(text: '15');
  final List<_ItemData> _items = [_ItemData()];

  @override
  void initState() {
    super.initState();
    _selectedMasterBakerId = widget.initialMasterBakerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.adminMode) {
        final userVM = context.read<AdminUserViewModel>();
        if (userVM.users.isEmpty) {
          userVM.loadUsers();
        }
        context
            .read<BakerProductionViewModel>()
            .loadData(_selectedMasterBakerId ?? '');
      } else {
        final user = context.read<AuthViewModel>().currentUser;
        if (user != null) {
          context.read<BakerProductionViewModel>().loadData(user.id);
        }
      }
    });
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    _ovenRateCtrl.dispose();
    super.dispose();
  }

  void _toggleHelper(String id) => setState(() {
        if (_selectedHelpers.contains(id)) {
          _selectedHelpers.remove(id);
          if (_ovenHelperId == id) {
            _ovenHelperId = null;
          }
        } else {
          _selectedHelpers.add(id);
        }
      });

  void _setMasterBaker(String? id) {
    if (id == null || id == _selectedMasterBakerId) return;
    setState(() => _selectedMasterBakerId = id);
    context.read<BakerProductionViewModel>().loadData(id);
  }

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

  double _previewBakerIncentive(BakerProductionViewModel vm) {
    final productMap = {for (final p in vm.products) p.id: p};
    double incentiveAmount = 0;

    for (final item in _validItems) {
      final product = productMap[item.productId];
      if (product == null) continue;
      if (PayrollService.isIncentiveExemptProduct(product)) continue;
      incentiveAmount +=
          product.masterBakerIncentivePerSack * item.effectiveSacks;
    }

    return incentiveAmount;
  }

  void _showSaveSuccessFeedback() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Row(children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 24),
          SizedBox(width: 10),
          Text('Production Saved'),
        ]),
        content: const Text(
          'Production has been saved successfully.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK',
                style: TextStyle(
                    color: AppColors.masterBaker,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _openHistory(AuthViewModel authVm) {
    final currentUser = authVm.currentUser;
    if (!widget.adminMode && currentUser != null && currentUser.isSellerBaker) {
      context.read<BakerProductionViewModel>().loadData(currentUser.id);
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Baker History'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.text,
            elevation: 0,
            surfaceTintColor: Colors.white,
          ),
          body: BakerHistoryScreen(
            showHeader: false,
            adminMode: widget.adminMode,
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);

    final signedInUser = context.read<AuthViewModel>().currentUser;
    final masterBakerId =
        widget.adminMode ? _selectedMasterBakerId : signedInUser?.id;

    if (masterBakerId == null || masterBakerId.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Select a master baker'),
        ]),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      return;
    }

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

    final ovenRate = double.tryParse(_ovenRateCtrl.text.trim());
    if (ovenRate == null || ovenRate < 0) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Enter a valid oven deduction/pay amount.'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    final result =
        await context.read<BakerProductionViewModel>().addProduction(
              date: _date,
              masterBakerId: masterBakerId,
              helperIds: _selectedHelpers.toList(),
              items: _validItems,
              ovenHelperId: _ovenHelperId,
              ovenRate: ovenRate,
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
      _showSaveSuccessFeedback();
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

  Widget _mobileProductsCard(BakerProductionViewModel vm) {
    const ink = Color(0xFF414750);
    const muted = Color(0xFF858A90);
    const line = Color(0xFFE0E2E3);
    const green = Color(0xFF55946B);
    const paleGreen = Color(0xFFECF3EE);
    const labelStyle = TextStyle(fontSize: 9, color: ink);
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: line),
    );

    Widget fieldShell(Widget child) => Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(5),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    Widget counterButton(_ItemData item, bool increase) => SizedBox(
      width: 24,
      height: 30,
      child: Material(
        color: paleGreen,
        child: InkWell(
          onTap: () => setState(() {
            if (increase) {
              item.sacks++;
            } else if (item.sacks > 0) {
              item.sacks--;
            }
            item.sacksCtrl.text = '${item.sacks}';
          }),
          child: Icon(increase ? Icons.add : Icons.remove,
              size: 14, color: green),
        ),
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 4, height: 19,
                  decoration: BoxDecoration(color: green,
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 10),
              const Expanded(child: Text('PRODUCTS PRODUCED',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.7, color: ink))),
              Material(
                color: paleGreen,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: _addItem,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, size: 14, color: green),
                      SizedBox(width: 6),
                      Text('Add Item', style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w600, color: green)),
                    ]),
                  ),
                ),
              ),
            ]),
            const Padding(
              padding: EdgeInsets.only(left: 14),
              child: Text('Add the products and quantities produced in this batch.',
                  style: TextStyle(fontSize: 9, color: muted)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 9),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F1F2)),
            ),
            Row(children: [
              const Expanded(flex: 2, child: Text('Product', style: labelStyle)),
              const SizedBox(width: 12),
              const Expanded(child: Text('Sacks', style: labelStyle)),
              const SizedBox(width: 12),
              const Expanded(child: Text('+ KG', style: labelStyle)),
              if (_items.length > 1) const SizedBox(width: 28),
            ]),
            const SizedBox(height: 5),
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              return Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                child: Row(children: [
                  Expanded(flex: 2, child: fieldShell(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                        value: item.productId,
                        isExpanded: true,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: muted),
                        style: const TextStyle(fontSize: 11, color: ink),
                        hint: const Text('Select product', style: TextStyle(fontSize: 11, color: muted)),
                        items: vm.products.map((p) => DropdownMenuItem(
                          value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (value) => setState(() => item.productId = value),
                      )),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: fieldShell(Row(children: [
                    counterButton(item, false),
                    const VerticalDivider(width: 1, thickness: 1, color: line),
                    Expanded(child: TextField(
                      controller: item.sacksCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink),
                      decoration: const InputDecoration(isCollapsed: true),
                      onChanged: (value) => setState(() => item.sacks = int.tryParse(value) ?? 0),
                    )),
                    const VerticalDivider(width: 1, thickness: 1, color: line),
                    counterButton(item, true),
                  ]))),
                  const SizedBox(width: 12),
                  Expanded(child: SizedBox(height: 32, child: TextField(
                    controller: item.kgCtrl,
                    keyboardType: TextInputType.number,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 11, color: ink),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      border: outline, enabledBorder: outline, focusedBorder: outline,
                      suffixIconConstraints: const BoxConstraints(minWidth: 28, maxWidth: 28),
                      suffixIcon: const Row(children: [
                        SizedBox(height: 14, child: VerticalDivider(width: 1, color: line)),
                        SizedBox(width: 7),
                        Text('kg', style: TextStyle(fontSize: 9, color: muted)),
                      ]),
                    ),
                    onChanged: (value) => setState(() {
                      final parsed = int.tryParse(value) ?? 0;
                      item.extraKg = parsed < 0 ? 0 : parsed;
                    }),
                  ))),
                  if (_items.length > 1)
                    SizedBox(width: 28, child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      tooltip: 'Remove item',
                      onPressed: () => _removeItem(i),
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                    )),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerProductionViewModel>();
    final compactProducts = MediaQuery.sizeOf(context).width <= 600;
    final currentUser = context.watch<AuthViewModel>().currentUser;
    final showHistoryButton =
        widget.adminMode || (currentUser?.isSellerBaker ?? false);
    final adminUserVM =
        widget.adminMode ? context.watch<AdminUserViewModel>() : null;
    final masterBakers = adminUserVM?.masterBakers ?? const [];
    final preview =
        vm.previewSalary(_validItems, _selectedHelpers.length);
    final previewBakerIncentive = _previewBakerIncentive(vm);
    final salaryLabel =
        widget.adminMode ? 'Baker Salary (est.)' : 'Your Salary (est.)';

    final content = ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, compactProducts ? 4 : 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Page Header ──────────────────────────────────────
            if (!widget.adminMode)
              Row(
              children: [
                const Expanded(
                  child: Text('Add Production',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                          letterSpacing: -0.5)),
                ),
                      if (showHistoryButton)
                  OutlinedButton.icon(
                    onPressed: () => _openHistory(context.read<AuthViewModel>()),
                    icon: const Icon(Icons.history_outlined, size: 18),
                    label: const Text('History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.masterBaker,
                      side: BorderSide(
                        color: AppColors.masterBaker.withValues(alpha: 0.45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            if (!widget.adminMode) ...[
              const SizedBox(height: 3),
              const Text('Record your daily bakery production',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
            if (!widget.adminMode) const SizedBox(height: 20),

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

            if (widget.adminMode) ...[
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('MASTER BAKER'),
                    const SizedBox(height: 12),
                    if (masterBakers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(children: [
                          Icon(Icons.person_off_outlined,
                              color: AppColors.danger, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No master bakers found',
                              style: TextStyle(
                                  color: AppColors.danger, fontSize: 13),
                            ),
                          ),
                        ]),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMasterBakerId,
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select Master Baker',
                          isDense: true,
                          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF858A90)),
                          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          prefixIcon: const Icon(Icons.person_outline,
                              color: AppColors.masterBaker),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.masterBaker, width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        items: masterBakers
                            .map((baker) => DropdownMenuItem(
                                  value: baker.id,
                                  child: Text(
                                    baker.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: _setMasterBaker,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

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
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ovenRateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Oven deduction / pay per helper (₱)',
                        hintText: '15',
                        prefixIcon: Icon(Icons.payments_outlined),
                        helperText:
                            'The oven helper receives this amount from each other helper.',
                      ),
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
            if (compactProducts)
              _mobileProductsCard(vm)
            else
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
                  const SizedBox(height: 3),
                  const Text(
                    'Add the products and quantities produced in this batch.',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 12),

                  // Column headers
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: const [
                      Expanded(
                        flex: 2,
                        child: Text('Product',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textHint)),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('Sacks',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textHint)),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('+ KG',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textHint)),
                      ),
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
                              flex: 2,
                              child: SizedBox(
                                height: compactProducts ? 32 : 48,
                                child: DropdownButtonFormField<String>(
                                initialValue: item.productId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: 'Select product',
                                  hintStyle: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHint),
                                   contentPadding:
                                       EdgeInsets.symmetric(
                                           horizontal: 12,
                                           vertical: compactProducts ? 0 : 4),
                                   isDense: true,
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
                                            p.name,
                                            style: const TextStyle(
                                                fontSize: 12),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(
                                    () => item.productId = v),
                              ),
                             ),
                             ),
                             const SizedBox(width: 6),

                            // Sacks counter
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Row(children: [
                                _CounterBtn(
                                  icon: Icons.remove,
                                  isLeft: true,
                                  compact: compactProducts,
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
                                    height: compactProducts ? 32 : 48,
                                    child: TextField(
                                      controller: item.sacksCtrl,
                                      keyboardType:
                                          TextInputType.number,
                                    textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w700),
                                       decoration: const InputDecoration(
                                         border: InputBorder.none,
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
                                  compact: compactProducts,
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
                            ),
                            const SizedBox(width: 6),

                            // KG input
                            Expanded(
                              child: SizedBox(
                                 height: compactProducts ? 32 : 48,
                                child: TextField(
                                   controller: item.kgCtrl,
                                  keyboardType: TextInputType.number,
                                    textAlign: TextAlign.left,
                                  style:
                                      const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    suffixText: 'kg',
                                    suffixStyle: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textHint),
                                    contentPadding:
                                        EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: compactProducts ? 0 : 8),
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
                                    final parsed = int.tryParse(v) ?? 0;
                                    setState(() => item.extraKg =
                                        parsed < 0 ? 0 : parsed);
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
                              const SizedBox.shrink(),
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

                  _ProductBreakdown(
                    items: _validItems,
                    products: vm.products,
                  ),
                  if (_validItems.isNotEmpty)
                    const SizedBox(height: 12),

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
                            formatCurrency(previewBakerIncentive),
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
                          Text(salaryLabel,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.text)),
                          Text(
                            formatCurrency(preview.salaryPerWorker +
                                previewBakerIncentive),
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
            SizedBox(height: widget.adminMode ? 0 : 12),
          ],
        ),
      ),
    );

    if (!widget.adminMode) return content;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text('Master Baker Productions',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_outlined,
                color: AppColors.masterBaker),
            onPressed: () => _openHistory(context.read<AuthViewModel>()),
          ),
        ],
      ),
      body: content,
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
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E2E3)),
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
          width: 4,
          height: 19,
          decoration: BoxDecoration(
            color: const Color(0xFF55946B),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF414750),
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

class _ProductBreakdown extends StatelessWidget {
  final List<ProductionItem> items;
  final List<ProductModel> products;

  const _ProductBreakdown({
    required this.items,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final productMap = {for (final product in products) product.id: product};
    final rows = items
        .map((item) {
          final product = productMap[item.productId];
          if (product == null) return null;
          return _BreakdownData(item: item, product: product);
        })
        .whereType<_BreakdownData>()
        .toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.masterBaker.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.masterBaker.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Breakdown',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            _ProductBreakdownItem(data: rows[i]),
            if (i != rows.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppColors.border, height: 1),
              ),
          ],
        ],
      ),
    );

  }
}

class _ProductBreakdownItem extends StatelessWidget {
  final _BreakdownData data;

  const _ProductBreakdownItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final item = data.item;
    final product = data.product;
    final pricePerKg = product.pricePerSack / 25;
    final sacksSubtotal = item.sacks * product.pricePerSack;
    final kgSubtotal = item.extraKg * pricePerKg;
    final subtotal = sacksSubtotal + kgSubtotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        if (item.sacks > 0)
          _BreakdownMoneyRow(
            label:
                '${item.sacks} ${item.sacks == 1 ? 'sack' : 'sacks'} x ${formatCurrency(product.pricePerSack)}',
            value: formatCurrency(sacksSubtotal),
          ),
        if (item.extraKg > 0)
          _BreakdownMoneyRow(
            label:
                '${item.extraKg} kg x ${formatCurrency(pricePerKg)}',
            value: formatCurrency(kgSubtotal),
          ),
        if (item.sacks > 0 && item.extraKg > 0)
          _BreakdownMoneyRow(
            label: 'Subtotal',
            value: formatCurrency(subtotal),
            isSubtotal: true,
          ),
      ],
    );
  }
}

class _BreakdownMoneyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSubtotal;

  const _BreakdownMoneyRow({
    required this.label,
    required this.value,
    this.isSubtotal = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSubtotal ? FontWeight.w700 : FontWeight.w500,
                color: isSubtotal
                    ? AppColors.text
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isSubtotal ? FontWeight.w800 : FontWeight.w700,
              color: isSubtotal
                  ? AppColors.primaryDark
                  : AppColors.text,
            ),
          ),
        ]),
      );
}

class _BreakdownData {
  final ProductionItem item;
  final ProductModel product;

  const _BreakdownData({
    required this.item,
    required this.product,
  });
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLeft;
  final bool compact;
  const _CounterBtn(
      {required this.icon,
      required this.onTap,
      required this.isLeft,
      this.compact = false});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(8) : Radius.zero,
          right: isLeft ? Radius.zero : const Radius.circular(8),
        ),
        child: Container(
          width: compact ? 24 : 32,
          height: compact ? 32 : 48,
          decoration: BoxDecoration(
            color: AppColors.masterBaker.withValues(alpha: 0.06),
            border: Border(
              right: isLeft
                  ? const BorderSide(color: AppColors.border)
                  : BorderSide.none,
              left: isLeft
                  ? BorderSide.none
                  : const BorderSide(color: AppColors.border),
            ),
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
