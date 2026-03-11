import 'package:flutter/material.dart';
import '../../../../core/models/payroll_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../../core/utils/helpers.dart';

class AdminPayrollViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final PayrollService _payroll;

  List<PayrollEntry> _entries = [];
  String _weekStart = '';
  String _weekEnd = '';
  bool _isLoading = false;

  AdminPayrollViewModel(this._db, this._payroll);

  List<PayrollEntry> get entries => _entries;
  String get weekStart => _weekStart;
  String get weekEnd => _weekEnd;
  bool get isLoading => _isLoading;
  double get totalPayroll => _entries.fold(0, (s, e) => s + e.finalSalary);

  Future<void> loadWeeklyPayroll(
    String weekStart,
    List<ProductModel> products,
    Map<String, String> userNames,
    Map<String, String> userRoles,
  ) async {
    _isLoading = true;
    _weekStart = weekStart;
    _weekEnd = getWeekEnd(weekStart);
    notifyListeners();

    _entries = await _payroll.computeWeeklyPayroll(
        _weekStart, _weekEnd, products, userNames, userRoles);

    _isLoading = false;
    notifyListeners();
  }

  void changeWeek(
    int direction,
    List<ProductModel> products,
    Map<String, String> userNames,
    Map<String, String> userRoles,
  ) {
    final d = DateTime.parse(_weekStart);
    final newStart = d.add(Duration(days: direction * 7)).toString().split(' ')[0];
    loadWeeklyPayroll(newStart, products, userNames, userRoles);
  }

  Future<void> saveDeduction({
    required String userId,
    required String weekStart,
    required double gas,
    required double vale,
    required double wifi,
  }) async {
    final ded = DeductionModel(
      id: generateId('ded'),
      userId: userId,
      weekStart: weekStart,
      gas: gas,
      vale: vale,
      wifi: wifi,
    );
    await _db.upsertDeduction(ded);
    notifyListeners();
  }
}
