import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/localizacao_model.dart';

class EventoService {
  static const String _baseUrl =
      'https://wideias.com.br/financeiro/api/externo/appwideiasclientes';

  static const String _basicUser = String.fromEnvironment('WIDEIAS_BASIC_USER');
  static const String _basicPassword = String.fromEnvironment(
    'WIDEIAS_BASIC_PASSWORD',
  );

  static Future<List<LocalizacaoModel>> buscarEventos({
    required String token,
    required String idCliente,
    required String appClienteUid,
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (_basicUser.isEmpty || _basicPassword.isEmpty) {
        throw Exception('Basic Auth não configurado.');
      }

      if (token.isEmpty) {
        throw Exception('Token do cliente não encontrado.');
      }

      if (idCliente.isEmpty) {
        throw Exception('IDCliente não encontrado.');
      }

      if (appClienteUid.isEmpty) {
        throw Exception('UID do cliente não encontrado.');
      }

      final basicEncoded = base64Encode(
        utf8.encode('$_basicUser:$_basicPassword'),
      );
      final url = Uri.parse('$_baseUrl/eventos');
      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Basic $basicEncoded',
        'AppClienteToken': token,
        'AppClienteUID': appClienteUid,
      });

      request.fields.addAll({
        'token': token,
        'idCliente': idCliente,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      });

      debugPrint('=== BUSCAR EVENTOS ===');
      debugPrint('URL: $url');
      debugPrint(
        'Basic Auth configurado: '
        '${_basicUser.isNotEmpty && _basicPassword.isNotEmpty}',
      );

      debugPrint('Token presente: ${token.isNotEmpty}');
      debugPrint('Token tamanho: ${token.length}');
      debugPrint('UID presente: ${appClienteUid.isNotEmpty}');
      debugPrint('UID tamanho: ${appClienteUid.length}');
      debugPrint('IDCliente: $idCliente');
      debugPrint('Lat: $latitude | Lng: $longitude');

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamed);

      debugPrint('HTTP EVENTOS: ${response.statusCode}');
      debugPrint('BODY EVENTOS: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Sessão inválida ou não autorizada.');
      }

      if (response.statusCode == 403) {
        throw Exception('Sem permissão para consultar eventos.');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Erro ao buscar eventos '
          '(${response.statusCode}): ${response.body}',
        );
      }

      final body = response.body.trim();
      final jsonStart = body.indexOf('[');

      if (jsonStart < 0) {
        debugPrint('Nenhum array JSON encontrado no body.');

        return [];
      }

      final jsonString = body.substring(jsonStart);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      debugPrint('Eventos encontrados: ${jsonList.length}');

      return jsonList
          .map(
            (evento) =>
                LocalizacaoModel.fromJson(Map<String, dynamic>.from(evento)),
          )
          .toList();
    } catch (e) {
      debugPrint('Exception em buscarEventos: $e');

      rethrow;
    }
  }
}