import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/payment_service.dart';
import '../../widgets/custom_alert.dart';

class PixScreen extends StatefulWidget {
  const PixScreen({super.key});

  @override
  State<PixScreen> createState() => _PixScreenState();
}

class _PixScreenState extends State<PixScreen> {
  double _valorTotal = 0;
  String _pixCode = '';

  bool _copiado = false;
  bool _pago = false;
  bool _carregando = true;

  int _pollAttempts = 0;

  static const int _maxPollAttempts = 36;

  String? _erro;

  final _paymentService = PaymentService();

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;

      if (args == null) {
        if (!mounted) return;

        setState(() {
          _carregando = false;
          _erro = 'Não foi possível obter os dados do pagamento.';
        });

        return;
      }

      _valorTotal = (args['valorTotal'] as num?)?.toDouble() ?? 0.0;

      if (_valorTotal <= 0) {
        if (!mounted) return;

        setState(() {
          _carregando = false;
          _erro = 'O valor do pagamento é inválido.';
        });

        return;
      }

      await _criarPix();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _criarPix() async {
    if (!mounted) return;

    _pollTimer?.cancel();

    setState(() {
      _carregando = true;
      _erro = null;
      _pixCode = '';
      _pago = false;
      _copiado = false;
    });

    try {
      final referenceId = 'WIDEIAS-${DateTime.now().millisecondsSinceEpoch}';

      final charge = await _paymentService.createPixCharge(
        amount: _valorTotal,
        referenceId: referenceId,
      );

      if (!mounted) return;

      setState(() {
        _pixCode = charge.copyPasteCode;
        _carregando = false;
      });

      _iniciarPolling(charge.chargeId, charge.expiresAt);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = _tratarErro(e);
      });
    }
  }

  void _iniciarPolling(String orderId, DateTime expiresAt) {
    _pollAttempts = 0;

    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (DateTime.now().isAfter(expiresAt)) {
        timer.cancel();

        if (!mounted) return;

        setState(() {
          _erro =
              'Este PIX expirou. '
              'Gere um novo PIX para continuar o pagamento.';
        });

        return;
      }

      _pollAttempts++;

      if (_pollAttempts >= _maxPollAttempts) {
        timer.cancel();

        if (!mounted) return;

        setState(() {
          _erro =
              'Pagamento ainda não confirmado. '
              'Você pode tentar novamente ou gerar um novo PIX.';
        });

        return;
      }

      try {
        final status = await _paymentService.checkPixStatus(orderId);

        if (!mounted) return;

        if (status == 'PAID') {
          timer.cancel();

          setState(() {
            _pago = true;
          });

          await Future.delayed(const Duration(milliseconds: 900));

          if (!mounted) return;

          Navigator.of(context).pop(true);

          return;
        }

        if (status == 'EXPIRED') {
          timer.cancel();

          setState(() {
            _erro =
                'Este PIX expirou. '
                'Gere um novo PIX para continuar o pagamento.';
          });

          return;
        }

        if (status == 'DECLINED' || status == 'CANCELED') {
          timer.cancel();

          setState(() {
            _erro = 'Pagamento não aprovado.';
          });

          return;
        }
      } catch (_) {}
    });
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

    setState(() {
      _copiado = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      setState(() {
        _copiado = false;
      });
    });

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

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL A PAGAR',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: AppColors.textSection,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${_valorTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          if (_carregando)
            const SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.bluePrimary),
              ),
            )
          else if (_erro != null)
            SizedBox(
              width: double.infinity,
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _erro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSection,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton.icon(
                      onPressed: _criarPix,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Gerar novo PIX'),
                    ),
                  ],
                ),
              ),
            )
          else if (_pixCode.isNotEmpty)
            QrImageView(
              data: _pixCode,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),

          const SizedBox(height: 12),

          if (!_pago && _erro == null)
            const Text(
              'Escaneie com o app do seu banco',
              style: TextStyle(fontSize: 14, color: AppColors.textSection),
            ),
        ],
      ),
    );
  }

  Widget _buildCopyButton() {
    return GestureDetector(
      onTap: _copiar,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _copiado
              ? AppColors.greenSuccess.withOpacity(0.08)
              : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _copiado ? AppColors.greenSuccess : AppColors.cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _copiado ? Icons.check_outlined : Icons.copy_outlined,
              color: _copiado ? AppColors.greenSuccess : AppColors.bluePrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _copiado ? 'Código copiado' : 'Copiar código PIX',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _copiado
                    ? AppColors.greenSuccess
                    : AppColors.bluePrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    if (_pago) {
      return const Column(
        children: [
          Icon(Icons.check_circle, color: AppColors.greenSuccess, size: 56),
          SizedBox(height: 8),
          Text(
            'Pagamento confirmado!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Seu pagamento foi confirmado com sucesso.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textEmpty),
          ),
        ],
      );
    }

    if (_erro != null) {
      return const SizedBox.shrink();
    }

    if (_carregando) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.bluePrimary,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Gerando PIX...',
            style: TextStyle(fontSize: 13, color: AppColors.textEmpty),
          ),
        ],
      );
    }

    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.bluePrimary,
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Aguardando pagamento...',
          style: TextStyle(fontSize: 13, color: AppColors.textEmpty),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.bluePrimary,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -30,
            child: _circle(130, AppColors.circleDeco1),
          ),
          Positioned(
            bottom: -20,
            left: -30,
            child: _circle(90, AppColors.circleDeco2),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _pollTimer?.cancel();
                  Navigator.of(context).pop();
                },
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
                  'Pagamento via PIX',
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

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
