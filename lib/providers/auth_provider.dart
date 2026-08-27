import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get isLogged => _user != null;

  Future<void> carregarSessao() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      return;
    }

    _user = UserModel(
      id: prefs.getString('user_id') ?? '',
      uid: prefs.getString('user_uid') ?? '',
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
      final emailNormalizado = email.trim().toLowerCase();
      final chave = 'local_senha_$emailNormalizado';
      final senhaLocal = prefs.getString(chave);

      debugPrint('=== LOGIN LOCAL ===');
      debugPrint('Senha local encontrada: ${senhaLocal != null}');

      if (senhaLocal != null) {
        if (senhaLocal != senha) {
          _loading = false;
          notifyListeners();

          return 'Senha incorreta';
        }

        final dadosJson = prefs.getString('local_dados_$emailNormalizado');

        if (dadosJson != null) {
          final dados = jsonDecode(dadosJson) as Map<String, dynamic>;

          final uid = dados['uid']?.toString() ?? '';

          if (uid.isNotEmpty) {
            _user = UserModel(
              id: dados['id']?.toString() ?? '',
              uid: uid,
              nome: dados['nome']?.toString() ?? '',
              email: dados['email']?.toString() ?? emailNormalizado,
              telefone: dados['telefone']?.toString() ?? '',
              token: dados['token']?.toString() ?? '',
            );

            await _salvarSessao(_user!);
            _loading = false;
            notifyListeners();
            return null;
          }

          debugPrint(
            'Sessão local antiga sem UID. '
            'Atualizando sessão pela API.',
          );
        }
      }

      final result = await AuthService.login(
        email: emailNormalizado,
        senha: senha,
      );

      if (result.sucesso && result.dados != null) {
        final dados = result.dados!;
        final idCliente = dados['IDCliente']?.toString() ?? '';
        final uid = dados['UID']?.toString() ?? '';
        final token = dados['Token']?.toString() ?? '';

        debugPrint('Login realizado com sucesso.');
        debugPrint(
          'IDCliente recebido: '
          '${idCliente.isNotEmpty}',
        );
        debugPrint('UID recebido: ${uid.isNotEmpty}');
        debugPrint('Token recebido: ${token.isNotEmpty}');

        _user = UserModel(
          id: idCliente,
          uid: uid,
          nome: dados['Nome']?.toString() ?? '',
          email: dados['Email']?.toString() ?? emailNormalizado,
          telefone: dados['Telefone']?.toString() ?? '',
          token: token,
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
      debugPrint('Exception no AuthProvider.login: $e');

      _loading = false;
      notifyListeners();
      return 'Erro inesperado: $e';
    }
  }

  Future<void> redefinirSenhaLocal(String email, String novaSenha) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveEmail = email.trim().toLowerCase();
    await prefs.setString('local_senha_$chaveEmail', novaSenha);
    final id = _user?.id ?? prefs.getString('user_id') ?? '';
    final uid = _user?.uid ?? prefs.getString('user_uid') ?? '';
    final nome = _user?.nome ?? prefs.getString('user_nome') ?? '';
    final telefone = _user?.telefone ?? prefs.getString('user_phone') ?? '';
    final token = _user?.token ?? prefs.getString('token') ?? '';

    if (token.isNotEmpty) {
      await prefs.setString(
        'local_dados_$chaveEmail',
        jsonEncode({
          'id': id,
          'uid': uid,
          'nome': nome,
          'email': chaveEmail,
          'telefone': telefone,
          'token': token,
        }),
      );

      debugPrint('Dados locais da sessão atualizados.');
    }
  }

  Future<bool> emailTemSenhaLocal(String email) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.containsKey('local_senha_${email.trim().toLowerCase()}');
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

    try {
      final result = await AuthService.cadastrar(
        nome: nome,
        cpf: cpf,
        email: email,
        senha: senha,
        telefone: telefone,
        nascimento: nascimento,
      );

      if (result.sucesso && result.dados != null) {
        final dados = result.dados!;
        final idCliente = dados['IDCliente']?.toString() ?? '';
        final uid = dados['UID']?.toString() ?? '';
        final token = dados['Token']?.toString() ?? dados['token']?.toString() ?? '';

        _user = UserModel(
          id: idCliente,
          uid: uid,
          nome: nome,
          email: email,
          telefone: telefone,
          token: token,
        );

        await _salvarSessao(_user!);
        _loading = false;
        notifyListeners();
        return null;
      }

      _loading = false;
      notifyListeners();

      return result.erro ?? 'Erro ao cadastrar';
    } catch (e) {
      _loading = false;
      notifyListeners();
      return 'Erro inesperado: $e';
    }
  }

  Future<void> logout() async {
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_uid');
    await prefs.remove('user_nome');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');

    notifyListeners();
  }

  Future<void> _salvarSessao(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', user.token);
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_uid', user.uid);
    await prefs.setString('user_nome', user.nome);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_phone', user.telefone);
  }

  Future<void> atualizarPerfil({
    required String nome,
    required String telefone,
  }) async {
    if (_user == null) {
      return;
    }

    _user = UserModel(
      id: _user!.id,
      uid: _user!.uid,
      nome: nome,
      email: _user!.email,
      telefone: telefone,
      token: _user!.token,
    );

    await _salvarSessao(_user!);
    notifyListeners();
  }
}
