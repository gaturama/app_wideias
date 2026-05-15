class ProdutoModel {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? description;

  ProdutoModel({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.description,
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) => ProdutoModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    imageUrl: json['imageUrl']?.toString(),
    description: json['description']?.toString(),
  );
}