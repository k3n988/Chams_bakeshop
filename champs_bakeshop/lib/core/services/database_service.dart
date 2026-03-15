import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/production_model.dart';
import '../models/payroll_model.dart';
import 'supabase_service.dart';

class DatabaseService {
  final SupabaseService _supa;
  SupabaseService get supa => _supa;
  DatabaseService(this._supa);

  // ─── USERS ────────────────────────────────────────────────────────────────

  Future<List<UserModel>> getAllUsers() => _supa.getAllUsers();
  Future<List<UserModel>> getUsersByRole(String role) => _supa.getUsersByRole(role);
  Future<UserModel?> getUserById(String id) => _supa.getUserById(id);
  Future<UserModel?> authenticateUser(String email, String password, String role) =>
      _supa.authenticateUser(email, password, role);

  Future<UserModel?> getUserByEmail(String email) async {
    final all = await _supa.getAllUsers();
    return all
        .where((u) => u.email == email.trim().toLowerCase())
        .firstOrNull;
  }

  Future<void> insertUser(UserModel user) => _supa.insertUser(user);
  Future<void> updateUser(UserModel user) => _supa.updateUser(user);
  Future<void> deleteUser(String id) => _supa.deleteUser(id);

  // ─── PRODUCTS ─────────────────────────────────────────────────────────────

  Future<List<ProductModel>> getAllProducts() => _supa.getAllProducts();
  Future<void> insertProduct(ProductModel product) => _supa.insertProduct(product);
  Future<void> updateProduct(ProductModel product) => _supa.updateProduct(product);
  Future<void> deleteProduct(String id) => _supa.deleteProduct(id);

  // ─── PRODUCTION ───────────────────────────────────────────────────────────

  Future<List<ProductionModel>> getAllProductions() => _supa.getAllProductions();
  Future<List<ProductionModel>> getProductionsByDateRange(String start, String end) =>
      _supa.getProductionsByDateRange(start, end);
  Future<List<ProductionModel>> getProductionsByMasterBaker(String id) =>
      _supa.getProductionsByMasterBaker(id);
  Future<bool> productionExistsForDate(String date, String masterBakerId) =>
      _supa.productionExistsForDate(date, masterBakerId);
  Future<void> insertProduction(ProductionModel production) =>
      _supa.insertProduction(production);
  Future<void> updateProduction(ProductionModel production) =>
      _supa.updateProduction(production);
  Future<void> deleteProduction(String id) => _supa.deleteProduction(id);

  // ─── HELPER BATCHES ───────────────────────────────────────────────────────

  Future<void> insertHelperBatch(Map<String, dynamic> batch) =>
      _supa.insertHelperBatch(batch);

  Future<List<Map<String, dynamic>>> getHelperBatches(String helperId) =>
      _supa.getHelperBatches(helperId);

  Future<List<Map<String, dynamic>>> getHelperBatchesByDateRange(
    String helperId,
    String start,
    String end,
  ) =>
      _supa.getHelperBatchesByDateRange(helperId, start, end);

  Future<void> deleteHelperBatch(String id) => _supa.deleteHelperBatch(id);

  // ─── DEDUCTIONS ───────────────────────────────────────────────────────────

  Future<List<DeductionModel>> getAllDeductions() => _supa.getAllDeductions();
  Future<DeductionModel?> getDeductionForUser(String userId, String weekStart) =>
      _supa.getDeduction(userId, weekStart);
  Future<List<DeductionModel>> getDeductionsForWeek(String weekStart) =>
      _supa.getDeductionsForWeek(weekStart);
  Future<List<DeductionModel>> getUserDeductions(String userId) =>
      _supa.getUserDeductions(userId);

  Future<void> upsertDeduction(DeductionModel d) => _supa.upsertDeduction(d);
  Future<void> insertDeduction(DeductionModel d) => _supa.upsertDeduction(d);
  Future<void> updateDeduction(DeductionModel d) => _supa.upsertDeduction(d);
  Future<void> deleteDeduction(String id) => _supa.deleteDeduction(id);

  // ─── PAYROLL RELEASES ─────────────────────────────────────────────────────

  Future<bool> isWeekReleased(String weekStart) => _supa.isWeekReleased(weekStart);
  Future<void> releaseWeeklyPayroll({
    required String id,
    required String weekStart,
    required String releasedBy,
    String? notes,
  }) =>
      _supa.releaseWeeklyPayroll(
        id: id,
        weekStart: weekStart,
        releasedBy: releasedBy,
        notes: notes,
      );
}