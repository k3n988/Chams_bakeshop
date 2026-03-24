import 'package:flutter/material.dart';
import '../../../core/models/packer_production_model.dart';
import '../../../core/models/packer_payroll_model.dart';
import '../../../core/services/packer_service.dart';

class PackerSalaryViewModel extends ChangeNotifier {
  final _service = PackerService();

  // ── State ──────────────────────────────────────────────────
  bool    _isLoading = false;
  String? _error;

  List<PackerProductionModel> _productions     = [];
  List<PackerProductionModel> _yearProductions = [];
  PackerPayrollModel?         _weekPayroll;

  DateTime _weekStart  = _currentMonday();
  DateTime _monthStart = _firstDayOfMonth(DateTime.now());

  // ── Getters ────────────────────────────────────────────────
  bool    get isLoading   => _isLoading;
  String? get error       => _error;

  List<PackerProductionModel> get productions => _productions;
  PackerPayrollModel?         get weekPayroll => _weekPayroll;

  // ── Week range (ISO – DB queries) ──────────────────────────
  String get weekStart => _isoDate(_weekStart);
  String get weekEnd   => _isoDate(_weekStart.add(const Duration(days: 6)));

  // ── Week display ───────────────────────────────────────────
  String get weekStartDisplay => _fmtDate(_weekStart);
  String get weekEndDisplay   => _fmtDate(_weekStart.add(const Duration(days: 6)));
  String get todayDisplay     => _fmtFull(DateTime.now());

  bool get isCurrentWeek {
    final today = _currentMonday();
    return _weekStart.year  == today.year  &&
           _weekStart.month == today.month &&
           _weekStart.day   == today.day;
  }

  // ── Month display ──────────────────────────────────────────
  String get monthDisplay => _fmtMonth(_monthStart);

  bool get isCurrentMonth {
    final now = DateTime.now();
    return _monthStart.year  == now.year &&
           _monthStart.month == now.month;
  }

  String get _monthStartIso => _isoDate(_monthStart);
  String get _monthEndIso   => _isoDate(_lastDayOfMonth(_monthStart));

  // ── Daily aggregates ───────────────────────────────────────
  Map<String, List<PackerProductionModel>> get productionsByDate {
    final map = <String, List<PackerProductionModel>>{};
    for (final p in _productions) {
      map.putIfAbsent(p.date, () => []).add(p);
    }
    return map;
  }

