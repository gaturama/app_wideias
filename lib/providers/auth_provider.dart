import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../core/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get isLogged => _user != null;

  Future<void> carregarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    _user = UserModel(
      id: prefs.getString('user_id') ?? '',
      nome: prefs.getString('user_nome') ?? '',
      email: prefs.getString('user_email') ?? '',
      telefone: prefs.getString('user_phone') ?? '',
      token: token,
    );
    notifyListeners();
  }

  Future<String?> login(String email, String senha) async {
    _loading = true;
    notifyListeners();

    try {
      final result = await AuthService.login(email: email, senha: senha);

      if (result.sucesso && result.dados != null) {
        final dados = result.dados!;

        print('Usuario retornado: ${dados['Nome']}');
        print('Token: ${dados['Token']}');

        _user = UserModel(
          id: dados['IDCliente']?.toString() ?? '',
          nome: dados['Nome']?.toString() ?? '',
          email: dados['Email']?.toString() ?? email,
          telefone: dados['Telefone']?.toString() ?? '',
          token: dados['Token']?.toString() ?? '', 
        );

        await _salvarSessao(_user!);
        _loading = false;
        notifyListeners();
        return null;
      }

      _loading = false;
      notifyListeners();
      return result.erro ?? 'Erro ao fazer login';
    } catch (e) {
      print('Exception no AuthProvider.login: $e');
      _loading = false;
      notifyListeners();
      return 'Erro inesperado: $e';
    }
  }

  Future<String?> cadastrar({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
    required String telefone,
    required String nascimento,
  }) async {
    _loading = true;
    notifyListeners();

    final result = await AuthService.cadastrar(
      nome: nome,
      cpf: cpf,
      email: email,
      senha: senha,
      telefone: telefone,
      nascimento: nascimento,
    );
    _loading = false;

    if (result.sucesso && result.dados != null) {
      final dados = result.dados!;
      final token = dados['token']?.toString() ?? 'token_placeholder';
      final userId = dados['IDCliente']?.toString() ?? '';

      _user = UserModel(
        id: userId,
        nome: nome,
        email: email,
        telefone: telefone,
        token: token,
      );

      await _salvarSessao(_user!);
      notifyListeners();
      return null;
    }

    notifyListeners();
    return result.erro ?? 'Erro ao cadastrar';
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_nome');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    notifyListeners();
  }

  Future<void> _salvarSessao(UserModel u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', u.token);
    await prefs.setString('user_id', u.id);
    await prefs.setString('user_nome', u.nome);
    await prefs.setString('user_email', u.email);
    await prefs.setString('user_phone', u.telefone);
  }

  Future<void> atualizarPerfil({
    required String nome,
    required String telefone,
  }) async {
    if (_user == null) return;
    _user = UserModel(
      id: _user!.id,
      nome: nome,
      email: _user!.email,
      telefone: telefone,
      token: _user!.token,
    );
    await _salvarSessao(_user!);
    notifyListeners();
  }
}
