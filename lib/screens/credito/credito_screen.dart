import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/storage_provider.dart';
import '../../widgets/custom_alert.dart';
import '../../widgets/bottom.nav_bar.dart';

class CreditoScreen extends StatefulWidget {
  const CreditoScreen({super.key});

  @override
  State<CreditoScreen> createState() => _CreditoScreenState();
}

class _CreditoScreenState extends State<CreditoScreen> {
  final _valorCtrl = TextEditingController();
  double? _valorSelecionado;
  bool _loading = false;

  static const _valoresRapidos = [20.0, 50.0, 100.0];
  static const _metodos = [
    {'key': 'PIX', 'label': 'PIX', 'icon': Icons.pix},
    {
      'key': 'Google Pay',
      'label': 'Google Pay',
      'icon': Icons.g_mobiledata_outlined,
    },
    {'key': 'Samsung Pay', 'label': 'Samsung Pay', 'icon': Icons.phone_android},
  ];

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  double? get _valorAtivo {
    if (_valorSelecionado != null) return _valorSelecionado;
    final v = double.tryParse(_valorCtrl.text.replaceAll(',', '.'));
    return (v != null && v > 0) ? v : null;
  }

  void _selecionarRapido(double v) {
    setState(() {
      _valorSelecionado = v;
      _valorCtrl.clear();
    });
  }

  void _handleMetodo(String metodo) {
    final v = _valorAtivo;
    if (v == null || v <= 0) {
      CustomAlert.show(
        dialogContext: context,
        context,
        title: 'Erro',
        message: 'Selecione ou digite um valor antes de pagar.',
      );
      return;
    }

    CustomAlert.show(
      dialogContext: context,
      context,
      title: 'Confirmar pagamento',
      message: 'Adicionar R\$ ${v.toStringAsFixed(2)} via $metodo?',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      onConfirm: () => _adicionarCredito(v, metodo),
      onCancel: () {},
    );
  }

  Future<void> _adicionarCredito(double valor, String metodo) async {
    setState(() => _loading = true);
    final storage = context.read<StorageProvider>();
    final novoSaldo = storage.credito + valor;
    await storage.setCredito(novoSaldo);

    setState(() {
      _loading = false;
      _valorSelecionado = null;
    });
    _valorCtrl.clear();

    if (!mounted) return;
    CustomAlert.show(
      dialogContext: context,
      context,
      title: 'Crédito adicionado!',
      message:
          'R\$ ${valor.toStringAsFixed(2)} via $metodo.\n\n'
          'Novo saldo: R\$ ${novoSaldo.toStringAsFixed(2)}',
      onConfirm: () {},
    );
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
                      (m) => _buildMetodoBtn(
                        m['key'] as String,
                        m['label'] as String,
                        m['icon'] as IconData,
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
                    Column(
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
      children: _valoresRapidos.map((v) {
        final ativo = _valorSelecionado == v;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: v == _valoresRapidos.last ? 0 : 8),
            child: OutlinedButton(
              onPressed: _loading ? null : () => _selecionarRapido(v),
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
                'R\$ ${v.toInt()}',
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
              onChanged: (_) => setState(() => _valorSelecionado = null),
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
          onTap: () => _handleMetodo(key),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.bluePrimary, size: 28),
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

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: AppColors.textSection,
    ),
  );

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
