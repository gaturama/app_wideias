import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pedidos_provider.dart';
import '../../providers/storage_provider.dart';
import '../../widgets/custom_alert.dart';
import '../../widgets/bottom.nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados({bool refresh = false}) async {
    if (refresh) {
      setState(() => _refreshing = true);
    }

    final auth = context.read<AuthProvider>();
    final pedidos = context.read<PedidosProvider>();

    if (auth.user != null) {
      await pedidos.carregar(auth.user!.id);
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _refreshing = false;
      });
    }
  }

  void _continuarPagamento(OrderItemModel item) {
    Navigator.of(context).pushNamed(
      '/pagamento',
      arguments: {
        'pedidoUid': item.backendUid ?? item.orderId,
        'saldoPagamento': item.saldoPagamento,
        'locationId': item.order?.location?.id,
        'locationName': item.order?.location?.name,
        'mesa': item.order?.mesa,
      },
    );
  }

  void _confirmarRetirada(List<OrderItemModel> itens) {
    if (itens.isEmpty) return;

    final pedido = itens.first;

    if (!pedido.pagamentoConcluido) {
      return;
    }

    final produtos = itens
        .map((item) => '${item.quantity}x ${item.product?.name ?? 'Produto'}')
        .join('\n');

    CustomAlert.show(
      context,
      title: 'Confirmar retirada',
      message: 'Você está retirando este pedido?\n\n$produtos',
      confirmText: 'Sim',
      cancelText: 'Cancelar',
      onConfirm: () async {
        final auth = context.read<AuthProvider>();
        final pedidosProvider = context.read<PedidosProvider>();

        await pedidosProvider.concluirPedido(pedido, auth.user?.id ?? '');

        if (!mounted) return;

        CustomAlert.show(
          context,
          title: 'Pedido retirado',
          message: 'O pedido foi movido para o histórico.',
          confirmText: 'OK',
          onConfirm: () {
            Navigator.of(context).pushNamed('/historico');
          },
        );
      },
      onCancel: () {},
    );
  }

  Map<String, List<OrderItemModel>> _agruparPedidos(
    List<OrderItemModel> itens,
  ) {
    final grupos = <String, List<OrderItemModel>>{};

    for (final item in itens) {
      final chave = item.backendUid ?? item.orderId;
      grupos.putIfAbsent(chave, () => []);
      grupos[chave]!.add(item);
    }

    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageProvider>();
    final pedidosProvider = context.watch<PedidosProvider>();
    final auth = context.watch<AuthProvider>();

    final grupos = _agruparPedidos(pedidosProvider.pedidos);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: Column(
        children: [
          _buildHeader(auth.user?.nome ?? ''),
          _buildCardCredito(storage.credito),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PEDIDOS PENDENTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.textSection,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(grupos.values.toList())),
        ],
      ),
    );
  }

  Widget _buildHeader(String nome) {
    return Container(
      color: AppColors.bluePrimary,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Home',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _headerBtn(
            Icons.person_outline,
            () => Navigator.of(context).pushNamed('/perfil'),
          ),
          const SizedBox(width: 10),
          _headerBtn(
            Icons.qr_code_scanner,
            () => Navigator.of(context).pushNamed('/qr-scanner'),
          ),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildCardCredito(double credito) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      width: 450,
      decoration: BoxDecoration(
        color: AppColors.bluePrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -75,
            right: -70,
            child: _circle(150, AppColors.circleDeco1),
          ),
          Positioned(
            bottom: -65,
            left: -45,
            child: _circle(110, AppColors.circleDeco2),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CRÉDITO DISPONÍVEL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'R\$ ${credito.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<List<OrderItemModel>> pedidos) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.bluePrimary),
            SizedBox(height: 12),
            Text(
              'Carregando pedidos...',
              style: TextStyle(color: AppColors.textEmpty),
            ),
          ],
        ),
      );
    }

    if (pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textEmpty,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nenhum pedido pendente',
              style: TextStyle(color: AppColors.textEmpty, fontSize: 15),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _carregarDados(refresh: true),
              child: const Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.bluePrimary,
      onRefresh: () => _carregarDados(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: pedidos.length,
        itemBuilder: (_, i) {
          return _buildCard(pedidos[i]);
        },
      ),
    );
  }

  Widget _buildCard(List<OrderItemModel> itens) {
    final item = itens.first;

    final total = itens.fold<double>(0.0, (sum, item) => sum + item.total);

    final saldo = item.saldoPagamento;
    final pagamentoConcluido = item.pagamentoConcluido;

    final produtos = itens
        .map((item) => '${item.quantity}x ${item.product?.name ?? 'Produto'}')
        .join('\n');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.bluePrimary,
                  size: 24,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pedido',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textEmpty,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      produtos,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.order?.location?.name ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSection,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: R\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.bluePrimary,
                  ),
                ),
              ),
              const Spacer(),
              if (pagamentoConcluido)
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.greenSuccess,
                      size: 17,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Pagamento confirmado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenSuccess,
                      ),
                    ),
                  ],
                )
              else
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 17,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Pagamento pendente',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (!pagamentoConcluido && saldo > 0.01) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Falta pagar R\$ ${saldo.toStringAsFixed(2)}.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: pagamentoConcluido
                  ? () => _confirmarRetirada(itens)
                  : null,
              icon: Icon(
                pagamentoConcluido
                    ? Icons.check_circle_outline
                    : Icons.lock_outline,
              ),
              label: Text(
                pagamentoConcluido
                    ? 'CONFIRMAR RETIRADA'
                    : 'PAGAMENTO PENDENTE',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenSuccess,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.red.withOpacity(0.08),
                disabledForegroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (!pagamentoConcluido && saldo > 0.01) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _continuarPagamento(item),
                icon: const Icon(Icons.payment_outlined),
                label: Text('PAGAR SALDO R\$ ${saldo.toStringAsFixed(2)}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.bluePrimary,
                  side: const BorderSide(
                    color: AppColors.bluePrimary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
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
