import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/card_model.dart';
import '../../core/services/card_encryption_service.dart';
import '../../core/services/payment_service.dart';

class CardPaymentScreen extends StatefulWidget {
  final double amount;
  final String referenceId;

  const CardPaymentScreen({
    super.key,
    required this.amount,
    required this.referenceId,
  });

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _expMonthController = TextEditingController();
  final _expYearController = TextEditingController();
  final _cvvController = TextEditingController();

  final _encryptionService = CardEncryptionService();
  final _paymentService = PaymentService();

  int _installments = 1;
  bool _processing = false;
  String? _erro;

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _expMonthController.dispose();
    _expYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _pagar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _processing = true;
      _erro = null;
    });

    final card = CardFormData(
      holder: _holderController.text.trim(),
      number: _numberController.text.replaceAll(' ', ''),
      expMonth: _expMonthController.text.trim(),
      expYear: _expYearController.text.trim(),
      securityCode: _cvvController.text.trim(),
      installments: _installments,
    );

    final encryptionResult = await _encryptionService.encryptCard(card);

    if (!encryptionResult.success || encryptionResult.encryptedCard == null) {
      setState(() {
        _processing = false;
        _erro = encryptionResult.errors.isNotEmpty
            ? encryptionResult.errors.first
            : 'Não foi possível processar o cartão';
      });
      return;
    }

    final resultado = await _paymentService.chargeCard(
      encryptedCard: encryptionResult.encryptedCard!,
      amount: widget.amount,
      installments: _installments,
      referenceId: widget.referenceId,
    );

    if (!mounted) return;

    if (resultado['status'] == 'PAID') {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _processing = false;
        _erro = 'Pagamento recusado. Verifique os dados do cartão.';
      });
    }
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
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'R\$ ${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildField(
                      controller: _holderController,
                      label: 'Nome no cartão',
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _numberController,
                      label: 'Número do cartão',
                      keyboardType: TextInputType.number,
                      maxLength: 19,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _expMonthController,
                            label: 'Mês (MM)',
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _expYearController,
                            label: 'Ano (AAAA)',
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _cvvController,
                            label: 'CVV',
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInstallmentsDropdown(),
                    if (_erro != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _erro!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _processing ? null : _pagar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bluePrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _processing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Pagar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Obrigatório';
        }
        return null;
      },
    );
  }

  Widget _buildInstallmentsDropdown() {
    return DropdownButtonFormField<int>(
      value: _installments,
      decoration: InputDecoration(
        labelText: 'Parcelas',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: List.generate(12, (i) => i + 1)
          .map(
            (n) => DropdownMenuItem(
              value: n,
              child: Text(
                n == 1
                    ? '1x de R\$ ${widget.amount.toStringAsFixed(2)}'
                    : '${n}x de R\$ ${(widget.amount / n).toStringAsFixed(2)}',
              ),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _installments = value ?? 1),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.bluePrimary,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Text(
              'Pagamento com cartão',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}