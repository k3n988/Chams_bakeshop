import '../models/product_model.dart';
import '../models/production_model.dart';
import '../models/payroll_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class PayrollService {
  final SupabaseService _db;

  PayrollService(this._db);

  // ───────────────────────────────────────────────────────────
  //  DAILY  —  compute salary for one production record
  // ───────────────────────────────────────────────────────────

  DailySalaryResult computeDaily(
      ProductionModel production, List<ProductModel> products) {
    double totalValue = 0;
    int totalSacks = 0;

    for (final item in production.items) {
      final product =
          products.where((p) => p.id == item.productId).firstOrNull;
      if (product != null) {
        totalValue += product.pricePerSack * item.sacks;
        totalSacks += item.sacks;
      }
    }

    final totalWorkers = production.totalWorkers; // 1 baker + N helpers
    final salaryPerWorker =
        totalWorkers > 0 ? totalValue / totalWorkers : 0.0;
    final masterBonus = totalSacks * AppConstants.masterBakerBonusPerSack;

    return DailySalaryResult(
      totalValue: totalValue,
      totalSacks: totalSacks,
      totalWorkers: totalWorkers,
      salaryPerWorker: salaryPerWorker,
      masterBonus: masterBonus,
    );
  }

  // ───────────────────────────────────────────────────────────
  //  WEEKLY  —  full payroll for all workers in a week
  // ───────────────────────────────────────────────────────────

  Future<List<PayrollEntry>> computeWeeklyPayroll(
    String weekStart,
    String weekEnd,
    List<ProductModel> products,
    Map<String, String> userNames,
    Map<String, String> userRoles,
  ) async {
    final productions =
        await _db.getProductionsByDateRange(weekStart, weekEnd);
    final deductionsList = await _db.getDeductionsForWeek(weekStart);

    // Accumulate per-worker totals
    final Map<String, _WorkerAccum> workers = {};

    for (final prod in productions) {
      final calc = computeDaily(prod, products);
      final allIds = [prod.masterBakerId, ...prod.helperIds];

      for (final wid in allIds) {
        workers.putIfAbsent(
          wid,
          () => _WorkerAccum(
            userId: wid,
            name: userNames[wid] ?? '?',
            role: userRoles[wid] ?? 'helper',
          ),
        );
        workers[wid]!.baseSalary += calc.salaryPerWorker;
        workers[wid]!.daysWorked += 1;
        if (wid == prod.masterBakerId) {
          workers[wid]!.isMaster = true;
          workers[wid]!.masterBonus += calc.masterBonus;
        }
      }
    }

    final dedMap = {for (final d in deductionsList) d.userId: d};

    return workers.values.map((w) {
      // Oven deduction only applies to helpers
      final oven = w.isMaster
          ? 0.0
          : w.daysWorked * AppConstants.helperOvenDeductionPerDay;
      final ded = dedMap[w.userId];
      return PayrollEntry(
        userId: w.userId,
        name: w.name,
        role: w.role,
        daysWorked: w.daysWorked,
        grossSalary: w.baseSalary,
        masterBonus: w.masterBonus,
        ovenDeduction: oven,
        gasDeduction: ded?.gas ?? 0,
        valeDeduction: ded?.vale ?? 0,
        wifiDeduction: ded?.wifi ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

// ── Internal accumulator ─────────────────────────────────────
class _WorkerAccum {
  final String userId;
  final String name;
  final String role;
  double baseSalary = 0;
  double masterBonus = 0;
  int daysWorked = 0;
  bool isMaster = false;

  _WorkerAccum({
    required this.userId,
    required this.name,
    required this.role,
  });
}