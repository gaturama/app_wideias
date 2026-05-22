import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_alert.dart';
import '../login/login_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _nascimentoCtrl = TextEditingController();
  bool _showSenha = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _telefoneCtrl.dispose();
    _nascimentoCtrl.dispose();
    super.dispose();
  }

  bool _validar() {
    final nome = _nomeCtrl.text.trim();
    final cpf = _cpfCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;
    final telefone = _telefoneCtrl.text.trim();
    final nascimento = _nascimentoCtrl.text.trim();

    if ([nome, cpf, email, senha, telefone, nascimento].any((v) => v.isEmpty)) {
      _alerta('Erro', 'Preencha todos os campos!');
      return false;
    }
    if (senha.length < 4) {
      _alerta('Erro', 'A senha deve ter pelo menos 4 caracteres!');
      return false;
    }
    if (!_cpfValido(cpf)) {
      _alerta('Erro', 'CPF inválido! Verifique os números digitados.');
      return false;
    }
    if (telefone.length < 10) {
      _alerta('Erro', 'Telefone inválido!');
      return false;
    }
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(nascimento)) {
      _alerta('Erro', 'Data inválida! Use o formato AAAA-MM-DD');
      return false;
    }
    return true;
  }

  bool _cpfValido(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'\D'), '');

    if (cpf.length != 11) return false;

    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }
    int resto = (soma * 10) % 11;
    if (resto == 10 || resto == 11) resto = 0;
    if (resto != int.parse(cpf[9])) return false;

    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }
    resto = (soma * 10) % 11;
    if (resto == 10 || resto == 11) resto = 0;
    if (resto != int.parse(cpf[10])) return false;

    return true;
  }

  Future<void> _handleCadastro() async {
    if (!_validar()) return;

    final auth = context.read<AuthProvider>();
    final erro = await auth.cadastrar(
      nome: _nomeCtrl.text.trim(),
      cpf: _cpfCtrl.text.trim(),
      email: _emailCtrl.text.trim().toLowerCase(),
      senha: _senhaCtrl.text,
      telefone: _telefoneCtrl.text.trim(),
      nascimento: _nascimentoCtrl.text.trim(),
    );

    if (!mounted) return;

    if (erro == null) {
      CustomAlert.show(
        dialogContext: context,
        context,
        title: 'Cadastro realizado!',
        message: 'Bem vindo, ${_nomeCtrl.text.trim()}!',
        confirmText: 'Entrar',
        onConfirm: () => Navigator.of(context).pushReplacementNamed('/login'),
      );
    } else {
      _alerta('Erro no cadastro', erro);
    }
  }

  void _alerta(String title, String message) =>
      CustomAlert.show(dialogContext: context, context, title: title, message: message);

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardDismissOnTap(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildField(
                      label: 'NOME COMPLETO',
                      controller: _nomeCtrl,
                      hint: 'Seu nome completo',
                      icon: Icons.person_outline,
                      capitalize: TextCapitalization.words,
                      enabled: !loading,
                    ),
                    _buildField(
                      label: 'CPF',
                      controller: _cpfCtrl,
                      hint: '12345678900',
                      icon: Icons.credit_card_outlined,
                      keyboard: TextInputType.number,
                      maxLength: 11,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: !loading,
                    ),
                    _buildField(
                      label: 'E-MAIL',
                      controller: _emailCtrl,
                      hint: 'seu@email.com',
                      icon: Icons.mail_outline,
                      keyboard: TextInputType.emailAddress,
                      enabled: !loading,
                    ),
                    _buildField(
                      label: 'SENHA',
                      controller: _senhaCtrl,
                      hint: 'Mínimo 4 caracteres',
                      icon: Icons.lock_outline,
                      obscure: !_showSenha,
                      enabled: !loading,
                      suffix: IconButton(
                        icon: Icon(
                          _showSenha ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSection,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showSenha = !_showSenha),
                      ),
                    ),
                    _buildField(
                      label: 'TELEFONE',
                      controller: _telefoneCtrl,
                      hint: '47999999999',
                      icon: Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                      maxLength: 11,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: !loading,
                    ),
                    _buildField(
                      label: 'DATA DE NASCIMENTO',
                      controller: _nascimentoCtrl,
                      hint: 'AAAA-MM-DD',
                      icon: Icons.calendar_today_outlined,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : _handleCadastro,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bluePrimary,
                          disabledBackgroundColor: AppColors.textEmpty,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'CADASTRAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Link login
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pushReplacementNamed('/login'),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          text: 'Já tem uma conta? ',
                          style: TextStyle(
                            color: AppColors.textSection,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Entrar',
                              style: TextStyle(
                                color: AppColors.bluePrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.bluePrimary,
      padding: const EdgeInsets.only(top: 52, bottom: 20),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -30,
            child: _circle(140, AppColors.circleDeco1),
          ),
          Positioned(
            bottom: -20,
            left: -30,
            child: _circle(100, AppColors.circleDeco2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Criar conta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 44),
                  child: Text(
                    'Preencha os dados abaixo para começar',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization capitalize = TextCapitalization.none,
    bool obscure = false,
    bool enabled = true,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textSection,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(icon, color: AppColors.textSection, size: 18),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboard,
                    textCapitalization: capitalize,
                    obscureText: obscure,
                    enabled: enabled,
                    maxLength: maxLength,
                    inputFormatters: inputFormatters,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(color: AppColors.textEmpty),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (suffix != null) suffix,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
