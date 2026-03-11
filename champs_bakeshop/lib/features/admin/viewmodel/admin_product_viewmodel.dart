import 'package:flutter/material.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/utils/helpers.dart';

class AdminProductViewModel extends ChangeNotifier {
  final DatabaseService _db;

  List<ProductModel> _products = [];
  bool _isLoading = false;

  AdminProductViewModel(this._db);

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  ProductModel? getById(String id) =>
      _products.where((p) => p.id == id).firstOrNull;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await _db.getAllProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProduct({required String name, required double pricePerSack}) async {
    try {
      final product = ProductModel(
        id: generateId('p'),
        name: name.trim(),
        pricePerSack: pricePerSack,
      );
      await _db.insertProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _db.updateProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _db.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (e) {
      return false;
    }
  }
}
