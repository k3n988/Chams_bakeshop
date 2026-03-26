import 'package:flutter/material.dart';
import '../../../../core/models/payroll_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../../core/services/packer_service.dart';
import '../../../../core/services/seller_service.dart';
import '../../../../core/utils/helpers.dart';

class AdminPayrollViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final PayrollService  _payroll;
  final PackerService   _packerSvc = PackerService();
  final SellerService   _sellerSvc = SellerService();

  AdminPayrollViewModel(this._db, this._payroll);

  // ─── State ────────────────────────────────────────────────────────────────

  List<PayrollEntry> _entries = [];
  String _weekStart = '';
  String _weekEnd = '';
  bool _isLoading = false;
  bool _isPaying = false;
  String? _error;

  double _packerWeeklyTotal = 0.0;
  double _sellerWeeklyTotal = 0.0;
  int    _packerPaidCount    = 0;
  int    _packerTotalCount   = 0;
  Map<String, double> _sellerWeeklyMap = {};

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<PayrollEntry> get entries => _entries;
  String get weekStart => _weekStart;
  String get weekEnd => _weekEnd;
  bool get isLoading => _isLoading;
  bool get isPaying => _isPaying;
  String? get error => _error; // ✅ added

  double get totalPayroll =>
      _entries.fold(0.0, (sum, e) => sum + e.finalSalary);

  double get totalPayrollPacker => _packerWeeklyTotal;
  double get totalPayrollSeller => _sellerWeeklyTotal;
  double get totalPayrollAll  => totalPayroll + _packerWeeklyTotal + _sellerWeeklyTotal;
  int    get bakerPaidCount   => _entries.where((e) => e.isPaid).length;
  int    get bakerTotalCount  => _entries.length;
  int    get packerPaidCount  => _packerPaidCount;
  int    get packerTotalCount => _packerTotalCount;
  Map<String, double> get sellerWeeklyMap => Map.unmodifiable(_sellerWeeklyMap);

  // ─── Auto-load (called from dashboard initState) ─────────────────────────

  /// Fetches products + users itself, then loads the current week's payroll
  /// plus packer and seller weekly totals.
  Future<void> autoLoad() async {
    final now  = DateTime.now();
    final mon  = now.subtract(Duration(days: now.weekday - 1));
    final sun  = mon.add(const Duration(days: 6));
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final weekStartStr = fmt(mon);
    final weekEndStr   = fmt(sun);

    final users    = await _db.getAllUsers();
    final products = await _db.getAllProducts();

    // Baker/Helper payroll
    final userNames = {for (final u in users) u.id: u.name};
    final userRoles = {for (final u in users) u.id: u.role};
    await loadWeeklyPayroll(weekStartStr, products, userNames, userRoles);

    // Packer weekly total — sum net_salary from packer_payroll table
    final packers = users.where((u) => u.role == 'packer').toList();
    double packerTotal = 0.0;
    int    packerPaid  = 0;
    for (final p in packers) {
      final record = await _packerSvc.getPayrollByWeek(
        packerId:  p.id,
        weekStart: weekStartStr,
        weekEnd:   weekEndStr,
      );
      if (record != null) {
        packerTotal += record.netSalary;
        if (record.isPaid) packerPaid++;
      }
    }
    _packerWeeklyTotal  = packerTotal;
    _packerPaidCount    = packerPaid;
    _packerTotalCount   = packers.length;

    // Seller weekly total — sum salary from remittances this week
    final sellers = users.where((u) => u.role == 'seller').toList();
    double sellerTotal = 0.0;
    _sellerWeeklyMap   = {};
    for (final s in sellers) {
      final remits = await _sellerSvc.getRemittancesByRange(
        sellerId: s.id,
        fromDate: weekStartStr,
        toDate:   weekEndStr,
      );
      final amt = remits.fold(0.0, (sum, r) => sum + r.salary);
      sellerTotal           += amt;
      _sellerWeeklyMap[s.id] = amt;
    }
    _sellerWeeklyTotal = sellerTotal;

    notifyListeners();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadWeeklyPayroll(
    String weekStart,
    List<ProductModel> products,
    Map<String, String> userNames,
    Map<String, String> userRoles,
  ) async {
    _weekStart = weekStart;
    _weekEnd = getWeekEnd(weekStart);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paidIds = await _db.getPaidUserIds(weekStart);
      _entries = await _payroll.computeWeeklyPayroll(
        _weekStart,
        _weekEnd,
        products,
        userNames,
        userRoles,
        paidUserIds: paidIds,
      );
    } catch (e) {
      _entries = [];
      _error = e.toString();
      debugPrint('PayrollVM error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Week Navigation ──────────────────────────────────────────────────────

  Future<void> changeWeek(
    int dir,
    List<ProductModel> products,
    Map<String, String> userNames,
    Map<String, String> userRoles,
  ) async {
    final current = _weekStart.isNotEmpty
        ? DateTime.parse(_weekStart)
        : DateTime.now();
    final next = current.add(Duration(days: dir * 7));
    final nextWeekStart = next.toString().split(' ')[0];
    await loadWeeklyPayroll(nextWeekStart, products, userNames, userRoles);
  }

  // ─── Deductions ───────────────────────────────────────────────────────────

  Future<bool> saveDeduction({
    required String userId,
    required String weekStart,
    required double oven,
    required double gas,
    required double vale,
    required double wifi,
  }) async {
    try {
      final existing = await _db.getDeductionForUser(userId, weekStart);
      final deduction = DeductionModel(
        id: existing?.id ?? generateId('ded'),
        userId: userId,
        weekStart: weekStart,
        oven: oven,
        gas: gas,
        vale: vale,
        wifi: wifi,
      );
      await _db.upsertDeduction(deduction);
      return true;
    } catch (e) {
      debugPrint('saveDeduction error: $e');
      return false;
    }
  }

  // ─── Mark as Paid ─────────────────────────────────────────────────────────

  Future<bool> markAsPaid({
    required String userId,
    required String paidBy,
    required double amount,
  }) async {
    _isPaying = true;
    notifyListeners();

    try {
      await _db.insertPayrollPaid(
        id: generateId('paid'),
        userId: userId,
        weekStart: _weekStart,
        paidBy: paidBy,
        amount: amount,
      );

      _entries = _entries.map((e) {
        if (e.userId == userId) return e.copyWith(isPaid: true);
        return e;
      }).toList();

      _isPaying = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('markAsPaid error: $e');
      _isPaying = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllAsPaid({required String paidBy}) async {
    _isPaying = true;
    notifyListeners();

    try {
      final unpaid = _entries.where((e) => !e.isPaid).toList();
      for (final e in unpaid) {
        await _db.insertPayrollPaid(
          id: generateId('paid'),
          userId: e.userId,
          weekStart: _weekStart,
          paidBy: paidBy,
          amount: e.finalSalary,
        );
      }

      _entries = _entries.map((e) => e.copyWith(isPaid: true)).toList();
      _isPaying = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('markAllAsPaid error: $e');
      _isPaying = false;
      notifyListeners();
      return false;
    }
  }
}