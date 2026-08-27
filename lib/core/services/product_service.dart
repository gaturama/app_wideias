import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProductService {
  static const String _baseUrl =
      'https://wideias.com.br/financeiro/api/externo/appwideiasclientes';

  static const String _basicUser = String.fromEnvironment('WIDEIAS_BASIC_USER');
  static const String _basicPassword = String.fromEnvironment(
    'WIDEIAS_BASIC_PASSWORD',
  );

  Future<Map<String, dynamic>> getCardapio({
    required String appClienteToken,
    required String appClientUid,
    required String cardapioId,
  }) async {
    if (_basicUser.isEmpty || _basicPassword.isEmpty) {
      throw Exception('Usuário ou senha do Basic Auth não configurados.');
    }

    final basicCredentials = '$_basicUser:$_basicPassword';
    final basicEncoded = base64Encode(utf8.encode(basicCredentials));
    final url = '$_baseUrl/cardapios/$cardapioId';

    debugPrint('=== CARDÁPIO ===');
    debugPrint('URL: $url');
    debugPrint(
      'Basic Auth configurado: '
      '${_basicUser.isNotEmpty && _basicPassword.isNotEmpty}',
    );

    debugPrint('UID disponível: ${appClientUid.isNotEmpty}');

    debugPrint('Token disponível: ${appClienteToken.isNotEmpty}');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Basic $basicEncoded',
        'AppClienteToken': appClienteToken,
        'AppClientUID': appClientUid,
      },
    );

    debugPrint('HTTP CARDÁPIO: ${response.statusCode}');
    debugPrint('BODY CARDÁPIO: ${response.body}');

    if (response.statusCode == 401) {
      throw Exception('Não autorizado ao acessar o cardápio.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao carregar produtos '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do endpoint de cardápio.');
    }

    return data;
  }
}
