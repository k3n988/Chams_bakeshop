import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/models/production_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import 'helper_dashboard.dart' show DashColors;

// ─────────────────────────────────────────────────────────
//  ADD PRODUCTION BOTTOM SHEET  (used by helper dashboard)
// ─────────────────────────────────────────────────────────
class AddProductionSheet extends StatefulWidget {
  const AddProductionSheet({super.key});

  @override
  State<AddProductionSheet> createState() => _AddProductionSheetState();
}

class _AddProductionSheetState extends State<AddProductionSheet> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedBakerId;

  List<Map<String, String>> _masterBakers = [];
  List<Map<String, String>> _products = [];
  final List<_BatchItem> _batches = [];

  String? _currentProductId;
  int _currentSacks = 1;
  final _cat60Ctrl = TextEditingController();
  final _cat36Ctrl = TextEditingController();
  final _cat48Ctrl = TextEditingController();
  final _subraCtrl = TextEditingController();
  final _sakaCtrl = TextEditingController();

  int? _editingIndex;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cat60Ctrl.dispose();
    _cat36Ctrl.dispose();
    _cat48Ctrl.dispose();
    _subraCtrl.dispose();
    _sakaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final db = context.read<DatabaseService>();
      final allUsers = await db.getAllUsers();
      _masterBakers = allUsers
          .where((u) => u.role == 'master_baker')
          .map((u) => {'id': u.id, 'name': u.name})
          .toList();

      final allProducts = await db.getAllProducts();
      _products = allProducts.map((p) => {'id': p.id, 'name': p.name}).toList();
      if (_products.isNotEmpty) _currentProductId = _products.first['id'];
    } catch (e) {
      if (mounted) _showSnack('Error loading data: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: DashColors.primary,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addOrUpdateBatch() {
    if (_currentProductId == null) {
      _showSnack('Please select a product first.');
      return;
    }
    final batch = _BatchItem(
      productId: _currentProductId!,
      sacks: _currentSacks,
      timestamp: TimeOfDay.now(),
      cat60: int.tryParse(_cat60Ctrl.text),
      cat36: int.tryParse(_cat36Ctrl.text),
      cat48: int.tryParse(_cat48Ctrl.text),
      subra: int.tryParse(_subraCtrl.text),
      saka: int.tryParse(_sakaCtrl.text),
    );

    setState(() {
      if (_editingIndex != null) {
        _batches[_editingIndex!] = batch;
        _editingIndex = null;
      } else {
        _batches.add(batch);
      }
      _resetBatchForm();
    });
  }

  void _editBatch(int index) {
    final b = _batches[index];
    setState(() {
      _editingIndex = index;
      _currentProductId = b.productId;
      _currentSacks = b.sacks;
      _cat60Ctrl.text = b.cat60?.toString() ?? '';
      _cat36Ctrl.text = b.cat36?.toString() ?? '';
      _cat48Ctrl.text = b.cat48?.toString() ?? '';
      _subraCtrl.text = b.subra?.toString() ?? '';
      _sakaCtrl.text = b.saka?.toString() ?? '';
    });
  }

  void _removeBatch(int index) {
    setState(() {
      _batches.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = null;
        _resetBatchForm();
      }
    });
  }

  void _resetBatchForm() {
    _currentProductId = _products.isNotEmpty ? _products.first['id'] : null;
    _currentSacks = 1;
    _cat60Ctrl.clear();
    _cat36Ctrl.clear();
    _cat48Ctrl.clear();
    _subraCtrl.clear();
    _sakaCtrl.clear();
  }

  Future<void> _save() async {
    if (_selectedBakerId == null) {
      _showSnack('Please select a Master Baker');
      return;
    }
    if (_batches.isEmpty) {
      _showSnack('Add at least one batch to the list');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = context.read<DatabaseService>();
      final currentUser = context.read<AuthViewModel>().currentUser!;
      final formattedDate = _selectedDate.toString().split(' ')[0];

      // Combine duplicate products
      final Map<String, _BatchItem> combined = {};
      for (final b in _batches) {
        if (combined.containsKey(b.productId)) {
          final existing = combined[b.productId]!;
          existing.sacks += b.sacks;
          existing.cat60 = (existing.cat60 ?? 0) + (b.cat60 ?? 0);
          existing.cat36 = (existing.cat36 ?? 0) + (b.cat36 ?? 0);
          existing.cat48 = (existing.cat48 ?? 0) + (b.cat48 ?? 0);
          existing.subra = (existing.subra ?? 0) + (b.subra ?? 0);
          existing.saka  = (existing.saka ?? 0)  + (b.saka ?? 0);
        } else {
          combined[b.productId] = _BatchItem(
            productId: b.productId,
            sacks: b.sacks,
            timestamp: b.timestamp,
            cat60: b.cat60,
            cat36: b.cat36,
            cat48: b.cat48,
            subra: b.subra,
            saka: b.saka,
          );
        }
      }

      final items = combined.values
          .map((e) => ProductionItem(
                productId: e.productId,
                sacks: e.sacks,
                // extraKg not collected in helper batch form (full sacks only)
                cat60: e.cat60,
                cat36: e.cat36,
                cat48: e.cat48,
                subra: e.subra,
                saka: e.saka,
              ))
          .toList();

      // totalWorkers = 1 (master baker) + 1 (this helper logging)
      // Salary/bonus/incentive will be 0 — admin recomputes via payroll service
      final production = ProductionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: formattedDate,
        masterBakerId: _selectedBakerId!,
        helperIds: [currentUser.id],
        items: items,
        totalWorkers: 2, // baker + helper
      );

      await db.insertProduction(production);

      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Production saved successfully!', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError
          ? AppColors.danger
          : isSuccess
              ? const Color(0xFF388E3C)
              : null,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  String _getProductName(String id) => _products
      .firstWhere((p) => p['id'] == id, orElse: () => {'name': 'Unknown'})['name']!;

  String get _formattedDate => _selectedDate.toString().split(' ')[0];
  int get _totalSacks => _batches.fold(0, (s, b) => s + b.sacks);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isLoading
          ? const _LoadingState()
          : Column(children: [
              _SheetHandle(),
              _SheetHeader(onClose: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Global inputs ──
                      _SectionCard(children: [
                        _DateRow(date: _formattedDate, onTap: _pickDate),
                        const SizedBox(height: 12),
                        _masterBakers.isEmpty
                            ? _NoBakersWarning()
                            : _BakerDropdown(
                                value: _selectedBakerId,
                                bakers: _masterBakers,
                                onChanged: (v) =>
                                    setState(() => _selectedBakerId = v),
                              ),
                      ]),
                      const SizedBox(height: 14),

                      // ── Batch form ──
                      _BatchFormSection(
                        editingIndex: _editingIndex,
                        products: _products,
                        currentProductId: _currentProductId,
                        currentSacks: _currentSacks,
                        cat60Ctrl: _cat60Ctrl,
                        cat36Ctrl: _cat36Ctrl,
                        cat48Ctrl: _cat48Ctrl,
                        subraCtrl: _subraCtrl,
                        sakaCtrl: _sakaCtrl,
                        onProductChanged: (v) =>
                            setState(() => _currentProductId = v),
                        onSacksDecrement: _currentSacks > 1
                            ? () => setState(() => _currentSacks--)
                            : null,
                        onSacksIncrement: () =>
                            setState(() => _currentSacks++),
                        onAddOrUpdate: _addOrUpdateBatch,
                      ),
                      const SizedBox(height: 14),

                      // ── Batch list ──
                      _BatchListSection(
                        batches: _batches,
                        editingIndex: _editingIndex,
                        getProductName: _getProductName,
                        onEdit: _editBatch,
                        onRemove: _removeBatch,
                      ),
                    ],
                  ),
                ),
              ),

              _SaveBar(
                batchCount: _batches.length,
                totalSacks: _totalSacks,
                isSaving: _isSaving,
                onSave: _batches.isEmpty ? null : _save,
              ),
            ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 200,
        child: Center(
            child: CircularProgressIndicator(color: DashColors.primary)),
      );
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _SheetHeader({required this.onClose});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DashColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_chart_outlined,
                color: DashColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add Production',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: DashColors.textPrimary,
                      letterSpacing: -0.3)),
              Text('Log your batches & categories',
                  style: TextStyle(fontSize: 12, color: DashColors.textHint)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 22),
            color: DashColors.textHint,
            onPressed: onClose,
          ),
        ]),
      );
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DashColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _DateRow extends StatelessWidget {
  final String date;
  final VoidCallback onTap;
  const _DateRow({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: DashColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DashColors.border),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 17, color: DashColors.textHint),
            const SizedBox(width: 10),
            Text(date,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: DashColors.textPrimary)),
            const Spacer(),
            const Text('Change',
                style: TextStyle(
                    fontSize: 12,
                    color: DashColors.primary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 16, color: DashColors.primary),
          ]),
        ),
      );
}

