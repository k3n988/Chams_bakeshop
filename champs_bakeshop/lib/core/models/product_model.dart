class ProductModel {
  final String id;
  final String name;
  final double pricePerSack;
  final double bonusPerSack; // Master baker bonus per sack produced

  ProductModel({
    required this.id,
    required this.name,
    required this.pricePerSack,
    this.bonusPerSack = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price_per_sack': pricePerSack,
        'bonus_per_sack': bonusPerSack,
      };

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
        id: map['id'],
        name: map['name'],
        pricePerSack: (map['price_per_sack'] as num).toDouble(),
        bonusPerSack: (map['bonus_per_sack'] as num? ?? 0).toDouble(),
      );

  ProductModel copyWith({
    String? name,
    double? pricePerSack,
    double? bonusPerSack,
  }) =>
      ProductModel(
        id: id,
        name: name ?? this.name,
        pricePerSack: pricePerSack ?? this.pricePerSack,
        bonusPerSack: bonusPerSack ?? this.bonusPerSack,
      );
}