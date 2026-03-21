import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/seller_session_model.dart';
import '../../../../core/models/seller_remittance_model.dart';
import '../../../../core/services/seller_service.dart';
import '../../viewmodel/admin_user_viewmodel.dart';

// ══════════════════════════════════════════════════════════════
//  SELLER PAYROLL TAB  — daily view, salary, mark paid (red)
// ══════════════════════════════════════════════════════════════
class SellerPayrollTab extends StatefulWidget {
  const SellerPayrollTab({super.key});

  @override
  State<SellerPayrollTab> createState() => _SellerPayrollTabState();
}

class _SellerPayrollTabState extends State<SellerPayrollTab> {
  final _service = SellerService();

  // Default to today
  DateTime _selectedDate = DateTime.now();
  bool     _isLoading    = false;
  String?  _error;

  Map<String, List<SellerSessionModel>>    _sessions    = {};
  Map<String, List<SellerRemittanceModel>> _remittances = {};

  // Tracks which sellers are marked paid for the selected date
  final Set<String> _paidSellerIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  // ── Date helpers ───────────────────────────────────────────
  String get _dateStr => _selectedDate.toIso8601String().substring(0, 10);

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _displayDate {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final d = _selectedDate;
    return '${weekdays[d.weekday - 1]}, ${months[d.month]} ${d.day}, ${d.year}';
  }

  // ── Data loading ───────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final sellers = context
          .read<AdminUserViewModel>()
          .nonAdminUsers
          .where((u) => u.isSeller)
          .toList();

      final newSessions    = <String, List<SellerSessionModel>>{};
      final newRemittances = <String, List<SellerRemittanceModel>>{};

      await Future.wait(sellers.map((s) async {
        newSessions[s.id] = await _service.getSessionsByRange(
          sellerId: s.id, fromDate: _dateStr, toDate: _dateStr,
        );
        newRemittances[s.id] = await _service.getRemittancesByRange(
          sellerId: s.id, fromDate: _dateStr, toDate: _dateStr,
        );
      }));

      _paidSellerIds.clear(); // reset paid state on date change

