import '../models/product_model.dart';
import '../models/production_model.dart';
import '../models/payroll_model.dart';
import 'supabase_service.dart';

class PayrollService {
  final SupabaseService _db;

  PayrollService(this._db);

  /// ₱100 incentive per effective sack — added to baker salary only
  static const double incentivePerSack = 100.0;
  static const double helperOvenDeductionPerDay = 20.0;

  // ───────────────────────────────────────────────────────────
  //  DAILY
  //
  //  • effectiveSacks    = sacks + extraKg / 25.0
  //  • salaryPerWorker   = totalValue / totalWorkers  (base only)
  //  • bonusPerWorker    = Σ(bonusPerSack × eff) / totalWorkers (all workers, separate)
  //  • bakerIncentive    = totalEffectiveSacks × ₱100 (baker only, included in salary)
  // ───────────────────────────────────────────────────────────

  DailySalaryResult computeDaily(
      ProductionModel production, List<ProductModel> products) {
    double totalValue = 0;
    double totalBonusAmount = 0;
    double totalEffectiveSacks = 0;
    int totalSacks = 0;
    int totalExtraKg = 0;

    for (final item in production.items) {
      final product =
          products.where((p) => p.id == item.productId).firstOrNull;
      if (product != null) {
        final effective = item.effectiveSacks;
        totalValue += product.pricePerSack * effective;
        totalBonusAmount += product.bonusPerSack * effective;
        totalEffectiveSacks += effective;
        totalSacks += item.sacks;
        totalExtraKg += item.extraKg;
      }
    }

    final totalWorkers =
        production.totalWorkers > 0 ? production.totalWorkers : 1;
    final salaryPerWorker = totalValue / totalWorkers;
    final bonusPerWorker = totalBonusAmount / totalWorkers;
    final bakerIncentive = totalEffectiveSacks * incentivePerSack;

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

  // ───────────────────────────────────────────────────────────
  //  WEEKLY
  //
  //  Baker accumulates: baseSalary (salaryPerWorker + bakerIncentive)
  //  Helper accumulates: baseSalary (salaryPerWorker only)
  //  Everyone accumulates: bonusTotal (shown separately, not in payroll)
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

        final w = workers[wid]!;
        w.bonusTotal += calc.bonusPerWorker; // everyone gets same bonus share
        w.daysWorked += 1;

        if (wid == prod.masterBakerId) {
          w.isMaster = true;
          // Baker gets base salary + incentive
          w.baseSalary += calc.salaryPerWorker + calc.bakerIncentive;
        } else {
          // Helpers get base salary only
          w.baseSalary += calc.salaryPerWorker;
        }
      }
    }

    final dedMap = {for (final d in deductionsList) d.userId: d};

    return workers.values.map((w) {
      final oven = w.isMaster
          ? 0.0
          : w.daysWorked * helperOvenDeductionPerDay;
      final ded = dedMap[w.userId];

      return PayrollEntry(
        userId: w.userId,
        name: w.name,
        role: w.role,
        daysWorked: w.daysWorked,
        grossSalary: w.baseSalary,  // base + incentive for baker, base for helpers
        bonusTotal: w.bonusTotal,   // shown separately
        ovenDeduction: oven,
        gasDeduction: ded?.gas ?? 0,
        valeDeduction: ded?.vale ?? 0,
        wifiDeduction: ded?.wifi ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

class _WorkerAccum {
  final String userId;
  final String name;
  final String role;
  double baseSalary = 0; // base + incentive for baker, base only for helpers
  double bonusTotal = 0;
  int daysWorked = 0;
  bool isMaster = false;

  _WorkerAccum({
    required this.userId,
    required this.name,
    required this.role,
  });
}