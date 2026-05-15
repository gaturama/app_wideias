import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_colors.dart';
import '../../models/localizacao_model.dart';

class EventoService {
  static const String _baseUrl =
      'https://wideias.com.br/financeiro/api/externo/appwideiasclientes/eventos';
  static const String _authToken =
      'Basic V2lkZWlhc0NsaWVudGVzOmI4Y2Q4ZjNlMTI4MDMyY2I0M2FhMGRiNzRmNmFiNTFk';

  static Future<List<LocalizacaoModel>> buscarEventos({
    required String token,
    required String idCliente,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/eventos').replace(
        queryParameters: {
          'token': token,
          'id_cliente': idCliente,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      );

      final response = await http.get(uri, headers: {
        'Authorization': _authToken,
      }).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (!body.startsWith('[') && !body.startsWith('{')) {
          return [];
        }
        final List<dynamic> json = jsonDecode(body);
        return json
            .map((e) => LocalizacaoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Erro ao buscar eventos: $e');
    }
  }
}
