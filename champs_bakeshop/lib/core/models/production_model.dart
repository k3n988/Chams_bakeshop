// lib/core/models/production_model.dart

class ProductionItem {
  final String productId;
  final int sacks;
  final int extraKg; // extra kg on top of full sacks (1 sack = 25 kg)
  final int? cat60;
  final int? cat36;
  final int? cat48;
  final int? subra;
  final int? saka;

  ProductionItem({
    required this.productId,
    required this.sacks,
    this.extraKg = 0,
    this.cat60,
    this.cat36,
    this.cat48,
    this.subra,
    this.saka,
  });

  /// Effective sacks including partial kg (e.g. 3 sacks + 10 kg = 3.4 effective sacks)
  double get effectiveSacks => sacks + (extraKg / 25.0);

  ProductionItem copyWith({
    String? productId,
    int? sacks,
    int? extraKg,
    int? cat60,
    int? cat36,
    int? cat48,
    int? subra,
    int? saka,
  }) =>
      ProductionItem(
        productId: productId ?? this.productId,
        sacks: sacks ?? this.sacks,
        extraKg: extraKg ?? this.extraKg,
        cat60: cat60 ?? this.cat60,
        cat36: cat36 ?? this.cat36,
        cat48: cat48 ?? this.cat48,
        subra: subra ?? this.subra,
        saka: saka ?? this.saka,
      );

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'sacks': sacks,
        'extra_kg': extraKg,
        'cat60': cat60,
        'cat36': cat36,
        'cat48': cat48,
        'subra': subra,
        'saka': saka,
      };

  factory ProductionItem.fromMap(Map<String, dynamic> map) => ProductionItem(
        productId: map['product_id'],
        sacks: map['sacks'] as int,
        extraKg: (map['extra_kg'] as int?) ?? 0,
        cat60: map['cat60'] as int?,
        cat36: map['cat36'] as int?,
        cat48: map['cat48'] as int?,
        subra: map['subra'] as int?,
        saka: map['saka'] as int?,
      );
}

class ProductionModel {
  final String id;
  final String date;
  final String masterBakerId;
  final List<String> helperIds;
  final List<ProductionItem> items;

  // Computed fields saved to DB
  final double totalValue;
  final int totalSacks;
  final int totalExtraKg;      // total extra kg across all items
  final int totalWorkers;
  final double salaryPerWorker; // base salary only, NO bonus
  final double bonusPerWorker;  // bonus split equally among all workers

  ProductionModel({
    required this.id,
    required this.date,
    required this.masterBakerId,
    required this.helperIds,
    required this.items,
    this.totalValue = 0.0,
    this.totalSacks = 0,
    this.totalExtraKg = 0,
    this.totalWorkers = 0,
    this.salaryPerWorker = 0.0,
    this.bonusPerWorker = 0.0,
  });

  // Keep masterBonus as a getter so existing code that reads it doesn't break
  double get masterBonus => bonusPerWorker;

  ProductionModel copyWith({
    String? id,
    String? date,
    String? masterBakerId,
    List<String>? helperIds,
    List<ProductionItem>? items,
    double? totalValue,
    int? totalSacks,
    int? totalExtraKg,
    int? totalWorkers,
    double? salaryPerWorker,
    double? bonusPerWorker,
  }) =>
      ProductionModel(
        id: id ?? this.id,
        date: date ?? this.date,
        masterBakerId: masterBakerId ?? this.masterBakerId,
        helperIds: helperIds ?? this.helperIds,
        items: items ?? this.items,
        totalValue: totalValue ?? this.totalValue,
        totalSacks: totalSacks ?? this.totalSacks,
        totalExtraKg: totalExtraKg ?? this.totalExtraKg,
        totalWorkers: totalWorkers ?? this.totalWorkers,
        salaryPerWorker: salaryPerWorker ?? this.salaryPerWorker,
        bonusPerWorker: bonusPerWorker ?? this.bonusPerWorker,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'master_baker_id': masterBakerId,
        'helper_ids': helperIds,
        'items': items.map((i) => i.toMap()).toList(),
        'total_value': totalValue,
        'total_sacks': totalSacks,
        'total_extra_kg': totalExtraKg,
        'total_workers': totalWorkers,
        'salary_per_worker': salaryPerWorker,
        'bonus_per_worker': bonusPerWorker,
        // keep master_bonus column in sync for any legacy reads
        'master_bonus': bonusPerWorker,
      };

  factory ProductionModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedHelpers = [];
    if (map['helper_ids'] != null) {
      if (map['helper_ids'] is String) {
        parsedHelpers = (map['helper_ids'] as String).isEmpty
            ? []
            : (map['helper_ids'] as String).split(',');
      } else if (map['helper_ids'] is List) {
        parsedHelpers = List<String>.from(map['helper_ids']);
      }
    }

    List<ProductionItem> parsedItems = [];
    if (map['items'] != null && map['items'] is List) {
      parsedItems = (map['items'] as List)
          .map((e) => ProductionItem.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    // Support both old (master_bonus) and new (bonus_per_worker) column names
    final bonus = (map['bonus_per_worker'] ?? map['master_bonus'] ?? 0).toDouble();

    return ProductionModel(
      id: map['id'],
      date: map['date'],
      masterBakerId: map['master_baker_id'],
      helperIds: parsedHelpers,
      items: parsedItems,
      totalValue: (map['total_value'] ?? 0).toDouble(),
      totalSacks: map['total_sacks'] ?? 0,
      totalExtraKg: map['total_extra_kg'] ?? 0,
      totalWorkers: map['total_workers'] ?? 0,
      salaryPerWorker: (map['salary_per_worker'] ?? 0).toDouble(),
      bonusPerWorker: bonus,
    );
  }
}