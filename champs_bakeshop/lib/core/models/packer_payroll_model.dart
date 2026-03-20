class PackerPayrollModel {
  final String id;
  final String packerId;
  final String weekStart;      // 'YYYY-MM-DD'
  final String weekEnd;        // 'YYYY-MM-DD'
  final int    totalBundles;
  final double grossSalary;    // totalBundles * ₱4
  final double valeDeduction;  // money borrowed (admin-set)
  final double netSalary;      // grossSalary - valeDeduction
  final bool   isPaid;
  final DateTime createdAt;

  const PackerPayrollModel({
    required this.id,
    required this.packerId,
    required this.weekStart,
    required this.weekEnd,
    required this.totalBundles,
    required this.grossSalary,
    required this.valeDeduction,
    required this.netSalary,
    required this.isPaid,
    required this.createdAt,
  });

  // ── Serialization ──────────────────────────────────────────
  factory PackerPayrollModel.fromJson(Map<String, dynamic> json) {
    return PackerPayrollModel(
      id:             json['id'] as String,
      packerId:       json['packer_id'] as String,
      weekStart:      json['week_start'] as String,
      weekEnd:        json['week_end'] as String,
      totalBundles:   (json['total_bundles'] as num).toInt(),
      grossSalary:    (json['gross_salary'] as num).toDouble(),
      valeDeduction:  (json['vale_deduction'] as num).toDouble(),
      netSalary:      (json['net_salary'] as num).toDouble(),
      isPaid:         json['is_paid'] as bool? ?? false,
      createdAt:      DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id':             id,
        'packer_id':      packerId,
        'week_start':     weekStart,
        'week_end':       weekEnd,
        'total_bundles':  totalBundles,
        'gross_salary':   grossSalary,
        'vale_deduction': valeDeduction,
        'net_salary':     netSalary,
        'is_paid':        isPaid,
        'created_at':     createdAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'packer_id':      packerId,
        'week_start':     weekStart,
        'week_end':       weekEnd,
        'total_bundles':  totalBundles,
        'gross_salary':   grossSalary,
        'vale_deduction': valeDeduction,
        'net_salary':     netSalary,
        'is_paid':        isPaid,
      };

  PackerPayrollModel copyWith({
    String?   id,
    String?   packerId,
    String?   weekStart,
    String?   weekEnd,
    int?      totalBundles,
    double?   grossSalary,
    double?   valeDeduction,
    double?   netSalary,
    bool?     isPaid,
    DateTime? createdAt,
  }) {
    return PackerPayrollModel(
      id:             id             ?? this.id,
      packerId:       packerId       ?? this.packerId,
      weekStart:      weekStart      ?? this.weekStart,
      weekEnd:        weekEnd        ?? this.weekEnd,
      totalBundles:   totalBundles   ?? this.totalBundles,
      grossSalary:    grossSalary    ?? this.grossSalary,
      valeDeduction:  valeDeduction  ?? this.valeDeduction,
      netSalary:      netSalary      ?? this.netSalary,
      isPaid:         isPaid         ?? this.isPaid,
      createdAt:      createdAt      ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'PackerPayrollModel(id: $id, week: $weekStart–$weekEnd, gross: $grossSalary, net: $netSalary)';
}