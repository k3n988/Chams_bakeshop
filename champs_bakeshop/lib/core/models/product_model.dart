class ProductModel {
  final String id;
  final String name;
  final double pricePerSack;
  final double bonusPerSack; // Shared worker bonus per sack produced
  final double masterBakerIncentivePerSack;

  ProductModel({
    required this.id,
    required this.name,
    required this.pricePerSack,
    this.bonusPerSack = 0,
    this.masterBakerIncentivePerSack = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price_per_sack': pricePerSack,
        'bonus_per_sack': bonusPerSack,
        'master_baker_incentive_per_sack': masterBakerIncentivePerSack,
      };

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
        id: map['id'],
        name: map['name'],
        pricePerSack: (map['price_per_sack'] as num).toDouble(),
        bonusPerSack: (map['bonus_per_sack'] as num? ?? 0).toDouble(),
        masterBakerIncentivePerSack:
            (map['master_baker_incentive_per_sack'] as num? ?? 0).toDouble(),
      );

  ProductModel copyWith({
    String? name,
    double? pricePerSack,
    double? bonusPerSack,
    double? masterBakerIncentivePerSack,
  }) =>
      ProductModel(
        id: id,
        name: name ?? this.name,
        pricePerSack: pricePerSack ?? this.pricePerSack,
        bonusPerSack: bonusPerSack ?? this.bonusPerSack,
        masterBakerIncentivePerSack: masterBakerIncentivePerSack ??
            this.masterBakerIncentivePerSack,
      );
}
