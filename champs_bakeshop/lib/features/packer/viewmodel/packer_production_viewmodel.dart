import 'package:flutter/material.dart';
import '../../../core/models/packer_production_model.dart';
import '../../../core/services/packer_service.dart';

class PackerProductionViewModel extends ChangeNotifier {
  final _service = PackerService();

  // ── State ──────────────────────────────────────────────────
  bool    _isLoading = false;
  String? _error;

  List<PackerProductionModel> _todayProductions = [];
  List<PackerProductionModel> _weekProductions  = [];

  // ── Getters ────────────────────────────────────────────────
  bool    get isLoading        => _isLoading;
  String? get error            => _error;

  List<PackerProductionModel> get todayProductions => _todayProductions;
  List<PackerProductionModel> get weekProductions  => _weekProductions;

  // ── Today aggregates ───────────────────────────────────────
  int get todayTotalBundles =>
      _todayProductions.fold(0, (s, p) => s + p.bundleCount);

  double get todaySalary => todayTotalBundles * 4.0;

  // ── Group today by product ─────────────────────────────────
  Map<String, int> get todayByProduct {
    final map = <String, int>{};
    for (final p in _todayProductions) {
      map[p.productName] = (map[p.productName] ?? 0) + p.bundleCount;
    }
    return map;
  }

  // ── Week aggregates ────────────────────────────────────────
  int get weekTotalBundles =>
      _weekProductions.fold(0, (s, p) => s + p.bundleCount);

  double get weekGrossSalary => weekTotalBundles * 4.0;

  // ─────────────────────────────────────────────────────────
  //  INIT
  // ─────────────────────────────────────────────────────────
  Future<void> init(String packerId) async {
    await Future.wait([
      loadTodayProductions(packerId),
      loadWeekProductions(packerId),
    ]);
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
  //  LOAD WEEK
  // ─────────────────────────────────────────────────────────
  Future<void> loadWeekProductions(String packerId) async {
    try {
      final now   = DateTime.now();
      final diff  = now.weekday - DateTime.monday;
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
    required String packerId,
    required String productName,
    required int    bundleCount,
  }) async {
    _setLoading(true);
    try {
      final now   = DateTime.now();
      final date  = now.toIso8601String().substring(0, 10);
      final tsStr = now.toIso8601String();

      final result = await _service.addProduction(
        packerId:    packerId,
        date:        date,
        productName: productName,
        bundleCount: bundleCount,
        timestamp:   tsStr,
      );

      if (result != null) {
        await init(packerId);
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
      await init(packerId);
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