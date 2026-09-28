import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_item_model.dart';
import '../models/historico_item_model.dart';
import '../models/cart_item_model.dart';
import '../core/services/order_service.dart';

class PedidosProvider extends ChangeNotifier {
  List<OrderItemModel> _pedidos = [];
  List<HistoricoItemModel> _historico = [];

  List<OrderItemModel> get pedidos => _pedidos;
  List<HistoricoItemModel> get historico => _historico;

  Future<void> carregar(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    final pedidosJson = prefs.getString('pedidos_$userId');
    final historicoJson = prefs.getString('historico_$userId');

    if (pedidosJson != null) {
      try {
        final list = jsonDecode(pedidosJson) as List;

        _pedidos = list
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Erro ao carregar pedidos: $e');
        _pedidos = [];
      }
    }

    if (historicoJson != null) {
      try {
        final list = jsonDecode(historicoJson) as List;

        _historico = list
            .map((e) => HistoricoItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Erro ao carregar historico: $e');
        _historico = [];
      }
    }

    notifyListeners();
  }

  Future<void> adicionarPedidos({
    required String userId,
    required List<CartItemModel> cart,
    required String metodo,
    required String locationId,
    required String locationName,
    String? mesa,
    String? backendUid,
    double saldoPagamento = 0.0,
    int statusPagamento = 0,
  }) async {
    final orderId =
        backendUid ?? 'order-${DateTime.now().millisecondsSinceEpoch}';

    final existentes = backendUid == null
        ? <OrderItemModel>[]
        : _pedidos.where((item) => item.backendUid == backendUid).toList();

    if (existentes.isNotEmpty) {
      _pedidos = _pedidos.map((item) {
        if (item.backendUid != backendUid) {
          return item;
        }

        return OrderItemModel(
          id: item.id,
          orderId: item.orderId,
          productId: item.productId,
          quantity: 1,
          price: item.price,
          observations: item.observations,
          product: item.product,
          order: item.order,
          backendUid: item.backendUid,
          saldoPagamento: saldoPagamento,
          statusPagamento: statusPagamento,
        );
      }).toList();
    } else {
      final novos = <OrderItemModel>[];
      final timestamp = DateTime.now().microsecondsSinceEpoch;

      for (final item in cart) {
        for (int i = 0; i < item.qty; i++) {
          novos.add(
            OrderItemModel(
              id: '${item.cartEntryId}-unit-${i + 1}-$timestamp',
              orderId: orderId,
              productId: item.id,
              quantity: 1,
              price: item.precoUnitario,
              observations: item.observacao,
              backendUid: backendUid,
              saldoPagamento: saldoPagamento,
              statusPagamento: statusPagamento,
              product: ProductInfo(
                id: item.id,
                name: item.name,
                imageUrl: item.imageUrl,
              ),
              order: OrderInfo(
                id: orderId,
                paymentMethod: metodo,
                mesa: mesa,
                location: LocationInfo(
                  id: locationId,
                  name: locationName,
                  address: '',
                ),
              ),
            ),
          );
        }
      }

      _pedidos.addAll(novos);
    }

    await _salvarPedidosCompleto(userId);
    notifyListeners();
  }

  Future<void> atualizarStatusPagamento({
    required String userId,
    required String backendUid,
    required double saldoPagamento,
    required int statusPagamento,
  }) async {
    for (int i = 0; i < _pedidos.length; i++) {
      if (_pedidos[i].backendUid == backendUid) {
        final pedido = _pedidos[i];
        _pedidos[i] = OrderItemModel(
          id: pedido.id,
          orderId: pedido.orderId,
          productId: pedido.productId,
          quantity: pedido.quantity,
          price: pedido.price,
          observations: pedido.observations,
          product: pedido.product,
          order: pedido.order,
          backendUid: pedido.backendUid,
          saldoPagamento: saldoPagamento,
          statusPagamento: statusPagamento,
        );
      }
    }

    await _salvarPedidosCompleto(userId);
    notifyListeners();
  }

  Future<void> sincronizarComBackend({
    required String appClienteToken,
    required String appClienteUid,
    required String userId,
  }) async {
    final service = OrderService();

    final response = await service.getPedidos(
      appClienteToken: appClienteToken,
      appClienteUid: appClienteUid,
    );

    if (response is! Map) return;

    final pedidosBackend = response['pedidos'];

    if (pedidosBackend is! List) return;

    final porUid = <String, Map<String, dynamic>>{};

    for (final pedido in pedidosBackend) {
      if (pedido is! Map) continue;

      final data = Map<String, dynamic>.from(pedido);
      final uid = data['UID']?.toString() ?? data['uid']?.toString() ?? '';

      if (uid.isEmpty) continue;

      porUid[uid] = data;
    }

    _pedidos = _pedidos.map((item) {
      final backendUid = item.backendUid;

      if (backendUid == null || backendUid.isEmpty) {
        return item;
      }

      final pedido = porUid[backendUid];

      if (pedido == null) {
        return item;
      }

      final saldo = (pedido['SaldoPagamentoPedido'] as num?)?.toDouble() ?? 0.0;

      final status = (pedido['Status'] as num?)?.toInt() ?? 0;

      return OrderItemModel(
        id: item.id,
        orderId: item.orderId,
        productId: item.productId,
        quantity: item.quantity,
        price: item.price,
        observations: item.observations,
        product: item.product,
        order: item.order,
        backendUid: item.backendUid,
        saldoPagamento: saldo,
        statusPagamento: status,
      );
    }).toList();

    await _salvarPedidosCompleto(userId);

    notifyListeners();
  }

  Future<void> concluirPedido(OrderItemModel item, String userId) async {
    final backendUid = item.backendUid ?? item.orderId;

    final itensPedido = _pedidos
        .where((e) => (e.backendUid ?? e.orderId) == backendUid)
        .toList();

    if (itensPedido.isEmpty) return;

    _pedidos.removeWhere((e) => (e.backendUid ?? e.orderId) == backendUid);

    for (final pedidoItem in itensPedido) {
      _historico.insert(
        0,
        HistoricoItemModel(
          id: pedidoItem.id,
          productName: pedidoItem.product?.name ?? 'Produto',
          productImage: pedidoItem.product?.imageUrl,
          quantity: pedidoItem.quantity,
          price: pedidoItem.price,
          total: pedidoItem.total,
          createdAt: DateTime.now().toIso8601String(),
          observations: pedidoItem.observations,
          locationName: pedidoItem.order?.location?.name ?? '',
          mesa: pedidoItem.order?.mesa,
          paymentMethod: pedidoItem.order?.paymentMethod,
        ),
      );
    }

    await _salvarPedidosCompleto(userId);
    await _salvarHistoricoCompleto(userId);

    notifyListeners();
  }

  Future<void> concluirItem(String itemId, String userId) async {
    final idx = _pedidos.indexWhere((e) => e.id == itemId);
    if (idx < 0) return;

    final item = _pedidos.removeAt(idx);

    _historico.insert(
      0,
      HistoricoItemModel(
        id: item.id,
        productName: item.product?.name ?? 'Produto',
        productImage: item.product?.imageUrl,
        quantity: item.quantity,
        price: item.price,
        total: item.total,
        createdAt: DateTime.now().toIso8601String(),
        observations: item.observations,
        locationName: item.order?.location?.name ?? '',
        mesa: item.order?.mesa,
        paymentMethod: item.order?.paymentMethod,
      ),
    );

    await _salvarPedidosCompleto(userId);
    await _salvarHistoricoCompleto(userId);

    notifyListeners();
  }

  Future<void> repetirPedido({
    required String userId,
    required HistoricoItemModel item,
    required String locationId,
    required String locationName,
  }) async {
    final orderId = 'order-${DateTime.now().millisecondsSinceEpoch}';
    final itemId = 'item-${DateTime.now().millisecondsSinceEpoch}';

    final novo = OrderItemModel(
      id: itemId,
      orderId: orderId,
      productId: itemId,
      quantity: item.quantity,
      price: item.price,
      observations: item.observations,
      backendUid: null,
      saldoPagamento: 0.0,
      statusPagamento: 1,
      product: ProductInfo(
        id: itemId,
        name: item.productName,
        imageUrl: item.productImage,
      ),
      order: OrderInfo(
        id: orderId,
        paymentMethod: item.paymentMethod,
        mesa: item.mesa,
        location: LocationInfo(id: locationId, name: locationName, address: ''),
      ),
    );

    _pedidos.add(novo);

    await _salvarPedidosCompleto(userId);
    notifyListeners();
  }

  Future<void> _salvarPedidosCompleto(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'pedidos_$userId',
      jsonEncode(_pedidos.map(_orderItemToJson).toList()),
    );
  }

