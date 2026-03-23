// lib/features/master_baker/viewmodel/baker_salary_viewmodel.dart
import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/payroll_service.dart';
import '../../../core/utils/helpers.dart';

// ─────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────

class BakerDashboardRecord {
  final String date;
  final int    totalWorkers;
  final int    totalSacks;
  final double salary;
  final double bonus;

  BakerDashboardRecord({
    required this.date,
    required this.totalWorkers,
    required this.totalSacks,
    required this.salary,
    this.bonus = 0,
  });
}

class BakerDailyEntry {
  final String date;
  final double baseSalary;
  final double bakerIncentive;
  final double bonus;

  BakerDailyEntry({
    required this.date,
    required this.baseSalary,
    required this.bakerIncentive,
    required this.bonus,
  });

  double get baseOnly => baseSalary - bakerIncentive;
}

// ─────────────────────────────────────────────────────────────
//  VIEW MODEL
// ─────────────────────────────────────────────────────────────
class BakerSalaryViewModel extends ChangeNotifier {
  final DatabaseService _db;
  late final PayrollService _payroll;

  BakerSalaryViewModel(this._db, [PayrollService? payroll]) {
    _payroll   = payroll ?? PayrollService(_db.supa);
    _weekStart = getWeekStart(DateTime.now());
    _weekEnd   = getWeekEnd(_weekStart);
  }

  // ── Loading / error ──────────────────────────────────
  bool    isLoading = false;
  String? error;

  // ── Week range ───────────────────────────────────────
  String _weekStart = '';
  String _weekEnd   = '';
  String get weekStart => _weekStart;
  String get weekEnd   => _weekEnd;

  // ── Salary values ────────────────────────────────────
  List<BakerDailyEntry> dailyEntries = [];

  double _grossSalary   = 0;
  double _bonusTotal    = 0;
  double _gasDeduction  = 0;
  double _valeDeduction = 0;
  double _wifiDeduction = 0;
  int    _daysWorked    = 0;

  double get grossSalary     => _grossSalary;
  double get bonusTotal      => _bonusTotal;
  double get gasDeduction    => _gasDeduction;
  double get valeDeduction   => _valeDeduction;
  double get wifiDeduction   => _wifiDeduction;
  double get totalDeductions =>
      _gasDeduction + _valeDeduction + _wifiDeduction;
  double get finalSalary => _grossSalary - totalDeductions;
  int    get daysWorked  => _daysWorked;

  // ── All-time records (dashboard + history) ───────────
  List<BakerDashboardRecord> dailyRecords = [];

  // ─────────────────────────────────────────────────────
  //  PUBLIC API
  // ─────────────────────────────────────────────────────

  /// Init weekly (called on dashboard load)
  Future<void> init(String userId) async {
    _weekStart = getWeekStart(DateTime.now());
    _weekEnd   = getWeekEnd(_weekStart);
    await _loadWeekly(userId);
  }

  /// Navigate weeks
  Future<void> changeWeek(int direction, String userId) async {
    final next = DateTime.parse(_weekStart)
        .add(Duration(days: direction * 7));
    _weekStart = getWeekStart(next);
    _weekEnd   = getWeekEnd(_weekStart);
    await _loadWeekly(userId);
  }

