import 'package:flutter/material.dart';
import '../../../../core/models/production_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/models/payroll_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/payroll_service.dart';

class AdminProductionViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final PayrollService _payroll;

  List<ProductionModel> _productions = [];
  bool _isLoading = false;

  AdminProductionViewModel(this._db, this._payroll);

  List<ProductionModel> get productions => _productions;
  bool get isLoading => _isLoading;

  Future<void> loadAllProductions() async {
    _isLoading = true;
    notifyListeners();
    _productions = await _db.getAllProductions();
    _isLoading = false;
    notifyListeners();
  }

  DailySalaryResult computeDaily(
          ProductionModel production, List<ProductModel> products) =>
      _payroll.computeDaily(production, products);
}
