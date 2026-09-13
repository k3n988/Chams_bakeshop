import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/models/user_model.dart';
import '../../viewmodel/admin_user_viewmodel.dart';
import '../../../seller/viewmodel/seller_session_viewmodel.dart';
import '../../../seller/view/screens/seller_session_input.dart';
import '../../../../core/services/seller_service.dart';
import '../../../../core/models/seller_session_model.dart';
import '../../../../core/models/seller_remittance_model.dart';

class AdminSellerSessionScreen extends StatefulWidget {
  const AdminSellerSessionScreen({super.key});

  @override
  State<AdminSellerSessionScreen> createState() =>
      _AdminSellerSessionScreenState();
}

class _AdminSellerSessionScreenState extends State<AdminSellerSessionScreen> {
  final _sellerService = SellerService();
  String? _sellerId;
  DateTime _selectedDate = DateTime.now();
  bool _loadingSessions = false;
  List<SellerSessionModel> _todaySessions = const [];
  List<SellerRemittanceModel> _selectedDateRemittances = const [];

  String get _dateStr => _selectedDate.toIso8601String().substring(0, 10);

  SellerSessionModel? _sessionFor(SessionType type) => _todaySessions
      .where((session) => session.sessionType ==
          (type == SessionType.morning ? 'morning' : 'afternoon'))
      .firstOrNull;

  bool _isRemitted(SellerSessionModel? session) => session != null &&
      _selectedDateRemittances
          .any((remittance) => remittance.sessionId == session.id);

  Future<void> _selectSeller(String? sellerId) async {
    setState(() {
      _sellerId = sellerId;
      _todaySessions = const [];
      _selectedDateRemittances = const [];
      _loadingSessions = sellerId != null;
    });
    if (sellerId == null) return;

    try {
      final results = await Future.wait([
        _sellerService.getSessionsByRange(
          sellerId: sellerId,
          fromDate: _dateStr,
          toDate: _dateStr,
        ),
        _sellerService.getRemittancesByRange(
          sellerId: sellerId,
          fromDate: _dateStr,
          toDate: _dateStr,
        ),
      ]);
      final sessions = results[0] as List<SellerSessionModel>;
      final remittances = results[1] as List<SellerRemittanceModel>;
      if (!mounted || _sellerId != sellerId) return;
      setState(() {
        _todaySessions = sessions;
        _selectedDateRemittances = remittances;
        _loadingSessions = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    if (_sellerId != null) await _selectSeller(_sellerId);
  }

  @override
  Widget build(BuildContext context) {
    final sellers = context.watch<AdminUserViewModel>().nonAdminUsers
        .where((user) => user.isSeller)
        .toList();
    final selected = sellers.where((user) => user.id == _sellerId).firstOrNull;
    final morningSession = _sessionFor(SessionType.morning);
    final afternoonSession = _sessionFor(SessionType.afternoon);
    final morningPending = morningSession != null && !_isRemitted(morningSession);
    final afternoonPending =
        afternoonSession != null && !_isRemitted(afternoonSession);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: const Text('Seller Session',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SESSION DATE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                      letterSpacing: 0.8, color: AppColors.textHint)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined,
                    size: 17, color: AppColors.seller),
                label: Text(_dateStr,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  alignment: Alignment.centerLeft,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('SELECT SELLER',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                      letterSpacing: 0.8, color: AppColors.textHint)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _sellerId,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Select seller',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.seller),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                items: sellers.map((user) => DropdownMenuItem(
                  value: user.id,
                  child: Text(user.name),
                )).toList(),
                onChanged: _selectSeller,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (selected == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select a seller to add a morning or afternoon session.',
                  style: TextStyle(color: AppColors.textHint)),
            )
          else if (_loadingSessions)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppColors.seller)))
          else ...[
            const Text('ADD SESSION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                    letterSpacing: 0.8, color: AppColors.textHint)),
            const SizedBox(height: 10),
            _SessionButton(
              label: morningSession == null
                  ? 'Morning Session'
                  : morningPending
                      ? 'Morning Session · Pending — Tap to edit'
                      : 'Morning Session · Remitted',
              icon: Icons.wb_sunny_outlined,
              color: AppColors.seller,
              locked: morningSession != null && !morningPending,
              onTap: () => _openSession(
                  selected, SessionType.morning, morningSession),
            ),
            const SizedBox(height: 10),
            _SessionButton(
              label: afternoonSession == null
                  ? 'Afternoon Session'
                  : afternoonPending
                      ? 'Afternoon Session · Pending — Tap to edit'
                      : 'Afternoon Session · Remitted',
              icon: Icons.wb_twilight_outlined,
              color: AppColors.warning,
              locked: afternoonSession != null && !afternoonPending,
              onTap: () => _openSession(
                  selected, SessionType.afternoon, afternoonSession),
            ),
          ],
        ]),
      ),
    );
  }

  void _openSession(UserModel seller, SessionType type,
      SellerSessionModel? existingSession) {
    if (existingSession != null && _isRemitted(existingSession)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('A remitted seller session can no longer be edited.'),
      ));
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SellerSessionInputScreen(
        sessionType: type,
        sellerId: seller.id,
        sellerName: seller.name,
        date: _dateStr,
        editableSession: existingSession,
      ),
    )).then((_) => _selectSeller(seller.id));
  }
}

class _SessionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool locked;
  final VoidCallback onTap;

  const _SessionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: locked ? null : onTap,
          icon: Icon(icon, color: color),
          label: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}