      setState(() {
        _sessions    = newSessions;
        _remittances = newRemittances;
        _isLoading   = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _changeDate(int dir) async {
    final next = _selectedDate.add(Duration(days: dir));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = next);
    await _load();
  }

  // ── Calendar picker — defaults to today ───────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedDate,
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   Color(0xFFFF7A00),
            onPrimary: Colors.white,
            surface:   Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      await _load();
    }
  }

  // ── Remittance dialog ──────────────────────────────────────
  void _showRemittanceDialog(
    UserModel              seller,
    SellerSessionModel     session,
    SellerRemittanceModel? existing,
  ) {
    final returnCtrl = TextEditingController(
        text: existing?.returnPieces.toString() ?? '0');
    final cashCtrl = TextEditingController(
        text: existing != null
            ? existing.actualRemittance.toStringAsFixed(0) : '');
    double selectedPct = 0.05;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final returnPieces = int.tryParse(returnCtrl.text) ?? 0;
          final actualCash   = double.tryParse(cashCtrl.text) ?? 0.0;
          final total        = session.totalPiecesTaken;
          final sold         = (total - returnPieces).clamp(0, total);
          final adjusted     = sold * 5.0;
          final variance     = actualCash - adjusted;
          final salary       = adjusted * selectedPct;
          final vColor       = variance >= 0 ? AppColors.success : AppColors.danger;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.seller.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  session.isMorning ? Icons.wb_sunny_outlined : Icons.wb_twilight_outlined,
                  color: AppColors.seller, size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${session.isMorning ? 'Morning' : 'Afternoon'} Remittance',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(seller.name,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w400)),
              ])),
            ]),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 12),
                // Session info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.seller.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(children: [
                    _DlgInfoRow(
                      label: 'Taken out',
                      value: '${session.plantsaCount} plantsa + '
                          '${session.subraPieces} subra = $total pcs',
                    ),
                    const SizedBox(height: 6),
                    _DlgInfoRow(
                      label: 'Expected',
                      value: formatCurrency(session.expectedRemittance),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                // Return pieces
                TextField(
                  controller: returnCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setDlg(() {}),
                  decoration: InputDecoration(
                    labelText: 'Returned Pieces',
                    prefixIcon: const Icon(Icons.undo_outlined, color: AppColors.warning),
                    suffixText: 'pcs',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.warning, width: 1.5),
                    ),
                    helperText: 'Sold: $sold pcs ($total − $returnPieces)',
                  ),
                ),
                const SizedBox(height: 12),
                // Actual cash
                TextField(
                  controller: cashCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                  onChanged: (_) => setDlg(() {}),
                  decoration: InputDecoration(
                    labelText: 'Actual Cash Remitted',
                    prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.success),
                    suffixText: '₱',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.success, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 5% / 15% selector
                Row(children: [
                  Expanded(child: _PctBtn(
                    label: '5% Salary', selected: selectedPct == 0.05,
                    onTap: () => setDlg(() => selectedPct = 0.05),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _PctBtn(
                    label: '15% Salary', selected: selectedPct == 0.15,
                    onTap: () => setDlg(() => selectedPct = 0.15),
                  )),
                ]),
                const SizedBox(height: 12),
                // Session salary display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.seller.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.seller.withValues(alpha: 0.25)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Session Salary (${(selectedPct * 100).toInt()}%)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(formatCurrency(salary),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.seller)),
                    ]),
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 24, color: AppColors.seller),
                  ]),
                ),
                const SizedBox(height: 12),
                // Variance
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: vColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: vColor.withValues(alpha: 0.20)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Should remit ($sold × ₱5)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      Text(formatCurrency(adjusted),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(variance >= 0 ? 'Overpaid' : 'Short',
                          style: TextStyle(fontSize: 11, color: vColor)),
                      Text(
                        variance >= 0
                            ? '+${formatCurrency(variance)}'
                            : formatCurrency(variance),
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: vColor),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 8),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.seller),
                onPressed: () async {
                  if (cashCtrl.text.trim().isEmpty) return;
                  final retPcs = int.tryParse(returnCtrl.text) ?? 0;
                  final cash   = double.tryParse(cashCtrl.text) ?? 0.0;
                  final msg    = ScaffoldMessenger.of(context);
                  try {
                    if (existing != null) {
                      await _service.updateRemittance(
                        remittanceId:     existing.id,
                        returnPieces:     retPcs,
                        actualRemittance: cash,
                        totalPiecesTaken: session.totalPiecesTaken,
                        salary:           salary,
                      );
                    } else {
                      await _service.createRemittance(
                        sellerId:           seller.id,
                        sessionId:          session.id,
                        date:               session.date,
                        returnPieces:       retPcs,
                        actualRemittance:   cash,
                        totalPiecesTaken:   session.totalPiecesTaken,
                        expectedRemittance: session.expectedRemittance,
                        salary:             salary,
                        remittedAt:         DateTime.now().toIso8601String(),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _load();
                    if (mounted) {
                      msg.showSnackBar(SnackBar(
                        content: const Text('Remittance saved! ✅'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(12),
                      ));
                    }
                  } catch (e) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      msg.showSnackBar(SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.danger,
                      ));
                    }
                  }
                },
                child: Text(existing != null ? 'Update' : 'Save Remittance'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Mark paid dialog ───────────────────────────────────────
  void _confirmSellerPaid(
    UserModel seller,
    double    totalRemitted,
    double    totalSalary,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Confirm Payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Mark ${seller.name} as paid for $_displayDate?',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Remitted',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(formatCurrency(totalRemitted),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: AppColors.success, fontSize: 18)),
              ]),
              if (totalSalary > 0) ...[
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total Salary',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(formatCurrency(totalSalary),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: AppColors.seller, fontSize: 18)),
                ]),
              ],
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Confirm Paid'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _paidSellerIds.add(seller.id));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${seller.name} marked as paid! ✅'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(12),
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sellers = context
        .watch<AdminUserViewModel>()
        .nonAdminUsers
        .where((u) => u.isSeller)
        .toList();

    double totalRemitted = 0;
    double totalSalary   = 0;
    for (final remits in _remittances.values) {
      for (final r in remits) {
        totalRemitted += r.actualRemittance;
        totalSalary   += r.salary;
      }
    }

    return RefreshIndicator(
      color: AppColors.seller,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ───────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.storefront_outlined, color: Color(0xFFFF7A00), size: 22),
            ),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Seller Payroll',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A), letterSpacing: -0.3)),
              Text('Admin records remittance',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            ]),
          ]),
          const SizedBox(height: 16),

          // ── Day navigator ─────────────────────────────────
          _DayNav(
            displayDate: _displayDate,
            isToday:     _isToday,
            onPrev:      () => _changeDate(-1),
            onNext:      _isToday ? null : () => _changeDate(1),
            onCalendar:  _pickDate,
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.seller))
          else if (_error != null)
            _ErrCard(_error!)
          else if (sellers.isEmpty)
            const _EmptyCard(message: 'No sellers found')
          else ...[
            ...sellers.map((seller) {
              final sessions     = _sessions[seller.id]    ?? [];
              final remits       = _remittances[seller.id] ?? [];
              final isPaid       = _paidSellerIds.contains(seller.id);
              final sellerTotal  = remits.fold(0.0, (s, r) => s + r.actualRemittance);
              final sellerSalary = remits.fold(0.0, (s, r) => s + r.salary);

              return _SellerPayrollCard(
                seller:      seller,
                sessions:    sessions,
                remittances: remits,
                isPaid:      isPaid,
                onRemit:     (session, existing) =>
                    _showRemittanceDialog(seller, session, existing),
                onPaid: sessions.isNotEmpty && sellerTotal > 0 && !isPaid
                    ? () => _confirmSellerPaid(seller, sellerTotal, sellerSalary)
                    : null,
              );
            }),
            _TotalBanner(totalRemitted: totalRemitted, totalSalary: totalSalary),
          ],
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DAY NAVIGATOR
// ══════════════════════════════════════════════════════════════
class _DayNav extends StatelessWidget {
  final String        displayDate;
  final bool          isToday;
  final VoidCallback  onPrev;
  final VoidCallback? onNext;
  final VoidCallback  onCalendar;