class _NoBakersWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: const Row(children: [
          Icon(Icons.warning_amber_outlined, color: AppColors.danger, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text('No master bakers found. Contact admin.',
                style: TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
        ]),
      );
}

class _BakerDropdown extends StatelessWidget {
  final String? value;
  final List<Map<String, String>> bakers;
  final ValueChanged<String?> onChanged;
  const _BakerDropdown(
      {required this.value, required this.bakers, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: 'Select Master Baker',
          hintStyle: const TextStyle(fontSize: 13, color: DashColors.textHint),
          prefixIcon:
              const Icon(Icons.person_outline, color: DashColors.primary),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: DashColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: DashColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: DashColors.primary, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
        ),
        items: bakers
            .map((b) => DropdownMenuItem(
                  value: b['id'],
                  child: Text(b['name']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ))
            .toList(),
        onChanged: onChanged,
      );
}

// ── Batch Form ───────────────────────────────────────────
class _BatchFormSection extends StatelessWidget {
  final int? editingIndex;
  final List<Map<String, String>> products;
  final String? currentProductId;
  final int currentSacks;
  final TextEditingController cat60Ctrl;
  final TextEditingController cat36Ctrl;
  final TextEditingController cat48Ctrl;
  final TextEditingController subraCtrl;
  final TextEditingController sakaCtrl;
  final ValueChanged<String?> onProductChanged;
  final VoidCallback? onSacksDecrement;
  final VoidCallback onSacksIncrement;
  final VoidCallback onAddOrUpdate;

