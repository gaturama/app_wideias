import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
    required List<Map<String, dynamic>> itens,
  }) async {
    if (_basicUser.isEmpty || _basicPassword.isEmpty) {
      throw Exception('Basic Auth não configurado');
    }

    if (appClienteToken.isEmpty) {
      throw Exception('Token do cliente não encontrado.');
    }

    if (appClienteUid.isEmpty) {
      throw Exception('UID do cliente não encontrado.');
    }

    if (itens.isEmpty) {
      throw Exception('O pedido precisa possuir pelo menos um item.');
    }

    final basicEncoded = base64Encode(
      utf8.encode('$_basicUser:$_basicPassword'),
    );

    final url = '$_baseUrl/pedidos';

    final body = {
      'pedido': {
        'cliente': appClienteUid,
        'valorTotal': valorTotal,
        'idEvento': idEvento,
        'itens': itens,
      },
    };

    debugPrint('=== CRIAR PEDIDO ===');
    debugPrint('Cliente UID presente: ${appClienteUid.isNotEmpty}');
    debugPrint('Evento: $idEvento');
    debugPrint('Valor total: $valorTotal');
    debugPrint('Quantidade de itens: ${itens.length}');

    final response = await http.post(
      Uri.parse(url),
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao criar pedido '
        '(${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      return {};
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao criar pedido.');
    }

    return data;
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
}
