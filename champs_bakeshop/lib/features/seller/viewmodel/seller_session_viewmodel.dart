import 'package:flutter/material.dart';
import '../../../core/models/seller_session_model.dart';
import '../../../core/models/seller_remittance_model.dart';
import '../../../core/services/seller_service.dart';

enum SessionType { morning, afternoon }
enum RemitType   { morning, afternoon }

class SellerSessionViewModel extends ChangeNotifier {
  final _service = SellerService();

  bool    _isLoading = false;
  String? _error;

  // Currently loaded date state
  SellerSessionModel?    _morningSession;
  SellerRemittanceModel? _morningRemittance;
  SellerSessionModel?    _afternoonSession;
  SellerRemittanceModel? _afternoonRemittance;

  // Weekly list
  List<SellerSessionModel>    _sessions    = [];
  List<SellerRemittanceModel> _remittances = [];

  DateTime _weekStart = DateTime.now();

  // ── Basic getters ──────────────────────────────────────────
  bool    get isLoading => _isLoading;
  String? get error     => _error;

  // ── Morning ────────────────────────────────────────────────
  /// Kept for backward compatibility — prefer morningSession
  SellerSessionModel?    get todaySession      => _morningSession;
  SellerSessionModel?    get morningSession    => _morningSession;
  SellerRemittanceModel? get morningRemittance => _morningRemittance;

  bool   get hasMorningSession    => _morningSession != null;
  bool   get hasMorningRemittance => _morningRemittance != null;

  int    get morningPiecesTaken        => _morningSession?.totalPiecesTaken    ?? 0;
  double get morningExpectedRemittance => _morningSession?.expectedRemittance   ?? 0;
  int    get morningReturnPieces       => _morningRemittance?.returnPieces      ?? 0;
  int    get morningPiecesSold         => _morningRemittance?.piecesSold        ?? 0;
  double get morningActualRemittance   => _morningRemittance?.actualRemittance  ?? 0;

  // ── Afternoon ──────────────────────────────────────────────
  SellerSessionModel?    get afternoonSession    => _afternoonSession;
  SellerRemittanceModel? get afternoonRemittance => _afternoonRemittance;

  bool   get hasAfternoonSession    => _afternoonSession != null;
  bool   get hasAfternoonRemittance => _afternoonRemittance != null;

  int    get afternoonPiecesTaken        => _afternoonSession?.totalPiecesTaken    ?? 0;
  double get afternoonExpectedRemittance => _afternoonSession?.expectedRemittance   ?? 0;
  int    get afternoonReturnPieces       => _afternoonRemittance?.returnPieces      ?? 0;
  int    get afternoonPiecesSold         => _afternoonRemittance?.piecesSold        ?? 0;
  double get afternoonActualRemittance   => _afternoonRemittance?.actualRemittance  ?? 0;

  // ── Combined ───────────────────────────────────────────────
  bool   get hasSessionToday    => hasMorningSession || hasAfternoonSession;
  bool   get hasRemittanceToday => hasMorningRemittance || hasAfternoonRemittance;
  bool   get hasSessionForDate  => hasMorningSession || hasAfternoonSession;

  int    get totalPiecesTaken   => morningPiecesTaken + afternoonPiecesTaken;
  double get expectedRemittance => morningExpectedRemittance + afternoonExpectedRemittance;
  int    get returnPieces       => morningReturnPieces + afternoonReturnPieces;
  int    get piecesSold         => morningPiecesSold + afternoonPiecesSold;
  double get actualRemittance   => morningActualRemittance + afternoonActualRemittance;
  double get adjustedRemittance => piecesSold * 5.0;
  double get variance           => actualRemittance - adjustedRemittance;

  // ── Weekly getters ─────────────────────────────────────────
  List<SellerSessionModel>    get sessions    => _sessions;
  List<SellerRemittanceModel> get remittances => _remittances;

  String get weekStart => _weekStart.toIso8601String().substring(0, 10);
  String get weekEnd {
    final end = _weekStart.add(const Duration(days: 6));
    return end.toIso8601String().substring(0, 10);
  }

