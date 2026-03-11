import 'package:flutter/material.dart';
import '../../../../core/models/payroll_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../../core/utils/helpers.dart';

// Helper class for the Dashboard UI to read daily record data easily
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

  // Existing lists
  List<DailySalaryEntry> _dailyEntries = [];
  double _grossTotal = 0;

  // Dashboard variables
  List<BakerDashboardRecord> _dailyRecords = [];
  int _daysWorked = 0;
  double _finalSalary = 0.0;

  BakerSalaryViewModel(this._db, this._payroll) {
    _weekStart = getWeekStart(DateTime.now());
    _weekEnd = getWeekEnd(_weekStart);
  }

  // Existing getters
  String get weekStart => _weekStart;
  String get weekEnd => _weekEnd;
  List<DailySalaryEntry> get dailyEntries => _dailyEntries;

  // Dashboard getters
  List<BakerDashboardRecord> get dailyRecords => _dailyRecords;
  int get daysWorked => _daysWorked;
  double get grossSalary => _grossTotal;
  double get finalSalary => _finalSalary;

  // ── 1. Load data for the "Recent Daily Records" List ──
  Future<void> loadDailyRecords(String userId) async {
    final productions = await _db.getProductionsByMasterBaker(userId);
    final products = await _db.getAllProducts();

    // Sort to show the most recent records first
    productions.sort((a, b) => b.date.compareTo(a.date));

    _dailyRecords = [];
    for (final prod in productions) {
      final calc = _payroll.computeDaily(prod, products);
      final totalSalary = calc.salaryPerWorker + calc.masterBonus;

      _dailyRecords.add(BakerDashboardRecord(
        date: prod.date,
        totalWorkers: prod.totalWorkers,
        totalSacks: prod.totalSacks,
        salary: totalSalary,
      ));
    }
    notifyListeners();
  }

  // ── 2. Load data for the Weekly Overview Cards ──
  Future<void> loadWeeklySalary(String userId) async {
    final productions = await _db.getProductionsByMasterBaker(userId);
    final products = await _db.getAllProducts();

    final weekProds = productions
        .where((p) =>
            p.date.compareTo(_weekStart) >= 0 &&
            p.date.compareTo(_weekEnd) <= 0)
        .toList();

    _dailyEntries = [];
    _grossTotal = 0;
    _daysWorked = weekProds.length;

    for (final prod in weekProds) {
      final calc = _payroll.computeDaily(prod, products);
      final total = calc.salaryPerWorker + calc.masterBonus;
      _grossTotal += total;

      _dailyEntries.add(DailySalaryEntry(
        date: prod.date,
        baseSalary: calc.salaryPerWorker,
        bonus: calc.masterBonus,
      ));
    }

    // Master Baker is EXEMPTED from oven deduction
    double valeDeduction = 0.0;
    _finalSalary = _grossTotal - valeDeduction;

    notifyListeners();
  }

  // ── 3. Keep existing loadSalary to prevent breaking other screens ──
  Future<void> loadSalary(String userId) async {
    await loadWeeklySalary(userId);
  }

  // ── 4. Change week function ──
  void changeWeek(int direction, String userId) {
    final d = DateTime.parse(_weekStart);
    _weekStart = d.add(Duration(days: direction * 7)).toString().split(' ')[0];
    _weekEnd = getWeekEnd(_weekStart);
    loadWeeklySalary(userId);
  }
}