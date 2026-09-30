import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CreditService {
  static const String _baseUrl =
      'https://wideias.com.br/financeiro/api/externo/appwideiasclientes';
  static const String _basicUser = String.fromEnvironment('WIDEIAS_BASIC_USER');
  static const String _basicPassword = String.fromEnvironment(
    'WIDEIAS_BASIC_PASSWORD',
  );

  String _basicAuth() {
    if (_basicUser.isEmpty || _basicPassword.isEmpty) {
      throw Exception('Basic Auth não configurado.');
    }
    return base64Encode(utf8.encode('$_basicUser:$_basicPassword'));
  }

  Future<Map<String, dynamic>> getCreditos({
    required String appClienteToken,
    required String appClienteUid,
  }) async {
    if (appClienteToken.isEmpty) {
      throw Exception('Token do cliente não encontrado.');
    }
    if (appClienteUid.isEmpty) {
      throw Exception('UID do cliente não encontrado.');
    }

    final basicEncoded = _basicAuth();
    final url = '$_baseUrl/creditos/$appClienteUid';

    debugPrint('=== REQUEST CRÉDITOS ===');
    debugPrint('URL: $url');
    debugPrint('UID: $appClienteUid');
    debugPrint('Token presente: ${appClienteToken.isNotEmpty}');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Basic $basicEncoded',
        'AppClienteToken': appClienteToken,
        'AppClienteUID': appClienteUid,
      },
    );

    debugPrint('HTTP CRÉDITOS: ${response.statusCode}');
    debugPrint('BODY CRÉDITOS: ${response.body}');

    if (response.statusCode == 401) {
      throw Exception('Sessão inválida ou não autorizada.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao consultar créditos (${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      return {};
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao consultar créditos.');
    }

    return data;
  }

  Future<Map<String, dynamic>> criarCredito({
    required String appClienteToken,
    required String appClienteUid,
    required double valor,
  }) async {
    if (appClienteToken.isEmpty) {
      throw Exception('Token do cliente não encontrado.');
    }
    if (appClienteUid.isEmpty) {
      throw Exception('UID do cliente não encontrado.');
    }
    if (valor <= 0) {
      throw Exception('Valor do crédito inválido.');
    }

    final basicEncoded = _basicAuth();
    final url = '$_baseUrl/creditos';

    debugPrint('=== CRIAR CRÉDITO ===');
    debugPrint('URL: $url');
    debugPrint('Cliente: $appClienteUid');
    debugPrint('Valor: $valor');

    final request = http.MultipartRequest('POST', Uri.parse(url));

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Basic $basicEncoded',
      'AppClienteToken': appClienteToken,
      'AppClienteUID': appClienteUid,
    });

    request.fields['cliente'] = appClienteUid;
    request.fields['valor'] = valor.toStringAsFixed(2);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('HTTP CRIAR CRÉDITO: ${response.statusCode}');
    debugPrint('BODY CRIAR CRÉDITO: ${response.body}');

    if (response.statusCode == 401) {
      throw Exception('Sessão inválida ou não autorizada.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao criar crédito (${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      return {};
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao criar crédito.');
    }

    return data;
  }

  Future<Map<String, dynamic>> atualizarPagamentoCredito({
    required String creditoUid,
    required String appClienteToken,
    required String appClienteUid,
    required Map<String, dynamic> pagamento,
  }) async {
    if (creditoUid.isEmpty) {
      throw Exception('UID do crédito não encontrado.');
    }
    if (appClienteToken.isEmpty) {
      throw Exception('Token do cliente não encontrado.');
    }
    if (appClienteUid.isEmpty) {
      throw Exception('UID do cliente não encontrado.');
    }

    final basicEncoded = _basicAuth();
    final url = '$_baseUrl/creditos/atualizarpagamento/$creditoUid';

    debugPrint('=== ATUALIZAR PAGAMENTO CRÉDITO ===');
    debugPrint('URL: $url');
    debugPrint('Crédito UID: $creditoUid');
    debugPrint('Token presente: ${appClienteToken.isNotEmpty}');
    debugPrint('Cliente UID: $appClienteUid');

    final body = {'pagamento': pagamento};

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

    debugPrint('HTTP ATUALIZAR CRÉDITO: ${response.statusCode}');
    debugPrint('BODY ATUALIZAR CRÉDITO: ${response.body}');

    if (response.statusCode == 401) {
      throw Exception('Sessão inválida ou não autorizada.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao atualizar pagamento do crédito '
        '(${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      return {};
    }

    final data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Resposta inválida ao atualizar crédito.');
  }
}
