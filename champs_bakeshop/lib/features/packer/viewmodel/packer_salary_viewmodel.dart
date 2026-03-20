import 'package:flutter/material.dart';
import '../../../core/models/packer_production_model.dart';
import '../../../core/models/packer_payroll_model.dart';
import '../../../core/services/packer_service.dart';

class PackerSalaryViewModel extends ChangeNotifier {
  final _service = PackerService();

  // ── State ──────────────────────────────────────────────────
  bool    _isLoading = false;
  String? _error;

  List<PackerProductionModel> _productions = [];
  PackerPayrollModel?         _weekPayroll;

  DateTime _weekStart = DateTime.now();

  // ── Getters ────────────────────────────────────────────────
  bool    get isLoading   => _isLoading;
  String? get error       => _error;

  List<PackerProductionModel> get productions => _productions;
  PackerPayrollModel?         get weekPayroll => _weekPayroll;

  // ── Week range ─────────────────────────────────────────────
  String get weekStart =>
      _weekStart.toIso8601String().substring(0, 10);

  String get weekEnd {
    final end = _weekStart.add(const Duration(days: 6));
    return end.toIso8601String().substring(0, 10);
  }

  // ── Daily aggregates ───────────────────────────────────────
  /// Group productions by date → {date: [productions]}
  Map<String, List<PackerProductionModel>> get productionsByDate {
    final map = <String, List<PackerProductionModel>>{};
    for (final p in _productions) {
      map.putIfAbsent(p.date, () => []).add(p);
    }
    return map;
  }

  /// Daily entries sorted newest first
  List<PackerDailyEntry> get dailyEntries {
    final entries = productionsByDate.entries.map((e) {
      final bundles = e.value.fold(0, (s, p) => s + p.bundleCount);
      return PackerDailyEntry(
        date:        e.key,
        productions: e.value,
        totalBundles: bundles,
        salary:      bundles * 4.0,
      );
    }).toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  // ── Weekly aggregates ──────────────────────────────────────
  int get totalBundles =>
      _productions.fold(0, (s, p) => s + p.bundleCount);

  double get grossSalary => totalBundles * 4.0;

  double get valeDeduction => _weekPayroll?.valeDeduction ?? 0.0;

  double get netSalary => grossSalary - valeDeduction;

  int get daysWorked => productionsByDate.keys.length;

  // ── Monthly weekly breakdown ───────────────────────────────
  List<PackerWeeklySummary> get weeklySummaries {
    final summaries = <PackerWeeklySummary>[];
    for (int i = 3; i >= 0; i--) {
      final wStart = _weekStart.subtract(Duration(days: 7 * i));
      final wEnd   = wStart.add(const Duration(days: 6));
      final wsStr  = wStart.toIso8601String().substring(0, 10);
      final weStr  = wEnd.toIso8601String().substring(0, 10);

      final weekProds = _productions
          .where((p) =>
              p.date.compareTo(wsStr) >= 0 &&
              p.date.compareTo(weStr) <= 0)
          .toList();

      final bundles = weekProds.fold(0, (s, p) => s + p.bundleCount);

      summaries.add(PackerWeeklySummary(
        weekStart:  wsStr,
        weekEnd:    weStr,
        bundles:    bundles,
        grossSalary: bundles * 4.0,
        days:       weekProds.map((p) => p.date).toSet().length,
      ));
    }
    return summaries;
  }

  // ─────────────────────────────────────────────────────────
  //  INIT
  // ─────────────────────────────────────────────────────────
  Future<void> init(String packerId) async {
    _setWeekToCurrentMonday();
    await _loadWeekData(packerId);
  }

  void _setWeekToCurrentMonday() {
    final now  = DateTime.now();
    final diff = now.weekday - DateTime.monday;
    _weekStart = DateTime(now.year, now.month, now.day - diff);
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD WEEK DATA
  // ─────────────────────────────────────────────────────────
  Future<void> _loadWeekData(String packerId) async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _service.getProductionsByWeek(
          packerId:  packerId,
          weekStart: weekStart,
          weekEnd:   weekEnd,
        ),
        _service.getPayrollByWeek(
          packerId:  packerId,
          weekStart: weekStart,
          weekEnd:   weekEnd,
        ),
      ]);

      _productions = results[0] as List<PackerProductionModel>;
      _weekPayroll = results[1] as PackerPayrollModel?;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD MONTHLY (4 weeks)
  // ─────────────────────────────────────────────────────────
  Future<void> loadMonthly(String packerId) async {
    _setLoading(true);
    try {
      final monthStart = _weekStart.subtract(const Duration(days: 21));
      final fromDate   = monthStart.toIso8601String().substring(0, 10);

      _productions = await _service.getProductionsByMonth(
        packerId:   packerId,
        monthStart: fromDate,
        monthEnd:   weekEnd,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  WEEK NAVIGATION
  // ─────────────────────────────────────────────────────────
  Future<void> changeWeek(int direction, String packerId) async {
    _weekStart = _weekStart.add(Duration(days: 7 * direction));
    await _loadWeekData(packerId);
  }

  // ─────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// ── Helper data classes ───────────────────────────────────────
class PackerDailyEntry {
  final String date;
  final List<PackerProductionModel> productions;
  final int    totalBundles;
  final double salary;

  const PackerDailyEntry({
    required this.date,
    required this.productions,
    required this.totalBundles,
    required this.salary,
  });
}

class PackerWeeklySummary {
  final String weekStart;
  final String weekEnd;
  final int    bundles;
  final double grossSalary;
  final int    days;

  const PackerWeeklySummary({
    required this.weekStart,
    required this.weekEnd,
    required this.bundles,
    required this.grossSalary,
    required this.days,
  });
}