  const _DayNav({
    required this.displayDate, required this.isToday,
    required this.onPrev, required this.onCalendar, this.onNext,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.seller.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.seller.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppColors.seller, iconSize: 20, onPressed: onPrev,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onCalendar,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.seller.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(displayDate,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryDark)),
                if (isToday) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.seller, borderRadius: BorderRadius.circular(4)),
                    child: const Text('Today',
                        style: TextStyle(
                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: onNext != null
                    ? AppColors.seller
                    : AppColors.seller.withValues(alpha: 0.25)),
            iconSize: 20, onPressed: onNext,
          ),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  SELLER PAYROLL CARD
// ══════════════════════════════════════════════════════════════
class _SellerPayrollCard extends StatelessWidget {
  final UserModel                   seller;
  final List<SellerSessionModel>    sessions;
  final List<SellerRemittanceModel> remittances;
  final bool                        isPaid;
  final Function(SellerSessionModel, SellerRemittanceModel?) onRemit;
  final VoidCallback?               onPaid;

  const _SellerPayrollCard({
    required this.seller, required this.sessions,
    required this.remittances, required this.isPaid,
    required this.onRemit, this.onPaid,
  });

  SellerRemittanceModel? _remitFor(SellerSessionModel s) =>
      remittances.where((r) => r.sessionId == s.id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final totalExpected = sessions.fold(0.0, (s, e) => s + e.expectedRemittance);
    final totalRemitted = remittances.fold(0.0, (s, r) => s + r.actualRemittance);
    final totalSalary   = remittances.fold(0.0, (s, r) => s + r.salary);
    final allRemitted   = sessions.isNotEmpty && sessions.every((s) => _remitFor(s) != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPaid
            ? Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 2)
            : allRemitted
                ? Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 1.5)
                : null,
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Seller header ────────────────────────────────
          Row(children: [
            Stack(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (isPaid ? AppColors.danger : AppColors.seller).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  seller.name.isNotEmpty ? seller.name[0].toUpperCase() : 'S',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18,
                      color: isPaid ? AppColors.danger : AppColors.seller),
                ),
              ),
              if (isPaid)
                Positioned(right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: AppColors.danger, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                  ),
                ),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(seller.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(width: 6),
                if (isPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('PAID',
                        style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w800,
                            color: AppColors.danger)),
                  ),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.seller.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Seller',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.seller)),
                ),
                const SizedBox(width: 8),
                Text('${sessions.length} sessions',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatCurrency(totalRemitted),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
              Text('of ${formatCurrency(totalExpected)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            ]),
          ]),

          if (sessions.isEmpty) ...[
            const SizedBox(height: 12),
            const _NoSessionsHint(),
          ] else ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Session rows ─────────────────────────────
            ...sessions.map((session) {
              final remit = _remitFor(session);
              return _SessionRemitRow(
                session: session, remit: remit,
                onTap: () => onRemit(session, remit),
              );
            }),

            // ── Daily salary summary ─────────────────────
            if (remittances.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.seller.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.seller.withValues(alpha: 0.15)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Row(children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 14, color: AppColors.seller),
                    SizedBox(width: 6),
                    Text('Total Daily Salary',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ]),
                  Text(formatCurrency(totalSalary),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.seller)),
                ]),
              ),
            ],

            const SizedBox(height: 12),

            // ── Action button ────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (isPaid)
                // RED "Paid" chip after confirming
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle, size: 15, color: AppColors.danger),
                    SizedBox(width: 6),
                    Text('Paid',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                            color: AppColors.danger)),
                  ]),
                )
              else if (allRemitted && remittances.isNotEmpty && onPaid != null)
                // GREEN "Mark Paid" — only when all sessions have remittances
                FilledButton.icon(
                  onPressed: onPaid,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Mark Paid'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else
                // AMBER "Pending" badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.pending_outlined, size: 14, color: AppColors.warning),
                    SizedBox(width: 6),
                    Text('Pending remittance',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.warning)),
                  ]),
                ),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SESSION REMIT ROW  — shows salary per session
