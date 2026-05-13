import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/order_item_model.dart';
import '../models/historico_item_model.dart';

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
      final list = jsonDecode(pedidosJson) as List;
      _pedidos = list
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (historicoJson != null) {
      final list = jsonDecode(historicoJson) as List;
      _historico = list
          .map((e) => HistoricoItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    notifyListeners();
  }

  Future<void> salvarPedidos(String userId, List<OrderItemModel> itens) async {
    _pedidos = itens;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pedidos_$userId',
      jsonEncode(
        itens
            .map(
              (e) => {
                'id': e.id,
                'order_id': e.orderId,
                'product_id': e.productId,
                'quantity': e.quantity,
                'price': e.price,
                'observations': e.observations,
              },
            )
            .toList(),
      ),
    );
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pedidos_$userId',
      jsonEncode(_pedidos.map((e) => {'id': e.id}).toList()),
    );
    await prefs.setString(
      'historico_$userId',
      jsonEncode(_historico.map((e) => {'id': e.id}).toList()),
    );

    notifyListeners();
  }
}
