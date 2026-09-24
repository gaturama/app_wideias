import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/cart_item_model.dart';
import '../../providers/pedidos_provider.dart';

import '../../providers/storage_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_alert.dart';
import '../../core/services/google_pay_service.dart';
import '../../core/services/order_service.dart';

class PagamentoScreen extends StatefulWidget {
  const PagamentoScreen({super.key});

  @override
  State<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends State<PagamentoScreen> {
  List<CartItemModel> _cart = [];

  String? _locationId;
  String? _locationName;
  String? _observacoes;
  String? _mesa;
  int? _idEvento;

  bool _usarCredito = false;
  bool _loading = false;
  bool _modoPagamentoExistente = false;

  String? _pedidoExistenteUid;
  double _saldoPagamento = 0.0;

  final GooglePayService _googlePayService = GooglePayService();

  final OrderService _orderService = OrderService();

  Map<String, dynamic>? _pedidoBackend;

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

      final pedidoUid = args['pedidoUid']?.toString();

      final saldo = double.tryParse(args['saldoPagamento']?.toString() ?? '');

      setState(() {
        _cart = List<CartItemModel>.from(args['cart'] ?? []);

        _locationId = args['locationId']?.toString();

        _locationName = args['locationName']?.toString();

        _observacoes = args['observacoes']?.toString();

        _mesa = args['mesa']?.toString();

        _idEvento = int.tryParse(args['idEvento']?.toString() ?? '');

        if (pedidoUid != null && pedidoUid.isNotEmpty) {
          _modoPagamentoExistente = true;
          _pedidoExistenteUid = pedidoUid;
          _saldoPagamento = saldo ?? 0.0;

          _pedidoBackend = {
            'uid': pedidoUid,
            'SaldoPagamentoPedido': _saldoPagamento,
            'Status': 0,
          };
        }
      });

      debugPrint('=== DADOS PAGAMENTO ===');
      debugPrint('Location ID: $_locationId');
      debugPrint('ID Evento: $_idEvento');
      debugPrint('Modo pedido existente: $_modoPagamentoExistente');
      debugPrint(
        'UID pedido presente: '
        '${_pedidoExistenteUid != null}',
      );
    });
  }

  double get _totalCarrinho {
    return _cart.fold(0.0, (sum, item) => sum + item.precoTotal);
  }

  double get _credito {
    return context.read<StorageProvider>().credito;
  }

  double get _creditoAplicado {
    return _usarCredito ? _credito.clamp(0, _totalCarrinho) : 0;
  }

  double get _totalFinal {
    return _totalCarrinho - _creditoAplicado;
  }

  double get _valorPagamentoTeste {
    if (_modoPagamentoExistente) {
      return _saldoPagamento;
    }

    if (_totalFinal <= 20) {
      return _totalFinal;
    }

    return 20.0;
  }

  Future<void> _handleMetodo(String key) async {
    if (!_modoPagamentoExistente && _cart.isEmpty) {
      CustomAlert.show(
        context,
        title: 'Carrinho vazio',
        message: 'Adicione produtos antes de continuar.',
      );
      return;
    }

    if (_modoPagamentoExistente && _saldoPagamento <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este pedido já está totalmente pago.')),
      );
      return;
    }

    if (key == 'Samsung Pay') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Samsung Pay ainda não está integrado.')),
      );
      return;
    }

    try {
      if (key == 'PIX') {
        setState(() => _loading = true);

        final pedido = await _garantirPedidoCriado();

        final pedidoUid = pedido['uid']?.toString();

        if (pedidoUid == null || pedidoUid.isEmpty) {
          throw Exception('UID do pedido não encontrado.');
        }

        final valorPagamento = _valorPagamentoTeste;

        debugPrint('=== VALOR PARA PAGAMENTO ===');
        debugPrint('Valor do carrinho: $_totalCarrinho');
        debugPrint('Valor restante: $_saldoPagamento');
        debugPrint(
          'Valor enviado para PIX: '
          '$valorPagamento',
        );

        if (!mounted) return;

        setState(() => _loading = false);

        final pago = await Navigator.of(context).pushNamed(
          '/pix',
          arguments: {'valorTotal': valorPagamento, 'pedidoUid': pedidoUid},
        );

        if (!mounted) return;

        if (pago == true) {
          setState(() => _loading = true);

          final pedidoAtualizado = await _consultarPedidoBackend();

          if (!mounted) return;

          if (pedidoAtualizado == null) {
            setState(() => _loading = false);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Pagamento confirmado, mas não foi possível consultar o pedido.',
                ),
              ),
            );

            return;
          }

          final saldo =
              double.tryParse(
                pedidoAtualizado['SaldoPagamentoPedido']?.toString() ?? '',
              ) ??
              0.0;

          final status =
              int.tryParse(pedidoAtualizado['Status']?.toString() ?? '') ?? 0;

          final uid = pedidoAtualizado['UID']?.toString() ?? pedidoUid;

          debugPrint('=== RESULTADO PAGAMENTO ===');
          debugPrint('Status: $status');
          debugPrint('Saldo restante: $saldo');

          final auth = context.read<AuthProvider>();

          final pedidosProvider = context.read<PedidosProvider>();

          await pedidosProvider.adicionarPedidos(
            userId: auth.user?.id ?? '',
            cart: _cart,
            metodo: 'PIX',
            locationId: _locationId ?? '',
            locationName:
                _locationName ??
                context.read<StorageProvider>().locationName ??
                '',
            mesa: _mesa,
            backendUid: uid,
            saldoPagamento: saldo,
            statusPagamento: status,
          );

          if (saldo > 0.01) {
            await _manterPedidoPendente(uid);

            if (!mounted) return;

            setState(() => _loading = false);

            CustomAlert.show(
              context,
              title: 'Pagamento parcial',
              message:
                  'Pagamento confirmado!\n\n'
                  'Ainda faltam '
                  'R\$ ${saldo.toStringAsFixed(2)} '
                  'para liberar a retirada.',
              confirmText: 'OK',
              onConfirm: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false),
            );

            return;
          }

          await _finalizarPagamentoPIX(uid, saldo, status);
        }

        return;
      }

      if (key == 'Google Pay') {
        setState(() => _loading = true);

        final disponivel = await _googlePayService.isReadyToPay();

        if (!mounted) return;

        if (!disponivel) {
          setState(() => _loading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Google Pay não está disponível neste dispositivo.',
              ),
            ),
          );

          return;
        }

        await _garantirPedidoCriado();

        final resultado = await _googlePayService.pay(amount: _totalFinal);

        if (!mounted) return;

        setState(() => _loading = false);

        if (resultado['status'] == 'PAID') {
          await _finalizarPagamento('Google Pay');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível confirmar o pagamento.'),
            ),
          );
        }

        return;
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar pagamento: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> _garantirPedidoCriado() async {
    if (_pedidoBackend != null) {
      debugPrint('=== PEDIDO JÁ DISPONÍVEL ===');
      debugPrint('UID presente: ${_pedidoBackend!['uid'] != null}');
      return _pedidoBackend!;
    }

    final user = context.read<AuthProvider>().user;
    final storage = context.read<StorageProvider>();

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    if (user.token.isEmpty) {
      throw Exception('Token do usuário não encontrado.');
    }

    if (user.uid.isEmpty) {
      throw Exception('UID do usuário não encontrado.');
    }

    if (_modoPagamentoExistente) {
      final pedidoUid = _pedidoExistenteUid;

      if (pedidoUid == null || pedidoUid.isEmpty) {
        throw Exception('UID do pedido não encontrado.');
      }

      debugPrint('=== CONTINUANDO PEDIDO EXISTENTE ===');
      debugPrint('UID do pedido presente: ${pedidoUid.isNotEmpty}');
      debugPrint('Saldo atual: $_saldoPagamento');

      _pedidoBackend = {
        'uid': pedidoUid,
        'SaldoPagamentoPedido': _saldoPagamento,
        'Status': 0,
      };

      return _pedidoBackend!;
    }

    if (_cart.isEmpty) {
      throw Exception('Carrinho vazio.');
    }

    final idEvento = _idEvento;

    if (idEvento == null || idEvento <= 0) {
      throw Exception('Não foi possível identificar o evento do pedido.');
    }

    for (final item in _cart) {
      final idProduto = int.tryParse(item.id);

      if (idProduto == null || idProduto <= 0) {
        throw Exception('ID inválido para o produto "${item.name}".');
      }

      if (item.idCardapio <= 0) {
        throw Exception('Cardápio inválido para o produto "${item.name}".');
      }

      if (item.qty <= 0) {
        throw Exception('Quantidade inválida para o produto "${item.name}".');
      }
    }

    debugPrint('=== NOVO PEDIDO ===');
    debugPrint('Cliente UID disponível: ${user.uid.isNotEmpty}');
    debugPrint('Token disponível: ${user.token.isNotEmpty}');
    debugPrint('ID Evento: $idEvento');
    debugPrint('Valor total: $_totalCarrinho');
    debugPrint('Quantidade de itens: ${_cart.length}');
    debugPrint('Não reutilizando pedido pendente salvo.');

    final response = await _orderService.criarPedido(
      appClienteToken: user.token,
      appClienteUid: user.uid,
      idEvento: idEvento,
      valorTotal: _totalCarrinho,
      cart: _cart,
      observacao: _observacoes,
    );

    final pedidoUid = response['uid']?.toString();

    if (pedidoUid == null || pedidoUid.isEmpty) {
      throw Exception('Backend não retornou o UID do pedido.');
    }

    await storage.setPedidoPendenteUid(pedidoUid);

    _pedidoBackend = response;

    debugPrint('=== PEDIDO CRIADO ===');
    debugPrint('UID presente: ${pedidoUid.isNotEmpty}');
    debugPrint('UID salvo para este pedido.');

    return response;
  }

  Future<Map<String, dynamic>?> _consultarPedidoBackend() async {
    final user = context.read<AuthProvider>().user;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    final storage = context.read<StorageProvider>();

    final pedidoUid =
        _pedidoBackend?['uid']?.toString() ??
        _pedidoExistenteUid ??
        storage.pedidoPendenteUid;

    if (pedidoUid == null || pedidoUid.isEmpty) {
      return null;
    }

    final pedidos = await _orderService.getPedidos(
      appClienteToken: user.token,
      appClienteUid: user.uid,
    );

    if (pedidos is! Map || pedidos['pedidos'] is! List) {
      return null;
    }

    final lista = pedidos['pedidos'] as List;

    for (final item in lista) {
      if (item is! Map) continue;

      final uid = item['UID']?.toString();

      if (uid != pedidoUid) {
        continue;
      }

      return Map<String, dynamic>.from(item);
    }

    return null;
  }

  Future<void> _manterPedidoPendente(String uid) async {
    final storage = context.read<StorageProvider>();

    await storage.setPedidoPendenteUid(uid);
  }

  Future<void> _finalizarPagamentoPIX(
    String uid,
    double saldo,
    int status,
  ) async {
    final auth = context.read<AuthProvider>();

    final storage = context.read<StorageProvider>();

    final pedidosProvider = context.read<PedidosProvider>();

    await pedidosProvider.adicionarPedidos(
      userId: auth.user?.id ?? '',
      cart: _cart,
      metodo: 'PIX',
      locationId: _locationId ?? '',
      locationName: _locationName ?? storage.locationName ?? '',
      mesa: _mesa,
      backendUid: uid,
      saldoPagamento: saldo,
      statusPagamento: status,
    );

    await storage.limparPedidoPendenteUid();

    if (!mounted) return;

    setState(() => _loading = false);

    CustomAlert.show(
      context,
      title: 'Pagamento confirmado!',
      message:
          'O pedido foi totalmente pago.\n\n'
          'A retirada já está liberada.',
      confirmText: 'OK',
      onConfirm: () => Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/home', (route) => false),
    );
  }

  Future<void> _finalizarPagamento(String metodo) async {
    if (_cart.isEmpty && !_modoPagamentoExistente) {
      return;
    }

    setState(() => _loading = true);

    final storage = context.read<StorageProvider>();

    final auth = context.read<AuthProvider>();

    final pedidos = context.read<PedidosProvider>();

    if (_creditoAplicado > 0) {
      await storage.setCredito(_credito - _creditoAplicado);
    }

    await pedidos.adicionarPedidos(
      userId: auth.user?.id ?? '',
      cart: _cart,
      metodo: metodo,
      locationId: _locationId ?? '',
      locationName: _locationName ?? storage.locationName ?? '',
      mesa: _mesa,
      backendUid: _pedidoBackend?['uid']?.toString(),
      saldoPagamento: 0.0,
      statusPagamento: 1,
    );

    await storage.limparPedidoPendenteUid();

    if (!mounted) return;

    setState(() => _loading = false);

    CustomAlert.show(
      context,
      title: 'Pagamento confirmado!',
      message: 'Pedido totalmente pago.',
      confirmText: 'OK',
      onConfirm: () => Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/home', (route) => false),
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
                  if (!_modoPagamentoExistente) ...[
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
                  ],
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false),
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
    );
  }

  Widget _buildTotalCard() {
    final valor = _valorPagamentoTeste;

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
              children: [
                const Icon(
                  Icons.credit_card_outlined,
                  color: Colors.white,
                  size: 68,
                ),
                const SizedBox(height: 8),
                Text(
                  _modoPagamentoExistente
                      ? 'Saldo restante'
                      : 'Valor a pagar agora',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  'R\$ ${valor.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_modoPagamentoExistente)
                  Text(
                    'Saldo atual do pedido',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
