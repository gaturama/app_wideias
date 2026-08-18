import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_alert.dart';
import '../../core/services/payment_service.dart';

class PixScreen extends StatefulWidget {
  const PixScreen({super.key});

  @override
  State<PixScreen> createState() => _PixScreenState();
}

class _PixScreenState extends State<PixScreen> {
  double _valorTotal = 0;
  String _pixCode = '';
  bool _copiado = false;

  final _paymentService = PaymentService();
  Timer? _pollTimer;
  bool _pago = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args == null) return;

      _valorTotal = (args['valorTotal'] as num?)?.toDouble() ?? 0.0;

      final valor = _valorTotal.toStringAsFixed(2).replaceAll('.', '');
      setState(() {
        _pixCode =
            '00020126580014BR.GOV.BCB.PIX0136chavepix@empresa.com'
            '520400005303986540${valor}5802BR5912Wideias App'
            '6009Joinville62070503***6304ABCD';
      });

      _iniciarPolling();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _iniciarPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final status = await _paymentService.checkPixStatus(_pixCode);

      if (!mounted) return;

      if (status == 'PAID') {
        _pollTimer?.cancel();
        setState(() => _pago = true);
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    });
  }

  void _copiar() {
    Clipboard.setData(ClipboardData(text: _pixCode));
    setState(() => _copiado = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copiado = false);
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
                  Container(
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
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_pixCode.isNotEmpty)
                          QrImageView(
                            data: _pixCode,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                        const SizedBox(height: 12),
                        const Text(
                          'Escaneie com o app do seu banco',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSection,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ou copie o código',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textEmpty,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.cardBorder),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
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
                          color: _copiado
                              ? AppColors.greenSuccess
                              : AppColors.cardBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _copiado
                                ? Icons.check_outlined
                                : Icons.copy_outlined,
                            color: _copiado
                                ? AppColors.greenSuccess
                                : AppColors.bluePrimary,
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
                  ),
                  const SizedBox(height: 20),

                  if (!_pago) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
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
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    const Icon(Icons.check_circle, color: AppColors.greenSuccess, size: 56),
                    const SizedBox(height: 8),
                    const Text(
                      'Pagamento confirmado!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text(
                    'Após o pagamento, seu pedido será confirmado automaticamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textEmpty),
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

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}