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
  final double grossSalary;
  final double masterBonus;
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
    this.masterBonus = 0,
    this.ovenDeduction = 0,
    this.gasDeduction = 0,
    this.valeDeduction = 0,
    this.wifiDeduction = 0,
  });

  double get totalDeductions =>
      ovenDeduction + gasDeduction + valeDeduction + wifiDeduction;
  double get totalSalary => grossSalary + masterBonus;
  double get finalSalary => totalSalary - totalDeductions;
}

class DailySalaryEntry {
  final String date;
  final double baseSalary;
  final double bonus;

  DailySalaryEntry({
    required this.date,
    required this.baseSalary,
    this.bonus = 0,
  });

  double get total => baseSalary + bonus;
}

/// Result of computing one day's production salary
class DailySalaryResult {
  final double totalValue;
  final int totalSacks;
  final int totalWorkers;
  final double salaryPerWorker;
  final double masterBonus;

  DailySalaryResult({
    required this.totalValue,
    required this.totalSacks,
    required this.totalWorkers,
    required this.salaryPerWorker,
    required this.masterBonus,
  });
}
