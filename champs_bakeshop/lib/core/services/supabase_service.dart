import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/production_model.dart';
import '../models/payroll_model.dart';

// ═══════════════════════════════════════════════════════════════════
//  SUPABASE SERVICE
//  Drop-in replacement for DatabaseService.
//  Same public API — just swap the provider in main.dart.
//
//  Setup:
//   1. Add to pubspec.yaml:  supabase_flutter: ^2.5.0
//   2. In main.dart call:    await Supabase.initialize(url: '...', anonKey: '...');
//   3. Replace DatabaseService() with SupabaseService() in providers.
// ═══════════════════════════════════════════════════════════════════
class SupabaseService {
  SupabaseClient get _db => Supabase.instance.client;

  // ──────────────────────────────────────────────────
  //  USER OPERATIONS
  // ──────────────────────────────────────────────────

  Future<UserModel?> authenticateUser(
      String email, String password, String role) async {
    final row = await _db
        .from('users')
        .select()
        .eq('email', email.trim().toLowerCase())
        .eq('password', password)
        .eq('role', role)
        .maybeSingle();
    return row == null ? null : UserModel.fromMap(row);
  }

  Future<List<UserModel>> getAllUsers() async {
    final rows = await _db.from('users').select().order('name');
    return rows.map((r) => UserModel.fromMap(r)).toList();
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    final rows = await _db
        .from('users')
        .select()
        .eq('role', role)
        .order('name');
    return rows.map((r) => UserModel.fromMap(r)).toList();
  }

  Future<UserModel?> getUserById(String id) async {
    final row = await _db
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : UserModel.fromMap(row);
  }

