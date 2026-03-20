import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/seller_session_viewmodel.dart';

class SellerRemitScreen extends StatefulWidget {
  final RemitType remitType;

  const SellerRemitScreen({
    super.key,
    required this.remitType,
  });

  @override
  State<SellerRemitScreen> createState() => _SellerRemitScreenState();
}

class _SellerRemitScreenState extends State<SellerRemitScreen> {
  final _returnCtrl   = TextEditingController();
  final _remittedCtrl = TextEditingController();

  int    get _returnPieces    => int.tryParse(_returnCtrl.text) ?? 0;
  double get _actualRemittance => double.tryParse(_remittedCtrl.text) ?? 0.0;

  bool get _isMorning => widget.remitType == RemitType.morning;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<SellerSessionViewModel>();
      // Pre-fill if editing existing remittance
      final existing = _isMorning
          ? vm.morningRemittance
          : vm.afternoonRemittance;
      if (existing != null) {
        _returnCtrl.text   = existing.returnPieces.toString();
        _remittedCtrl.text =
            existing.actualRemittance.toStringAsFixed(0);
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
  int    _piecesSold(int total) => (total - _returnPieces).clamp(0, total);
  double _adjusted(int total)   => _piecesSold(total) * 5.0;
  double _variance(int total)   => _actualRemittance - _adjusted(total);

  Future<void> _submit() async {
    final vm        = context.read<SellerSessionViewModel>();
    final uid       = context.read<AuthViewModel>().currentUser!.id;
    final messenger = ScaffoldMessenger.of(context);

    if (_remittedCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Please enter the amount remitted'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    final int totalTaken = _isMorning
        ? vm.morningPiecesTaken
        : vm.afternoonPiecesTaken;

    if (_returnPieces > totalTaken) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Return pieces cannot exceed total pieces taken'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    final hasExisting = _isMorning
        ? vm.hasMorningRemittance
        : vm.hasAfternoonRemittance;

    bool ok;
    if (hasExisting) {
      ok = await vm.updateRemittance(
        returnPieces:     _returnPieces,
        actualRemittance: _actualRemittance,
        remitType:        widget.remitType,
      );
    } else {
      ok = await vm.createRemittance(
        sellerId:         uid,
        returnPieces:     _returnPieces,
        actualRemittance: _actualRemittance,
        remitType:        widget.remitType,
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
    final vm = context.watch<SellerSessionViewModel>();

    final session    = _isMorning ? vm.morningSession : vm.afternoonSession;
    final totalTaken = _isMorning
        ? vm.morningPiecesTaken
        : vm.afternoonPiecesTaken;
    final hasExisting = _isMorning
        ? vm.hasMorningRemittance
        : vm.hasAfternoonRemittance;

    final primaryColor = _isMorning
        ? const Color(0xFF1976D2)
        : AppColors.success;
    final sessionLabel = _isMorning ? 'Morning' : 'Afternoon';

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
        title: Text(
          hasExisting
              ? 'Edit $sessionLabel Remittance'
              : '$sessionLabel Remittance',
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.text),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Session summary ────────────────────────────────
            if (session != null)
              _SessionSummaryBanner(
                session:    session,
                totalPieces: totalTaken,
                color:      _isMorning ? AppColors.seller : AppColors.warning,
                label:      sessionLabel,
              ),
            const SizedBox(height: 20),

            // ── Input card ─────────────────────────────────────
            _WhiteCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardLabel('REMITTANCE DETAILS',
                      color: primaryColor),
                  const SizedBox(height: 16),

                  _InputField(
                    controller: _returnCtrl,
                    label:  'Returned Pieces',
                    hint:   '0',
                    icon:   Icons.undo_outlined,
                    suffix: 'pieces',
                    color:  AppColors.warning,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'Pieces sold: ${_piecesSold(totalTaken)} '
                      '($totalTaken taken − $_returnPieces returned)',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _InputField(
                    controller: _remittedCtrl,
                    label:     'Actual Cash Remitted',
                    hint:      '0.00',
                    icon:      Icons.payments_outlined,
                    suffix:    '₱',
                    color:     AppColors.success,
                    onChanged: (_) => setState(() {}),
                    isDecimal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Live breakdown ─────────────────────────────────
            _RemittanceBreakdown(
              totalTaken:         totalTaken,
              returnPieces:       _returnPieces,
              piecesSold:         _piecesSold(totalTaken),
              adjustedRemittance: _adjusted(totalTaken),
              actualRemittance:   _actualRemittance,
              variance:           _variance(totalTaken),
            ),
            const SizedBox(height: 28),

            // ── Submit ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: vm.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: vm.isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5)
                    : Text(
                        hasExisting
                            ? 'Update Remittance'
                            : 'Submit Remittance',
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
  final dynamic session;
  final int     totalPieces;
  final Color   color;
  final String  label;
  const _SessionSummaryBanner({
    required this.session,
    required this.totalPieces,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.storefront_outlined,
                color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label Session',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                Text(
                  '${session.plantsaCount} plantsa '
                  '+ ${session.subraPieces} subra '
                  '= $totalPieces pieces',
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
                formatCurrency(session.expectedRemittance),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color),
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

  Color get _vColor {
    if (variance > 0) return AppColors.success;
    if (variance < 0) return AppColors.danger;
    return AppColors.textHint;
  }

  String get _vLabel {
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
            const _CardLabel('BREAKDOWN', color: AppColors.seller),
            const SizedBox(height: 14),
            _BRow(
                icon: Icons.inventory_2_outlined,
                label: 'Total taken out',
                value: '$totalTaken pieces',
                color: AppColors.text),
            _BRow(
                icon: Icons.undo_outlined,
                label: 'Returned',
                value: '−$returnPieces pieces',
                color: AppColors.warning),
            _BRow(
                icon: Icons.sell_outlined,
                label: 'Sold',
                value: '$piecesSold pieces',
                color: AppColors.success),
            const Divider(height: 20, color: AppColors.border),
            _BRow(
                icon: Icons.calculate_outlined,
                label: 'Should remit ($piecesSold × ₱5)',
                value: formatCurrency(adjustedRemittance),
                color: AppColors.primaryDark,
                bold: true),
            _BRow(
                icon: Icons.payments_outlined,
                label: 'Actual remitted',
                value: formatCurrency(actualRemittance),
                color: AppColors.primaryDark,
                bold: true),
            const Divider(height: 20, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.balance_outlined, size: 16, color: _vColor),
                  const SizedBox(width: 8),
                  Text('Variance ($_vLabel)',
                      style: TextStyle(
                          fontSize: 13,
                          color: _vColor,
                          fontWeight: FontWeight.w700)),
                ]),
                Text(
                  variance >= 0
                      ? '+${formatCurrency(variance)}'
                      : formatCurrency(variance),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _vColor),
                ),
              ],
            ),
          ],
        ),
      );
}

class _BRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final bool     bold;
  const _BRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
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
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
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
  final Color  color;
  const _CardLabel(this.text, {required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
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
  final String                label;
  final String                hint;
  final IconData              icon;
  final String                suffix;
  final Color                 color;
  final void Function(String) onChanged;
  final bool                  isDecimal;

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
            ? [FilteringTextInputFormatter.allow(
                RegExp(r'^\d+\.?\d{0,2}'))]
            : [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText:  hint,
          prefixIcon: Icon(icon, color: color, size: 20),
          suffixText: suffix,
          suffixStyle:
              const TextStyle(color: AppColors.textHint, fontSize: 13),
          filled:    true,
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