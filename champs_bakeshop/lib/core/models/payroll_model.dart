// lib/core/models/payroll_model.dart

class DeductionModel {
  final String id;
  final String userId;
  final String weekStart;
  final double gas;
  final double vale;
  final double wifi;

  DeductionModel({
    required this.id,
    required this.userId,
    required this.weekStart,
    this.gas = 0,
    this.vale = 0,
    this.wifi = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'week_start': weekStart,
        'gas': gas,
        'vale': vale,
        'wifi': wifi,
      };

  factory DeductionModel.fromMap(Map<String, dynamic> map) => DeductionModel(
        id: map['id'],
        userId: map['user_id'],
        weekStart: map['week_start'],
        gas: (map['gas'] as num?)?.toDouble() ?? 0,
        vale: (map['vale'] as num?)?.toDouble() ?? 0,
        wifi: (map['wifi'] as num?)?.toDouble() ?? 0,
      );
}

class PayrollEntry {
  final String userId;
  final String name;
  final String role;
  final int daysWorked;
  final double grossSalary;   // base salary + incentive (baker only) — bonus NOT included
  final double bonusTotal;    // shown separately, never in payroll total
  final double ovenDeduction;
  final double gasDeduction;
  final double valeDeduction;
  final double wifiDeduction;

  PayrollEntry({
    required this.userId,
    required this.name,
    required this.role,
    required this.daysWorked,
    required this.grossSalary,
    double masterBonus = 0,  // legacy param name — maps to bonusTotal
    double bonusTotal = 0,
    this.ovenDeduction = 0,
    this.gasDeduction = 0,
    this.valeDeduction = 0,
    this.wifiDeduction = 0,
  }) : bonusTotal = bonusTotal != 0 ? bonusTotal : masterBonus;

  double get masterBonus => bonusTotal;

  double get totalDeductions =>
      ovenDeduction + gasDeduction + valeDeduction + wifiDeduction;

  /// Gross salary (base + incentive) minus deductions. Bonus is NOT included.
  double get finalSalary => grossSalary - totalDeductions;

  /// For display only — final salary + bonus shown together
  double get finalSalaryWithBonus => finalSalary + bonusTotal;
}

class DailySalaryEntry {
  final String date;
  final double baseSalary;  // includes baker incentive for master baker
  final double bonus;       // shown separately

  DailySalaryEntry({
    required this.date,
    required this.baseSalary,
    this.bonus = 0,
  });

  double get total => baseSalary;             // use for weekly/monthly sums
  double get totalWithBonus => baseSalary + bonus; // use for display only
}

/// Result of computing one day's production salary.
///
/// KEY RULES:
/// • effectiveSacks    = sacks + extraKg / 25.0  (1 sack = 25 kg)
/// • salaryPerWorker   = totalValue / totalWorkers      ← base, NO bonus, NO incentive
/// • bonusPerWorker    = Σ(bonusPerSack × eff) / totalWorkers  ← split equally, paid separately
/// • bakerIncentive    = totalEffectiveSacks × ₱100            ← ADDED to baker salary only
///                       e.g. 2 sacks + 2 kg → 2.08 × ₱100 = ₱208
class DailySalaryResult {
  final double totalValue;
  final int totalSacks;
  final int totalExtraKg;
  final int totalWorkers;
  final double salaryPerWorker;   // base share for every worker
  final double bonusPerWorker;    // same share for master baker AND helpers (separate)
  final double bakerIncentive;    // added to baker salary only (₱100/sack)

  const DailySalaryResult({
    required this.totalValue,
    required this.totalSacks,
    this.totalExtraKg = 0,
    required this.totalWorkers,
    required this.salaryPerWorker,
    required this.bonusPerWorker,
    this.bakerIncentive = 0,
  });

  // Legacy getter
  double get masterBonus => bonusPerWorker;
}