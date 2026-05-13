class HistoricoItemModel {
  final String id;
  final String productName;
  final String? productImage;
  final int quantity;
  final double price;
  final double total;
  final String? createdAt;
  final String? observations;
  final String locationName;
  final String? mesa;
  final String? paymentMethod;

  HistoricoItemModel({
    required this.id,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.price,
    required this.total,
    this.createdAt,
    this.observations,
    required this.locationName,
    this.mesa,
    this.paymentMethod,
  });

  factory HistoricoItemModel.fromJson(Map<String, dynamic> json) {
    final price    = (json['price'] as num?)?.toDouble()    ?? 0.0;
    final quantity = json['quantity'] as int?               ?? 1;
    return HistoricoItemModel(
      id:            json['id']?.toString()                   ?? '',
      productName:   json['products']?['name']?.toString()    ?? 'Produto',
      productImage:  json['products']?['image_url']?.toString(),
      quantity:      quantity,
      price:         price,
      total:         price * quantity,
      createdAt:     json['created_at']?.toString(),
      observations:  json['observations']?.toString(),
      locationName:  json['orders']?['locations']?['name']?.toString() ?? 'N/A',
      mesa:          json['orders']?['mesa']?.toString(),
      paymentMethod: json['orders']?['payment_method']?.toString(),
    );
  }
}