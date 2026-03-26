import 'package:flutter/material.dart';
import '../../../../core/models/production_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/models/payroll_model.dart';
import '../../../../core/models/packer_production_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../../core/services/packer_service.dart';

class AdminProductionViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final PayrollService  _payroll;
  final PackerService   _packer = PackerService();

  List<ProductionModel>        _productions            = [];
  List<PackerProductionModel>  _todayPackerProductions = [];
  bool _isLoading = false;

  AdminProductionViewModel(this._db, this._payroll);

  List<ProductionModel> get productions => _productions;
  bool get isLoading => _isLoading;

  /// Bundles packed this week, summed per product across all packers.
  Map<String, int> get weekPackedByProduct {
    final map = <String, int>{};
    for (final p in _todayPackerProductions) {
      map[p.productName] = (map[p.productName] ?? 0) + p.bundleCount;
    }
    return map;
  }

  int get weekTotalBundles =>
      _todayPackerProductions.fold(0, (s, p) => s + p.bundleCount);

  // ── Today's data (derived from weekly load) ───────────────
  Map<String, int> get todayPackedByProduct {
    final today = _fmtDate(DateTime.now());
    final map = <String, int>{};
    for (final p in _todayPackerProductions.where((p) => p.date == today)) {
      map[p.productName] = (map[p.productName] ?? 0) + p.bundleCount;
    }
    return map;
  }

  int get todayTotalBundles {
    final today = _fmtDate(DateTime.now());
    return _todayPackerProductions
        .where((p) => p.date == today)
        .fold(0, (s, p) => s + p.bundleCount);
  }

  // Top packer this week: returns MapEntry(packerId, bundleCount) or null
  MapEntry<String, int>? get topPackerEntry {
    final map = <String, int>{};
    for (final p in _todayPackerProductions) {
      map[p.packerId] = (map[p.packerId] ?? 0) + p.bundleCount;
    }
    if (map.isEmpty) return null;
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadAllProductions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final now = DateTime.now();
      final mon = now.subtract(Duration(days: now.weekday - 1));
      final sun = mon.add(const Duration(days: 6));
      String dateStr(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      _productions = await _db.getAllProductions();
      _todayPackerProductions =
          await _packer.getAllPackerProductionsByWeek(
        weekStart: dateStr(mon),
        weekEnd:   dateStr(sun),
      );
    } catch (_) {
      // keep existing data on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DailySalaryResult computeDaily(
          ProductionModel production, List<ProductModel> products) =>
      _payroll.computeDaily(production, products);
}
