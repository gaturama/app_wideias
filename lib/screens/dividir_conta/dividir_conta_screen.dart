import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';

class DividirContaScreen extends StatefulWidget {
  const DividirContaScreen({super.key});

  @override
  State<DividirContaScreen> createState() => _DividirContaScreenState();
}

class _DividirContaScreenState extends State<DividirContaScreen> {
  String _pedidoId  = '';
  double _valorTotal = 0;
  int    _numPessoas = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args == null) return;
      setState(() {
        _pedidoId   = args['pedidoId']?.toString()             ?? '';
        _valorTotal = (args['valorTotal'] as num?)?.toDouble() ?? 0.0;
      });
    });
  }

  double get _valorPorPessoa => _numPessoas > 0
      ? _valorTotal / _numPessoas
      : 0;

  String get _qrData =>
      '{"idPedido":"$_pedidoId","valor":"${_valorPorPessoa.toStringAsFixed(2)}"}';

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
                  Text(
                    'Dividir em $_numPessoas pessoas',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${_valorPorPessoa.toStringAsFixed(2)} por pessoa',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.bluePrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data:            _qrData,
                      version:         QrVersions.auto,
                      size:            220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Controles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ctrlBtn(Icons.remove, () {
                        if (_numPessoas > 2) {
                          setState(() => _numPessoas--);
                        }
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Text('$_numPessoas',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                )),
                            const Text('pessoas',
                                style: TextStyle(
                                    color: AppColors.textSection,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      _ctrlBtn(Icons.add,
                          () => setState(() => _numPessoas++)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Mostre o QR Code para cada pessoa\nefetuar o pagamento',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textEmpty),
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
          Positioned(top: -20, right: -30,
              child: _circle(120, AppColors.circleDeco1)),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                ),
              ),
              const Expanded(
                child: Text('Dividir Conta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.badgeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.bluePrimary, size: 20),
        ),
      );

  Widget _circle(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}