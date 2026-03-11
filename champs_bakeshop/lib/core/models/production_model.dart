class ProductionItem {
  final String productId;
  final int sacks;
  
  // New optional categories
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
  final String date; // YYYY-MM-DD
  final String masterBakerId;
  final List<String> helperIds;
  final List<ProductionItem> items;

  ProductionModel({
    required this.id,
    required this.date,
    required this.masterBakerId,
    required this.helperIds,
    required this.items,
  });

  int get totalSacks => items.fold(0, (sum, item) => sum + item.sacks);
  int get totalWorkers => 1 + helperIds.length;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'master_baker_id': masterBakerId,
        'helper_ids': helperIds.join(','),
        // Encode the new optional fields into the string separated by colons
        'items': items.map((i) {
          return '${i.productId}:${i.sacks}:${i.cat60 ?? 0}:${i.cat36 ?? 0}:${i.cat48 ?? 0}:${i.subra ?? 0}:${i.saka ?? 0}';
        }).join('|'),
      };

  factory ProductionModel.fromMap(Map<String, dynamic> map) {
    final helperStr = map['helper_ids'] as String? ?? '';
    final itemsStr = map['items'] as String? ?? '';

    return ProductionModel(
      id: map['id'],
      date: map['date'],
      masterBakerId: map['master_baker_id'],
      helperIds: helperStr.isEmpty ? [] : helperStr.split(','),
      items: itemsStr.isEmpty
          ? []
          : itemsStr.split('|').map((s) {
              final parts = s.split(':');
              return ProductionItem(
                productId: parts[0],
                sacks: int.parse(parts[1]),
                // We use parts.length check to ensure older database records don't crash the app
                cat60: parts.length > 2 ? int.tryParse(parts[2]) : null,
                cat36: parts.length > 3 ? int.tryParse(parts[3]) : null,
                cat48: parts.length > 4 ? int.tryParse(parts[4]) : null,
                subra: parts.length > 5 ? int.tryParse(parts[5]) : null,
                saka: parts.length > 6 ? int.tryParse(parts[6]) : null,
              );
            }).toList(),
    );
  }
}