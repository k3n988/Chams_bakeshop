import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';

import '../../../auth/viewmodel/auth_viewmodel.dart';

import '../../viewmodel/seller_session_viewmodel.dart';
import 'package:flutter/services.dart';

class SellerRemitScreen extends StatefulWidget {
  const SellerRemitScreen({super.key});

  @override
  State<SellerRemitScreen> createState() => _SellerRemitScreenState();
}

class _SellerRemitScreenState extends State<SellerRemitScreen> {
  final _returnCtrl    = TextEditingController();
  final _remittedCtrl  = TextEditingController();

  int get _returnPieces => int.tryParse(_returnCtrl.text) ?? 0;
  double get _actualRemittance =>
      double.tryParse(_remittedCtrl.text) ?? 0.0;

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing existing remittance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<SellerSessionViewModel>();
      if (vm.hasRemittanceToday) {
        _returnCtrl.text   = vm.returnPieces.toString();
        _remittedCtrl.text = vm.actualRemittance.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _returnCtrl.dispose();
    _remittedCtrl.dispose();
    super.dispose();
  }

  // ── Live preview ───────────────────────────────────────────
  int _piecesSold(int totalTaken) =>
      (totalTaken - _returnPieces).clamp(0, totalTaken);

  double _adjustedRemittance(int totalTaken) =>
      _piecesSold(totalTaken) * 5.0;

  double _variance(int totalTaken) =>
      _actualRemittance - _adjustedRemittance(totalTaken);

