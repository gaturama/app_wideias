import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wideias_app/models/historico_item_model.dart';
import 'package:wideias_app/providers/storage_provider.dart';
import 'package:wideias_app/widgets/custom_alert.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pedidos_provider.dart';
import '../../widgets/bottom.nav_bar.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<PedidosProvider>().carregar(auth.user!.id);
      }
    });
  }

  void _confirmarRepetirPedido(HistoricoItemModel item) {
    final storage = context.read<StorageProvider>();
    final auth = context.read<AuthProvider>();

    CustomAlert.show(
      context,
      dialogContext: context,
      title: 'Repetir pedido',
      message:
          'Deseja fazer novamente:\n"${item.productName}" (${item.quantity}x)\nR\$ ${item.total.toStringAsFixed(2)}?',
      confirmText: 'Pedir',
      cancelText: 'Cancelar',
      onConfirm: () async {
        await context.read<PedidosProvider>().repetirPedido(
          userId: auth.user?.id ?? '',
          item: item,
          locationId: storage.locationId ?? '',
          locationName: storage.locationName ?? '',
        );

        if (!mounted) return;
        CustomAlert.show(
          context,
          dialogContext: context,
          title: 'Pedido adicionado!',
          message: 'O pedido foi adicionado aos seus pendentes.',
          confirmText: 'Ver pedidos',
          onConfirm: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (r) => false),
        );
      },
      onCancel: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final itens = context.watch<PedidosProvider>().historico;

    return Scaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: itens.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 48,
                          color: AppColors.textEmpty,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nenhum pedido finalizado ainda',
                          style: TextStyle(
                            color: AppColors.textEmpty,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: itens.length,
                    itemBuilder: (_, i) => _buildCard(itens[i]),
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
      width: 500,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -55,
            right: -65,
            child: _circle(150, AppColors.circleDeco1),
          ),

          Positioned(
            bottom: -45,
            left: -45,
            child: _circle(110, AppColors.circleDeco2),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Seus pedidos finalizados',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(HistoricoItemModel item) {
    return GestureDetector(
      onTap: () => _confirmarRepetirPedido(item),
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
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.badgeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fastfood_outlined,
                color: AppColors.textEmpty,
                size: 28,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.locationName,
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
                  if (item.mesa != null && item.mesa!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Mesa: ${item.mesa}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textEmpty,
                        ),
                      ),
                    ),
                  if (item.observations != null &&
                      item.observations!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Obs: ${item.observations}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textEmpty,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.createdAt != null
                            ? _formatarData(item.createdAt!)
                            : '-',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textEmpty,
                        ),
                      ),
                      Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: AppColors.greenSuccess,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Concluído',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.greenSuccess,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.replay_outlined,
                color: AppColors.bluePrimary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