// ══════════════════════════════════════════════════════════════
class _SessionRemitRow extends StatelessWidget {
  final SellerSessionModel     session;
  final SellerRemittanceModel? remit;
  final VoidCallback           onTap;

  const _SessionRemitRow({required this.session, required this.onTap, this.remit});

  @override
  Widget build(BuildContext context) {
    final isMorning = session.isMorning;
    final color     = isMorning ? AppColors.seller : AppColors.warning;
    final hasRemit  = remit != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasRemit
              ? AppColors.success.withValues(alpha: 0.04)
              : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasRemit
                ? AppColors.success.withValues(alpha: 0.20)
                : color.withValues(alpha: 0.20),
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(
              isMorning ? Icons.wb_sunny_outlined : Icons.wb_twilight_outlined,
              size: 16, color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${isMorning ? 'Morning' : 'Afternoon'} — ${session.date}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
            Text(
              '${session.totalPiecesTaken} pcs · Exp: ${formatCurrency(session.expectedRemittance)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            if (hasRemit) ...[
              Text(
                'Returned: ${remit!.returnPieces} · Cash: ${formatCurrency(remit!.actualRemittance)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
              ),
              // ── Per-session salary ────────────────────
              if (remit!.salary > 0)
                Text(
                  'Salary: ${formatCurrency(remit!.salary)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.seller, fontWeight: FontWeight.w700),
                ),
            ],
          ])),
          hasRemit
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('✓ Done',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppColors.success)),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Enter',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TOTAL BANNER
// ══════════════════════════════════════════════════════════════
class _TotalBanner extends StatelessWidget {
  final double totalRemitted;
  final double totalSalary;
  const _TotalBanner({required this.totalRemitted, required this.totalSalary});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A00), Color(0xFFFFA03A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
            blurRadius: 14, offset: const Offset(0, 5),
          )],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TOTAL REMITTED',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700,
                    letterSpacing: 1, fontSize: 11)),
            SizedBox(height: 2),
            Text('Seller total today',
                style: TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatCurrency(totalRemitted),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                    fontSize: 24, letterSpacing: -0.5)),
            if (totalSalary > 0)
              Text('Salary: ${formatCurrency(totalSalary)}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  SMALL HELPERS
// ══════════════════════════════════════════════════════════════
class _DlgInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _DlgInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.seller)),
        ],
      );
}

class _PctBtn extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;
  const _PctBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.seller : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.seller : AppColors.seller.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13,
                  color: selected ? Colors.white : AppColors.seller)),
        ),
      );
}

class _NoSessionsHint extends StatelessWidget {
  const _NoSessionsHint();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, size: 14, color: AppColors.textHint),
          SizedBox(width: 8),
          Text('No sessions recorded for this day',
              style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        ]),
      );
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(Icons.storefront_outlined, size: 40,
              color: AppColors.seller.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
        ]),
      );
}

class _ErrCard extends StatelessWidget {
  final String message;
  const _ErrCard(this.message);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          const Icon(Icons.cloud_off_outlined, size: 36, color: AppColors.danger),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontSize: 13)),
        ]),
      );
}