  List<PackerDailyEntry> get dailyEntries {
    final entries = productionsByDate.entries.map((e) {
      final bundles = e.value.fold(0, (s, p) => s + p.bundleCount);
      return PackerDailyEntry(
        date:         e.key,
        productions:  e.value,
        totalBundles: bundles,
        salary:       bundles * 4.0,
      );
    }).toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  // ── Weekly aggregates ──────────────────────────────────────
  int    get totalBundles  => _productions.fold(0, (s, p) => s + p.bundleCount);
  double get grossSalary   => totalBundles * 4.0;
  double get valeDeduction => _weekPayroll?.valeDeduction ?? 0.0;
  double get netSalary     => grossSalary - valeDeduction;
  int    get daysWorked    => productionsByDate.keys.length;

  // ── Yearly aggregates (used by profile) ───────────────────
  int    get yearlyBundles => _yearProductions.fold(0, (s, p) => s + p.bundleCount);
  double get yearlyGross   => yearlyBundles * 4.0;
  int    get yearlyDays    {
    final dates = <String>{};
    for (final p in _yearProductions) dates.add(p.date);
    return dates.length;
  }

  // ── Monthly weekly breakdown ───────────────────────────────
  List<PackerWeeklySummary> get weeklySummaries {
    final summaries = <PackerWeeklySummary>[];
    for (int i = 3; i >= 0; i--) {
      final wStart = _weekStart.subtract(Duration(days: 7 * i));
      final wEnd   = wStart.add(const Duration(days: 6));
      final wsStr  = _isoDate(wStart);
      final weStr  = _isoDate(wEnd);

      final weekProds = _productions
          .where((p) =>
              p.date.compareTo(wsStr) >= 0 &&
              p.date.compareTo(weStr) <= 0)
          .toList();

      final bundles = weekProds.fold(0, (s, p) => s + p.bundleCount);

      final dayMap = <String, List<PackerProductionModel>>{};
      for (final p in weekProds) {
        dayMap.putIfAbsent(p.date, () => []).add(p);
      }

      final weekDailyEntries = dayMap.entries.map((e) {
        final b = e.value.fold(0, (s, p) => s + p.bundleCount);
        return PackerDailyEntry(
          date:         e.key,
          productions:  e.value,
          totalBundles: b,
          salary:       b * 4.0,
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      summaries.add(PackerWeeklySummary(
        weekStart:    wsStr,
        weekEnd:      weStr,
        bundles:      bundles,
        grossSalary:  bundles * 4.0,
        days:         dayMap.keys.length,
        dailyEntries: weekDailyEntries,
      ));
    }
    return summaries;
  }

  // ─────────────────────────────────────────────────────────
  //  INIT — resets to current week
  // ─────────────────────────────────────────────────────────
  Future<void> init(String packerId) async {
    _weekStart = _currentMonday();
    await Future.wait([
      _loadWeekData(packerId),
      _loadYearData(packerId),
    ]);
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
  //  LOAD YEAR DATA (Jan 1 → Dec 31 of current year)
  // ─────────────────────────────────────────────────────────
  Future<void> _loadYearData(String packerId) async {
    try {
      final year      = DateTime.now().year;
      final yearStart = '$year-01-01';
      final yearEnd   = '$year-12-31';
      _yearProductions = await _service.getProductionsByMonth(
        packerId:   packerId,
        monthStart: yearStart,
        monthEnd:   yearEnd,
      );
    } catch (_) {
      _yearProductions = [];
    }
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD MONTHLY
  // ─────────────────────────────────────────────────────────
  Future<void> loadMonthly(String packerId) async {
    _monthStart = _firstDayOfMonth(DateTime.now());
    await _loadMonthData(packerId);
  }

  Future<void> _loadMonthData(String packerId) async {
    _setLoading(true);
    try {
      _productions = await _service.getProductionsByMonth(
        packerId:   packerId,
        monthStart: _monthStartIso,
        monthEnd:   _monthEndIso,
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

  Future<void> goToDate(DateTime date, String packerId) async {
    final diff = date.weekday - DateTime.monday;
    _weekStart = DateTime(date.year, date.month, date.day - diff);
    await _loadWeekData(packerId);
  }

  // ─────────────────────────────────────────────────────────
  //  MONTH NAVIGATION
  // ─────────────────────────────────────────────────────────
  Future<void> changeMonth(int direction, String packerId) async {
    final m = _monthStart.month + direction;
    final y = _monthStart.year + (m < 1 ? -1 : m > 12 ? 1 : 0);
    final adjustedMonth = m < 1 ? 12 : m > 12 ? 1 : m;
    _monthStart = DateTime(y, adjustedMonth, 1);
    await _loadMonthData(packerId);
  }

  Future<void> goToCurrentMonth(String packerId) async {
    _monthStart = _firstDayOfMonth(DateTime.now());
    await _loadMonthData(packerId);
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

  static DateTime _currentMonday() {
    final now  = DateTime.now();
    final diff = now.weekday - DateTime.monday;
    return DateTime(now.year, now.month, now.day - diff);
  }

  static DateTime _firstDayOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime _lastDayOfMonth(DateTime d)  => DateTime(d.year, d.month + 1, 0);
  static String   _isoDate(DateTime d)         => d.toIso8601String().substring(0, 10);

  static String _fmtDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  static String _fmtMonth(DateTime d) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month]} ${d.year}';
  }

  static String _fmtFull(DateTime d) {
    const days = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[d.weekday]}, ${_fmtDate(d)}';
  }
}

// ══════════════════════════════════════════════════════════════
//  HELPER DATA CLASSES
// ══════════════════════════════════════════════════════════════
class PackerDailyEntry {
  final String                      date;
  final List<PackerProductionModel> productions;
  final int                         totalBundles;
  final double                      salary;

  const PackerDailyEntry({
    required this.date,
    required this.productions,
    required this.totalBundles,
    required this.salary,
  });
}

class PackerWeeklySummary {
  final String                 weekStart;
  final String                 weekEnd;
  final int                    bundles;
  final double                 grossSalary;
  final int                    days;
  final List<PackerDailyEntry> dailyEntries;

  const PackerWeeklySummary({
    required this.weekStart,
    required this.weekEnd,
    required this.bundles,
    required this.grossSalary,
    required this.days,
    required this.dailyEntries,
  });
}