import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/cart_item_model.dart';
import '../../providers/pedidos_provider.dart';
import '../../providers/storage_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_alert.dart';

class PagamentoScreen extends StatefulWidget {
  const PagamentoScreen({super.key});

  @override
  State<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends State<PagamentoScreen> {
  List<CartItemModel> _cart = [];
  String? _locationId;
  String? _observacoes;
  String? _mesa;
  bool _usarCredito = false;
  bool _loading = false;

  static const _metodos = [
    {'key': 'PIX', 'label': 'PIX', 'icon': Icons.pix},
    {'key': 'Google Pay', 'label': 'Google Pay', 'icon': Icons.g_mobiledata},
    {'key': 'Samsung Pay', 'label': 'Samsung Pay', 'icon': Icons.phone_android},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args == null) return;
      setState(() {
        _cart = List<CartItemModel>.from(args['cart'] ?? []);
        _locationId = args['locationId']?.toString();
        _observacoes = args['observacoes']?.toString();
        _mesa = args['mesa']?.toString();
      });
    });
  }

  double get _totalCarrinho => _cart.fold(0.0, (s, i) => s + i.precoTotal);

  double get _credito => context.read<StorageProvider>().credito;

  double get _creditoAplicado =>
      _usarCredito ? _credito.clamp(0, _totalCarrinho) : 0;

  double get _totalFinal => _totalCarrinho - _creditoAplicado;

  Future<void> _handleMetodo(String key) async {
    if (key == 'Samsung Pay') {
      await _abrirApp(
        'samsungpay://',
        'https://play.google.com/store/apps/details?id=com.samsung.android.spay',
      );
      await Future.delayed(const Duration(seconds: 1));
    } else if (key == 'Google Pay') {
      await _abrirApp(
        'intent:#Intent;package=com.google.android.apps.walletnfcrel;end',
        'https://play.google.com/store/apps/details?id=com.google.android.apps.walletnfcrel',
      );
      await Future.delayed(const Duration(seconds: 1));
    }
    _finalizarPagamento(key);
  }

  Future<void> _abrirApp(String scheme, String fallback) async {
    try {
      final uri = Uri.parse(scheme);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(
          Uri.parse(fallback),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}
  }

  Future<void> _finalizarPagamento(String metodo) async {
    if (_cart.isEmpty) {
      CustomAlert.show(
        context,
        title: 'Carrinho vazio',
        message: 'Adicione produtos antes de finalizar',
      );
      return;
    }

    setState(() => _loading = true);

    final storage = context.read<StorageProvider>();
    final auth = context.read<AuthProvider>();
    final pedidos = context.read<PedidosProvider>();

    // Descontar crédito se usado
    if (_creditoAplicado > 0) {
      await storage.setCredito(_credito - _creditoAplicado);
    }

    // Salvar pedidos pendentes
    await pedidos.adicionarPedidos(
      userId: auth.user?.id ?? '',
      cart: _cart,
      metodo: metodo,
      locationId: _locationId ?? '',
      locationName: storage.locationName ?? '',
      mesa: _mesa,
    );

    setState(() => _loading = false);
    if (!mounted) return;

    CustomAlert.show(
      context,
      title: 'Pedido confirmado!',
      message:
          'Total: R\$ ${_totalCarrinho.toStringAsFixed(2)}\nPagamento: $metodo',
      confirmText: 'OK',
      onConfirm: () =>
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credito = context.watch<StorageProvider>().credito;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTotalCard(),
                  const SizedBox(height: 16),
                  _buildCreditoToggle(credito),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        '/dividir-conta',
                        arguments: {
                          'pedidoId': _locationId ?? '',
                          'valorTotal': _totalFinal,
                        },
                      ),
                      icon: const Icon(Icons.people_outline),
                      label: const Text(
                        'Dividir conta',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.bluePrimary,
                        side: const BorderSide(
                          color: AppColors.bluePrimary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'FORMA DE PAGAMENTO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textSection,
                    ),
                  ),
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
                            'Processando pagamento...',
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

  Widget _buildHeader() {
    return Container(
      color: AppColors.bluePrimary,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Stack(
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
                  'Pagamento',
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

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.hardEdge,
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

          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.credit_card_outlined,
                  color: Colors.white,
                  size: 68,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Total a pagar',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),

                Text(
                  'R\$ ${_totalFinal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (_creditoAplicado > 0)
                  Text(
                    'Carrinho: R\$ ${_totalCarrinho.toStringAsFixed(2)} · Crédito: −R\$ ${_creditoAplicado.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditoToggle(double credito) {
    return GestureDetector(
      onTap: credito > 0
          ? () => setState(() => _usarCredito = !_usarCredito)
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _usarCredito ? AppColors.badgeBg : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _usarCredito ? AppColors.bluePrimary : AppColors.cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.badgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: _usarCredito
                    ? AppColors.bluePrimary
                    : AppColors.textEmpty,
                size: 20,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usar crédito disponível',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _usarCredito
                          ? AppColors.bluePrimary
                          : AppColors.textSection,
                    ),
                  ),
                  Text(
                    'R\$ ${credito.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textEmpty,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _usarCredito ? Icons.check_box : Icons.check_box_outline_blank,
              color: _usarCredito ? AppColors.bluePrimary : AppColors.textEmpty,
            ),
          ],
        ),
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
                const Icon(Icons.chevron_right, color: AppColors.textEmpty),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
