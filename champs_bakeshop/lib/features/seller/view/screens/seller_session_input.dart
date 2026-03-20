import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';

import '../../../auth/viewmodel/auth_viewmodel.dart';

import '../../viewmodel/seller_session_viewmodel.dart';
import 'package:flutter/services.dart';

class SellerSessionInputScreen extends StatefulWidget {
  const SellerSessionInputScreen({super.key});

  @override
  State<SellerSessionInputScreen> createState() =>
      _SellerSessionInputScreenState();
}

class _SellerSessionInputScreenState
    extends State<SellerSessionInputScreen> {
  final _plantsaCtrl = TextEditingController();
  final _subraCtrl   = TextEditingController();

  static const int _piecesPerPlantsa = 25;
  static const double _pricePerPiece = 5.0;

  // ── Live preview ───────────────────────────────────────────
  int get _plantsa => int.tryParse(_plantsaCtrl.text) ?? 0;
  int get _subra   => int.tryParse(_subraCtrl.text)   ?? 0;
  int get _totalPieces => (_plantsa * _piecesPerPlantsa) + _subra;
  double get _expectedRemittance => _totalPieces * _pricePerPiece;

  @override
  void dispose() {
    _plantsaCtrl.dispose();
    _subraCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_plantsa == 0 && _subra == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 1 plantsa or subra pieces'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final vm  = context.read<SellerSessionViewModel>();
    final uid = context.read<AuthViewModel>().currentUser!.id;
    final messenger = ScaffoldMessenger.of(context);

    final ok = await vm.createSession(
      sellerId:     uid,
      plantsaCount: _plantsa,
      subraPieces:  _subra,
    );

    if (ok && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Session started! Good luck selling 🥖'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted && vm.error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(vm.error!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SellerSessionViewModel>();
    final today = DateTime.now();
    final dateLabel =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

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
        title: const Text('Morning Session',
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
            // ── Date header ────────────────────────────────────
            _DateHeader(dateLabel: dateLabel),
            const SizedBox(height: 20),

            // ── Instruction card ───────────────────────────────
            _InfoCard(
              icon: Icons.info_outline,
              color: AppColors.seller,
              text:
                  'Enter the number of plantsa and extra pieces (subra) you are taking out to sell today. Each plantsa contains $_piecesPerPlantsa pieces of pandesal at ₱${_pricePerPiece.toStringAsFixed(0)} each.',
            ),
            const SizedBox(height: 20),

            // ── Input card ─────────────────────────────────────
            _WhiteCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardLabel('PANDESAL TAKEN OUT'),
                  const SizedBox(height: 16),

                  // Plantsa input
                  _InputField(
                    controller: _plantsaCtrl,
                    label: 'Number of Plantsa',
                    hint: 'e.g. 5',
                    icon: Icons.grid_view_outlined,
                    suffix: 'plantsa',
                    color: AppColors.seller,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      '$_plantsa plantsa × $_piecesPerPlantsa pieces = ${_plantsa * _piecesPerPlantsa} pieces',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subra input
                  _InputField(
                    controller: _subraCtrl,
                    label: 'Subra (extra pieces)',
                    hint: 'e.g. 5',
                    icon: Icons.add_circle_outline,
                    suffix: 'pieces',
                    color: const Color(0xFF1976D2),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Live preview card ──────────────────────────────
            _PreviewCard(
              totalPieces:         _totalPieces,
              expectedRemittance:  _expectedRemittance,
              plantsa:             _plantsa,
              subra:               _subra,
              piecesPerPlantsa:    _piecesPerPlantsa,
              pricePerPiece:       _pricePerPiece,
            ),
            const SizedBox(height: 28),

            // ── Submit button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: vm.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.seller,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: vm.isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5)
                    : const Text('Start Selling',
                        style: TextStyle(
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

// ── Preview card ──────────────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  final int    totalPieces;
  final double expectedRemittance;
  final int    plantsa;
  final int    subra;
  final int    piecesPerPlantsa;
  final double pricePerPiece;

  const _PreviewCard({
    required this.totalPieces,
    required this.expectedRemittance,
    required this.plantsa,
    required this.subra,
    required this.piecesPerPlantsa,
    required this.pricePerPiece,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.seller,
              AppColors.seller.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.seller.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.receipt_outlined,
                  size: 14, color: Colors.white70),
              SizedBox(width: 6),
              Text('EXPECTED REMITTANCE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 0.8)),
            ]),
            const SizedBox(height: 10),
            Text(
              formatCurrency(expectedRemittance),
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                _CalcRow(
                  label: 'Plantsa (${plantsa} × $piecesPerPlantsa)',
                  value: '${plantsa * piecesPerPlantsa} pieces',
                ),
                const SizedBox(height: 6),
                _CalcRow(label: 'Subra', value: '$subra pieces'),
                const Divider(height: 14, color: Colors.white30),
                _CalcRow(
                  label: 'Total × ₱${pricePerPiece.toStringAsFixed(0)}',
                  value: '$totalPieces pcs = ${formatCurrency(expectedRemittance)}',
                  isBold: true,
                ),
              ]),
            ),
          ],
        ),
      );
}

class _CalcRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   isBold;
  const _CalcRow(
      {required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight:
                      isBold ? FontWeight.w800 : FontWeight.w500)),
        ],
      );
}

// ── Shared sub-widgets ────────────────────────────────────────
class _DateHeader extends StatelessWidget {
  final String dateLabel;
  const _DateHeader({required this.dateLabel});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.seller.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.wb_sunny_outlined,
              color: AppColors.seller, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Morning Session',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
            Text(dateLabel,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ]);
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   text;
  const _InfoCard(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
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
  final Widget               child;
  final EdgeInsetsGeometry?  padding;
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

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.suffix,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: color.withValues(alpha: 0.20)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
      );
}