  Future<void> insertUser(UserModel user) async {
    await _db.from('users').insert(user.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    await _db.from('users').update(user.toMap()).eq('id', user.id);
  }

  Future<void> deleteUser(String id) async {
    await _db.from('users').delete().eq('id', id);
  }

  // ──────────────────────────────────────────────────
  //  PRODUCT OPERATIONS
  // ──────────────────────────────────────────────────

  Future<List<ProductModel>> getAllProducts() async {
    final rows = await _db.from('products').select().order('name');
    return rows.map((r) => ProductModel.fromMap(r)).toList();
  }

  Future<void> insertProduct(ProductModel product) async {
    await _db.from('products').insert(product.toMap());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _db
        .from('products')
        .update(product.toMap())
        .eq('id', product.id);
  }

  Future<void> deleteProduct(String id) async {
    await _db.from('products').delete().eq('id', id);
  }

  // ──────────────────────────────────────────────────
  //  PRODUCTION OPERATIONS
  // ──────────────────────────────────────────────────

  Future<List<ProductionModel>> getAllProductions() async {
    final rows = await _db
        .from('productions')
        .select()
        .order('date', ascending: false);
    return rows.map(_rowToProduction).toList();
  }

  Future<List<ProductionModel>> getProductionsByDateRange(
      String start, String end) async {
    final rows = await _db
        .from('productions')
        .select()
        .gte('date', start)
        .lte('date', end)
        .order('date');
    return rows.map(_rowToProduction).toList();
  }

  Future<List<ProductionModel>> getProductionsByMasterBaker(String id) async {
    final rows = await _db
        .from('productions')
        .select()
        .eq('master_baker_id', id)
        .order('date', ascending: false);
    return rows.map(_rowToProduction).toList();
  }

  Future<bool> productionExistsForDate(
      String date, String masterBakerId) async {
    final row = await _db
        .from('productions')
        .select('id')
        .eq('date', date)
        .eq('master_baker_id', masterBakerId)
        .maybeSingle();
    return row != null;
  }

  Future<void> insertProduction(ProductionModel production) async {
    await _db.from('productions').insert(_productionToRow(production));
  }

  Future<void> updateProduction(ProductionModel production) async {
    await _db
        .from('productions')
        .update(_productionToRow(production))
        .eq('id', production.id);
  }

  Future<void> deleteProduction(String id) async {
    await _db.from('productions').delete().eq('id', id);
  }

  // ── ProductionModel ↔ Supabase row conversion ──────────

  Map<String, dynamic> _productionToRow(ProductionModel p) => {
        'id': p.id,
        'date': p.date,
        'master_baker_id': p.masterBakerId,
        'helper_ids': p.helperIds.join(','),
        'items': p.items.map((i) => i.toMap()).toList(),
      };

  ProductionModel _rowToProduction(Map<String, dynamic> map) {
    final helperStr = (map['helper_ids'] as String? ?? '').trim();
    final rawItems = map['items'];

    final List<ProductionItem> items;
    if (rawItems is List) {
      // Proper JSONB from Supabase
      items = rawItems
          .map((i) => ProductionItem.fromMap(Map<String, dynamic>.from(i)))
          .toList();
    } else if (rawItems is String && rawItems.isNotEmpty) {
      // Legacy pipe-delimited fallback (SQLite migration)
      items = rawItems.split('|').map((s) {
        final p = s.split(':');
        return ProductionItem(
          productId: p[0],
          sacks: int.tryParse(p[1]) ?? 0,
          cat60: p.length > 2 ? int.tryParse(p[2]) : null,
          cat36: p.length > 3 ? int.tryParse(p[3]) : null,
          cat48: p.length > 4 ? int.tryParse(p[4]) : null,
          subra: p.length > 5 ? int.tryParse(p[5]) : null,
          saka:  p.length > 6 ? int.tryParse(p[6]) : null,
        );
      }).toList();
    } else {
      items = [];
    }

    // Supabase returns dates as "2026-03-01T00:00:00" — keep only YYYY-MM-DD
    final rawDate = map['date']?.toString() ?? '';
    final date = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

    return ProductionModel(
      id: map['id'],
      date: date,
      masterBakerId: map['master_baker_id'],
      helperIds: helperStr.isEmpty ? [] : helperStr.split(','),
      items: items,
    );
  }

  // ──────────────────────────────────────────────────
  //  DEDUCTION OPERATIONS
  // ──────────────────────────────────────────────────

  Future<DeductionModel?> getDeduction(
      String userId, String weekStart) async {
    final row = await _db
        .from('deductions')
        .select()
        .eq('user_id', userId)
        .eq('week_start', weekStart)
        .maybeSingle();
    return row == null ? null : DeductionModel.fromMap(row);
  }

  Future<List<DeductionModel>> getDeductionsForWeek(String weekStart) async {
    final rows = await _db
        .from('deductions')
        .select()
        .eq('week_start', weekStart);
    return rows.map((r) => DeductionModel.fromMap(r)).toList();
  }

  /// All deductions for one user — used by monthly summary to avoid
  /// N+1 queries (one DB call for all weeks in the month).
  Future<List<DeductionModel>> getUserDeductions(String userId) async {
    final rows = await _db
        .from('deductions')
        .select()
        .eq('user_id', userId)
        .order('week_start');
    return rows.map((r) => DeductionModel.fromMap(r)).toList();
  }

  Future<void> upsertDeduction(DeductionModel deduction) async {
    await _db.from('deductions').upsert(
      deduction.toMap(),
      onConflict: 'user_id,week_start',
    );
  }

  // ──────────────────────────────────────────────────
  //  PAYROLL RELEASE OPERATIONS
  // ──────────────────────────────────────────────────

  Future<bool> isWeekReleased(String weekStart) async {
    final row = await _db
        .from('payroll_releases')
        .select('id')
        .eq('week_start', weekStart)
        .maybeSingle();
    return row != null;
  }

  Future<void> releaseWeeklyPayroll({
    required String id,
    required String weekStart,
    required String releasedBy,
    String? notes,
  }) async {
    await _db.from('payroll_releases').upsert({
      'id': id,
      'week_start': weekStart,
      'released_by': releasedBy,
      'notes': notes,
    }, onConflict: 'week_start');
  }

  Future<List<Map<String, dynamic>>> getAllPayrollReleases() async {
    return await _db
        .from('payroll_releases')
        .select()
        .order('week_start', ascending: false);
  }
}