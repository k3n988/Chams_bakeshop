// lib/core/models/production_model.dart

class ProductionItem {
  final String productId;
  final int sacks;
  final int? cat60;
  final int? cat36;
  final int? cat48;
  final int? subra;
  final int? saka;

  ProductionItem({
    required this.productId,
    required this.sacks,
    this.cat60,
    this.cat36,
    this.cat48,
    this.subra,
    this.saka,
  });

  // TAMANG JSON FORMAT
  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'sacks': sacks,
        'cat60': cat60,
        'cat36': cat36,
        'cat48': cat48,
        'subra': subra,
        'saka': saka,
      };

  factory ProductionItem.fromMap(Map<String, dynamic> map) => ProductionItem(
        productId: map['product_id'],
        sacks: map['sacks'] as int,
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
  
  // MGA BAGONG FIELDS PARA NAKA-SAVE NA ANG COMPUTATION
  final double totalValue;
  final int totalSacks;
  final int totalWorkers;
  final double salaryPerWorker;
  final double masterBonus;

  ProductionModel({
    required this.id,
    required this.date,
    required this.masterBakerId,
    required this.helperIds,
    required this.items,
    this.totalValue = 0.0,
    this.totalSacks = 0,
    this.totalWorkers = 0,
    this.salaryPerWorker = 0.0,
    this.masterBonus = 0.0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'master_baker_id': masterBakerId,
        'helper_ids': helperIds, // Pwedeng ipasa as list kung jsonb ang Supabase field
        'items': items.map((i) => i.toMap()).toList(), // TAMA NA ANG JSON
        'total_value': totalValue,
        'total_sacks': totalSacks,
        'total_workers': totalWorkers,
        'salary_per_worker': salaryPerWorker,
        'master_bonus': masterBonus,
      };

  factory ProductionModel.fromMap(Map<String, dynamic> map) {
    // Handling ng helperIds kung string (luma) o list (bago)
    List<String> parsedHelpers = [];
    if (map['helper_ids'] != null) {
      if (map['helper_ids'] is String) {
        parsedHelpers = (map['helper_ids'] as String).isEmpty ? [] : (map['helper_ids'] as String).split(',');
      } else if (map['helper_ids'] is List) {
        parsedHelpers = List<String>.from(map['helper_ids']);
      }
    }

    // Handling ng items
    List<ProductionItem> parsedItems = [];
    if (map['items'] != null && map['items'] is List) {
       parsedItems = (map['items'] as List).map((e) => ProductionItem.fromMap(e as Map<String, dynamic>)).toList();
    }

    return ProductionModel(
      id: map['id'],
      date: map['date'],
      masterBakerId: map['master_baker_id'],
      helperIds: parsedHelpers,
      items: parsedItems,
      totalValue: (map['total_value'] ?? 0).toDouble(),
      totalSacks: map['total_sacks'] ?? 0,
      totalWorkers: map['total_workers'] ?? 0,
      salaryPerWorker: (map['salary_per_worker'] ?? 0).toDouble(),
      masterBonus: (map['master_bonus'] ?? 0).toDouble(),
    );
  }
}