  int    get totalPiecesSoldRange =>
      _remittances.fold(0, (s, r) => s + r.piecesSold);
  double get totalActualRemittanceRange =>
      _remittances.fold(0.0, (s, r) => s + r.actualRemittance);
  double get totalAdjustedRemittanceRange =>
      _remittances.fold(0.0, (s, r) => s + r.adjustedRemittance);
  int    get daysRemitted =>
      _remittances.map((r) => r.date).toSet().length;
  double get totalVariance =>
      _remittances.fold(0.0, (s, r) => s + r.variance);
  int    get totalReturns =>
      _remittances.fold(0, (s, r) => s + r.returnPieces);

  Map<String, SellerRemittanceModel> get remittanceByDate =>
      {for (final r in _remittances) r.date: r};

  List<SellerRemittanceModel> get sortedRemittances {
    final list = List<SellerRemittanceModel>.from(_remittances);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<SellerSessionModel> get pendingRemittanceSessions {
    final remittedIds = _remittances.map((r) => r.sessionId).toSet();
    return _sessions.where((s) => !remittedIds.contains(s.id)).toList();
  }

  // ─────────────────────────────────────────────────────────
  //  INIT
  // ─────────────────────────────────────────────────────────
  Future<void> init(String sellerId) async {
    _setWeekToCurrentMonday();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await Future.wait([
      loadDateRecord(sellerId, today),
      loadWeeklyRemittances(sellerId),
    ]);
  }

  void _setWeekToCurrentMonday() {
    final now  = DateTime.now();
    final diff = now.weekday - DateTime.monday;
    _weekStart = DateTime(now.year, now.month, now.day - diff);
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD ANY DATE
  // ─────────────────────────────────────────────────────────
  Future<void> loadDateRecord(String sellerId, String date) async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _service.getSessionsByRange(
          sellerId: sellerId, fromDate: date, toDate: date),
        _service.getRemittancesByRange(
          sellerId: sellerId, fromDate: date, toDate: date),
      ]).timeout(const Duration(seconds: 15));
      final sessions    = results[0] as List<SellerSessionModel>;
      final remittances = results[1] as List<SellerRemittanceModel>;

      _morningSession      = sessions.where((s) => s.sessionType == 'morning').firstOrNull;
      _afternoonSession    = sessions.where((s) => s.sessionType == 'afternoon').firstOrNull;
      _morningRemittance   = null;
      _afternoonRemittance = null;

