import 'package:flutter/material.dart';
import '../../../../core/models/payroll_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../../core/utils/helpers.dart';

class BakerDashboardRecord {
  final String date;
  final int totalWorkers;
  final int totalSacks;
  final double salary;

  BakerDashboardRecord({
    required this.date,
    required this.totalWorkers,
    required this.totalSacks,
    required this.salary,
  });
}

class BakerSalaryViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final PayrollService _payroll;

  String _weekStart = '';
  String _weekEnd = '';
  bool _isLoading = false;

  List<DailySalaryEntry> _dailyEntries = [];
  List<BakerDashboardRecord> _dailyRecords = [];
  double _grossTotal = 0;
  double _finalSalary = 0;
  int _daysWorked = 0;

  BakerSalaryViewModel(this._db, this._payroll) {
    _weekStart = getWeekStart(DateTime.now());
    _weekEnd = getWeekEnd(_weekStart);
  }

  // ─── Getters ──────────────────────────────────────────────────────────────

  String get weekStart => _weekStart;
  String get weekEnd => _weekEnd;
  bool get isLoading => _isLoading;
  List<DailySalaryEntry> get dailyEntries => _dailyEntries;
  List<BakerDashboardRecord> get dailyRecords => _dailyRecords;
  int get daysWorked => _daysWorked;
  double get grossSalary => _grossTotal;
  double get finalSalary => _finalSalary;

  // ─── Load all records (for history screen) ────────────────────────────────

  Future<void> loadDailyRecords(String userId) async {
    _isLoading = true;
    notifyListeners();

    final productions = await _db.getProductionsByMasterBaker(userId);
    final products    = await _db.getAllProducts();

    productions.sort((a, b) => b.date.compareTo(a.date));

    _dailyRecords = productions.map((prod) {
      final calc = _payroll.computeDaily(prod, products);
      return BakerDashboardRecord(
        date: prod.date,
        totalWorkers: prod.totalWorkers,
        totalSacks: prod.totalSacks,
        salary: calc.salaryPerWorker + calc.masterBonus,
      );
    }).toList();

    _isLoading = false;
    notifyListeners();
  }

  // ─── Load weekly salary (for salary + dashboard screens) ─────────────────

  Future<void> loadWeeklySalary(String userId) async {
    _isLoading = true;
    notifyListeners();

    final productions = await _db.getProductionsByMasterBaker(userId);
    final products    = await _db.getAllProducts();

    final weekProds = productions.where((p) =>
        p.date.compareTo(_weekStart) >= 0 &&
        p.date.compareTo(_weekEnd) <= 0).toList();

    _dailyEntries = [];
    _grossTotal   = 0;
    _daysWorked   = weekProds.length;

    for (final prod in weekProds) {
      final calc  = _payroll.computeDaily(prod, products);
      final total = calc.salaryPerWorker + calc.masterBonus;
      _grossTotal += total;

      _dailyEntries.add(DailySalaryEntry(
        date: prod.date,
        baseSalary: calc.salaryPerWorker,
        bonus: calc.masterBonus, // now comes from product.bonusPerSack
      ));
    }

    // Deductions for master baker: fetch gas/vale/wifi from deductions table
    final deduction = await _db.getDeductionForUser(userId, _weekStart);
    final totalDeductions = (deduction?.gas ?? 0) +
        (deduction?.vale ?? 0) +
        (deduction?.wifi ?? 0);

    _finalSalary = _grossTotal - totalDeductions;

    _isLoading = false;
    notifyListeners();
  }

  // Alias for backward compatibility
  Future<void> loadSalary(String userId) => loadWeeklySalary(userId);

  // ─── Week navigation ──────────────────────────────────────────────────────

  void changeWeek(int direction, String userId) {
    final d = DateTime.parse(_weekStart).add(Duration(days: direction * 7));
    _weekStart = d.toString().split(' ')[0];
    _weekEnd   = getWeekEnd(_weekStart);
    loadWeeklySalary(userId);
  }
}