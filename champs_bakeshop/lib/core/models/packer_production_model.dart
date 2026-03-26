import '../utils/constants.dart';

class PackerProductionModel {
  final String id;
  final String packerId;
  final String date;         // 'YYYY-MM-DD'
  final String productName;  // e.g. 'otap', 'ugoy'
  final int bundleCount;
  final String timestamp;    // full datetime string
  final DateTime createdAt;

  const PackerProductionModel({
    required this.id,
    required this.packerId,
    required this.date,
    required this.productName,
    required this.bundleCount,
    required this.timestamp,
    required this.createdAt,
  });

  // ── Derived ────────────────────────────────────────────────
  double get salaryEarned => bundleCount * AppConstants.packerRatePerBundle;

  // ── Serialization ──────────────────────────────────────────
  factory PackerProductionModel.fromJson(Map<String, dynamic> json) {
    return PackerProductionModel(
      id:          json['id'] as String,
      packerId:    json['packer_id'] as String,
      date:        json['date'] as String,
      productName: json['product_name'] as String,
      bundleCount: (json['bundle_count'] as num).toInt(),
      timestamp:   json['timestamp'] as String,
      createdAt:   DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id':           id,
        'packer_id':    packerId,
        'date':         date,
        'product_name': productName,
        'bundle_count': bundleCount,
        'timestamp':    timestamp,
        'created_at':   createdAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'packer_id':    packerId,
        'date':         date,
        'product_name': productName,
        'bundle_count': bundleCount,
        'timestamp':    timestamp,
      };

  PackerProductionModel copyWith({
    String?   id,
    String?   packerId,
    String?   date,
    String?   productName,
    int?      bundleCount,
    String?   timestamp,
    DateTime? createdAt,
  }) {
    return PackerProductionModel(
      id:          id          ?? this.id,
      packerId:    packerId    ?? this.packerId,
      date:        date        ?? this.date,
      productName: productName ?? this.productName,
      bundleCount: bundleCount ?? this.bundleCount,
      timestamp:   timestamp   ?? this.timestamp,
      createdAt:   createdAt   ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'PackerProductionModel(id: $id, product: $productName, bundles: $bundleCount, date: $date)';
}