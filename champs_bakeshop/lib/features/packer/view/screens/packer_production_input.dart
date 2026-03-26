import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/packer_production_viewmodel.dart';
import '../../viewmodel/packer_salary_viewmodel.dart';

class PackerProductionInputScreen extends StatefulWidget {
  const PackerProductionInputScreen({super.key});

  @override
  State<PackerProductionInputScreen> createState() =>
      _PackerProductionInputScreenState();
}

class _PackerProductionInputScreenState
    extends State<PackerProductionInputScreen> {
  final _bundleCtrl = TextEditingController();

  String?  _selectedProduct;
  DateTime _entryDate = DateTime.now();

  int    get _bundles       => int.tryParse(_bundleCtrl.text) ?? 0;
  double get _previewSalary => _bundles * AppConstants.packerRatePerBundle;

  // ── Listen for late-loading products ──────────────────────
  void _onVmChange() {
    if (!mounted) return;
    final vm = context.read<PackerProductionViewModel>();
    if (_selectedProduct == null && vm.productNames.isNotEmpty) {
      setState(() => _selectedProduct = vm.productNames.first);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<PackerProductionViewModel>();
      if (vm.productNames.isNotEmpty && _selectedProduct == null) {
        setState(() => _selectedProduct = vm.productNames.first);
      }
      vm.addListener(_onVmChange);
    });
  }

  @override
  void dispose() {
    context.read<PackerProductionViewModel>().removeListener(_onVmChange);
    _bundleCtrl.dispose();
    super.dispose();
  }

  // ── Date picker ────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(DateTime.now().year - 1, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.packer,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _entryDate = picked);
  }

  String get _dateLabel {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[_entryDate.month - 1]} ${_entryDate.day}, ${_entryDate.year}';
  }

  bool get _isToday {
    final now = DateTime.now();
    return _entryDate.year  == now.year &&
           _entryDate.month == now.month &&
           _entryDate.day   == now.day;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.danger : AppColors.success,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedProduct == null) {
      _showSnack('Please select a product', isError: true);
      return;
    }
    if (_bundles <= 0) {
      _showSnack('Please enter at least 1 bundle', isError: true);
      return;
    }

    final vm        = context.read<PackerProductionViewModel>();
    final salaryVm  = context.read<PackerSalaryViewModel>();
    final uid       = context.read<AuthViewModel>().currentUser!.id;

    vm.clearError();

    final ok = await vm.addProduction(
      packerId:    uid,
      productName: _selectedProduct!,
      bundleCount: _bundles,
      entryDate:   _entryDate,
    );

    if (!mounted) return;

    if (ok) {
      _showSnack('Production added!');
      _bundleCtrl.clear();
      setState(() {});
      // Refresh yearly totals in profile
      salaryVm.reloadYear(uid);
    } else if (vm.error != null) {
      _showSnack(vm.error!, isError: true);
      vm.clearError();
    }
  }

  // ── Delete with confirmation ───────────────────────────────
  Future<void> _confirmDelete(dynamic prod, String packerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Remove ${prod.bundleCount} bundles of '
          '"${prod.productName}"?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.danger),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final vm       = context.read<PackerProductionViewModel>();
    final salaryVm = context.read<PackerSalaryViewModel>();

    final ok = await vm.deleteProduction(prod.id, packerId);
    if (!mounted) return;

    if (ok) {
      _showSnack('Entry deleted');
      salaryVm.reloadYear(packerId);
    } else if (vm.error != null) {
      _showSnack(vm.error!, isError: true);
      vm.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<PackerProductionViewModel>();
    final uid = context.read<AuthViewModel>().currentUser!.id;

    // Productions for selected date
    final selectedProds = vm.selectedDayProductions.isNotEmpty
        ? vm.selectedDayProductions
        : (_isToday ? vm.todayProductions : <dynamic>[]);

    final totalBundles =
        selectedProds.fold<int>(0, (s, p) => s + (p.bundleCount as int));
    final totalSalary =
        totalBundles * AppConstants.packerRatePerBundle;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Production',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date selector ──────────────────────────────────
            _DateSelectorCard(
              dateLabel: _dateLabel,
              isToday:   _isToday,
              onTap:     _pickDate,
            ),
            const SizedBox(height: 16),

            // ── Info banner ────────────────────────────────────
            _InfoBanner(
              text: 'Each bundle earns '
                  '${formatCurrency(AppConstants.packerRatePerBundle)}. '
                  'You can add multiple entries per day.',
            ),
            const SizedBox(height: 16),

            // ── Input card ─────────────────────────────────────
            _WhiteCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardLabel('PRODUCTION ENTRY'),
                  const SizedBox(height: 16),

                  // ── Product from admin ────────────────────────
                  const Text('Product',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),

                  if (vm.isLoading && vm.productNames.isEmpty)
                    const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.packer, strokeWidth: 2),
                    )
                  else if (vm.productNames.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.warning
                                .withValues(alpha: 0.25)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.warning_amber_outlined,
                            size: 16, color: AppColors.warning),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No products found. Ask admin to add products.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning),
                          ),
                        ),
                      ]),
                    )
                  else
                    _ProductChips(
                      products:  vm.productNames,
                      selected:  _selectedProduct ?? '',
                      onChanged: (v) =>
                          setState(() => _selectedProduct = v),
                    ),

                  const SizedBox(height: 16),

                  // ── Bundle count ──────────────────────────────
                  TextField(
                    controller: _bundleCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Number of Bundles',
                      hintText:  'e.g. 25',
                      prefixIcon: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.packer,
                          size: 20),
                      suffixText: 'bundles',
                      suffixStyle: const TextStyle(
                          color: AppColors.textHint, fontSize: 13),
                      filled:    true,
                      fillColor:
                          AppColors.packer.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppColors.packer
                                  .withValues(alpha: 0.3))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppColors.packer
                                  .withValues(alpha: 0.20))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.packer, width: 2)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Preview card ───────────────────────────────────
            _PreviewCard(
              product: _selectedProduct ?? '—',
              bundles: _bundles,
              salary:  _previewSalary,
            ),
            const SizedBox(height: 28),

            // ── Submit button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: vm.isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.add, color: Colors.white),
                label: Text(
                  vm.isLoading ? 'Adding...' : 'Add Production',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.packer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: vm.isLoading ? null : _submit,
              ),
            ),

            const SizedBox(height: 24),

            // ── Entries for selected date ──────────────────────
            if (selectedProds.isNotEmpty) ...[
              _CardLabel(
                _isToday ? "TODAY'S ENTRIES" : 'ENTRIES FOR $_dateLabel',
              ),
              const SizedBox(height: 10),
              ...selectedProds.map((p) => _EntryRow(
                    prod:     p,
                    packerId: uid,
                    onDelete: () => _confirmDelete(p, uid),
                  )),
              const Divider(height: 20, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.text)),
                  Text(
                    '$totalBundles bundles = ${formatCurrency(totalSalary)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.packer),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Date selector card ────────────────────────────────────────
class _DateSelectorCard extends StatelessWidget {
  final String     dateLabel;
  final bool       isToday;
  final VoidCallback onTap;
  const _DateSelectorCard({
    required this.dateLabel,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.packer.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.packer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  color: AppColors.packer, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Entry Date',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    isToday ? 'Today — $dateLabel' : dateLabel,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.packer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Change',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.packer)),
            ),
          ]),
        ),
      );
}

