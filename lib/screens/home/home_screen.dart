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
    if (refresh) setState(() => _refreshing = true);
    final auth = context.read<AuthProvider>();
    final pedidos = context.read<PedidosProvider>();
    if (auth.user != null) await pedidos.carregar(auth.user!.id);
    if (mounted)
      setState(() {
        _loading = false;
        _refreshing = false;
      });
  }

  void _confirmarRetirada(OrderItemModel item) {
    CustomAlert.show(
      context,
      dialogContext: context,
      title: 'Confirmar retirada',
      message: 'Você está retirando "${item.product?.name ?? 'Produto'}"?',
      confirmText: 'Sim',
      cancelText: 'Cancelar',
      onConfirm: () async {
        final auth = context.read<AuthProvider>();
        final pedidos = context.read<PedidosProvider>();
        await pedidos.concluirItem(item.id, auth.user?.id ?? '');
        if (!mounted) return;
        CustomAlert.show(
          context,
          dialogContext: context,
          title: 'Item retirado',
          message: 'Esse item foi movido para histórico!',
          confirmText: 'OK',
          onConfirm: () {
            _carregarDados();
            Navigator.of(context).pushNamed('/historico');
          },
        );
      },
      onCancel: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageProvider>();
    final pedidos = context.watch<PedidosProvider>();
    final auth = context.watch<AuthProvider>();
    final itens = pedidos.pedidos;

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
          Expanded(child: _buildBody(itens)),
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

  Widget _headerBtn(IconData icon, VoidCallback onTap) => GestureDetector(
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

  Widget _buildBody(List<OrderItemModel> itens) {
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
    if (itens.isEmpty) {
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
        itemCount: itens.length,
        itemBuilder: (_, i) => _buildCard(itens[i]),
      ),
    );
  }

  Widget _buildCard(OrderItemModel item) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        '/qr-code',
        arguments: {
          'pedidoId': item.orderId,
          'usuario': item.product?.name ?? 'Produto',
          'valorTotal': item.total,
          'produtos': ['${item.quantity}x ${item.product?.name ?? 'Produto'}'],
        },
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
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
                Icons.fastfood_outlined,
                color: AppColors.bluePrimary,
                size: 24,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product?.name ?? 'Produto',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.order?.location?.name ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSection,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Qtd: ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.bluePrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'R\$ ${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.bluePrimary,
                        ),
                      ),
                    ],
                  ),
                  if (item.observations != null &&
                      item.observations!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Obs: ${item.observations}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textEmpty,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _confirmarRetirada(item),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.greenSuccess,
                size: 32,
              ),
            ),
          ],
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
