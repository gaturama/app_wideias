import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_alert.dart';

class RedefinirSenhaScreen extends StatefulWidget {
  const RedefinirSenhaScreen({super.key});

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final _senhaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showSenha = false;
  bool _showConfirm = false;
  bool _loading = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      setState(() => _email = args?['email']?.toString() ?? '');
    });
  }

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRedefinir() async {
    final senha = _senhaCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (senha.isEmpty) {
      CustomAlert.show(dialogContext: context, context, title: 'Erro', message: 'Informe a nova senha');
      return;
    }
    if (senha.length < 4) {
      CustomAlert.show(
        dialogContext: context,
        context,
        title: 'Erro',
        message: 'A senha deve ter pelo menos 4 caracteres',
      );
      return;
    }
    if (senha != confirm) {
      CustomAlert.show(
        dialogContext: context,
        context,
        title: 'Erro',
        message: 'As senah não coincidem',
      );
      return;
    }

    setState(() => _loading = true);
    await context.read<AuthProvider>().redefinirSenhaLocal(_email, senha);
    setState(() => _loading = false);

    if (!mounted) return;
    CustomAlert.show(
      dialogContext: context,
      context,
      title: 'Senha redefinida!',
      message: 'Sua nova senha foi salva. Use-a no próximo login.',
      confirmText: 'Ir para login',
      onConfirm: () =>
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.lock_reset_outlined,
                    size: 64,
                    color: AppColors.bluePrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Redefinido senha para\n$_email',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSection,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildLabel('NOVA SENHA'),
                  _buildInput(
                    controller: _senhaCtrl,
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscure: !_showSenha,
                    suffix: IconButton(
                      icon: Icon(
                        _showSenha ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSection,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _showSenha = !_showSenha),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('CONFIRMAR SENHA'),
                  _buildInput(
                    controller: _confirmCtrl,
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscure: !_showConfirm,
                    suffix: IconButton(
                      icon: Icon(
                        _showConfirm ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSection,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleRedefinir,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bluePrimary,
                        disabledBackgroundColor: AppColors.textEmpty,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'SALVAR NOVA SENHA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
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

  Widget _buildHeader() {
    return Container(
      color: AppColors.bluePrimary,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -20,
            right: -30,
            child: _circle(120, AppColors.circleDeco1),
          ),
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
                  'Redefinir Senha',
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
    bool obscure = false,
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
              obscureText: obscure,
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
