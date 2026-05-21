import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthResult {
  final bool sucesso;
  final String? erro;
  final Map<String, dynamic>? dados;

  AuthResult({required this.sucesso, this.erro, this.dados});
}

class AuthService {
  static const String _baseUrl =
      'https://wideias.com.br/financeiro/api/externo/appwideiasclientes';
  static const String _authToken =
      'Basic V2lkZWlhc0NsaWVudGVzOmI4Y2Q4ZjNlMTI4MDMyY2I0M2FhMGRiNzRmNmFiNTFk';

  static Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/login'),
      );
      request.headers['Authorization'] = _authToken;
      request.fields['email'] = email.trim().toLowerCase();
      request.fields['senha'] = senha;

      print('=== LOGIN ===');
      print('URL: $_baseUrl/login');
      print('Email: $email');

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      print('HTTP Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = _parseBody(response.body);
        print('Body parseado: $body');

        if (body == null) {
          return AuthResult(sucesso: false, erro: 'Resposta inválida da API');
        }
        if (body['erro'] != null && body['erro'].toString().isNotEmpty) {
          return AuthResult(sucesso: false, erro: body['erro'].toString());
        }
        return AuthResult(sucesso: true, dados: body);
      } else {
        String mensagemErro =
            'Email ou senha incorretos (HTTP ${response.statusCode})';
        try {
          final bodyErro = _parseBody(response.body);
          if (bodyErro != null) {
            mensagemErro =
                bodyErro['erro']?.toString() ??
                bodyErro['message']?.toString() ??
                mensagemErro;
          }
        } catch (_) {}
        print('Erro login: $mensagemErro');
        return AuthResult(sucesso: false, erro: mensagemErro);
      }
    } catch (e) {
      print('Exception no login: $e');
      return AuthResult(sucesso: false, erro: _mensagemErro(e));
    }
  }

  static Future<AuthResult> cadastrar({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
    required String telefone,
    required String nascimento,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/cadastrar'),
      );
      request.headers['Authorization'] = _authToken;
      request.fields['nome'] = nome.trim();
      request.fields['cpf'] = cpf;
      request.fields['email'] = email.trim().toLowerCase();
      request.fields['senha'] = senha;
      request.fields['telefone'] = telefone;
      request.fields['nascimento'] = nascimento;

      print('==== CADASTRO ====');
      print('URL: $_baseUrl/cadastrar');
      print('Campos: ${request.fields}');

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      print('HTTP Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = _parseBody(response.body);
        print('Body parseado: $body');

        if (body == null) {
          return AuthResult(sucesso: false, erro: 'Resposta inválida da API');
        }

        final resultado = body['Resultado']?.toString();
        if (resultado == 'OK') {
          return AuthResult(sucesso: true, dados: body);
        }

        if (body['erro'] != null && body['erro'].toString().isNotEmpty) {
          return AuthResult(sucesso: false, erro: body['erro'].toString());
        }
        return AuthResult(sucesso: true, dados: body);
      } else {
        String mensagemErro = 'Erro ao cadastrar (HTTP ${response.statusCode})';
        try {
          final bodyErro = _parseBody(response.body);
          if (bodyErro != null) {
            mensagemErro =
                bodyErro['erro']?.toString() ??
                bodyErro['message']?.toString() ??
                bodyErro['Resultado']?.toString() ??
                mensagemErro;
          }
        } catch (_) {}
        print('Erro: $mensagemErro');
        return AuthResult(sucesso: false, erro: mensagemErro);
      }
    } catch (e) {
      return AuthResult(sucesso: false, erro: _mensagemErro(e));
    }
  }

  static Map<String, dynamic>? _parseBody(String body) {
    try {
      final trimmed = body.trim().replaceAll('\r', '').replaceAll('\n', '');

      final jsonStart = trimmed.indexOf('{');
      final jsonStartArray = trimmed.indexOf('[');

      int start = -1;
      if (jsonStart >= 0 && jsonStartArray >= 0) {
        start = jsonStart < jsonStartArray ? jsonStart : jsonStartArray;
      } else if (jsonStart >= 0) {
        start = jsonStart;
      } else if (jsonStartArray >= 0) {
        start = jsonStartArray;
      }

      if (start < 0) return null;

      final jsonStr = trimmed.substring(start);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao parsear body: $e');
      print('Body original: $body');
      return null;
    }
  }

  static String _mensagemErro(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Failed host')) {
      return 'Sem conexão com a internet.';
    }
    if (msg.contains('TimeoutException')) {
      return 'Tempo de conexão esgotado.';
    }
    return 'Erro inesperado. Tente novamente.';
  }
}
