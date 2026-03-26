import 'package:flutter/material.dart';
import '../../../core/models/seller_remittance_model.dart';
import '../../../core/models/seller_session_model.dart';
import '../../../core/services/seller_service.dart';

/// Handles salary computation for daily / weekly / monthly views
class SellerRemittanceViewModel extends ChangeNotifier {
  final _service = SellerService();

  // ── State ──────────────────────────────────────────────────
  bool    _isLoading = false;
  String? _error;

  List<SellerRemittanceModel> _remittances       = [];
  List<SellerSessionModel>    _sessions          = [];
  List<SellerWeeklySummary> _cachedSummaries = [];

  // ── Yearly snapshot (profile) ──────────────────────────────
  int    _yearlyPiecesSold    = 0;
  double _yearlyRemittance    = 0;
  double _yearlySalary        = 0;
  int    _yearlyDays          = 0;

  int    get yearlyPiecesSold => _yearlyPiecesSold;
  double get yearlyRemittance => _yearlyRemittance;
  double get yearlySalary     => _yearlySalary;
  int    get yearlyDays       => _yearlyDays;

  DateTime _weekStart = _currentMonday();

  // ── Getters ────────────────────────────────────────────────
  bool    get isLoading    => _isLoading;
  String? get error        => _error;

  bool get isCurrentWeek =>
      weekStart == _currentMonday().toIso8601String().substring(0, 10);

  List<SellerRemittanceModel> get remittances => _remittances;
  List<SellerSessionModel>    get sessions    => _sessions;

  // ── Week range strings ─────────────────────────────────────
  String get weekStart =>
      _weekStart.toIso8601String().substring(0, 10);

  String get weekEnd {
    final end = _weekStart.add(const Duration(days: 6));
    return end.toIso8601String().substring(0, 10);
  }

  // ─────────────────────────────────────────────────────────
  //  DAILY AGGREGATES (over loaded remittances)
  // ─────────────────────────────────────────────────────────

  /// Total pieces sold
  int get totalPiecesSold =>
      _remittances.fold(0, (s, r) => s + r.piecesSold);

  /// Total actual cash remitted
  double get totalActualRemittance =>
      _remittances.fold(0.0, (s, r) => s + r.actualRemittance);

  /// Total adjusted (after returns)
  double get totalAdjustedRemittance =>
      _remittances.fold(0.0, (s, r) => s + r.adjustedRemittance);

  /// Total returns across range
  int get totalReturns =>
      _remittances.fold(0, (s, r) => s + r.returnPieces);

  /// Days with complete remittance
  int get daysRemitted => _remittances.length;

  /// Net variance (positive = short, negative = overpaid)
  double get totalVariance =>
      _remittances.fold(0.0, (s, r) => s + r.variance);

  // ─────────────────────────────────────────────────────────
  //  INIT
  // ─────────────────────────────────────────────────────────
  Future<void> init(String sellerId) async {
    _setWeekToCurrentMonday();
    await _loadRange(sellerId);
  }

  Future<void> loadYearlySummary(String sellerId) async {
    final year  = DateTime.now().year;
    final start = '$year-01-01';
    final end   = '$year-12-31';
    try {
      final remittances = await _service.getRemittancesByRange(
        sellerId: sellerId, fromDate: start, toDate: end,
      );
      _yearlyPiecesSold = remittances.fold(0,   (s, r) => s + r.piecesSold);
      _yearlyRemittance = remittances.fold(0.0, (s, r) => s + r.actualRemittance);
      _yearlySalary     = remittances.fold(0.0, (s, r) => s + r.salary);
      _yearlyDays       = remittances.length;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load yearly summary.';
      notifyListeners();
    }
  }