  Future<void> _salvarHistoricoCompleto(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'historico_$userId',
      jsonEncode(_historico.map(_historicoItemToJson).toList()),
    );
  }

  Map<String, dynamic> _orderItemToJson(OrderItemModel e) => {
    'id': e.id,
    'order_id': e.orderId,
    'product_id': e.productId,
    'quantity': e.quantity,
    'price': e.price,
    'observations': e.observations,
    'backend_uid': e.backendUid,
    'saldo_pagamento': e.saldoPagamento,
    'status_pagamento': e.statusPagamento,
    'products': {
      'id': e.product?.id ?? '',
      'name': e.product?.name ?? 'Produto',
      'image_url': e.product?.imageUrl,
    },
    'orders': {
      'id': e.order?.id ?? '',
      'payment_method': e.order?.paymentMethod ?? '',
      'mesa': e.order?.mesa,
      'locations': {
        'id': e.order?.location?.id ?? '',
        'name': e.order?.location?.name ?? '',
        'address': e.order?.location?.address ?? '',
      },
    },
  };

  Map<String, dynamic> _historicoItemToJson(HistoricoItemModel e) {
    return {
      'id': e.id,
      'product_name': e.productName,
      'product_image': e.productImage,
      'quantity': e.quantity,
      'price': e.price,
      'total': e.total,
      'created_at': e.createdAt,
      'observations': e.observations,
      'location_name': e.locationName,
      'mesa': e.mesa,
      'payment_method': e.paymentMethod,
    };
  }
}