  const _BatchFormSection({
    required this.editingIndex,
    required this.products,
    required this.currentProductId,
    required this.currentSacks,
    required this.cat60Ctrl,
    required this.cat36Ctrl,
    required this.cat48Ctrl,
    required this.subraCtrl,
    required this.sakaCtrl,
    required this.onProductChanged,
    required this.onSacksDecrement,
    required this.onSacksIncrement,
    required this.onAddOrUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isEditing = editingIndex != null;
    final accentColor =
        isEditing ? const Color(0xFF1976D2) : DashColors.primary;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
              color: accentColor, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          isEditing ? 'EDITING BATCH #${editingIndex! + 1}' : 'NEW BATCH',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 0.8),
        ),
      ]),
      const SizedBox(height: 8),

      _SectionCard(children: [
        // Product dropdown
        DropdownButtonFormField<String>(
          value: currentProductId,
          decoration: InputDecoration(
            labelText: 'Select Product',
            labelStyle:
                const TextStyle(fontSize: 13, color: DashColors.textHint),
            prefixIcon: const Icon(Icons.bakery_dining_outlined,
                size: 20, color: DashColors.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: DashColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: DashColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: DashColors.primary, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            isDense: true,
          ),
          items: products
              .map((p) => DropdownMenuItem(
                    value: p['id'],
                    child:
                        Text(p['name']!, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: onProductChanged,
        ),
        const SizedBox(height: 14),

        // Sacks counter
        Row(children: [
          const Text('Total Sacks',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: DashColors.textPrimary)),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: DashColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DashColors.border),
            ),
            child: Row(children: [
              _CounterButton(
                  icon: Icons.remove, onPressed: onSacksDecrement),
              Container(
                width: 46,
                alignment: Alignment.center,
                child: Text('$currentSacks',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: DashColors.textPrimary)),
              ),
              _CounterButton(
                  icon: Icons.add, onPressed: onSacksIncrement),
            ]),
          ),
        ]),
        const SizedBox(height: 14),

        // Categories
        const Text('Categories (Optional)',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DashColors.textHint,
                letterSpacing: 0.3)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CategoryField(label: '60',    controller: cat60Ctrl),
            _CategoryField(label: '36',    controller: cat36Ctrl),
            _CategoryField(label: '48',    controller: cat48Ctrl),
            _CategoryField(label: 'Subra', controller: subraCtrl),
            _CategoryField(label: 'Saka',  controller: sakaCtrl),
          ],
        ),
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAddOrUpdate,
            icon: Icon(
                isEditing
                    ? Icons.check_circle_outline
                    : Icons.add_circle_outline,
                size: 18),
            label: Text(
              isEditing ? 'Update Batch' : 'Add to List',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    ]);
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _CounterButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        color: onPressed == null ? DashColors.textHint : DashColors.primary,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      );
}

