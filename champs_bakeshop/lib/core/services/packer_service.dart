import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/packer_production_model.dart';
import '../models/packer_payroll_model.dart';

class PackerService {
  final _db = Supabase.instance.client;

  // ── Table names ────────────────────────────────────────────
  static const _productionTable = 'packer_productions';
  static const _payrollTable    = 'packer_payrolls';

  // ════════════════════════════════════════════════════════════
  //  PRODUCTION
  // ════════════════════════════════════════════════════════════

  /// Add a new packer production entry
  Future<PackerProductionModel?> addProduction({
    required String packerId,
    required String date,
    required String productName,
    required int    bundleCount,
    required String timestamp,
  }) async {
    try {
      final data = await _db
          .from(_productionTable)
          .insert({
            'packer_id':    packerId,
            'date':         date,
            'product_name': productName,
            'bundle_count': bundleCount,
            'timestamp':    timestamp,
          })
          .select()
          .single();

      return PackerProductionModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to add production: $e');
    }
  }

  /// Fetch all productions for a packer on a specific date
  Future<List<PackerProductionModel>> getProductionsByDate({
    required String packerId,
    required String date,
  }) async {
    try {
      final data = await _db
          .from(_productionTable)
          .select()
          .eq('packer_id', packerId)
          .eq('date', date)
          .order('timestamp', ascending: true);

      return (data as List)
          .map((e) => PackerProductionModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch productions: $e');
    }
  }

  /// Fetch all productions for a packer within a date range (week)
  Future<List<PackerProductionModel>> getProductionsByWeek({
    required String packerId,
    required String weekStart,
    required String weekEnd,
  }) async {
    try {
      final data = await _db
          .from(_productionTable)
          .select()
          .eq('packer_id', packerId)
          .gte('date', weekStart)
          .lte('date', weekEnd)
          .order('date', ascending: true)
          .order('timestamp', ascending: true);

      return (data as List)
          .map((e) => PackerProductionModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch weekly productions: $e');
    }
  }

  /// Fetch productions for a packer within a month
  Future<List<PackerProductionModel>> getProductionsByMonth({
    required String packerId,
    required String monthStart,
    required String monthEnd,
  }) async {
    try {
      final data = await _db
          .from(_productionTable)
          .select()
          .eq('packer_id', packerId)
          .gte('date', monthStart)
          .lte('date', monthEnd)
          .order('date', ascending: true);

      return (data as List)
          .map((e) => PackerProductionModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch monthly productions: $e');
    }
  }

  /// Delete a production entry
  Future<void> deleteProduction(String productionId) async {
    try {
      await _db
          .from(_productionTable)
          .delete()
          .eq('id', productionId);
    } catch (e) {
      throw Exception('Failed to delete production: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  //  PAYROLL
  // ════════════════════════════════════════════════════════════

  /// Fetch payroll for a specific week
  Future<PackerPayrollModel?> getPayrollByWeek({
    required String packerId,
    required String weekStart,
    required String weekEnd,
  }) async {
    try {
      final data = await _db
          .from(_payrollTable)
          .select()
          .eq('packer_id', packerId)
          .eq('week_start', weekStart)
          .eq('week_end', weekEnd)
          .maybeSingle();

      if (data == null) return null;
      return PackerPayrollModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch payroll: $e');
    }
  }

  /// Fetch all payroll records for a packer (for monthly view)
  Future<List<PackerPayrollModel>> getPayrollHistory({
    required String packerId,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final data = await _db
          .from(_payrollTable)
          .select()
          .eq('packer_id', packerId)
          .gte('week_start', fromDate)
          .lte('week_end', toDate)
          .order('week_start', ascending: false);

      return (data as List)
          .map((e) => PackerPayrollModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch payroll history: $e');
    }
  }

  /// Upsert weekly payroll (create or update)
  Future<PackerPayrollModel?> upsertPayroll({
    required String packerId,
    required String weekStart,
    required String weekEnd,
    required int    totalBundles,
    required double grossSalary,
    required double valeDeduction,
    required double netSalary,
    bool isPaid = false,
  }) async {
    try {
      final data = await _db
          .from(_payrollTable)
          .upsert(
            {
              'packer_id':      packerId,
              'week_start':     weekStart,
              'week_end':       weekEnd,
              'total_bundles':  totalBundles,
              'gross_salary':   grossSalary,
              'vale_deduction': valeDeduction,
              'net_salary':     netSalary,
              'is_paid':        isPaid,
            },
            onConflict: 'packer_id,week_start,week_end',
          )
          .select()
          .single();

      return PackerPayrollModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to upsert payroll: $e');
    }
  }

  /// Admin updates vale deduction for a payroll record
  Future<PackerPayrollModel?> updateValeDeduction({
    required String payrollId,
    required double valeDeduction,
    required double grossSalary,
  }) async {
    try {
      final netSalary = grossSalary - valeDeduction;
      final data = await _db
          .from(_payrollTable)
          .update({
            'vale_deduction': valeDeduction,
            'net_salary':     netSalary,
          })
          .eq('id', payrollId)
          .select()
          .single();

      return PackerPayrollModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update vale deduction: $e');
    }
  }

  /// Admin: fetch all packer payrolls for a given week (for payroll screen)
  Future<List<PackerPayrollModel>> getAllPackerPayrollsByWeek({
    required String weekStart,
    required String weekEnd,
  }) async {
    try {
      final data = await _db
          .from(_payrollTable)
          .select()
          .eq('week_start', weekStart)
          .eq('week_end', weekEnd)
          .order('created_at', ascending: true);

      return (data as List)
          .map((e) => PackerPayrollModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all packer payrolls: $e');
    }
  }
}