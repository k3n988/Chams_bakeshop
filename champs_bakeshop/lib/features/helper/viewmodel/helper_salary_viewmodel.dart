import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../../core/models/production_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';

// ═══════════════════════════════════════════════════════════════════
//  HELPER SALARY VIEW-MODEL
// ═══════════════════════════════════════════════════════════════════
class HelperSalaryViewModel extends ChangeNotifier {
  final SupabaseService _db;
  final PayrollService  _payroll;

  HelperSalaryViewModel(this._db, this._payroll) {
    _weekStart = getWeekStart(DateTime.now());
    _weekEnd   = getWeekEnd(_weekStart);
  }

  // ── Loading / error ──────────────────────────────────────────
  bool    _isLoading = false;
  String? _error;

  bool    get isLoading => _isLoading;
  String? get error     => _error;

  // ── Daily ────────────────────────────────────────────────────
  List<HelperDailyRecord> _dailyRecords = [];
  List<HelperDailyRecord> get dailyRecords => _dailyRecords;

  // ── Weekly ───────────────────────────────────────────────────
  String _weekStart = '';
  String _weekEnd   = '';
  List<MapEntry<String, double>> _weeklyDaily = [];
  double _grossSalary   = 0;
  int    _daysWorked    = 0;
  double _ovenDeduction = 0;
  double _gasDeduction  = 0;
  double _valeDeduction = 0;
  double _wifiDeduction = 0;

  String get weekStart  => _weekStart;
  String get weekEnd    => _weekEnd;
  List<MapEntry<String, double>> get weeklyDaily => _weeklyDaily;
  double get grossSalary   => _grossSalary;
  int    get daysWorked    => _daysWorked;
  double get ovenDeduction => _ovenDeduction;
  double get gasDeduction  => _gasDeduction;
  double get valeDeduction => _valeDeduction;
  double get wifiDeduction => _wifiDeduction;
  double get totalDeductions =>
      _ovenDeduction + _gasDeduction + _valeDeduction + _wifiDeduction;
  double get finalSalary => _grossSalary - totalDeductions;

  // ── Monthly ──────────────────────────────────────────────────
  List<WeeklySummary> _monthlyWeeks       = [];
  double _monthlyTotalSalary             = 0;
  double _monthlyGrossSalary             = 0;
  double _monthlyTotalDeductions         = 0;
  double _monthlyAvgPerWeek              = 0;
  int    _monthlyTotalDays               = 0;
  int    _monthlyTotalSacks              = 0;
  double _monthlyOvenTotal               = 0;
  double _monthlyGasTotal                = 0;
  double _monthlyValeTotal               = 0;
  double _monthlyWifiTotal               = 0;

  List<WeeklySummary> get monthlyWeeks         => _monthlyWeeks;
  double get monthlyTotalSalary                => _monthlyTotalSalary;
  double get monthlyGrossSalary                => _monthlyGrossSalary;
  double get monthlyTotalDeductions            => _monthlyTotalDeductions;
  double get monthlyAvgPerWeek                 => _monthlyAvgPerWeek;
  int    get monthlyTotalDays                  => _monthlyTotalDays;
  int    get monthlyTotalSacks                 => _monthlyTotalSacks;
  double get monthlyOvenTotal                  => _monthlyOvenTotal;
  double get monthlyGasTotal                   => _monthlyGasTotal;
  double get monthlyValeTotal                  => _monthlyValeTotal;
  double get monthlyWifiTotal                  => _monthlyWifiTotal;

  // ── Internal ─────────────────────────────────────────────────
  void _begin() {
    _isLoading = true;
    _error     = null;
    notifyListeners();
  }

  void _end([String? err]) {
    _isLoading = false;
    _error     = err;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('ClientException')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (s.contains('PostgrestException')) return 'Database error. Please try again.';
    return s;
  }

  // ═══════════════════════════════════════════════════
  //  DAILY
  // ═══════════════════════════════════════════════════

  Future<void> loadDailyRecords(String userId) async {
    _begin();
    try {
      final productions = await _db.getAllProductions();
      final products    = await _db.getAllProducts();
      _dailyRecords = _buildDailyRecords(userId, productions, products);
    } catch (e) {
      _end('Failed to load daily records.\n${_friendlyError(e)}');
      return;
    }
    _end();
  }