  /// All productions for dashboard + history cards
  Future<void> loadDailyRecords(String userId) async {
    isLoading = true;
    error     = null;
    notifyListeners();

    try {
      final productions =
          await _db.getProductionsByMasterBaker(userId);
      final products = await _db.getAllProducts();
      productions.sort((a, b) => b.date.compareTo(a.date));

      dailyRecords = productions.map((prod) {
        final calc = _payroll.computeDaily(prod, products);
        return BakerDashboardRecord(
          date:         prod.date,
          totalWorkers: prod.totalWorkers,
          totalSacks:   prod.totalSacks,
          salary:       calc.salaryPerWorker + calc.bakerIncentive,
          bonus:        calc.bonusPerWorker,
        );
      }).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Loads productions for a single specific date.
  /// Used by the Daily tab.
  Future<void> loadDailyForDate(String userId, String date) async {
    isLoading = true;
    error     = null;
    notifyListeners();

    try {
      final productions =
          await _db.getProductionsByDateRange(date, date);
      final products = await _db.getAllProducts();

      final myProds = productions
          .where((p) => p.masterBakerId == userId)
          .toList();

      final Map<String, _DayAccum> byDate = {};
      for (final prod in myProds) {
        final prodDate = prod.date.split('T').first;
        final calc     = _payroll.computeDaily(prod, products);
        byDate.putIfAbsent(prodDate, () => _DayAccum(prodDate));
        byDate[prodDate]!
          ..baseSalary     += calc.salaryPerWorker + calc.bakerIncentive
          ..bakerIncentive += calc.bakerIncentive
          ..bonus          += calc.bonusPerWorker;
      }

      dailyEntries = byDate.values
          .map((a) => BakerDailyEntry(
                date:           a.date,
                baseSalary:     a.baseSalary,
                bakerIncentive: a.bakerIncentive,
                bonus:          a.bonus,
              ))
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Loads productions for a full month range.
  /// Used by the Monthly tab.
  Future<void> loadMonthlyData(
      String userId, String monthStart, String monthEnd) async {
    isLoading = true;
    error     = null;
    notifyListeners();

    try {
      final productions =
          await _db.getProductionsByDateRange(monthStart, monthEnd);
      final products = await _db.getAllProducts();

      final myProds = productions
          .where((p) => p.masterBakerId == userId)
          .toList();

      final Map<String, _DayAccum> byDate = {};
      for (final prod in myProds) {
        final date = prod.date.split('T').first;
        final calc = _payroll.computeDaily(prod, products);
        byDate.putIfAbsent(date, () => _DayAccum(date));
        byDate[date]!
          ..baseSalary     += calc.salaryPerWorker + calc.bakerIncentive
          ..bakerIncentive += calc.bakerIncentive
          ..bonus          += calc.bonusPerWorker;
      }

      dailyEntries = byDate.values
          .map((a) => BakerDailyEntry(
                date:           a.date,
                baseSalary:     a.baseSalary,
                bakerIncentive: a.bakerIncentive,
                bonus:          a.bonus,
              ))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      _daysWorked  = dailyEntries.length;
      _grossSalary =
          dailyEntries.fold(0.0, (s, d) => s + d.baseSalary);
      _bonusTotal  =
          dailyEntries.fold(0.0, (s, d) => s + d.bonus);

      final ded      =
          await _db.getDeductionForUser(userId, monthStart);
      _gasDeduction  = ded?.gas  ?? 0;
      _valeDeduction = ded?.vale ?? 0;
      _wifiDeduction = ded?.wifi ?? 0;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWeeklySalary(String userId) =>
      _loadWeekly(userId);

  // ─────────────────────────────────────────────────────
  //  CORE WEEKLY LOADER
  // ─────────────────────────────────────────────────────
  Future<void> _loadWeekly(String userId) async {
    isLoading = true;
    error     = null;
    notifyListeners();

    try {
      final productions = await _db.getProductionsByDateRange(
          _weekStart, _weekEnd);
      final products = await _db.getAllProducts();

      final myProds = productions
          .where((p) => p.masterBakerId == userId)
          .toList();

      final Map<String, _DayAccum> byDate = {};
      for (final prod in myProds) {
        final date = prod.date.split('T').first;
        final calc = _payroll.computeDaily(prod, products);
        byDate.putIfAbsent(date, () => _DayAccum(date));
        byDate[date]!
          ..baseSalary     += calc.salaryPerWorker + calc.bakerIncentive
          ..bakerIncentive += calc.bakerIncentive
          ..bonus          += calc.bonusPerWorker;
      }

      dailyEntries = byDate.values
          .map((a) => BakerDailyEntry(
                date:           a.date,
                baseSalary:     a.baseSalary,
                bakerIncentive: a.bakerIncentive,
                bonus:          a.bonus,
              ))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      _daysWorked  = dailyEntries.length;
      _grossSalary =
          dailyEntries.fold(0.0, (s, d) => s + d.baseSalary);
      _bonusTotal  =
          dailyEntries.fold(0.0, (s, d) => s + d.bonus);

      final ded      =
          await _db.getDeductionForUser(userId, _weekStart);
      _gasDeduction  = ded?.gas  ?? 0;
      _valeDeduction = ded?.vale ?? 0;
      _wifiDeduction = ded?.wifi ?? 0;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  INTERNAL ACCUMULATOR
// ─────────────────────────────────────────────────────────────
class _DayAccum {
  final String date;
  double baseSalary     = 0;
  double bakerIncentive = 0;
  double bonus          = 0;
  _DayAccum(this.date);
}