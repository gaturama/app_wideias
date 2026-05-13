class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double price;
  final String? observations;
  final ProductInfo? product;
  final OrderInfo? order;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.observations,
    this.product,
    this.order,
  });

  double get total => price * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      observations: json['observations']?.toString(),
      product: json['products'] != null
          ? ProductInfo.fromJson(json['products'])
          : null,
      order: json['orders'] != null ? OrderInfo.fromJson(json['orders']) : null,
    );
  }
}

class ProductInfo {
  final String id;
  final String name;
  final String? imageUrl;

  ProductInfo({required this.id, required this.name, this.imageUrl});

  factory ProductInfo.fromJson(Map<String, dynamic> json) => ProductInfo(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Produto',
    imageUrl: json['image_url']?.toString(),
  );
}

class OrderInfo {
  final String id;
  final String? paymentMethod;
  final String? mesa;
  final LocationInfo? location;

  OrderInfo({required this.id, this.paymentMethod, this.mesa, this.location});

  factory OrderInfo.fromJson(Map<String, dynamic> json) => OrderInfo(
    id: json['id']?.toString() ?? '',
    paymentMethod: json['payment_method']?.toString(),
    mesa: json['mesa']?.toString(),
    location: json['locations'] != null
        ? LocationInfo.fromJson(json['locations'])
        : null,
  );
}

class LocationInfo {
  final String id;
  final String name;
  final String? address;

  LocationInfo({required this.id, required this.name, this.address});

  factory LocationInfo.fromJson(Map<String, dynamic> json) => LocationInfo(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    address: json['address']?.toString(),
  );
}
