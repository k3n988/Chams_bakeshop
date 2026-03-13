import '../models/product_model.dart';
import '../models/production_model.dart';
import '../models/payroll_model.dart';
import 'supabase_service.dart';

class PayrollService {
  final SupabaseService _db;

  PayrollService(this._db);

  // ───────────────────────────────────────────────────────────
  //  DAILY  —  compute salary for one production record
  //
  //  Rules:
  //  • effectiveSacks  = sacks + extraKg / 25.0  (1 sack = 25 kg)
  //  • totalValue      = Σ(pricePerSack × effectiveSacks)
  //  • salaryPerWorker = totalValue / totalWorkers  ← base only, NO bonus
  //  • bonusPerWorker  = Σ(bonusPerSack × effectiveSacks) / totalWorkers
  //                      split equally — master baker AND helpers get the same
  //  • Bonus is NEVER added to salaryPerWorker
  // ───────────────────────────────────────────────────────────

  DailySalaryResult computeDaily(
      ProductionModel production, List<ProductModel> products) {
    double totalValue = 0;
    double totalBonusAmount = 0;
    int totalSacks = 0;
    int totalExtraKg = 0;

    for (final item in production.items) {
      final product =
          products.where((p) => p.id == item.productId).firstOrNull;
      if (product != null) {
        final effective = item.effectiveSacks; // sacks + extraKg/25
        totalValue += product.pricePerSack * effective;
        totalBonusAmount += product.bonusPerSack * effective;
        totalSacks += item.sacks;
        totalExtraKg += item.extraKg;
      }
    }

    final totalWorkers = production.totalWorkers > 0
        ? production.totalWorkers
        : 1; // guard against 0
    final salaryPerWorker = totalValue / totalWorkers;
    final bonusPerWorker = totalBonusAmount / totalWorkers;

    return DailySalaryResult(
      totalValue: totalValue,
      totalSacks: totalSacks,
      totalExtraKg: totalExtraKg,
      totalWorkers: totalWorkers,
      salaryPerWorker: salaryPerWorker,
      bonusPerWorker: bonusPerWorker,
    );
  }

  // ───────────────────────────────────────────────────────────
  //  WEEKLY  —  full payroll for all workers in a week
  //
  //  • grossSalary accumulates base salary only
  //  • bonusTotal  accumulates bonus separately (same per-worker amount
  //    for both master baker and helpers on the same day)
  //  • Oven deduction applies to helpers only
  //  • Weekly/monthly totals use base salary — bonus shown alongside
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
        w.baseSalary += calc.salaryPerWorker; // base only
        w.bonusTotal += calc.bonusPerWorker;  // same share for everyone
        w.daysWorked += 1;

        if (wid == prod.masterBakerId) {
          w.isMaster = true;
        }
      }
    }

    final dedMap = {for (final d in deductionsList) d.userId: d};

    return workers.values.map((w) {
      final oven = w.isMaster
          ? 0.0
          : w.daysWorked * _helperOvenDeductionPerDay;
      final ded = dedMap[w.userId];

      return PayrollEntry(
        userId: w.userId,
        name: w.name,
        role: w.role,
        daysWorked: w.daysWorked,
        grossSalary: w.baseSalary,   // base only
        bonusTotal: w.bonusTotal,    // shown separately
        ovenDeduction: oven,
        gasDeduction: ded?.gas ?? 0,
        valeDeduction: ded?.vale ?? 0,
        wifiDeduction: ded?.wifi ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Oven deduction constant — move to AppConstants if you prefer
  static const double _helperOvenDeductionPerDay = 20.0;
}

// ── Internal accumulator ─────────────────────────────────────
class _WorkerAccum {
  final String userId;
  final String name;
  final String role;
  double baseSalary = 0;
  double bonusTotal = 0; // renamed from masterBonus — applies to all workers
  int daysWorked = 0;
  bool isMaster = false;

  _WorkerAccum({
    required this.userId,
    required this.name,
    required this.role,
  });
}