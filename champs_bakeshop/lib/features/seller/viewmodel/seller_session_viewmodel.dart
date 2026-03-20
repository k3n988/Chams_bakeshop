import 'package:flutter/material.dart';
import '../../../core/models/seller_session_model.dart';
import '../../../core/models/seller_remittance_model.dart';
import '../../../core/services/seller_service.dart';

class SellerSessionViewModel extends ChangeNotifier {
  final _service = SellerService();

  // ── State ──────────────────────────────────────────────────
  bool    _isLoading = false;
  String? _error;

  SellerSessionModel?     _todaySession;
  SellerRemittanceModel?  _todayRemittance;

  List<SellerSessionModel>    _sessions    = [];
  List<SellerRemittanceModel> _remittances = [];

  // ── Getters ────────────────────────────────────────────────
  bool    get isLoading        => _isLoading;
  String? get error            => _error;

  SellerSessionModel?    get todaySession    => _todaySession;
  SellerRemittanceModel? get todayRemittance => _todayRemittance;

  List<SellerSessionModel>    get sessions    => _sessions;
  List<SellerRemittanceModel> get remittances => _remittances;

  // ── Derived: today ─────────────────────────────────────────
  bool get hasSessionToday    => _todaySession != null;
  bool get hasRemittanceToday => _todayRemittance != null;

  int    get totalPiecesTaken    => _todaySession?.totalPiecesTaken ?? 0;
  double get expectedRemittance  => _todaySession?.expectedRemittance ?? 0;
  int    get returnPieces        => _todayRemittance?.returnPieces ?? 0;
  int    get piecesSold          => _todayRemittance?.piecesSold ?? 0;
  double get actualRemittance    => _todayRemittance?.actualRemittance ?? 0;
  double get adjustedRemittance  => _todayRemittance?.adjustedRemittance ?? 0;
  double get variance            => _todayRemittance?.variance ?? 0;

  // ── Derived: history lists ─────────────────────────────────
  /// Group remittances by date for daily view
  Map<String, SellerRemittanceModel> get remittanceByDate {
    return { for (final r in _remittances) r.date : r };
  }

  /// Total pieces sold across loaded remittances
  int get totalPiecesSoldRange =>
      _remittances.fold(0, (sum, r) => sum + r.piecesSold);

  /// Total actual remittance across loaded remittances
  double get totalActualRemittanceRange =>
      _remittances.fold(0, (sum, r) => sum + r.actualRemittance);

  /// Total adjusted (expected after returns) remittance
  double get totalAdjustedRemittanceRange =>
      _remittances.fold(0, (sum, r) => sum + r.adjustedRemittance);

  // ── Week navigation ────────────────────────────────────────
  DateTime _weekStart = DateTime.now();

  String get weekStartStr =>
      _weekStart.toIso8601String().substring(0, 10);

  String get weekEndStr {
    final end = _weekStart.add(const Duration(days: 6));
    return end.toIso8601String().substring(0, 10);
  }

  // ─────────────────────────────────────────────────────────
  //  INIT
  // ─────────────────────────────────────────────────────────
  Future<void> init(String sellerId) async {
    _setWeekToCurrentMonday();
    await Future.wait([
      loadTodayRecord(sellerId),
      loadWeeklyRemittances(sellerId),
    ]);
  }

  void _setWeekToCurrentMonday() {
    final now  = DateTime.now();
    final diff = now.weekday - DateTime.monday;
    _weekStart = DateTime(now.year, now.month, now.day - diff);
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD TODAY
  // ─────────────────────────────────────────────────────────
  Future<void> loadTodayRecord(String sellerId) async {
    _setLoading(true);
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final record = await _service.getDailyRecord(
        sellerId: sellerId,
        date: today,
      );
      _todaySession    = record['session']    as SellerSessionModel?;
      _todayRemittance = record['remittance'] as SellerRemittanceModel?;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD WEEKLY REMITTANCES
  // ─────────────────────────────────────────────────────────
  Future<void> loadWeeklyRemittances(String sellerId) async {
    try {
      _remittances = await _service.getRemittancesByRange(
        sellerId: sellerId,
        fromDate: weekStartStr,
        toDate:   weekEndStr,
      );
      _sessions = await _service.getSessionsByRange(
        sellerId: sellerId,
        fromDate: weekStartStr,
        toDate:   weekEndStr,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  //  WEEK NAVIGATION
  // ─────────────────────────────────────────────────────────
  Future<void> changeWeek(int direction, String sellerId) async {
    _weekStart = _weekStart.add(Duration(days: 7 * direction));
    await loadWeeklyRemittances(sellerId);
  }

  // ─────────────────────────────────────────────────────────
  //  CREATE SESSION (morning)
  // ─────────────────────────────────────────────────────────
  Future<bool> createSession({
    required String sellerId,
    required int    plantsaCount,
    required int    subraPieces,
  }) async {
    _setLoading(true);
    try {
      final now   = DateTime.now();
      final date  = now.toIso8601String().substring(0, 10);
      final tsStr = now.toIso8601String();

      final session = await _service.createSession(
        sellerId:     sellerId,
        date:         date,
        plantsaCount: plantsaCount,
        subraPieces:  subraPieces,
        takenOutAt:   tsStr,
      );

      if (session != null) {
        _todaySession = session;
        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  CREATE REMITTANCE (evening)
  // ─────────────────────────────────────────────────────────
  Future<bool> createRemittance({
    required String sellerId,
    required int    returnPieces,
    required double actualRemittance,
  }) async {
    if (_todaySession == null) {
      _error = 'No session found for today. Please create a session first.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final now   = DateTime.now();
      final tsStr = now.toIso8601String();

      final remittance = await _service.createRemittance(
        sellerId:           sellerId,
        sessionId:          _todaySession!.id,
        date:               _todaySession!.date,
        returnPieces:       returnPieces,
        actualRemittance:   actualRemittance,
        totalPiecesTaken:   _todaySession!.totalPiecesTaken,
        expectedRemittance: _todaySession!.expectedRemittance,
        remittedAt:         tsStr,
      );

      if (remittance != null) {
        _todayRemittance = remittance;
        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UPDATE REMITTANCE
  // ─────────────────────────────────────────────────────────
  Future<bool> updateRemittance({
    required int    returnPieces,
    required double actualRemittance,
  }) async {
    if (_todayRemittance == null) return false;

    _setLoading(true);
    try {
      final updated = await _service.updateRemittance(
        remittanceId:     _todayRemittance!.id,
        returnPieces:     returnPieces,
        actualRemittance: actualRemittance,
        totalPiecesTaken: _todayRemittance!.totalPiecesTaken,
      );

      if (updated != null) {
        _todayRemittance = updated;
        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
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