  void _setWeekToCurrentMonday() {
    _weekStart = _currentMonday();
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD RANGE
  // ─────────────────────────────────────────────────────────
  Future<void> _loadRange(String sellerId) async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _service.getRemittancesByRange(
          sellerId: sellerId,
          fromDate: weekStart,
          toDate:   weekEnd,
        ),
        _service.getSessionsByRange(
          sellerId: sellerId,
          fromDate: weekStart,
          toDate:   weekEnd,
        ),
      ]).timeout(const Duration(seconds: 15));
      _remittances     = results[0] as List<SellerRemittanceModel>;
      _sessions        = results[1] as List<SellerSessionModel>;
      _cachedSummaries = _buildWeeklySummaries();
      _error = null;
    } catch (e) {
      _error = 'Failed to load data. Check your connection.';
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD MONTHLY (4-week range)
  // ─────────────────────────────────────────────────────────
  Future<void> loadMonthly(String sellerId) async {
    _setLoading(true);
    try {
      final monthStart = _weekStart.subtract(const Duration(days: 21));
      final fromDate   = monthStart.toIso8601String().substring(0, 10);

      final results = await Future.wait([
        _service.getRemittancesByRange(
          sellerId: sellerId,
          fromDate: fromDate,
          toDate:   weekEnd,
        ),
        _service.getSessionsByRange(
          sellerId: sellerId,
          fromDate: fromDate,
          toDate:   weekEnd,
        ),
      ]).timeout(const Duration(seconds: 15));
      _remittances     = results[0] as List<SellerRemittanceModel>;
      _sessions        = results[1] as List<SellerSessionModel>;
      _cachedSummaries = _buildWeeklySummaries();
      _error = null;
    } catch (e) {
      _error = 'Failed to load monthly data. Check your connection.';
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  WEEK NAVIGATION
  // ─────────────────────────────────────────────────────────
  Future<void> changeWeek(int direction, String sellerId) async {
    if (direction > 0 && isCurrentWeek) return;
    _weekStart = _weekStart.add(Duration(days: 7 * direction));
    await _loadRange(sellerId);
  }

  // ─────────────────────────────────────────────────────────
  //  GROUP BY DATE  (for daily list view)
  // ─────────────────────────────────────────────────────────

  /// Returns remittances sorted newest first
  List<SellerRemittanceModel> get sortedRemittances {
    final list = List<SellerRemittanceModel>.from(_remittances);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Sessions that have no remittance yet
  List<SellerSessionModel> get pendingRemittanceSessions {
    final remittedDates = _remittances.map((r) => r.date).toSet();
    return _sessions.where((s) => !remittedDates.contains(s.date)).toList();
  }

  // ─────────────────────────────────────────────────────────
  //  WEEKLY BREAKDOWN  (for monthly tab)
  // ─────────────────────────────────────────────────────────

  /// Returns cached summaries — rebuilt only after each load.
  List<SellerWeeklySummary> get weeklySummaries => _cachedSummaries;

  List<SellerWeeklySummary> _buildWeeklySummaries() {
    final summaries = <SellerWeeklySummary>[];
    for (int i = 3; i >= 0; i--) {
      final wStart = _weekStart.subtract(Duration(days: 7 * i));
      final wEnd   = wStart.add(const Duration(days: 6));
      final wsStr  = wStart.toIso8601String().substring(0, 10);
      final weStr  = wEnd.toIso8601String().substring(0, 10);

      final weekRemittances = _remittances
          .where((r) => r.date.compareTo(wsStr) >= 0 &&
                        r.date.compareTo(weStr) <= 0)
          .toList();

      summaries.add(SellerWeeklySummary(
        weekStart:       wsStr,
        weekEnd:         weStr,
        piecesSold:      weekRemittances.fold(0,   (s, r) => s + r.piecesSold),
        totalRemittance: weekRemittances.fold(0.0, (s, r) => s + r.actualRemittance),
        days:            weekRemittances.length,
      ));
    }
    return summaries;
  }

  // ─────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────
  static DateTime _currentMonday() {
    final now  = DateTime.now();
    final diff = now.weekday - DateTime.monday;
    return DateTime(now.year, now.month, now.day - diff);
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// ── Helper data class ─────────────────────────────────────────
class SellerWeeklySummary {
  final String weekStart;
  final String weekEnd;
  final int    piecesSold;
  final double totalRemittance;
  final int    days;

  const SellerWeeklySummary({
    required this.weekStart,
    required this.weekEnd,
    required this.piecesSold,
    required this.totalRemittance,
    required this.days,
  });
}