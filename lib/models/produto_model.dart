class ProdutoModel {
  final String id;
  final int idCardapio;
  final String name;
  final double price;
  final String? imageUrl;
  final String? description;

  ProdutoModel({
    required this.id,
    required this.idCardapio,
    required this.name,
    required this.price,
    this.imageUrl,
    this.description,
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) => ProdutoModel(
    id: json['id']?.toString() ?? '',
    idCardapio: int.tryParse(json['idCardapio']?.toString() ?? '', )?? 0,
    name: json['name']?.toString() ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    imageUrl: json['imageUrl']?.toString(),
    description: json['description']?.toString(),
  );

  Map<String, dynamic> toJson() {
   return {
    'id': id,
    'idCardapio': idCardapio,
    'name': name,
    'imageUrl': imageUrl,
    'price': price,
    'description': description,
   };
  }
}