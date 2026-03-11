class ProductModel {
  final String id;
  final String name;
  final double pricePerSack;

  ProductModel({
    required this.id,
    required this.name,
    required this.pricePerSack,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price_per_sack': pricePerSack,
      };

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
        id: map['id'],
        name: map['name'],
        pricePerSack: (map['price_per_sack'] as num).toDouble(),
      );

  ProductModel copyWith({String? name, double? pricePerSack}) => ProductModel(
        id: id,
        name: name ?? this.name,
        pricePerSack: pricePerSack ?? this.pricePerSack,
      );
}
