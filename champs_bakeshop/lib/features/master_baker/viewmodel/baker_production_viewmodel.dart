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
  final PayrollService  _payroll;

  BakerProductionViewModel(this._db, this._payroll);

  List<ProductionModel> _productions = [];
  List<ProductModel>    _products    = [];
  List<UserModel>       _helpers     = [];
  bool                  _isLoading   = false;

  List<ProductionModel> get productions => _productions;
  List<ProductModel>    get products    => _products;
  List<UserModel>       get helpers     => _helpers;
  bool                  get isLoading   => _isLoading;

  Future<void> loadData(String masterBakerId) async {
    _isLoading = true;
    notifyListeners();

    try {
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
      ]).timeout(const Duration(seconds: 15));
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteProduction(String productionId, String masterBakerId) async {
    try {
      await _db.deleteChristmasBonusesByProduction(productionId);
      await _db.deleteProduction(productionId);
      _productions.removeWhere((p) => p.id == productionId);
      notifyListeners();
      await loadData(masterBakerId);
      return true;
    } catch (_) {
      return false;
    }
  }

  DailySalaryResult computeDaily(ProductionModel production) =>
      _payroll.computeDaily(production, _products);

  DailySalaryResult previewSalary(
      List<ProductionItem> items, int helperCount) {
    double totalValue          = 0;
    double totalBonusAmount    = 0;
    double totalEffectiveSacks = 0;
    int    totalSacks          = 0;
    int    totalExtraKg        = 0;

    for (final item in items) {
      final product =
          _products.where((p) => p.id == item.productId).firstOrNull;
      if (product != null) {
        final eff = item.effectiveSacks;
        totalValue          += product.pricePerSack * eff;
        totalBonusAmount    += product.bonusPerSack * eff;
        totalEffectiveSacks += eff;
        totalSacks          += item.sacks;
        totalExtraKg        += item.extraKg;
      }
    }

    final totalWorkers    = 1 + helperCount;
    final salaryPerWorker =
        totalWorkers > 0 ? totalValue / totalWorkers : 0.0;
    final bonusPerWorker =
        totalWorkers > 0 ? totalBonusAmount / totalWorkers : 0.0;
    final bakerIncentive =
        totalEffectiveSacks * PayrollService.incentivePerSack;

    return DailySalaryResult(
      totalValue:      totalValue,
      totalSacks:      totalSacks,
      totalExtraKg:    totalExtraKg,
      totalWorkers:    totalWorkers,
      salaryPerWorker: salaryPerWorker,
      bonusPerWorker:  bonusPerWorker,
      bakerIncentive:  bakerIncentive,
    );
  }

  Future<bool?> addProduction({
    required String               date,
    required String               masterBakerId,
    required List<String>         helperIds,
    required List<ProductionItem> items,
    String?                       ovenHelperId,
  }) async {
    try {
      final exists =
          await _db.productionExistsForDate(date, masterBakerId);
      if (exists) return false;

      final computed = previewSalary(items, helperIds.length);
      final productionId = generateId('prod');

      final production = ProductionModel(
        id:              productionId,
        date:            date,
        masterBakerId:   masterBakerId,
        helperIds:       helperIds,
        items:           items,
        ovenHelperId:    ovenHelperId,
        totalValue:      computed.totalValue,
        totalSacks:      computed.totalSacks,
        totalExtraKg:    computed.totalExtraKg,
        totalWorkers:    computed.totalWorkers,
        salaryPerWorker: computed.salaryPerWorker,
        bonusPerWorker:  computed.bonusPerWorker,
        bakerIncentive:  computed.bakerIncentive,
      );

      await _db.insertProduction(production);

      // ✅ Auto-save bonus for each worker into christmas_bonuses
      if (computed.bonusPerWorker > 0) {
        final allWorkerIds = [masterBakerId, ...helperIds];

        // Get user info for names and roles
        final allUsers = await _db.getAllUsers();
        final userMap = {for (final u in allUsers) u.id: u};

        for (final workerId in allWorkerIds) {
          final user = userMap[workerId];
          if (user == null) continue;

          await _db.upsertChristmasBonus({
            'id':            generateId('bonus'),
            'user_id':       workerId,
            'user_name':     user.name,
            'role':          user.role,
            'date':          date,
            'amount':        computed.bonusPerWorker,
            'note':          'Production bonus',
            'production_id': productionId,
          });
        }
      }

      await loadData(masterBakerId);
      return true;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProduction(ProductionModel updated) async {
    try {
      final recomputed =
          previewSalary(updated.items, updated.helperIds.length);

      final refreshed = updated.copyWith(
        totalValue:      recomputed.totalValue,
        totalSacks:      recomputed.totalSacks,
        totalExtraKg:    recomputed.totalExtraKg,
        totalWorkers:    recomputed.totalWorkers,
        salaryPerWorker: recomputed.salaryPerWorker,
        bonusPerWorker:  recomputed.bonusPerWorker,
        bakerIncentive:  recomputed.bakerIncentive,
      );

      await _db.updateProduction(refreshed);

      // ✅ Re-sync bonus entries when production is updated
      await _db.deleteChristmasBonusesByProduction(updated.id);

      if (recomputed.bonusPerWorker > 0) {
        final allWorkerIds = [
          updated.masterBakerId,
          ...updated.helperIds
        ];
        final allUsers = await _db.getAllUsers();
        final userMap  = {for (final u in allUsers) u.id: u};

        for (final workerId in allWorkerIds) {
          final user = userMap[workerId];
          if (user == null) continue;

          await _db.upsertChristmasBonus({
            'id':            generateId('bonus'),
            'user_id':       workerId,
            'user_name':     user.name,
            'role':          user.role,
            'date':          updated.date,
            'amount':        recomputed.bonusPerWorker,
            'note':          'Production bonus',
            'production_id': updated.id,
          });
        }
      }

      final idx =
          _productions.indexWhere((p) => p.id == refreshed.id);
      if (idx != -1) {
        _productions[idx] = refreshed;
        notifyListeners();
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}