import 'package:flutter/material.dart';
import '../../../../core/models/payroll_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../../core/utils/helpers.dart';

class AdminPayrollViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final PayrollService _payroll;

  AdminPayrollViewModel(this._db, this._payroll);

  // ─── State ────────────────────────────────────────────────────────────────

  List<PayrollEntry> _entries = [];
  String _weekStart = '';
  String _weekEnd = '';
  bool _isLoading = false;
  bool _isPaying = false;
  String? _error; // ✅ added

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<PayrollEntry> get entries => _entries;
  String get weekStart => _weekStart;
  String get weekEnd => _weekEnd;
  bool get isLoading => _isLoading;
  bool get isPaying => _isPaying;
  String? get error => _error; // ✅ added

  double get totalPayroll =>
      _entries.fold(0.0, (sum, e) => sum + e.finalSalary);

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