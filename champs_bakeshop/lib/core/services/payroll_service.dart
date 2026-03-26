import '../models/product_model.dart';
import '../models/production_model.dart';
import '../models/payroll_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class PayrollService {
  final SupabaseService _db;

  PayrollService(this._db);

  static const double incentivePerSack = 100.0;

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

  Future<List<PayrollEntry>> computeWeeklyPayroll(
    String weekStart,
    String weekEnd,
    List<ProductModel> products,
    Map<String, String> userNames,
    Map<String, String> userRoles, {
    Set<String> paidUserIds = const {}, // ← NEW
  }) async {
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
        w.bonusTotal += calc.bonusPerWorker;
        w.daysWorked += 1;

        if (wid == prod.masterBakerId) {
          w.isMaster = true;
          w.baseSalary += calc.salaryPerWorker + calc.bakerIncentive;
        } else {
          w.baseSalary += calc.salaryPerWorker;
          if (prod.ovenHelperId == wid) {
            w.ovenExemptDays += 1; // this helper operated the oven — exempt
          }
        }
      }
    }

    final dedMap = {for (final d in deductionsList) d.userId: d};

    return workers.values.map((w) {
      final ded = dedMap[w.userId];

      // Oven helper rule:
      // - If a helper did the oven ANY day this week → fully exempt from oven
      //   deduction for the whole week (not just the oven days)
      // - On top of that, they earn ₱15 incentive for each day they did the oven
      // Regular helpers (no oven days) → ₱15 deduction per day as usual
      final autoOven = w.isMaster
          ? 0.0
          : (w.ovenExemptDays > 0
              ? 0.0
              : w.daysWorked * AppConstants.helperOvenDeductionPerDay);
      final ovenDeduction = (ded != null && ded.oven > 0)
          ? ded.oven
          : autoOven;
      // Oven incentive: ₱15 per day the helper operated the oven (added to salary)
      final ovenIncentive = w.isMaster
          ? 0.0
          : w.ovenExemptDays * AppConstants.helperOvenDeductionPerDay;

      return PayrollEntry(
        userId: w.userId,
        name: w.name,
        role: w.role,
        daysWorked: w.daysWorked,
        ovenExemptDays: w.ovenExemptDays,
        grossSalary: w.baseSalary,
        bonusTotal: w.bonusTotal,
        ovenIncentive: ovenIncentive,
        ovenDeduction: ovenDeduction,
        gasDeduction: ded?.gas ?? 0,
        valeDeduction: ded?.vale ?? 0,
        wifiDeduction: ded?.wifi ?? 0,
        isPaid: paidUserIds.contains(w.userId),
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

class _WorkerAccum {
  final String userId;
  final String name;
  final String role;
  double baseSalary = 0;
  double bonusTotal = 0;
  int daysWorked = 0;
  int ovenExemptDays = 0;
  bool isMaster = false;

  _WorkerAccum({
    required this.userId,
    required this.name,
    required this.role,
  });
}