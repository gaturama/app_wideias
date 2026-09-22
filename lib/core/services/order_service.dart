import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wideias_app/models/cart_item_model.dart';

class OrderService {
  static const String _baseUrl =
      'https://wideias.com.br/financeiro/api/externo/appwideiasclientes';

  static const String _basicUser = String.fromEnvironment('WIDEIAS_BASIC_USER');

  static const String _basicPassword = String.fromEnvironment(
    'WIDEIAS_BASIC_PASSWORD',
  );

  Future<Map<String, dynamic>> criarPedido({
    required String appClienteToken,
    required String appClienteUid,
    required int idEvento,
    required double valorTotal,
    required List<CartItemModel> cart,
    String? observacao,
  }) async {
    final basicEncoded = base64Encode(
      utf8.encode('$_basicUser:$_basicPassword'),
    );

    final itens = cart.map((item) {
      final idProduto = int.tryParse(item.id);

      if (idProduto == null || idProduto <= 0) {
        throw Exception('ID inválido para o produto "${item.name}".');
      }

      return {
        'idProduto': idProduto,
        'idCardapio': item.idCardapio,
        'quantidade': item.qty,
        'obs': item.observacao,
      };
    }).toList();

    final body = {
      'pedido': {
        'cliente': appClienteUid,
        'valorTotal': valorTotal,
        'idEvento': idEvento,
        'obs': observacao?.trim().isEmpty == true ? null : observacao?.trim(),
        'itens': itens,
      },
    };

    debugPrint('=== CRIAR PEDIDO ===');
    debugPrint('Cliente UID presente: ${appClienteUid.isNotEmpty}');
    debugPrint('Evento: $idEvento');
    debugPrint('Valor total: $valorTotal');
    debugPrint('Quantidade de itens: ${itens.length}');

    final response = await http.post(
      Uri.parse('$_baseUrl/pedidos'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Basic $basicEncoded',
        'AppClienteToken': appClienteToken,
        'AppClienteUID': appClienteUid,
      },
      body: jsonEncode(body),
    );

    debugPrint('HTTP PEDIDO: ${response.statusCode}');
    debugPrint('BODY PEDIDO: ${response.body}');

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded is Map && decoded['erro'] != null
            ? decoded['erro'].toString()
            : 'Erro ao criar pedido.',
      );
    }

    if (decoded is! Map) {
      throw Exception('Resposta inválida ao criar pedido.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<dynamic> getPedidos({
    required String appClienteToken,
    required String appClienteUid,
  }) async {
    if (_basicUser.isEmpty || _basicPassword.isEmpty) {
      throw Exception('Basic Auth não configurado.');
    }

    if (appClienteToken.isEmpty) {
      throw Exception('Token do cliente não encontrado.');
    }

    if (appClienteUid.isEmpty) {
      throw Exception('UID do cliente não encontrado.');
    }

    final basicEncoded = base64Encode(
      utf8.encode('$_basicUser:$_basicPassword'),
    );

    final url = '$_baseUrl/pedidos/$appClienteUid';

    debugPrint('=== CONSULTAR PEDIDOS ===');
    debugPrint('URL: $url');
    debugPrint('UID disponível: ${appClienteUid.isNotEmpty}');
    debugPrint('Token disponível: ${appClienteToken.isNotEmpty}');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Basic $basicEncoded',
        'AppClienteToken': appClienteToken,
        'AppClienteUID': appClienteUid,
      },
    );

    debugPrint('HTTP PEDIDOS: ${response.statusCode}');

    debugPrint('BODY PEDIDOS: ${response.body}');

    if (response.statusCode == 401) {
      throw Exception('Sessão inválida ou não autorizada.');
    }

    if (response.statusCode == 403) {
      throw Exception('Sem permissão para consultar os pedidos.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao consultar pedidos '
        '(${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      return null;
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> registrarPagamentoPedido({
    required String appClienteToken,
    required String appClienteUid,
    required String pedidoUid,
    required String transactionCode,
    required String transactionID,
    required String nsu,
    required String bin,
    required String autoCode,
    required String cardBrand,
    required String idTipoPagamento,
    required String status,
    required double valor,
  }) async {
    if (_basicUser.isEmpty || _basicPassword.isEmpty) {
      throw Exception('Basic Auth não configurado.');
    }

    if (appClienteToken.isEmpty) {
      throw Exception('Token do cliente não encontrado.');
    }

    if (appClienteUid.isEmpty) {
      throw Exception('UID do cliente não encontrado.');
    }

    if (pedidoUid.isEmpty) {
      throw Exception('UID do pedido não encontrado.');
    }

    final basicEncoded = base64Encode(
      utf8.encode('$_basicUser:$_basicPassword'),
    );

    final body = {
      'pedido': pedidoUid,
      'pagamento': {
        'transactionCode': transactionCode,
        'transactionID': transactionID,
        'nsu': nsu,
        'bin': bin,
        'autoCode': autoCode,
        'cardBrand': cardBrand,
        'idTipoPagamento': idTipoPagamento,
        'status': status,
        'valor': valor,
      },
    };

    debugPrint('=== REGISTRAR PAGAMENTO PEDIDO ===');
    debugPrint('Pedido UID: $pedidoUid');
    debugPrint('Tipo pagamento: $idTipoPagamento');
    debugPrint('Status: $status');
    debugPrint('Valor: $valor');

    final response = await http.post(
      Uri.parse('$_baseUrl/pedidos/pagamento'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Basic $basicEncoded',
        'AppClienteToken': appClienteToken,
        'AppClienteUID': appClienteUid,
      },
      body: jsonEncode(body),
    );

    debugPrint('HTTP PAGAMENTO PEDIDO: ${response.statusCode}');
    debugPrint('BODY PAGAMENTO PEDIDO: ${response.body}');

    dynamic decoded;

    if (response.body.trim().isNotEmpty) {
      decoded = jsonDecode(response.body);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded is Map && decoded['erro'] != null
            ? decoded['erro'].toString()
            : 'Erro ao registrar pagamento do pedido.',
      );
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return {};
  }
}