      if (_morningSession != null) {
        _morningRemittance = remittances
            .where((r) => r.sessionId == _morningSession!.id)
            .firstOrNull;
      }
      if (_afternoonSession != null) {
        _afternoonRemittance = remittances
            .where((r) => r.sessionId == _afternoonSession!.id)
            .firstOrNull;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Keep legacy method for compatibility ──────────────────
  Future<void> loadTodayRecord(String sellerId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await loadDateRecord(sellerId, today);
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD WEEKLY
  // ─────────────────────────────────────────────────────────
  Future<void> loadWeeklyRemittances(String sellerId) async {
    try {
      final results = await Future.wait([
        _service.getRemittancesByRange(
          sellerId: sellerId, fromDate: weekStart, toDate: weekEnd),
        _service.getSessionsByRange(
          sellerId: sellerId, fromDate: weekStart, toDate: weekEnd),
      ]).timeout(const Duration(seconds: 15));
      _remittances = results[0] as List<SellerRemittanceModel>;
      _sessions    = results[1] as List<SellerSessionModel>;
      _error = null;
    } catch (e) {
      _error = 'Failed to load data. Check your connection.';
    }
    notifyListeners();
  }

  Future<void> changeWeek(int direction, String sellerId) async {
    _weekStart = _weekStart.add(Duration(days: 7 * direction));
    await loadWeeklyRemittances(sellerId);
  }

  // ─────────────────────────────────────────────────────────
  //  CREATE SESSION — accepts any date (not just today)
  // ─────────────────────────────────────────────────────────
  Future<bool> createSession({
    required String      sellerId,
    required int         plantsaCount,
    required int         subraPieces,
    required SessionType sessionType,
    String?              date,        // if null → uses today
  }) async {
    _setLoading(true);
    try {
      final now     = DateTime.now();
      final dateStr = date ?? now.toIso8601String().substring(0, 10);
      final tsStr   = now.toIso8601String();
      final typeStr = sessionType == SessionType.morning ? 'morning' : 'afternoon';

      // ── Duplicate guard ──────────────────────────────────────
      final exists = await _service.sessionExistsForDate(
        sellerId:    sellerId,
        date:        dateStr,
        sessionType: typeStr,
      );
      if (exists) {
        _error = 'A $typeStr session for $dateStr already exists.';
        notifyListeners();
        _setLoading(false);
        return false;
      }

      final session = await _service.createSession(
        sellerId:     sellerId,
        date:         dateStr,
        plantsaCount: plantsaCount,
        subraPieces:  subraPieces,
        takenOutAt:   tsStr,
        sessionType:  typeStr,
      );

      if (session != null) {
        if (sessionType == SessionType.morning) {
          _morningSession = session;
        } else {
          _afternoonSession = session;
        }
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
  //  CREATE REMITTANCE
  // ─────────────────────────────────────────────────────────
  Future<bool> createRemittance({
    required String    sellerId,
    required int       returnPieces,
    required double    actualRemittance,
    required double    salary,
    required RemitType remitType,
  }) async {
    final session = remitType == RemitType.morning
        ? _morningSession
        : _afternoonSession;

    if (session == null) {
      _error = 'No session found for this type.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final remittance = await _service.createRemittance(
        sellerId:           sellerId,
        sessionId:          session.id,
        date:               session.date,
        returnPieces:       returnPieces,
        actualRemittance:   actualRemittance,
        totalPiecesTaken:   session.totalPiecesTaken,
        expectedRemittance: session.expectedRemittance,
        salary:             salary,
        remittedAt:         DateTime.now().toIso8601String(),
      );

      if (remittance != null) {
        if (remitType == RemitType.morning) {
          _morningRemittance = remittance;
        } else {
          _afternoonRemittance = remittance;
        }
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
    required int       returnPieces,
    required double    actualRemittance,
    required double    salary,
    required RemitType remitType,
  }) async {
    final existing = remitType == RemitType.morning
        ? _morningRemittance
        : _afternoonRemittance;

    if (existing == null) return false;

    _setLoading(true);
    try {
      final updated = await _service.updateRemittance(
        remittanceId:     existing.id,
        returnPieces:     returnPieces,
        actualRemittance: actualRemittance,
        totalPiecesTaken: existing.totalPiecesTaken,
        salary:           salary,
      );

      if (updated != null) {
        if (remitType == RemitType.morning) {
          _morningRemittance = updated;
        } else {
          _afternoonRemittance = updated;
        }
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
  //  DELETE
  // ─────────────────────────────────────────────────────────

  /// Deletes a session (and its remittance if present) for the
  /// current loaded date, then reloads the date record.
  Future<bool> deleteSession({
    required String      sellerId,
    required SessionType sessionType,
    required String      date,
  }) async {
    final session = sessionType == SessionType.morning
        ? _morningSession
        : _afternoonSession;
    if (session == null) return false;

    _setLoading(true);
    try {
      // Delete remittance first (FK dependency)
      final remittance = sessionType == SessionType.morning
          ? _morningRemittance
          : _afternoonRemittance;
      if (remittance != null) {
        await _service.deleteRemittance(remittance.id);
      }
      await _service.deleteSession(session.id);

      if (sessionType == SessionType.morning) {
        _morningSession    = null;
        _morningRemittance = null;
      } else {
        _afternoonSession    = null;
        _afternoonRemittance = null;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete session.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes only the remittance record for the given session type.
  Future<bool> deleteRemittance({required RemitType remitType}) async {
    final remittance = remitType == RemitType.morning
        ? _morningRemittance
        : _afternoonRemittance;
    if (remittance == null) return false;

    _setLoading(true);
    try {
      await _service.deleteRemittance(remittance.id);
      if (remitType == RemitType.morning) {
        _morningRemittance = null;
      } else {
        _afternoonRemittance = null;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete remittance.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
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