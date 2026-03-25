// lib/features/admin/viewmodel/admin_batch_viewmodel.dart

import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';

class AdminBatchViewModel extends ChangeNotifier {
  final DatabaseService _db;

  AdminBatchViewModel(this._db);

  // ── State ─────────────────────────────────────────────────
  bool    isLoadingLookup  = false;
  bool    isLoadingDaily   = false;
  bool    isLoadingWeekly  = false;
  String? errorMessage;

  // Daily — always starts at today
  DateTime selectedDate = _today();
  List<Map<String, dynamic>> dailyBatches = [];

  // Weekly — always starts at the current Mon–Sun
  DateTime _weekStart = _mondayOf(_today());
  List<Map<String, dynamic>> weeklyBatches = [];

  // Lookup maps
  Map<String, String> _userNames    = {};
  Map<String, String> _productNames = {};

  // ── Computed ──────────────────────────────────────────────
  DateTime get today     => _today();
  DateTime get weekStart => _weekStart;
  DateTime get weekEnd   => _weekStart.add(const Duration(days: 6));

  String get formattedSelectedDate => _dateStr(selectedDate);
  String get formattedWeekRange    => '${_fmt(_weekStart)} – ${_fmt(weekEnd)}';

  String helperName(String id)  => _userNames[id]    ?? id;
  String bakerName(String id)   => _userNames[id]    ?? id;
  String productName(String id) => _productNames[id] ?? id;

  // Weekly totals
  int get weeklyTotalBatches => weeklyBatches.length;
  int get weeklyTotalSacks =>
      weeklyBatches.fold(0, (s, b) => s + ((b['saka'] as int?) ?? 0));

  // ── Init ──────────────────────────────────────────────────
  Future<void> init() async {
    isLoadingLookup = true;
    notifyListeners();
    try {
      final users    = await _db.getAllUsers();
      final products = await _db.getAllProducts();
      _userNames    = {for (final u in users)    u.id: u.name};
      _productNames = {for (final p in products) p.id: p.name};
    } catch (e) {
      errorMessage = 'Failed to load lookup data: $e';
    } finally {
      isLoadingLookup = false;
      notifyListeners();
    }
    await Future.wait([loadDaily(), loadWeekly()]);
  }

  // ── Daily ─────────────────────────────────────────────────
  Future<void> loadDaily() async {
    isLoadingDaily = true;
    notifyListeners();
    try {
      dailyBatches = await _db.getHelperBatchesByDate(formattedSelectedDate);
    } catch (e) {
      errorMessage = 'Error loading daily batches: $e';
      dailyBatches = [];
    } finally {
      isLoadingDaily = false;
      notifyListeners();
    }
  }

  Future<void> setDate(DateTime date) async {
    selectedDate = _stripTime(date);
    await loadDaily();
  }

  // ── Weekly ────────────────────────────────────────────────
  Future<void> loadWeekly() async {
    isLoadingWeekly = true;
    notifyListeners();
    try {
      final from = _dateStr(_weekStart);
      final to   = _dateStr(weekEnd);
      weeklyBatches =
          await _db.getHelperBatches(dateFrom: from, dateTo: to);
    } catch (e) {
      errorMessage = 'Error loading weekly batches: $e';
      weeklyBatches = [];
    } finally {
      isLoadingWeekly = false;
      notifyListeners();
    }
  }

  bool get isCurrentWeek =>
      _weekStart == _mondayOf(_today());

  void prevWeek() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    loadWeekly();
  }

  void nextWeek() {
    if (isCurrentWeek) return;
    _weekStart = _weekStart.add(const Duration(days: 7));
    loadWeekly();
  }

  // ── Helpers ───────────────────────────────────────────────
  static DateTime _today() => _stripTime(DateTime.now());

  static DateTime _stripTime(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  static String _dateStr(DateTime d) =>
      '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _fmt(DateTime d) =>
      '${_monthAbbr(d.month)} ${d.day}';

  static String _monthAbbr(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];

  String categorySummary(Map<String, dynamic> row) {
    final parts = <String>[
      if ((row['cat60'] ?? 0) > 0) '60: ${row['cat60']}',
      if ((row['cat36'] ?? 0) > 0) '36: ${row['cat36']}',
      if ((row['cat48'] ?? 0) > 0) '48: ${row['cat48']}',
      if ((row['subra'] ?? 0) > 0) 'Subra: ${row['subra']}',
      if ((row['saka']  ?? 0) > 0) 'Saka: ${row['saka']}',
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}
