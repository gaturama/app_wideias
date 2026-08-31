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

  Future<Map<String, dynamic>> getCreditos({
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

    final url = '$_baseUrl/creditos/$appClienteUid';

    debugPrint('=== REQUEST CRÉDITOS ===');
    debugPrint('URL: $url');
    debugPrint(
      'Basic Auth configurado: ${_basicUser.isNotEmpty && _basicPassword.isNotEmpty}',
    );
    debugPrint('UID: $appClienteUid');
    debugPrint('UID tamanho: ${appClienteUid.length}');
    debugPrint('Token presente: ${appClienteToken.isNotEmpty}');
    debugPrint('Token tamanho: ${appClienteToken.length}');

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
        'Erro ao consultar créditos'
        '(${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao consultar créditos.');
    }

    return data;
  }
}
