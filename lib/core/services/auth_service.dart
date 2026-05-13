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

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final body = _parseBody(response.body);
        if (body == null) {
          return AuthResult(sucesso: false, erro: 'Resposta inválida da API');
        }
        if (body['erro'] != null && body['erro'].toString().isNotEmpty) {
          return AuthResult(sucesso: false, erro: body['erro'].toString());
        }
        return AuthResult(sucesso: true, dados: body);
      } else {
        return AuthResult(
          sucesso: false,
          erro: 'Email ou senha incorretos (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
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

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final body = _parseBody(response.body);
        if (body == null) {
          return AuthResult(sucesso: false, erro: 'Resposta inválida da API');
        }
        if (body['erro'] != null && body['erro'].toString().isNotEmpty) {
          return AuthResult(sucesso: false, erro: body['erro'].toString());
        }
        return AuthResult(sucesso: true, dados: body);
      } else {
        return AuthResult(
          sucesso: false,
          erro: 'Erro ao cadastrar (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      return AuthResult(sucesso: false, erro: _mensagemErro(e));
    }
  }

  static Map<String, dynamic>? _parseBody(String body) {
    try {
      final trimmed = body.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        return jsonDecode(trimmed) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
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
