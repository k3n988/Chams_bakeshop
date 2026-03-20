import 'package:flutter/material.dart';
import '../../../core/models/packer_production_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/packer_service.dart';
import '../../../core/services/database_service.dart';

class PackerProductionViewModel extends ChangeNotifier {
  final PackerService   _service;
  final DatabaseService _db;

  PackerProductionViewModel(this._db) : _service = PackerService();

  // ── State ──────────────────────────────────────────────────
  bool    _isLoading = false;
  String? _error;

  List<PackerProductionModel> _todayProductions       = [];
  List<PackerProductionModel> _selectedDayProductions = [];
  List<PackerProductionModel> _weekProductions        = [];
  List<ProductModel>          _products               = [];

  DateTime _selectedDate = DateTime.now();

  // ── Getters ────────────────────────────────────────────────
  bool    get isLoading => _isLoading;
  String? get error     => _error;

  List<PackerProductionModel> get todayProductions       => _todayProductions;
  List<PackerProductionModel> get selectedDayProductions => _selectedDayProductions;
  List<PackerProductionModel> get weekProductions        => _weekProductions;
  List<ProductModel>          get products               => _products;

  DateTime get selectedDate    => _selectedDate;
  String   get selectedDateStr =>
      '${_selectedDate.year}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  bool get isSelectedDateToday {
    final now = DateTime.now();
    return _selectedDate.year  == now.year &&
           _selectedDate.month == now.month &&
           _selectedDate.day   == now.day;
  }

  // ── Today aggregates ───────────────────────────────────────
  int    get todayTotalBundles =>
      _todayProductions.fold(0, (s, p) => s + p.bundleCount);
  double get todaySalary => todayTotalBundles * 4.0;

  Map<String, int> get todayByProduct {
    final map = <String, int>{};
    for (final p in _todayProductions) {
      map[p.productName] = (map[p.productName] ?? 0) + p.bundleCount;
    }
    return map;
  }

  // ── Selected day aggregates ────────────────────────────────
  int    get selectedDayTotalBundles =>
      _selectedDayProductions.fold(0, (s, p) => s + p.bundleCount);
  double get selectedDaySalary => selectedDayTotalBundles * 4.0;

  Map<String, int> get selectedDayByProduct {
    final map = <String, int>{};
    for (final p in _selectedDayProductions) {
      map[p.productName] = (map[p.productName] ?? 0) + p.bundleCount;
    }
    return map;
  }

  // ── Week aggregates ────────────────────────────────────────
  int    get weekTotalBundles => _weekProductions.fold(0, (s, p) => s + p.bundleCount);
  double get weekGrossSalary  => weekTotalBundles * 4.0;

  // ── Product names list (from admin) ───────────────────────
  List<String> get productNames =>
      _products.map((p) => p.name).toList();

  // ─────────────────────────────────────────────────────────
  //  INIT
  // ─────────────────────────────────────────────────────────
  Future<void> init(String packerId) async {
    _selectedDate = DateTime.now();
    await Future.wait([
      loadProducts(),
      loadTodayProductions(packerId),
      loadWeekProductions(packerId),
    ]);
    // also load selected day (today)
    _selectedDayProductions = List.from(_todayProductions);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD PRODUCTS FROM ADMIN
  // ─────────────────────────────────────────────────────────
  Future<void> loadProducts() async {
    try {
      _products = await _db.getAllProducts();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD TODAY
  // ─────────────────────────────────────────────────────────
  Future<void> loadTodayProductions(String packerId) async {
    _setLoading(true);
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      _todayProductions = await _service.getProductionsByDate(
        packerId: packerId,
        date:     today,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD SELECTED DAY
  // ─────────────────────────────────────────────────────────
  Future<void> loadSelectedDayProductions(String packerId) async {
    _setLoading(true);
    try {
      _selectedDayProductions = await _service.getProductionsByDate(
        packerId: packerId,
        date:     selectedDateStr,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  CHANGE DATE
  // ─────────────────────────────────────────────────────────
  Future<void> changeSelectedDate(DateTime date, String packerId) async {
    _selectedDate = date;
    notifyListeners();
    await loadSelectedDayProductions(packerId);
  }

  // ─────────────────────────────────────────────────────────
  //  LOAD WEEK
  // ─────────────────────────────────────────────────────────
  Future<void> loadWeekProductions(String packerId) async {
    try {
      final now    = DateTime.now();
      final diff   = now.weekday - DateTime.monday;
      final wStart = DateTime(now.year, now.month, now.day - diff);
      final wEnd   = wStart.add(const Duration(days: 6));

      _weekProductions = await _service.getProductionsByWeek(
        packerId:  packerId,
        weekStart: wStart.toIso8601String().substring(0, 10),
        weekEnd:   wEnd.toIso8601String().substring(0, 10),
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  //  ADD PRODUCTION
  // ─────────────────────────────────────────────────────────
  Future<bool> addProduction({
    required String   packerId,
    required String   productName,
    required int      bundleCount,
    required DateTime entryDate,
  }) async {
    _setLoading(true);
    try {
      final dateStr = '${entryDate.year}-'
          '${entryDate.month.toString().padLeft(2, '0')}-'
          '${entryDate.day.toString().padLeft(2, '0')}';
      final now   = DateTime.now();
      final tsStr = '${dateStr}T'
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';

      final result = await _service.addProduction(
        packerId:    packerId,
        date:        dateStr,
        productName: productName,
        bundleCount: bundleCount,
        timestamp:   tsStr,
      );

      if (result != null) {
        await Future.wait([
          loadTodayProductions(packerId),
          loadWeekProductions(packerId),
          loadSelectedDayProductions(packerId),
        ]);
        _error = null;
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
  //  DELETE PRODUCTION
  // ─────────────────────────────────────────────────────────
  Future<bool> deleteProduction(String productionId, String packerId) async {
    _setLoading(true);
    try {
      await _service.deleteProduction(productionId);
      await Future.wait([
        loadTodayProductions(packerId),
        loadWeekProductions(packerId),
        loadSelectedDayProductions(packerId),
      ]);
      _error = null;
      return true;
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