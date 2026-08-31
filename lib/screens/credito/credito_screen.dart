import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/credit_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_alert.dart';
import '../../widgets/bottom.nav_bar.dart';

class CreditoScreen extends StatefulWidget {
  const CreditoScreen({super.key});

  @override
  State<CreditoScreen> createState() => _CreditoScreenState();
}

class _CreditoScreenState extends State<CreditoScreen> {
  final TextEditingController _valorCtrl = TextEditingController();
  final CreditService _creditService = CreditService();
  double? _valorSelecionado;
  double _saldoAtual = 0;
  bool _loading = false;
  bool _loadingSaldo = true;
  String? _erroSaldo;

  static const List<double> _valoresRapidos = [20.0, 50.0, 100.0];

  static const List<Map<String, dynamic>> _metodos = [
    {'key': 'PIX', 'label': 'PIX', 'icon': Icons.pix},
    {
      'key': 'Google Pay',
      'label': 'Google Pay',
      'icon': Icons.g_mobiledata_outlined,
    },
    {'key': 'Samsung Pay', 'label': 'Samsung Pay', 'icon': Icons.phone_android},
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarSaldo();
    });
  }

  @override
  void dispose() {
    _valorCtrl.dispose();

    super.dispose();
  }

  double? get _valorAtivo {
    if (_valorSelecionado != null) {
      return _valorSelecionado;
    }
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.'));
    if (valor == null || valor <= 0) {
      return null;
    }

    return valor;
  }

  Future<void> _carregarSaldo() async {
    if (!mounted) return;

    setState(() {
      _loadingSaldo = true;
      _erroSaldo = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      if (user.token.isEmpty) {
        throw Exception('Token da sessão não encontrado.');
      }

      if (user.uid.isEmpty) {
        throw Exception('UID do cliente não encontrado.');
      }

      debugPrint('=== CONSULTAR SALDO ===');
      debugPrint('UID disponível: ${user.uid.isNotEmpty}');
      debugPrint('Token disponível: ${user.token.isNotEmpty}');

      final response = await _creditService.getCreditos(
        appClienteToken: user.token,
        appClienteUid: user.uid,
      );

      debugPrint('RESPOSTA CRÉDITOS: $response');

      final saldo = _extrairSaldo(response);

      if (!mounted) return;

      setState(() {
        _saldoAtual = saldo;
        _loadingSaldo = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar saldo: $e');

      if (!mounted) return;

      setState(() {
        _loadingSaldo = false;
        _erroSaldo = 'Não foi possível consultar seu saldo.';
      });
    }
  }

  double _extrairSaldo(Map<String, dynamic> response) {
    final credito = response['creditos'];

    if (credito is num) {
      return credito.toDouble();
    }

    if (credito is String) {
      return double.tryParse(credito) ?? 0.0;
    }

    return 0.0;
  }

  void _selecionarRapido(double valor) {
    setState(() {
      _valorSelecionado = valor;

      _valorCtrl.clear();
    });
  }

  void _handleMetodo(String metodo) {
    final valor = _valorAtivo;

    if (valor == null || valor <= 0) {
      CustomAlert.show(
        context,
        title: 'Erro',
        message: 'Selecione ou digite um valor antes de pagar.',
      );

      return;
    }

    CustomAlert.show(
      context,
      title: 'Confirmar pagamento',
      message: 'Adicionar R\$ ${valor.toStringAsFixed(2)} via $metodo?',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      onConfirm: () {
        _iniciarAdicaoCredito(valor, metodo);
      },
      onCancel: () {},
    );
  }

  Future<void> _iniciarAdicaoCredito(double valor, String metodo) async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      debugPrint('=== NOVO CRÉDITO ===');
      debugPrint('Valor: ${valor.toStringAsFixed(2)}');
      debugPrint('Método: $metodo');

      if (!mounted) return;

      CustomAlert.show(
        context,
        title: 'Crédito',
        message:
            'A consulta de saldo já está integrada.\n\n'
            'A criação do crédito aguarda o endpoint '
            'de registro pendente do backend.',
        onConfirm: () {},
      );
    } catch (e) {
      debugPrint('Erro ao iniciar crédito: $e');

      if (!mounted) return;

      CustomAlert.show(
        context,
        title: 'Erro',
        message: 'Não foi possível iniciar a adição de crédito.',
        onConfirm: () {},
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregarSaldo,
              color: AppColors.bluePrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLabel('VALOR RÁPIDO'),
                    const SizedBox(height: 12),
                    _buildValoresRapidos(),
                    const SizedBox(height: 24),
                    _buildLabel('OUTRO VALOR'),
                    const SizedBox(height: 12),
                    _buildInputValor(),
                    if (_valorAtivo != null) ...[
                      const SizedBox(height: 12),
                      _buildResumoBadge(),
                    ],
                    const SizedBox(height: 24),
                    _buildLabel('FORMA DE PAGAMENTO'),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.bluePrimary,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Processando...',
                              style: TextStyle(color: AppColors.textEmpty),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._metodos.map(
                        (metodo) => _buildMetodoBtn(
                          metodo['key'] as String,
                          metodo['label'] as String,
                          metodo['icon'] as IconData,
                        ),
                      ),
                  ],
                ),
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
            top: -55,
            right: -55,
            child: _circle(150, AppColors.circleDeco1),
          ),
          Positioned(
            bottom: -45,
            left: -45,
            child: _circle(110, AppColors.circleDeco2),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adicionar Crédito',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.bluePrimary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SALDO ATUAL',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSection,
                            ),
                          ),

                          const SizedBox(height: 4),

                          if (_loadingSaldo)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.bluePrimary,
                              ),
                            )
                          else if (_erroSaldo != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _erroSaldo!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),

                                TextButton(
                                  onPressed: _carregarSaldo,
                                  child: const Text('Tentar novamente'),
                                ),
                              ],
                            )
                          else
                            Text(
                              'R\$ ${_saldoAtual.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_loadingSaldo)
                      IconButton(
                        onPressed: _carregarSaldo,
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.bluePrimary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValoresRapidos() {
    return Row(
      children: _valoresRapidos.map((valor) {
        final ativo = _valorSelecionado == valor;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: valor == _valoresRapidos.last ? 0 : 8,
            ),
            child: OutlinedButton(
              onPressed: _loading ? null : () => _selecionarRapido(valor),
              style: OutlinedButton.styleFrom(
                backgroundColor: ativo
                    ? AppColors.bluePrimary
                    : AppColors.white,
                foregroundColor: ativo ? Colors.white : AppColors.bluePrimary,
                side: BorderSide(
                  color: ativo ? AppColors.bluePrimary : AppColors.cardBorder,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(
                'R\$ ${valor.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputValor() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'R\$',
              style: TextStyle(
                color: AppColors.bluePrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              enabled: !_loading,
              onChanged: (_) {
                setState(() {
                  _valorSelecionado = null;
                });
              },
              decoration: const InputDecoration(
                hintText: '0,00',
                hintStyle: TextStyle(color: AppColors.textEmpty),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.badgeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.bluePrimary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Adicionando R\$ ${_valorAtivo!.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.bluePrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoBtn(String key, String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : () => _handleMetodo(key),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.bluePrimary, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textEmpty,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: AppColors.textSection,
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