  Future<void> loadDailyRecordsForMonth(
      String userId, int year, int month) async {
    _begin();
    try {
      final prefix  = '$year-${month.toString().padLeft(2, '0')}';
      final lastDay = DateTime(year, month + 1, 0).day;
      final start   = '$prefix-01';
      final end     = '$prefix-${lastDay.toString().padLeft(2, '0')}';

      final productions = await _db.getProductionsByDateRange(start, end);
      final products    = await _db.getAllProducts();

      _dailyRecords = _buildDailyRecords(userId, productions, products)
        ..retainWhere((r) => r.date.startsWith(prefix));
    } catch (e) {
      _end('Failed to load daily records.\n${_friendlyError(e)}');
      return;
    }
    _end();
  }

  /// Typed helper — avoids List<dynamic> assignment errors.
  List<HelperDailyRecord> _buildDailyRecords(
    String userId,
    List<ProductionModel> productions,   // ← explicit type
    List<ProductModel>    products,       // ← explicit type
  ) {
    return productions
        .where((p) => p.helperIds.contains(userId))
        .map((prod) {
          final calc = _payroll.computeDaily(prod, products);
          return HelperDailyRecord(
            date:         prod.date,
            salary:       calc.salaryPerWorker,
            totalWorkers: calc.totalWorkers,
            totalSacks:   calc.totalSacks,
            totalValue:   calc.totalValue,
          );
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ═══════════════════════════════════════════════════
  //  WEEKLY
  // ═══════════════════════════════════════════════════

  Future<void> loadWeeklySalary(String userId) async {
    _begin();
    try {
      final productions = await _db.getProductionsByDateRange(
          _weekStart, _weekEnd);
      final products = await _db.getAllProducts();

      _weeklyDaily = [];
      _grossSalary = 0;
      _daysWorked  = 0;

      for (final prod in productions.where(
          (p) => p.helperIds.contains(userId))) {
        final calc = _payroll.computeDaily(prod, products);
        _grossSalary += calc.salaryPerWorker;
        _daysWorked  += 1;
        _weeklyDaily.add(MapEntry(prod.date, calc.salaryPerWorker));
      }

      _weeklyDaily.sort((a, b) => a.key.compareTo(b.key));

      _ovenDeduction = _daysWorked * AppConstants.helperOvenDeductionPerDay;

      final ded      = await _db.getDeduction(userId, _weekStart);
      _gasDeduction  = ded?.gas  ?? 0;
      _valeDeduction = ded?.vale ?? 0;
      _wifiDeduction = ded?.wifi ?? 0;
    } catch (e) {
      _end('Failed to load weekly salary.\n${_friendlyError(e)}');
      return;
    }
    _end();
  }

  void changeWeek(int direction, String userId) {
    final d = DateTime.parse(_weekStart);
    _weekStart =
        d.add(Duration(days: direction * 7)).toString().split(' ')[0];
    _weekEnd = getWeekEnd(_weekStart);
    loadWeeklySalary(userId);
  }

  Future<void> loadWeeklySalaryForMonth(
      String userId, int year, int month) async {
    final firstDay = DateTime(year, month, 1);
    final monday =
        firstDay.subtract(Duration(days: firstDay.weekday - 1));
    _weekStart = monday.toString().split(' ')[0];
    _weekEnd   = getWeekEnd(_weekStart);
    await loadWeeklySalary(userId);
  }

  // ═══════════════════════════════════════════════════
  //  MONTHLY
  // ═══════════════════════════════════════════════════

  Future<void> loadMonthlySummary(String userId,
      {int? year, int? month}) async {
    _begin();
    try {
      final now = DateTime.now();
      final y   = year  ?? now.year;
      final m   = month ?? now.month;

      final prefix   = '$y-${m.toString().padLeft(2, '0')}';
      final firstDay = DateTime(y, m, 1);
      final lastDay  = DateTime(y, m + 1, 0);
      final start    = '$prefix-01';
      final end      = '$prefix-${lastDay.day.toString().padLeft(2, '0')}';

      // Parallel fetches — explicit typed casts
      final results = await Future.wait([
        _db.getProductionsByDateRange(start, end),
        _db.getAllProducts(),
        _db.getUserDeductions(userId),
      ]);

      final monthProds =
          (results[0] as List<ProductionModel>)
              .where((p) => p.helperIds.contains(userId))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

      final products = results[1] as List<ProductModel>;
      final allDeds  = results[2]; // List<DeductionModel>

      final dedMap = <String, dynamic>{
        for (final d in allDeds) (d as dynamic).weekStart: d,
      };

      final weeks = <WeeklySummary>[];
      var weekStart =
          firstDay.subtract(Duration(days: firstDay.weekday - 1));
      int weekNum = 1;

      while (!weekStart.isAfter(lastDay)) {
        final weekEnd = weekStart.add(const Duration(days: 6));
        final wsStr   = weekStart.toString().split(' ')[0];
        final weStr   = weekEnd.toString().split(' ')[0];

        final weekProds = monthProds.where((p) =>
            p.date.compareTo(wsStr) >= 0 &&
            p.date.compareTo(weStr) <= 0).toList();

        double gross = 0;
        int    sacks = 0;
        for (final prod in weekProds) {
          final calc = _payroll.computeDaily(prod, products);
          gross += calc.salaryPerWorker;
          sacks += calc.totalSacks;
        }

        final days = weekProds.length;
        final oven = days * AppConstants.helperOvenDeductionPerDay;
        final ded  = dedMap[wsStr];
        final gas  = (ded?.gas  as double?) ?? 0.0;
        final vale = (ded?.vale as double?) ?? 0.0;
        final wifi = (ded?.wifi as double?) ?? 0.0;

        weeks.add(WeeklySummary(
          label:         'Week $weekNum  (${_fmtShort(weekStart)} – ${_fmtShort(weekEnd)})',
          weekStart:     wsStr,
          daysWorked:    days,
          totalSacks:    sacks,
          grossSalary:   gross,
          ovenDeduction: oven,
          gasDeduction:  gas,
          vale:          vale,
          wifi:          wifi,
          finalSalary:   gross - oven - gas - vale - wifi,
        ));

        weekStart = weekEnd.add(const Duration(days: 1));
        weekNum++;
        if (weekStart.month != m && weekStart.isAfter(lastDay)) break;
      }

      _monthlyWeeks           = weeks;
      _monthlyGrossSalary     = weeks.fold(0, (s, w) => s + w.grossSalary);
      _monthlyOvenTotal       = weeks.fold(0, (s, w) => s + w.ovenDeduction);
      _monthlyGasTotal        = weeks.fold(0, (s, w) => s + w.gasDeduction);
      _monthlyValeTotal       = weeks.fold(0, (s, w) => s + w.vale);
      _monthlyWifiTotal       = weeks.fold(0, (s, w) => s + w.wifi);
      _monthlyTotalDeductions = _monthlyOvenTotal + _monthlyGasTotal +
          _monthlyValeTotal + _monthlyWifiTotal;
      _monthlyTotalSalary     = _monthlyGrossSalary - _monthlyTotalDeductions;
      _monthlyTotalDays       = weeks.fold(0, (s, w) => s + w.daysWorked);
      _monthlyTotalSacks      = weeks.fold(0, (s, w) => s + w.totalSacks);
      _monthlyAvgPerWeek      =
          weeks.isNotEmpty ? _monthlyTotalSalary / weeks.length : 0;
    } catch (e) {
      _end('Failed to load monthly summary.\n${_friendlyError(e)}');
      return;
    }
    _end();
  }

  String _fmtShort(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

// ═══════════════════════════════════════════════════════
//  LOCAL DATA MODELS
// ═══════════════════════════════════════════════════════

class HelperDailyRecord {
  final String date;
  final double salary;
  final int    totalWorkers;
  final int    totalSacks;
  final double totalValue;

  const HelperDailyRecord({
    required this.date,
    required this.salary,
    required this.totalWorkers,
    required this.totalSacks,
    required this.totalValue,
  });
}

class WeeklySummary {
  final String label;
  final String weekStart;
  final int    daysWorked;
  final int    totalSacks;
  final double grossSalary;
  final double ovenDeduction;
  final double gasDeduction;
  final double vale;
  final double wifi;
  final double finalSalary;

  const WeeklySummary({
    required this.label,
    required this.weekStart,
    required this.daysWorked,
    this.totalSacks = 0,
    required this.grossSalary,
    required this.ovenDeduction,
    required this.gasDeduction,
    required this.vale,
    required this.wifi,
    required this.finalSalary,
  });

  double get totalDeductions =>
      ovenDeduction + gasDeduction + vale + wifi;
}