// ── Dynamic product chips ─────────────────────────────────────
class _ProductChips extends StatelessWidget {
  final List<String>          products;
  final String                selected;
  final void Function(String) onChanged;
  const _ProductChips({
    required this.products,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: products.map((p) {
          final isSelected = p == selected;
          return GestureDetector(
            onTap: () => onChanged(p),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.packer
                    : AppColors.packer.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected
                        ? AppColors.packer
                        : AppColors.packer.withValues(alpha: 0.20)),
              ),
              child: Text(p,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : AppColors.packer)),
            ),
          );
        }).toList(),
      );
}

// ── Preview card ──────────────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  final String product;
  final int    bundles;
  final double salary;
  const _PreviewCard({
    required this.product,
    required this.bundles,
    required this.salary,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
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
              Icon(Icons.calculate_outlined,
                  size: 14, color: Colors.white70),
              SizedBox(width: 6),
              Text('SALARY PREVIEW',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 0.8)),
            ]),
            const SizedBox(height: 10),
            Text(
              formatCurrency(salary),
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(product,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text(
                    '$bundles bundles × '
                    '${formatCurrency(AppConstants.packerRatePerBundle)}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Entry row with delete ─────────────────────────────────────
class _EntryRow extends StatelessWidget {
  final dynamic      prod;
  final String       packerId;
  final VoidCallback onDelete;
  const _EntryRow({
    required this.prod,
    required this.packerId,
    required this.onDelete,
  });

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
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.packer.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.packer.withValues(alpha: 0.12)),
        ),
        child: Row(children: [
          const Icon(Icons.inventory_2_outlined,
              size: 14, color: AppColors.packer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(prod.productName,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary)),
          ),
          Text('${prod.bundleCount} bundles',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.packer)),
          const SizedBox(width: 10),
          Text(_formatTime(prod.timestamp),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.delete_outline,
                size: 16,
                color: AppColors.danger.withValues(alpha: 0.7)),
          ),
        ]),
      );
}

// ── Shared sub-widgets ────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.packer.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.packer.withValues(alpha: 0.20)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                size: 16, color: AppColors.packer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
}

class _WhiteCard extends StatelessWidget {
  final Widget              child;
  final EdgeInsetsGeometry? padding;
  const _WhiteCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
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
        child: child,
      );
}

class _CardLabel extends StatelessWidget {
  final String text;
  const _CardLabel(this.text);

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
