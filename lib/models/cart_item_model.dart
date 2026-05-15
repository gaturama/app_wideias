class CartItemModel {
  final String cartEntryId;
  final String id;
  final String name;
  final String? imageUrl;
  final double price;
  int qty;
  final String? observacao;
  final List<IngredienteRemovido> ingredientesRemovidos;
  final List<AdicionalSelecionado> adicionais;

  CartItemModel({
    required this.cartEntryId,
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    this.qty = 1,
    this.observacao,
    this.ingredientesRemovidos = const [],
    this.adicionais = const [],
  });

  double get precoTotal {
    final extra = adicionais.fold(0.0, (sum, a) => sum + a.preco);
    return (price + extra) * qty;
  }

  double get precoUnitario {
    final extra = adicionais.fold(0.0, (sum, a) => sum + a.preco);
    return price + extra;
  }

  CartItemModel copyWith({int? qty, String? observacao}) => CartItemModel(
    cartEntryId: cartEntryId,
    id: id,
    name: name,
    imageUrl: imageUrl,
    price: price,
    qty: qty ?? this.qty,
    observacao: observacao ?? this.observacao,
    ingredientesRemovidos: ingredientesRemovidos,
    adicionais: adicionais,
  );

  Map<String, dynamic> toJson() => {
    'cartEntryId': cartEntryId,
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'price': price,
    'qty': qty,
    'observacao': observacao,
    'ingredientesRemovidos': ingredientesRemovidos
        .map((i) => i.toJson())
        .toList(),
    'adicionais': adicionais.map((a) => a.toJson()).toList(),
  };

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    cartEntryId: json['cartEntryId']?.toString() ?? '',
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString(),
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    qty: json['qty'] as int? ?? 1,
    observacao: json['observacao']?.toString(),
    ingredientesRemovidos: (json['ingredientesRemovidos'] as List? ?? [])
        .map((i) => IngredienteRemovido.fromJson(i))
        .toList(),
    adicionais: (json['adicionais'] as List)
        .map((a) => AdicionalSelecionado.fromJson(a))
        .toList(),
  );
}

class IngredienteRemovido {
  final String id;
  final String name;
  IngredienteRemovido({required this.id, required this.name});
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory IngredienteRemovido.fromJson(Map<String, dynamic> j) =>
      IngredienteRemovido(id: j['id'] ?? '', name: j['name'] ?? '');
}

class AdicionalSelecionado {
  final String id;
  final String nome;
  final double preco;
  AdicionalSelecionado({
    required this.id,
    required this.nome,
    required this.preco,
  });
  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'preco': preco};
  factory AdicionalSelecionado.fromJson(Map<String, dynamic> j) =>
      AdicionalSelecionado(
        id: j['id'] ?? '',
        nome: j['nome'] ?? '',
        preco: (j['preco'] as num?)?.toDouble() ?? 0.0,
      );
}
