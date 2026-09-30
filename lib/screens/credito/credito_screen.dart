import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/credit_service.dart';
import '../../core/services/payment_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/storage_provider.dart';
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
  bool _loading = false;

  static const List<double> _valoresRapidos = [20.0, 50.0, 100.0];

  static const List<Map<String, dynamic>> _metodos = [
    {'key': 'PIX', 'label': 'PIX', 'icon': Icons.pix},
  ];

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
      final user = context.read<AuthProvider>().user;

      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      if (user.token.isEmpty) {
        throw Exception('Token da sessão não encontrado.');
      }

      if (user.uid.isEmpty) {
        throw Exception('UID do cliente não encontrado.');
      }

      final creditoCriado = await _creditService.criarCredito(
        appClienteToken: user.token,
        appClienteUid: user.uid,
        valor: valor,
      );

      final creditoUid = _extrairCreditoUid(creditoCriado);

      if (creditoUid == null || creditoUid.isEmpty) {
        throw Exception('O backend não retornou o UID do crédito.');
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      final resultado = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CreditoPixScreen(valor: valor, creditoUid: creditoUid),
        ),
      );

      if (!mounted) return;

      if (resultado is Map && resultado['sucesso'] == true) {
        final storage = context.read<StorageProvider>();
        final saldoAtual = storage.credito;
        final novoSaldo = saldoAtual + valor;

        await storage.setCredito(novoSaldo);

        setState(() {
          _valorSelecionado = null;
          _valorCtrl.clear();
        });

        CustomAlert.show(
          context,
          title: 'Crédito adicionado!',
          message:
              'R\$ ${valor.toStringAsFixed(2)} '
              'foi adicionado ao seu crédito.\n\n'
              'Novo saldo: R\$ ${novoSaldo.toStringAsFixed(2)}',
          onConfirm: () {},
        );
      }
    } catch (e) {
      debugPrint('Erro ao adicionar crédito: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      CustomAlert.show(
        context,
        title: 'Erro',
        message: _tratarErroCredito(e),
        onConfirm: () {},
      );
    }
  }

  String? _extrairCreditoUid(Map<String, dynamic> response) {
    final credito = response['credito'];

    if (credito is String && credito.isNotEmpty) {
      return credito;
    }

    if (credito is Map) {
      final uid = credito['UID']?.toString() ?? credito['uid']?.toString();

      if (uid != null && uid.isNotEmpty) {
        return uid;
      }
    }

    final uid = response['uid']?.toString();

    if (uid != null && uid.isNotEmpty) {
      return uid;
    }

    final creditoUid = response['creditoUid']?.toString();

    if (creditoUid != null && creditoUid.isNotEmpty) {
      return creditoUid;
    }

    final uidCredito = response['UID']?.toString();

    if (uidCredito != null && uidCredito.isNotEmpty) {
      return uidCredito;
    }

    return null;
  }

  String _tratarErroCredito(Object erro) {
    final mensagem = erro.toString();

    if (mensagem.contains('Token Sandbox não configurado')) {
      return 'Token do PagBank Sandbox não configurado.';
    }

    if (mensagem.contains('UID do crédito')) {
      return 'O crédito foi criado, mas o backend não retornou o UID necessário para continuar o pagamento.';
    }

    if (mensagem.contains('401') || mensagem.contains('403')) {
      return 'Não foi possível autorizar a operação.';
    }

    return 'Não foi possível iniciar a adição de crédito.';
  }

  @override
  Widget build(BuildContext context) {
    final credito = context.watch<StorageProvider>().credito;

    return Scaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(credito),
          Expanded(
            child: SingleChildScrollView(
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
        ],
      ),
    );
  }

  Widget _buildHeader(double credito) {
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
                          Text(
                            'R\$ ${credito.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
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

class CreditoPixScreen extends StatefulWidget {
  final double valor;
  final String creditoUid;

  const CreditoPixScreen({
    super.key,
    required this.valor,
    required this.creditoUid,
  });

  @override
  State<CreditoPixScreen> createState() => _CreditoPixScreenState();
}

class _CreditoPixScreenState extends State<CreditoPixScreen> {
  final PaymentService _paymentService = PaymentService();
  final CreditService _creditService = CreditService();

  Timer? _timer;
  int _tentativas = 0;
  static const int _maxTentativas = 36;

  String _pixCode = '';
  bool _carregando = true;
  bool _pago = false;
  String? _erro;
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _criarPix();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _criarPix() async {
    try {
      final saleCode = _paymentService.generateSaleCode();

      final charge = await _paymentService.createPixCharge(
        amount: widget.valor,
        saleCode: saleCode,
      );

      if (!mounted) return;

      setState(() {
        _pixCode = charge.copyPasteCode;
        _carregando = false;
      });

      _iniciarPolling(charge.chargeId);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = _tratarErro(e);
      });
    }
  }

  void _iniciarPolling(String orderId) {
    _tentativas = 0;

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _tentativas++;

      if (_tentativas >= _maxTentativas) {
        timer.cancel();

        if (!mounted) return;

        setState(() {
          _erro =
              'Pagamento ainda não confirmado. Gere um novo PIX para continuar.';
        });

        return;
      }

      try {
        final status = await _paymentService.checkPixStatus(orderId);

        if (!mounted) return;

        if (status == 'PAID') {
          timer.cancel();

          await _confirmarCredito(orderId);

          return;
        }

        if (status == 'EXPIRED') {
          timer.cancel();

          setState(() {
            _erro = 'Este PIX expirou. Gere um novo PIX para continuar.';
          });

          return;
        }

        if (status == 'DECLINED' || status == 'CANCELED') {
          timer.cancel();

          setState(() {
            _erro = 'Pagamento não aprovado.';
          });
        }
      } catch (e) {
        debugPrint('Erro ao consultar PIX do crédito: $e');
      }
    });
  }

  Future<void> _confirmarCredito(String orderId) async {
    if (_registrando) return;

    setState(() {
      _registrando = true;
      _pago = true;
    });

    try {
      final pagamento = await _paymentService.getPixPaymentData(orderId);

      if (pagamento == null) {
        throw Exception(
          'Pagamento confirmado, mas os dados da transação não foram encontrados.',
        );
      }

      final user = context.read<AuthProvider>().user;

      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      final pagamentoBackend = {
        'transactionCode': pagamento['chargeId']?.toString() ?? '',
        'transactionID': pagamento['orderId']?.toString() ?? '',
        'nsu': pagamento['endToEndId']?.toString() ?? '',
        'bin': '',
        'autoCode': '',
        'cardBrand': '',
        'idTipoPagamento': '3',
        'status': '1',
      };

      debugPrint('=== PAGAMENTO CRÉDITO ENVIADO ===');
      debugPrint(pagamentoBackend.toString());

      await _creditService.atualizarPagamentoCredito(
        creditoUid: widget.creditoUid,
        appClienteToken: user.token,
        appClienteUid: user.uid,
        pagamento: pagamentoBackend,
      );

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.of(context).pop({'sucesso': true});
    } catch (e) {
      debugPrint('Erro ao confirmar crédito: $e');

      if (!mounted) return;

      setState(() {
        _registrando = false;
        _pago = false;
        _erro =
            'O pagamento foi confirmado, mas não foi possível registrar o crédito. Tente novamente.';
      });
    }
  }

  String _tratarErro(Object erro) {
    final mensagem = erro.toString();

    if (mensagem.contains('Token Sandbox não configurado')) {
      return 'Token do PagBank Sandbox não configurado.';
    }

    if (mensagem.contains('não retornou o QR Code PIX')) {
      return 'O PagBank não retornou o QR Code PIX.';
    }

    if (mensagem.contains('não retornou o código PIX')) {
      return 'O PagBank não retornou o código PIX copia e cola.';
    }

    return 'Não foi possível gerar o pagamento PIX.';
  }

  void _copiar() {
    if (_pixCode.isEmpty) return;

    Clipboard.setData(ClipboardData(text: _pixCode));

    CustomAlert.show(
      context,
      title: 'Copiado!',
      message: 'O código PIX foi copiado para a área de transferência.',
      onConfirm: () {},
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
                children: [
                  _buildTotalCard(),
                  const SizedBox(height: 24),
                  _buildPixCard(),
                  const SizedBox(height: 24),
                  if (_pixCode.isNotEmpty && !_pago && _erro == null)
                    _buildCopyButton(),
                  const SizedBox(height: 20),
                  _buildStatus(),
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
      child: Row(
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
              'Pagamento do Crédito',
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
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white,
            size: 58,
          ),
          const SizedBox(height: 12),
          const Text(
            'Adicionar crédito',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${widget.valor.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.pix, color: AppColors.bluePrimary, size: 48),
          const SizedBox(height: 12),
          const Text(
            'PIX',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pague o valor abaixo para adicionar o crédito à sua conta.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textEmpty),
          ),
          const SizedBox(height: 20),
          if (_carregando)
            const Column(
              children: [
                CircularProgressIndicator(color: AppColors.bluePrimary),
                SizedBox(height: 10),
                Text(
                  'Gerando PIX...',
                  style: TextStyle(color: AppColors.textEmpty),
                ),
              ],
            )
          else if (_erro != null)
            Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 42),
                const SizedBox(height: 10),
                Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            )
          else if (_pago)
            Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 10),
                Text(
                  _registrando
                      ? 'Confirmando crédito...'
                      : 'Pagamento confirmado!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _pixCode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aguardando pagamento...',
                  style: TextStyle(fontSize: 13, color: AppColors.textEmpty),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCopyButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _copiar,
        icon: const Icon(Icons.copy),
        label: const Text(
          'COPIAR PIX',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bluePrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _erro != null
              ? Icons.error_outline
              : _pago
              ? Icons.check_circle
              : Icons.access_time,
          size: 18,
          color: _erro != null
              ? Colors.red
              : _pago
              ? Colors.green
              : AppColors.bluePrimary,
        ),
        const SizedBox(width: 8),
        Text(
          _erro != null
              ? 'Pagamento não concluído'
              : _pago
              ? 'Pagamento concluído'
              : 'Aguardando pagamento',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSection,
          ),
        ),
      ],
    );
  }
}
