import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_alert.dart';
import '../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _showSenha = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  bool _validar() {
    if (_emailCtrl.text.trim().isEmpty) {
      CustomAlert.show(dialogContext: context, context, title: 'Erro', message: 'Informe o email');
      return false;
    }
    if (_senhaCtrl.text.trim().isEmpty) {
      CustomAlert.show(dialogContext: context,context, title: 'Erro', message: 'Informe a senha');
      return false;
    }
    return true;
  }

  Future<void> _handleLogin() async {
    if (!_validar()) return;

    final auth = context.read<AuthProvider>();
    final erro = await auth.login(
      _emailCtrl.text.trim().toLowerCase(),
      _senhaCtrl.text.trim(),
    );

    if (!mounted) return;

    if (erro == null) {
      CustomAlert.show(
        dialogContext: context,
        context,
        title: 'Bem vindo!',
        message: 'Login realizado com sucesso',
        confirmText: 'OK',
        onConfirm: () =>
            Navigator.of(context).pushReplacementNamed('/localizacao'),
      );
    } else {
      CustomAlert.show(
        dialogContext: context,
        context,
        title: 'Erro na autenticação',
        message: erro,
      );
    }
  }

  void _mostrarEsqueciSenha() {
    final emailCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          bool loading = false;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Esqueci minha senha',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Informe seu e-mail cadastrado para continuar.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSection,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.mail_outline,
                            color: AppColors.textSection,
                            size: 18,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'user@email.com',
                              hintStyle: TextStyle(color: AppColors.textEmpty),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  StatefulBuilder(
                    builder: (ctx2, setButtonState) => SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                final email = emailCtrl.text
                                    .trim()
                                    .toLowerCase();

                                // ✅ Validações usando ctx do modal
                                if (email.isEmpty) {
                                  CustomAlert.show(
                                    dialogContext: context,
                                    ctx,
                                    title: 'Erro',
                                    message: 'Informe o e-mail',
                                  );
                                  return;
                                }
                                if (!email.contains('@')) {
                                  CustomAlert.show(
                                    dialogContext: context,
                                    ctx,
                                    title: 'Erro',
                                    message: 'E-mail inválido',
                                  );
                                  return;
                                }

                                setModalState(() => loading = true);
                                setButtonState(() {});

                                final result = await AuthService.login(
                                  email: email,
                                  senha: '___verificacao___',
                                );

                                setModalState(() => loading = false);
                                setButtonState(() {});

                                final erro = result.erro ?? '';
                                final emailExiste =
                                    result.sucesso ||
                                    erro.toLowerCase().contains('senha') ||
                                    erro.toLowerCase().contains('inválidos');

                                if (!ctx.mounted) return;
                                Navigator.of(ctx).pop();

                                if (!mounted) return;
                                if (emailExiste) {
                                  Navigator.of(context).pushNamed(
                                    '/redefinir-senha',
                                    arguments: {'email': email},
                                  );
                                } else {
                                  CustomAlert.show(
                                    context,
                                    dialogContext: context,
                                    title: 'E-mail não encontrado',
                                    message:
                                        'Não encontramos uma conta com esse e-mail.',
                                  );
                                }
                              },
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
                                'CONTINUAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardDismissOnTap(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(children: [_buildHeroCard(), _buildForm(loading)]),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 120, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: _circle(150, AppColors.circleDeco1),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: _circle(110, AppColors.circleDeco2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/ic_logo_wideias.png',
                    width: 300,
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
                      style: TextStyle(color: Colors.white70, fontSize: 14),
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
            controller: _emailCtrl,
            hint: 'user@email.com',
            icon: Icons.mail_outline,
            keyboard: TextInputType.emailAddress,
            enabled: !loading,
          ),
          const SizedBox(height: 16),

          _buildLabel('SENHA'),
          _buildInput(
            controller: _senhaCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: !_showSenha,
            enabled: !loading,
            suffix: IconButton(
              icon: Icon(
                _showSenha ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSection,
                size: 20,
              ),
              onPressed: () => setState(() => _showSenha = !_showSenha),
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _mostrarEsqueciSenha(),
              child: const Text(
                'Esqueci minha senha',
                style: TextStyle(color: AppColors.bluePrimary, fontSize: 13),
              ),
            ),
          ),

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

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                const Expanded(child: Divider(color: AppColors.cardBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
                    style: TextStyle(color: AppColors.textEmpty, fontSize: 13),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.cardBorder)),
              ],
            ),
          ),

          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: loading
                  ? null
                  : () => Navigator.of(context).pushNamed('/cadastro'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.bluePrimary,
                  width: 1.5,
                ),
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
    bool obscure = false,
    bool enabled = true,
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
              controller: controller,
              keyboardType: keyboard,
              obscureText: obscure,
              enabled: enabled,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textEmpty),
                border: InputBorder.none,
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
