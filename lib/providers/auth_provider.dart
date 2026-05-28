import 'dart:convert';
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
      final prefs = await SharedPreferences.getInstance();
      final chave = 'local_senha_${email.toLowerCase()}';
      final senhaLocal = prefs.getString(chave);

      print('=== LOGIN LOCAL ===');
      print('Chave buscada: $chave');
      print('Senha local encontrada: ${senhaLocal != null}');

      if (senhaLocal != null) {
        if (senhaLocal != senha) {
          _loading = false;
          notifyListeners();
          return 'Senha incorreta';
        }

        final dadosJson = prefs.getString('local_dados_${email.toLowerCase()}');
        if (dadosJson == null) {
          _loading = false;
          notifyListeners();
          return 'Sessão expirada. Faça login com a senha original primeiro.';
        }

        final dados = jsonDecode(dadosJson) as Map<String, dynamic>;
        _user = UserModel(
          id: dados['id']?.toString() ?? '',
          nome: dados['nome']?.toString() ?? '',
          email: dados['email']?.toString() ?? email,
          telefone: dados['telefone']?.toString() ?? '',
          token: dados['token']?.toString() ?? '',
        );

        await _salvarSessao(_user!);
        _loading = false;
        notifyListeners();
        return null;
      }

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

  Future<void> redefinirSenhaLocal(String email, String novaSenha) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveEmail = email.toLowerCase();

    await prefs.setString('local_senha_$chaveEmail', novaSenha);

    final id = _user?.id ?? prefs.getString('user_id') ?? '';
    final nome = _user?.nome ?? prefs.getString('user_nome') ?? '';
    final telefone = _user?.telefone ?? prefs.getString('user_phone') ?? '';
    final token = _user?.token ?? prefs.getString('token') ?? '';

    if (token.isNotEmpty) {
      await prefs.setString(
        'local_dados_$chaveEmail',
        jsonEncode({
          'id': id,
          'nome': nome,
          'email': email,
          'telefone': telefone,
          'token': token,
        }),
      );
      print('=== SENHA SALVA ===');
      print('Chave salva: local_senha_$chaveEmail');
      print('Dados salvos: true');
    } else {
      print('=== SENHA SALVA ===');
      print('Chave salva: local_senha_$chaveEmail');
      print('AVISO: token vazio — snapshot não salvo');
    }
  }

  Future<bool> emailTemSenhaLocal(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('local_senha_${email.toLowerCase()}');
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