  Future<void> _submit() async {
    final vm  = context.read<SellerSessionViewModel>();
    final uid = context.read<AuthViewModel>().currentUser!.id;
    final messenger = ScaffoldMessenger.of(context);

    if (_remittedCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Please enter the amount remitted'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    final int totalTaken = vm.totalPiecesTaken;
    if (_returnPieces > totalTaken) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Return pieces cannot exceed total pieces taken'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    bool ok;
    if (vm.hasRemittanceToday) {
      ok = await vm.updateRemittance(
        returnPieces:     _returnPieces,
        actualRemittance: _actualRemittance,
      );
    } else {
      ok = await vm.createRemittance(
        sellerId:         uid,
        returnPieces:     _returnPieces,
        actualRemittance: _actualRemittance,
      );
    }

    if (ok && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Remittance submitted! ✅'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted && vm.error != null) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(vm.error!),
            backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm         = context.watch<SellerSessionViewModel>();
    final totalTaken = vm.totalPiecesTaken;
    final isEdit     = vm.hasRemittanceToday;

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
        title: Text(isEdit ? 'Edit Remittance' : 'Evening Remittance',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Session summary ────────────────────────────────
            _SessionSummaryBanner(vm: vm),
            const SizedBox(height: 20),

            // ── Input card ─────────────────────────────────────
            _WhiteCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardLabel('REMITTANCE DETAILS'),
                  const SizedBox(height: 16),

                  // Return pieces
                  _InputField(
                    controller: _returnCtrl,
                    label: 'Returned Pieces',
                    hint: '0',
                    icon: Icons.undo_outlined,
                    suffix: 'pieces',
                    color: AppColors.warning,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'Pieces sold: ${_piecesSold(totalTaken)} '
                      '(${totalTaken} taken − $_returnPieces returned)',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Actual remittance
                  _InputField(
                    controller: _remittedCtrl,
                    label: 'Actual Cash Remitted',
                    hint: '0.00',
                    icon: Icons.payments_outlined,
                    suffix: '₱',
                    color: AppColors.success,
                    onChanged: (_) => setState(() {}),
                    isDecimal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Live breakdown ─────────────────────────────────
            _RemittanceBreakdown(
              totalTaken:          totalTaken,
              returnPieces:        _returnPieces,
              piecesSold:          _piecesSold(totalTaken),
              adjustedRemittance:  _adjustedRemittance(totalTaken),
              actualRemittance:    _actualRemittance,
              variance:            _variance(totalTaken),
            ),
            const SizedBox(height: 28),

            // ── Submit ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: vm.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: vm.isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5)
                    : Text(isEdit ? 'Update Remittance' : 'Submit Remittance',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session summary banner ────────────────────────────────────
class _SessionSummaryBanner extends StatelessWidget {
  final SellerSessionViewModel vm;
  const _SessionSummaryBanner({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.seller.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.seller.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.seller.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_outlined,
                color: AppColors.seller, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Morning Session',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                Text(
                  '${vm.todaySession?.plantsaCount ?? 0} plantsa '
                  '+ ${vm.todaySession?.subraPieces ?? 0} subra '
                  '= ${vm.totalPiecesTaken} pieces',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Expected',
                  style: TextStyle(
                      fontSize: 10, color: AppColors.textHint)),
              Text(
                formatCurrency(vm.expectedRemittance),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.seller),
              ),
            ],
          ),
        ]),
      );
}

// ── Remittance breakdown ──────────────────────────────────────
class _RemittanceBreakdown extends StatelessWidget {
  final int    totalTaken;
  final int    returnPieces;
  final int    piecesSold;
  final double adjustedRemittance;
  final double actualRemittance;
  final double variance;

  const _RemittanceBreakdown({
    required this.totalTaken,
    required this.returnPieces,
    required this.piecesSold,
    required this.adjustedRemittance,
    required this.actualRemittance,
    required this.variance,
  });

  Color get _varianceColor {
    if (variance > 0) return AppColors.success;
    if (variance < 0) return AppColors.danger;
    return AppColors.textHint;
  }

  String get _varianceLabel {
    if (variance > 0) return 'Overpaid';
    if (variance < 0) return 'Short';
    return 'Exact';
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
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
          children: [
            const _CardLabel('BREAKDOWN'),
            const SizedBox(height: 14),
            _BreakdownRow(
              icon: Icons.inventory_2_outlined,
              label: 'Total taken out',
              value: '$totalTaken pieces',
              color: AppColors.text,
            ),
            _BreakdownRow(
              icon: Icons.undo_outlined,
              label: 'Returned',
              value: '−$returnPieces pieces',
              color: AppColors.warning,
            ),
            _BreakdownRow(
              icon: Icons.sell_outlined,
              label: 'Sold',
              value: '$piecesSold pieces',
              color: AppColors.success,
            ),
            const Divider(height: 20, color: AppColors.border),
            _BreakdownRow(
              icon: Icons.calculate_outlined,
              label: 'Should remit ($piecesSold × ₱5)',
              value: formatCurrency(adjustedRemittance),
              color: AppColors.primaryDark,
              isBold: true,
            ),
            _BreakdownRow(
              icon: Icons.payments_outlined,
              label: 'Actual remitted',
              value: formatCurrency(actualRemittance),
              color: AppColors.primaryDark,
              isBold: true,
            ),
            const Divider(height: 20, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.balance_outlined,
                      size: 16, color: _varianceColor),
                  const SizedBox(width: 8),
                  Text('Variance ($_varianceLabel)',
                      style: TextStyle(
                          fontSize: 13,
                          color: _varianceColor,
                          fontWeight: FontWeight.w700)),
                ]),
                Text(
                  variance >= 0
                      ? '+${formatCurrency(variance)}'
                      : formatCurrency(variance),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _varianceColor),
                ),
              ],
            ),
          ],
        ),
      );
}

class _BreakdownRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final bool     isBold;

  const _BreakdownRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 15, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w600,
                  color: color)),
        ]),
      );
}

// ── Shared sub-widgets ────────────────────────────────────────
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
          width: 3,
          height: 13,
          decoration: BoxDecoration(
              color: AppColors.seller,
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String   label;
  final String   hint;
  final IconData icon;
  final String   suffix;
  final Color    color;
  final void Function(String) onChanged;
  final bool     isDecimal;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.suffix,
    required this.color,
    required this.onChanged,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: isDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: isDecimal
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
            : [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: color, size: 20),
          suffixText: suffix,
          suffixStyle:
              const TextStyle(color: AppColors.textHint, fontSize: 13),
          filled: true,
          fillColor: color.withValues(alpha: 0.04),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: color.withValues(alpha: 0.3))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: color.withValues(alpha: 0.20))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2)),
        ),
      );
}