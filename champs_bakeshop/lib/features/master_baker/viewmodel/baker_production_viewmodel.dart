import 'package:flutter/material.dart';
import '../../../../core/models/production_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/models/payroll_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../../core/utils/helpers.dart';

class BakerProductionViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final PayrollService _payroll;

  List<ProductionModel> _productions = [];
  List<ProductModel> _products = [];
  List<UserModel> _helpers = [];
  bool _isLoading = false;
  String? _lastMasterBakerId;

  BakerProductionViewModel(this._db, this._payroll);

  List<ProductionModel> get productions => _productions;
  List<ProductModel> get products => _products;
  List<UserModel> get helpers => _helpers;
  bool get isLoading => _isLoading;

  Future<void> loadData(String masterBakerId) async {
    _isLoading = true;
    _lastMasterBakerId = masterBakerId;
    notifyListeners();

    // Run independently so one failing table doesn't block the others
    await Future.wait([
      _db.getProductionsByMasterBaker(masterBakerId)
          .then((v) => _productions = v)
          .catchError((_) => _productions = []),
      _db.getAllProducts()
          .then((v) => _products = v)
          .catchError((_) => _products = []),
      _db.getUsersByRole('helper')
          .then((v) => _helpers = v)
          .catchError((_) => _helpers = []),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  DailySalaryResult computeDaily(ProductionModel production) =>
      _payroll.computeDaily(production, _products);

  Future<bool> addProduction({
    required String date,
    required String masterBakerId,
    required List<String> helperIds,
    required List<ProductionItem> items,
  }) async {
    try {
      final exists = await _db.productionExistsForDate(date, masterBakerId);
      if (exists) return false;

      final computedSalary = previewSalary(items, helperIds.length);

      final production = ProductionModel(
        id: generateId('prod'),
        date: date,
        masterBakerId: masterBakerId,
        helperIds: helperIds,
        items: items,
        totalValue: computedSalary.totalValue,
        totalSacks: computedSalary.totalSacks,
        totalWorkers: computedSalary.totalWorkers,
        salaryPerWorker: computedSalary.salaryPerWorker,
        masterBonus: computedSalary.masterBonus,
      );

      await _db.insertProduction(production);
      await loadData(masterBakerId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Recomputes salary from updated items, persists to DB, refreshes local list.
  Future<bool> updateProduction(ProductionModel updated) async {
    try {
      // Recompute all salary fields so stored values stay consistent with items
      final recomputed = previewSalary(updated.items, updated.helperIds.length);

      final refreshed = updated.copyWith(
        totalValue: recomputed.totalValue,
        totalSacks: recomputed.totalSacks,
        totalWorkers: recomputed.totalWorkers,
        salaryPerWorker: recomputed.salaryPerWorker,
        masterBonus: recomputed.masterBonus,
      );

      await _db.updateProduction(refreshed);

      // Swap in-memory entry immediately — no full reload needed
      final index = _productions.indexWhere((p) => p.id == refreshed.id);
      if (index != -1) {
        _productions[index] = refreshed;
        notifyListeners();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Preview salary using bonusPerSack from each ProductModel — aligned with PayrollService
  DailySalaryResult previewSalary(List<ProductionItem> items, int helperCount) {
    double totalValue = 0;
    double totalBonus = 0;
    int totalSacks = 0;

    for (final item in items) {
      final product = _products.where((p) => p.id == item.productId).firstOrNull;
      if (product != null) {
        totalValue += product.pricePerSack * item.sacks;
        totalBonus += product.bonusPerSack * item.sacks;
        totalSacks += item.sacks;
      }
    }

    final totalWorkers = 1 + helperCount;
    final salaryPerWorker = totalWorkers > 0 ? totalValue / totalWorkers : 0.0;

    return DailySalaryResult(
      totalValue: totalValue,
      totalSacks: totalSacks,
      totalWorkers: totalWorkers,
      salaryPerWorker: salaryPerWorker,
      masterBonus: totalBonus,
    );
  }
}