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
    _productions = await _db.getProductionsByMasterBaker(masterBakerId);
    _products = await _db.getAllProducts();
    _helpers = await _db.getUsersByRole('helper');
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

      final production = ProductionModel(
        id: generateId('prod'),
        date: date,
        masterBakerId: masterBakerId,
        helperIds: helperIds,
        items: items,
      );
      await _db.insertProduction(production);
      await loadData(masterBakerId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Preview computation for the production input form
  DailySalaryResult previewSalary(
      List<ProductionItem> items, int helperCount) {
    double totalValue = 0;
    int totalSacks = 0;
    for (final item in items) {
      final product = _products.where((p) => p.id == item.productId).firstOrNull;
      if (product != null) {
        totalValue += product.pricePerSack * item.sacks;
        totalSacks += item.sacks;
      }
    }
    final totalWorkers = 1 + helperCount;
    final salaryPerWorker = totalWorkers > 0 ? totalValue / totalWorkers : 0.0;
    final masterBonus = totalSacks * 100.0;

    return DailySalaryResult(
      totalValue: totalValue,
      totalSacks: totalSacks,
      totalWorkers: totalWorkers,
      salaryPerWorker: salaryPerWorker,
      masterBonus: masterBonus,
    );
  }
}