class _CategoryField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _CategoryField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 65,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                const TextStyle(fontSize: 11, color: DashColors.textHint),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: DashColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: DashColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: DashColors.primary, width: 1.5)),
          ),
        ),
      );
}

// ── Batch List ───────────────────────────────────────────
class _BatchListSection extends StatelessWidget {
  final List<_BatchItem> batches;
  final int? editingIndex;
  final String Function(String) getProductName;
  final void Function(int) onEdit;
  final void Function(int) onRemove;

  const _BatchListSection({
    required this.batches,
    required this.editingIndex,
    required this.getProductName,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
              color: DashColors.textHint,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        const Text('BATCH LIST',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: DashColors.textHint,
                letterSpacing: 0.8)),
        const Spacer(),
        if (batches.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: DashColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${batches.length} batch${batches.length > 1 ? 'es' : ''}',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: DashColors.primary),
            ),
          ),
      ]),
      const SizedBox(height: 8),

      if (batches.isEmpty)
        _EmptyBatchList()
      else
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: batches.length,
          itemBuilder: (context, i) => _BatchTile(
            batch: batches[i],
            index: i,
            isEditing: editingIndex == i,
            productName: getProductName(batches[i].productId),
            onEdit: () => onEdit(i),
            onRemove: () => onRemove(i),
          ),
        ),
    ]);
  }
}

class _EmptyBatchList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DashColors.border),
        ),
        child: Column(children: [
          Icon(Icons.layers_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text('No batches added yet',
              style: TextStyle(
                  color: DashColors.textHint,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text('Fill the form above and tap "Add to List"',
              style: TextStyle(color: DashColors.textHint, fontSize: 11)),
        ]),
      );
}

class _BatchTile extends StatelessWidget {
  final _BatchItem batch;
  final int index;
  final bool isEditing;
  final String productName;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _BatchTile({
    required this.batch,
    required this.index,
    required this.isEditing,
    required this.productName,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cats = <String>[
      if (batch.cat60 != null) '60: ${batch.cat60}',
      if (batch.cat36 != null) '36: ${batch.cat36}',
      if (batch.cat48 != null) '48: ${batch.cat48}',
      if (batch.subra != null) 'Subra: ${batch.subra}',
      if (batch.saka  != null) 'Saka: ${batch.saka}',
    ];
    final accentColor =
        isEditing ? const Color(0xFF1976D2) : DashColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isEditing ? const Color(0xFF1976D2) : DashColors.border,
            width: isEditing ? 1.5 : 1),
        boxShadow: [
          if (isEditing)
            BoxShadow(
                color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('${index + 1}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accentColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: DashColors.textPrimary)),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: DashColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${batch.sacks} sacks',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: DashColors.primary)),
              ),
              if (cats.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(cats.join(' · '),
                    style: const TextStyle(
                        fontSize: 11, color: DashColors.textHint)),
              ],
            ]),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _IconBtn(
                icon: Icons.edit_outlined,
                color: const Color(0xFF1976D2),
                onTap: onEdit),
            _IconBtn(
                icon: Icons.delete_outline,
                color: AppColors.danger,
                onTap: onRemove),
          ]),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: 20),
        color: color,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      );
}

// ── Save Bar ─────────────────────────────────────────────
class _SaveBar extends StatelessWidget {
  final int batchCount;
  final int totalSacks;
  final bool isSaving;
  final VoidCallback? onSave;

  const _SaveBar({
    required this.batchCount,
    required this.totalSacks,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -3)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (batchCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DashColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$batchCount batch${batchCount > 1 ? 'es' : ''}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: DashColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('$totalSacks total sacks',
                      style: const TextStyle(
                          fontSize: 13,
                          color: DashColors.primaryDark,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isSaving || onSave == null ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(isSaving ? 'Saving…' : 'Save Production',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                disabledForegroundColor: Colors.grey[400],
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────
//  BATCH ITEM MODEL
// ─────────────────────────────────────────────────────────
class _BatchItem {
  String productId;
  int sacks;
  final TimeOfDay timestamp;
  int? cat60;
  int? cat36;
  int? cat48;
  int? subra;
  int? saka;

  _BatchItem({
    required this.productId,
    required this.sacks,
    required this.timestamp,
    this.cat60,
    this.cat36,
    this.cat48,
    this.subra,
    this.saka,
  });
}