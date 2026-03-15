class DeductionModel {
  final String id;
  final String userId;
  final String weekStart;
  final double oven; // ← NEW: overrides auto-calc when set > 0
  final double gas;
  final double vale;
  final double wifi;

  DeductionModel({
    required this.id,
    required this.userId,
    required this.weekStart,
    this.oven = 0,
    this.gas = 0,
    this.vale = 0,
    this.wifi = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'week_start': weekStart,
        'oven': oven,
        'gas': gas,
        'vale': vale,
        'wifi': wifi,
      };

  factory DeductionModel.fromMap(Map<String, dynamic> map) => DeductionModel(
        id: map['id'],
        userId: map['user_id'],
        weekStart: map['week_start'],
        oven: (map['oven'] as num?)?.toDouble() ?? 0,
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
  final double bonusTotal;
  final double ovenDeduction;
  final double gasDeduction;
  final double valeDeduction;
  final double wifiDeduction;
  final bool isPaid; // ← NEW

  PayrollEntry({
    required this.userId,
    required this.name,
    required this.role,
    required this.daysWorked,
    required this.grossSalary,
    double masterBonus = 0,
    double bonusTotal = 0,
    this.ovenDeduction = 0,
    this.gasDeduction = 0,
    this.valeDeduction = 0,
    this.wifiDeduction = 0,
    this.isPaid = false, // ← NEW
  }) : bonusTotal = bonusTotal != 0 ? bonusTotal : masterBonus;

  double get masterBonus => bonusTotal;

  double get totalDeductions =>
      ovenDeduction + gasDeduction + valeDeduction + wifiDeduction;

  double get finalSalary => grossSalary - totalDeductions;
  double get finalSalaryWithBonus => finalSalary + bonusTotal;

  // copyWith for toggling isPaid
  PayrollEntry copyWith({bool? isPaid}) => PayrollEntry(
        userId: userId,
        name: name,
        role: role,
        daysWorked: daysWorked,
        grossSalary: grossSalary,
        bonusTotal: bonusTotal,
        ovenDeduction: ovenDeduction,
        gasDeduction: gasDeduction,
        valeDeduction: valeDeduction,
        wifiDeduction: wifiDeduction,
        isPaid: isPaid ?? this.isPaid,
      );
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

  double get total => baseSalary;
  double get totalWithBonus => baseSalary + bonus;
}

class DailySalaryResult {
  final double totalValue;
  final int totalSacks;
  final int totalExtraKg;
  final int totalWorkers;
  final double salaryPerWorker;
  final double bonusPerWorker;
  final double bakerIncentive;

  const DailySalaryResult({
    required this.totalValue,
    required this.totalSacks,
    this.totalExtraKg = 0,
    required this.totalWorkers,
    required this.salaryPerWorker,
    required this.bonusPerWorker,
    this.bakerIncentive = 0,
  });

  double get masterBonus => bonusPerWorker;
}