import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_alert.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _nascimentoCtrl = TextEditingController();
  bool _showSenha = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    _nomeCtrl.text = user.nome;
    _emailCtrl.text = user.email;
    _telefoneCtrl.text = user.telefone;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _telefoneCtrl.dispose();
    _cpfCtrl.dispose();
    _nascimentoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      CustomAlert.show(
        dialogContext: context,
        context,
        title: 'Erro',
        message: 'Preencha pelo menos o nome!',
      );
      return;
    }

    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();

    await auth.atualizarPerfil(
      nome: _nomeCtrl.text.trim(),
      telefone: _telefoneCtrl.text.trim(),
    );

    setState(() => _saving = false);
    if (!mounted) return;

    CustomAlert.show(
      dialogContext: context,
      context,
      title: 'Sucesso',
      message: 'Informações atualizadas com sucesso!',
      onConfirm: () {},
    );
  }

  void _confirmarLogout() {
    CustomAlert.show(
      dialogContext: context,
      context,
      title: 'Sair da conta',
      message: 'Tem certeza que deseja sair?',
      confirmText: 'Sair',
      cancelText: 'Cancelar',
      onConfirm: () async {
        await context.read<AuthProvider>().logout();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      },
      onCancel: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(user?.nome ?? '', user?.email ?? ''),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'INFORMAÇÕES PESSOAIS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textSection,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    'NOME',
                    _nomeCtrl,
                    icon: Icons.person_outline,
                    capitalize: TextCapitalization.words,
                  ),
                  _buildField(
                    'E-MAIL',
                    _emailCtrl,
                    icon: Icons.mail_outline,
                    keyboard: TextInputType.emailAddress,
                    enabled: false,
                  ),
                  _buildField(
                    'NOVA SENHA',
                    _senhaCtrl,
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

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bluePrimary,
                        disabledBackgroundColor: AppColors.textEmpty,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        _saving ? 'Salvando...' : 'Salvar Alterações',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: AppColors.cardBorder),
                  ),

                  // Logout
                  GestureDetector(
                    onTap: _confirmarLogout,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppColors.redErrorBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.exit_to_app,
                              color: AppColors.redError,
                              size: 20,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Sair da conta',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.redError,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textEmpty,
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
    );
  }

  Widget _buildHeader(String nome, String email) {
    return Container(
      color: AppColors.bluePrimary,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -70,
            right: -70,
            child: _circle(160, AppColors.circleDeco1),
          ),

          Positioned(
            bottom: -60,
            left: -60,
            child: _circle(130, AppColors.circleDeco2),
          ),
          Column(
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
                      'Perfil',
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
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nome.isEmpty ? 'Seu nome' : nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
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
              color: enabled ? AppColors.white : const Color(0xFFF8F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    icon,
                    color: enabled
                        ? AppColors.textSection
                        : AppColors.textEmpty,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    keyboardType: keyboard,
                    textCapitalization: capitalize,
                    obscureText: obscure,
                    enabled: enabled,
                    maxLength: maxLength,
                    inputFormatters: inputFormatters,
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textEmpty,
                    ),
                    decoration: InputDecoration(
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
