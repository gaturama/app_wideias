import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/localizacao_model.dart';

class EventoService {
  static const String _baseUrl =
      'https://wideias.com.br/financeiro/api/externo/appwideiasclientes';
  static const String _authToken =
      'Basic V2lkZWlhc0NsaWVudGVzOmI4Y2Q4ZjNlMTI4MDMyY2I0M2FhMGRiNzRmNmFiNTFk';

  static Future<List<LocalizacaoModel>> buscarEventos({
    required String token,
    required String idCliente,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/eventos'),
      );
      request.headers['Authorization'] = _authToken;
      request.fields['token'] = token;
      request.fields['idCliente'] = idCliente;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      print('=== BUSCAR EVENTOS ===');
      print('URL: $_baseUrl/eventos');
      print('Fields: ${request.fields}');

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      print('HTTP Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body.trim();
        final jsonStart = body.indexOf('[');
        if (jsonStart < 0) {
          print('Nenhum array JSON encontrado no body');
          return [];
        }
        final jsonStr = body.substring(jsonStart);
        final List<dynamic> json = jsonDecode(jsonStr);
        print('Eventos encontrados: ${json.length}');
        return json
            .map((e) => LocalizacaoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      print('Erro HTTP: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Exception em buscarEventos: $e');
      throw Exception('Erro ao buscar eventos: $e');
    }
  }
}