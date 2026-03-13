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

  // ─── Getters ──────────────────────────────────────────────────────────────
  // Names match exactly what payroll_screen.dart and admin_dashboard.dart use

  List<PayrollEntry> get entries => _entries;
  String get weekStart => _weekStart;
  String get weekEnd => _weekEnd;
  bool get isLoading => _isLoading;

  double get totalPayroll =>
      _entries.fold(0.0, (sum, e) => sum + e.finalSalary);

  // ─── Load ─────────────────────────────────────────────────────────────────

  /// Called by payroll_screen on init and after week/month changes.
  /// Receives products + user maps from sibling ViewModels — no redundant fetching.
  Future<void> loadWeeklyPayroll(
    String weekStart,
    List<ProductModel> products,
    Map<String, String> userNames,
    Map<String, String> userRoles,
  ) async {
    _weekStart = weekStart;
    _weekEnd = getWeekEnd(weekStart);
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await _payroll.computeWeeklyPayroll(
        _weekStart,
        _weekEnd,
        products,
        userNames,
        userRoles,
      );
    } catch (_) {
      _entries = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Week Navigation ──────────────────────────────────────────────────────

  /// dir = -1 for previous week, +1 for next week
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

  /// weekStart passed explicitly so the dialog controls which week it applies to.
  Future<bool> saveDeduction({
    required String userId,
    required String weekStart,
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
        gas: gas,
        vale: vale,
        wifi: wifi,
      );

      if (existing != null) {
        await _db.updateDeduction(deduction);
      } else {
        await _db.insertDeduction(deduction);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}