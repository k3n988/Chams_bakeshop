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
  final double grossSalary;   // base salary only — bonus is NOT included here
  final double bonusTotal;    // total bonus earned (shown separately)
  final double ovenDeduction;
  final double gasDeduction;
  final double valeDeduction;
  final double wifiDeduction;

  // Legacy param name kept so existing call sites don't break
  PayrollEntry({
    required this.userId,
    required this.name,
    required this.role,
    required this.daysWorked,
    required this.grossSalary,
    double masterBonus = 0,   // legacy — maps to bonusTotal
    double bonusTotal = 0,
    this.ovenDeduction = 0,
    this.gasDeduction = 0,
    this.valeDeduction = 0,
    this.wifiDeduction = 0,
  }) : bonusTotal = bonusTotal != 0 ? bonusTotal : masterBonus;

  // Legacy getter so existing reads of .masterBonus still compile
  double get masterBonus => bonusTotal;

  double get totalDeductions =>
      ovenDeduction + gasDeduction + valeDeduction + wifiDeduction;

  /// Base salary minus deductions — bonus is excluded
  double get totalSalary => grossSalary;
  double get finalSalary => grossSalary - totalDeductions;

  /// Final salary + bonus (for display purposes only — bonus paid separately)
  double get finalSalaryWithBonus => finalSalary + bonusTotal;
}

class DailySalaryEntry {
  final String date;
  final double baseSalary; // base only
  final double bonus;      // shown separately, not added to base

  DailySalaryEntry({
    required this.date,
    required this.baseSalary,
    this.bonus = 0,
  });

  /// Base salary only — use this for weekly/monthly payroll totals
  double get total => baseSalary;

  /// Base + bonus — use this only for display breakdown
  double get totalWithBonus => baseSalary + bonus;
}

/// Result of computing one day's production salary.
///
/// KEY RULES:
/// • salaryPerWorker = totalValue / totalWorkers  (base only, NO bonus)
/// • bonusPerWorker  = Σ(bonusPerSack × effectiveSacks) / totalWorkers
///                     split equally among master baker AND helpers
/// • Bonus is always displayed separately — never summed into salary
/// • effectiveSacks  = sacks + extraKg / 25.0  (1 sack = 25 kg)
class DailySalaryResult {
  final double totalValue;
  final int totalSacks;
  final int totalExtraKg;    // extra kg across all items (0–24 per item)
  final int totalWorkers;
  final double salaryPerWorker; // base salary — no bonus
  final double bonusPerWorker;  // bonus share — same for master baker & helpers

  const DailySalaryResult({
    required this.totalValue,
    required this.totalSacks,
    this.totalExtraKg = 0,
    required this.totalWorkers,
    required this.salaryPerWorker,
    required this.bonusPerWorker,
  });

  // Legacy getter — keeps all existing reads of .masterBonus compiling
  double get masterBonus => bonusPerWorker;
}