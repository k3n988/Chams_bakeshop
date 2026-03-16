import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/production_model.dart';
import '../models/payroll_model.dart';

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

  Future<List<ProductionModel>> getProductionsByMasterBaker(
      String id) async {
    final rows = await _db
        .from('productions')
        .select()
        .eq('master_baker_id', id)
        .order('date', ascending: false);
    return rows.map(_rowToProduction).toList();
  }

  Future<bool> productionExistsForDate(
      String date, String masterBakerId) async {
    try {
      final rows = await _db
          .from('productions')
          .select('id')
          .gte('date', date)
          .lte('date', '${date}T23:59:59')
          .eq('master_baker_id', masterBakerId);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
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

  Map<String, dynamic> _productionToRow(ProductionModel p) => {
        'id': p.id,
        'date': p.date,
        'master_baker_id': p.masterBakerId,
        'helper_ids': p.helperIds.join(','),
        'items': p.items.map((i) => i.toMap()).toList(),
        'total_value': p.totalValue,
        'total_sacks': p.totalSacks,
        'total_extra_kg': p.totalExtraKg,
        'total_workers': p.totalWorkers,
        'salary_per_worker': p.salaryPerWorker,
        'bonus_per_worker': p.bonusPerWorker,
        'master_bonus': p.bonusPerWorker,
        'baker_incentive': p.bakerIncentive,
      };

  ProductionModel _rowToProduction(Map<String, dynamic> map) {
    final helperStr = (map['helper_ids'] as String? ?? '').trim();
    final rawItems  = map['items'];

    final List<ProductionItem> items;
    if (rawItems is List) {
      items = rawItems
          .map((i) =>
              ProductionItem.fromMap(Map<String, dynamic>.from(i)))
          .toList();
    } else if (rawItems is String && rawItems.isNotEmpty) {
      items = rawItems.split('|').map((s) {
        final p = s.split(':');
        return ProductionItem(
          productId: p[0],
          sacks:     int.tryParse(p[1]) ?? 0,
          extraKg:   p.length > 2 ? (int.tryParse(p[2]) ?? 0) : 0,
        );
      }).toList();
    } else {
      items = [];
    }

    final rawDate = map['date']?.toString() ?? '';
    final date =
        rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    final bonus =
        (map['bonus_per_worker'] ?? map['master_bonus'] ?? 0)
            .toDouble();

    return ProductionModel(
      id:              map['id'],
      date:            date,
      masterBakerId:   map['master_baker_id'],
      helperIds:       helperStr.isEmpty ? [] : helperStr.split(','),
      items:           items,
      totalValue:      (map['total_value'] ?? 0).toDouble(),
      totalSacks:      map['total_sacks'] ?? 0,
      totalExtraKg:    map['total_extra_kg'] ?? 0,
      totalWorkers:    map['total_workers'] ?? 0,
      salaryPerWorker: (map['salary_per_worker'] ?? 0).toDouble(),
      bonusPerWorker:  bonus,
      bakerIncentive:  (map['baker_incentive'] ?? 0).toDouble(),
    );
  }

  // ──────────────────────────────────────────────────
  //  HELPER BATCH OPERATIONS
  // ──────────────────────────────────────────────────

  Future<void> insertHelperBatch(Map<String, dynamic> batch) async {
    await _db.from('helper_batches').insert(batch);
  }

  Future<List<Map<String, dynamic>>> getHelperBatches({
    String? helperId,
    String? dateFrom,
    String? dateTo,
  }) async {
    var query = _db.from('helper_batches').select();
    if (helperId != null) query = query.eq('helper_id', helperId);
    if (dateFrom  != null) query = query.gte('date', dateFrom);
    if (dateTo    != null) query = query.lte('date', dateTo);
    return await query.order('date', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getHelperBatchesByDate(
      String date) async {
    return await _db
        .from('helper_batches')
        .select()
        .eq('date', date)
        .order('created_at', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getHelperBatchesByBaker(
      String masterBakerId) async {
    return await _db
        .from('helper_batches')
        .select()
        .eq('master_baker_id', masterBakerId)
        .order('date', ascending: false);
  }

  Future<void> deleteHelperBatch(String id) async {
    await _db.from('helper_batches').delete().eq('id', id);
  }

  Future<void> updateHelperBatch(
      String id, Map<String, dynamic> fields) async {
    await _db.from('helper_batches').update(fields).eq('id', id);
  }

  // ──────────────────────────────────────────────────
  //  DEDUCTION OPERATIONS
  // ──────────────────────────────────────────────────

  Future<List<DeductionModel>> getAllDeductions() async {
    final rows = await _db
        .from('deductions')
        .select()
        .order('week_start', ascending: false);
    return rows.map((r) => DeductionModel.fromMap(r)).toList();
  }

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

  Future<List<DeductionModel>> getDeductionsForWeek(
      String weekStart) async {
    final rows = await _db
        .from('deductions')
        .select()
        .eq('week_start', weekStart);
    return rows.map((r) => DeductionModel.fromMap(r)).toList();
  }

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

  Future<void> deleteDeduction(String id) async {
    await _db.from('deductions').delete().eq('id', id);
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

  // ──────────────────────────────────────────────────
  //  PAYROLL PAID OPERATIONS
  // ──────────────────────────────────────────────────

  /// Upsert a paid record — safe to call multiple times.
  Future<void> insertPayrollPaid({
    required String id,
    required String userId,
    required String weekStart,
    required String paidBy,
    required double amount,
  }) async {
    await _db.from('payroll_paid').upsert({
      'id':         id,
      'user_id':    userId,
      'week_start': weekStart,
      'paid_by':    paidBy,
      'amount':     amount,
    }, onConflict: 'user_id,week_start');
  }

  /// Returns the set of user IDs paid for [weekStart].
  /// Used by admin payroll screen.
  Future<Set<String>> getPaidUserIds(String weekStart) async {
    final rows = await _db
        .from('payroll_paid')
        .select('user_id')
        .eq('week_start', weekStart);
    return rows
        .map<String>((r) => r['user_id'] as String)
        .toSet();
  }

  /// Returns all week-start dates where [userId] has been paid.
  /// Used by helper dashboard to show Paid/Unpaid badge per record.
  Future<Set<String>> getPaidWeekStartsForUser(String userId) async {
    final rows = await _db
        .from('payroll_paid')
        .select('week_start')
        .eq('user_id', userId);
    return rows
        .map<String>(
            (r) => r['week_start'].toString().substring(0, 10))
        .toSet();
  }

  // ──────────────────────────────────────────────────
  //  CHRISTMAS BONUS OPERATIONS
  // ──────────────────────────────────────────────────

  Future<void> upsertChristmasBonus(
      Map<String, dynamic> bonus) async {
    await _db.from('christmas_bonuses').upsert(
      bonus,
      onConflict: 'user_id,date,production_id',
    );
  }

  Future<List<Map<String, dynamic>>> getChristmasBonuses({
    int? month,
    int? year,
  }) async {
    var query = _db.from('christmas_bonuses').select();
    if (year != null) {
      final y = year.toString();
      final m = month?.toString().padLeft(2, '0');
      if (m != null) {
        query = query
            .gte('date', '$y-$m-01')
            .lte('date', '$y-$m-31');
      } else {
        query = query
            .gte('date', '$y-01-01')
            .lte('date', '$y-12-31');
      }
    }
    return await query.order('date', ascending: false);
  }

  Future<void> deleteChristmasBonus(String id) async {
    await _db.from('christmas_bonuses').delete().eq('id', id);
  }

  Future<void> deleteChristmasBonusesByProduction(
      String productionId) async {
    await _db
        .from('christmas_bonuses')
        .delete()
        .eq('production_id', productionId);
  }
}