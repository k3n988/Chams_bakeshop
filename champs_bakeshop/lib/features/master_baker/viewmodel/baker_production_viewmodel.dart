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

  BakerProductionViewModel(this._db, this._payroll);

  List<ProductionModel> get productions => _productions;
  List<ProductModel> get products => _products;
  List<UserModel> get helpers => _helpers;
  bool get isLoading => _isLoading;

  Future<void> loadData(String masterBakerId) async {
    _isLoading = true;
    notifyListeners();

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

  // ── Add ──────────────────────────────────────────────────────────────────

  /// Returns:
  ///  true  — saved successfully
  ///  false — production already exists for this date
  ///  null  — unexpected error (DB / network)
  Future<bool?> addProduction({
    required String date,
    required String masterBakerId,
    required List<String> helperIds,
    required List<ProductionItem> items,
  }) async {
    try {
      final exists = await _db.productionExistsForDate(date, masterBakerId);
      if (exists) return false; // already exists

      final computed = previewSalary(items, helperIds.length);

      final production = ProductionModel(
        id: generateId('prod'),
        date: date,
        masterBakerId: masterBakerId,
        helperIds: helperIds,
        items: items,
        totalValue: computed.totalValue,
        totalSacks: computed.totalSacks,
        totalExtraKg: computed.totalExtraKg,
        totalWorkers: computed.totalWorkers,
        salaryPerWorker: computed.salaryPerWorker,
        bonusPerWorker: computed.bonusPerWorker,
        bakerIncentive: computed.bakerIncentive,
      );

      await _db.insertProduction(production);
      await loadData(masterBakerId);
      return true;
    } catch (e) {
      return null; // unexpected error — distinguishable from "already exists"
    }
  }

  // ── Update ───────────────────────────────────────────────────────────────

  Future<bool> updateProduction(ProductionModel updated) async {
    try {
      final recomputed =
          previewSalary(updated.items, updated.helperIds.length);

      final refreshed = updated.copyWith(
        totalValue: recomputed.totalValue,
        totalSacks: recomputed.totalSacks,
        totalExtraKg: recomputed.totalExtraKg,
        totalWorkers: recomputed.totalWorkers,
        salaryPerWorker: recomputed.salaryPerWorker,
        bonusPerWorker: recomputed.bonusPerWorker,
        bakerIncentive: recomputed.bakerIncentive,
      );

      await _db.updateProduction(refreshed);

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

  // ── Preview ───────────────────────────────────────────────────────────────

  /// • effectiveSacks    = sacks + extraKg / 25.0
  /// • salaryPerWorker   = totalValue / totalWorkers  (base only)
  /// • bonusPerWorker    = Σ(bonusPerSack × eff) / totalWorkers (all, separate)
  /// • bakerIncentive    = totalEffectiveSacks × ₱100 (baker only, in salary)
  DailySalaryResult previewSalary(
      List<ProductionItem> items, int helperCount) {
    double totalValue = 0;
    double totalBonusAmount = 0;
    double totalEffectiveSacks = 0;
    int totalSacks = 0;
    int totalExtraKg = 0;

    for (final item in items) {
      final product =
          _products.where((p) => p.id == item.productId).firstOrNull;
      if (product != null) {
        final effective = item.effectiveSacks;
        totalValue += product.pricePerSack * effective;
        totalBonusAmount += product.bonusPerSack * effective;
        totalEffectiveSacks += effective;
        totalSacks += item.sacks;
        totalExtraKg += item.extraKg;
      }
    }

    final totalWorkers = 1 + helperCount;
    final salaryPerWorker =
        totalWorkers > 0 ? totalValue / totalWorkers : 0.0;
    final bonusPerWorker =
        totalWorkers > 0 ? totalBonusAmount / totalWorkers : 0.0;
    final bakerIncentive =
        totalEffectiveSacks * PayrollService.incentivePerSack;

    return DailySalaryResult(
      totalValue: totalValue,
      totalSacks: totalSacks,
      totalExtraKg: totalExtraKg,
      totalWorkers: totalWorkers,
      salaryPerWorker: salaryPerWorker,
      bonusPerWorker: bonusPerWorker,
      bakerIncentive: bakerIncentive,
    );
  }
}