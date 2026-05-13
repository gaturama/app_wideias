import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_alert.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl  = TextEditingController();
  final _senhaCtrl  = TextEditingController();
  bool _showSenha   = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  bool _validar() {
    if (_emailCtrl.text.trim().isEmpty) {
      CustomAlert.show(context, title: 'Erro', message: 'Informe o email');
      return false;
    }
    if (_senhaCtrl.text.trim().isEmpty) {
      CustomAlert.show(context, title: 'Erro', message: 'Informe a senha');
      return false;
    }
    return true;
  }

  Future<void> _handleLogin() async {
    if (!_validar()) return;

    final auth  = context.read<AuthProvider>();
    final erro  = await auth.login(
      _emailCtrl.text.trim().toLowerCase(),
      _senhaCtrl.text.trim(),
    );

    if (!mounted) return;

    if (erro == null) {
      CustomAlert.show(
        context,
        title:       'Bem vindo!',
        message:     'Login realizado com sucesso',
        confirmText: 'OK',
        onConfirm:   () => Navigator.of(context)
            .pushReplacementNamed('/localizacao'),
      );
    } else {
      CustomAlert.show(
        context,
        title:   'Erro na autenticação',
        message: erro,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardDismissOnTap(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildHeroCard(),
              _buildForm(loading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Círculos decorativos
          Positioned(
            top: -30, right: -30,
            child: _circle(120, AppColors.circleDeco1),
          ),
          Positioned(
            bottom: -20, left: -20,
            child: _circle(90, AppColors.circleDeco2),
          ),
          Positioned(
            top: 10, left: -40,
            child: _circle(80, AppColors.circleDeco2),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Logo
                Image.asset(
                  'assets/images/ic_logo_wideias.png',
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.storefront,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: 'Peça sem sair do lugar.\n',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: 'Seu pedido chega até você.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool loading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel('E-MAIL'),
          _buildInput(
            controller:  _emailCtrl,
            hint:        'user@email.com',
            icon:        Icons.mail_outline,
            keyboard:    TextInputType.emailAddress,
            enabled:     !loading,
          ),
          const SizedBox(height: 16),

          _buildLabel('SENHA'),
          _buildInput(
            controller:   _senhaCtrl,
            hint:         '••••••••',
            icon:         Icons.lock_outline,
            obscure:      !_showSenha,
            enabled:      !loading,
            suffix: IconButton(
              icon: Icon(
                _showSenha ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSection,
                size: 20,
              ),
              onPressed: () => setState(() => _showSenha = !_showSenha),
            ),
          ),

          // Esqueci senha
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {/* TODO: EsqueciSenhaDialog */},
              child: const Text(
                'Esqueci minha senha',
                style: TextStyle(
                  color: AppColors.bluePrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // Botão entrar
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : _handleLogin,
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
                      'ENTRAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                const Expanded(child: Divider(color: AppColors.cardBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou',
                      style: TextStyle(
                          color: AppColors.textEmpty, fontSize: 13)),
                ),
                const Expanded(child: Divider(color: AppColors.cardBorder)),
              ],
            ),
          ),

          // Botão cadastro
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: loading
                  ? null
                  : () => Navigator.of(context).pushNamed('/cadastro'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: AppColors.bluePrimary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'REALIZAR CADASTRO',
                style: TextStyle(
                  color: AppColors.bluePrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.textSection,
          ),
        ),
      );

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure  = false,
    bool enabled  = true,
    Widget? suffix,
  }) {
    return Container(
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
              controller:    controller,
              keyboardType:  keyboard,
              obscureText:   obscure,
              enabled:       enabled,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText:      hint,
                hintStyle:     const TextStyle(color: AppColors.textEmpty),
                border:        InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (suffix != null) suffix,
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

class KeyboardDismissOnTap extends StatelessWidget {
  final Widget child;
  const KeyboardDismissOnTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: child,
      );
}