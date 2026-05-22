import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/cart_item_model.dart';
import '../../providers/storage_provider.dart';
import '../../widgets/custom_alert.dart';

class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({super.key});

  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  List<CartItemModel> _cart = [];
  final _obsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['cart'] != null) {
        setState(() => _cart = List<CartItemModel>.from(args['cart']));
      }
    });
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  double get _total => _cart.fold(0.0, (sum, item) => sum + item.precoTotal);

  int get _totalItens => _cart.fold(0, (sum, item) => sum + item.qty);

  void _aumentar(String id) {
    setState(() {
      for (final item in _cart) {
        if (item.cartEntryId == id) {
          item.qty++;
          break;
        }
      }
    });
  }

  void _diminuir(String id) {
    setState(() {
      final idx = _cart.indexWhere((e) => e.cartEntryId == id);
      if (idx < 0) return;
      if (_cart[idx].qty <= 1) {
        _cart.removeAt(idx);
      } else {
        _cart[idx].qty--;
      }
    });
  }

  void _editarItem(CartItemModel item) {
    final idx = _cart.indexOf(item);
    Navigator.of(context)
        .pushNamed(
          '/descricao-produto',
          arguments: {
            'produto': item,
            'produtoEditado': item,
            'cart': _cart,
            'editar': true,
            'editIndex': idx,
            'tipoLocal': context.read<StorageProvider>().tipoLocal,
            'locationId': context.read<StorageProvider>().locationId,
          },
        )
        .then((result) {
          if (result is Map && result['cart'] != null) {
            setState(() => _cart = List<CartItemModel>.from(result['cart']));
          }
        });
  }

  void _proximo() {
    if (_cart.isEmpty) {
      CustomAlert.show(
        dialogContext: context,
        context,
        title: 'Carrinho vazio',
        message: 'Adicione produtos antes de continuar',
      );
      return;
    }
    final storage = context.read<StorageProvider>();
    final tipoLocal = storage.tipoLocal;

    if (tipoLocal == 'restaurante') {
      Navigator.of(context).pushNamed(
        '/mesa',
        arguments: {
          'cart': _cart,
          'tipoLocal': tipoLocal,
          'locationId': storage.locationId,
          'observacoes': _obsCtrl.text,
          'total': _total,
        },
      );
    } else {
      Navigator.of(context).pushNamed(
        '/pagamento',
        arguments: {
          'cart': _cart,
          'locationId': storage.locationId,
          'observacoes': _obsCtrl.text,
          'mesa': null,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipoLocal = context.watch<StorageProvider>().tipoLocal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _cart.isEmpty
                ? _buildEmpty()
                : Column(
                    children: [
                      Expanded(child: _buildLista()),
                      _buildAddMore(),
                      _buildObservacoes(),
                      _buildFooter(tipoLocal),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.bluePrimary,
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

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Column(
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
                        'Carrinho',
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

                if (_cart.isNotEmpty) ...[
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.bluePrimary,
                          size: 15,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          '$_totalItens item${_totalItens > 1 ? 's' : ''} · R\$ ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.bluePrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 52,
            color: AppColors.textEmpty,
          ),
          const SizedBox(height: 12),
          const Text(
            'Seu carrinho está vazio',
            style: TextStyle(color: AppColors.textEmpty, fontSize: 15),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar produtos'),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemCount: _cart.length,
      itemBuilder: (_, i) => _buildCard(_cart[i]),
    );
  }

  Widget _buildCard(CartItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
              size: 24,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.ingredientesRemovidos.isNotEmpty)
                  ...item.ingredientesRemovidos.map(
                    (e) => Text(
                      '− Sem ${e.name}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.redError,
                      ),
                    ),
                  ),
                if (item.adicionais.isNotEmpty)
                  ...item.adicionais.map(
                    (e) => Text(
                      '+ ${e.nome} (R\$ ${e.preco.toStringAsFixed(2)})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.greenSuccess,
                      ),
                    ),
                  ),
                if (item.observacao != null && item.observacao!.isNotEmpty)
                  Text(
                    'Obs: ${item.observacao}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textEmpty,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'R\$ ${item.precoTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.bluePrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _editarItem(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Editar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.bluePrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              _qtyBtn(Icons.add, () => _aumentar(item.cartEntryId)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${item.qty}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _qtyBtn(Icons.remove, () => _diminuir(item.cartEntryId)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.badgeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.bluePrimary, size: 16),
    ),
  );

  Widget _buildAddMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          side: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(
          Icons.add_circle_outline,
          color: AppColors.bluePrimary,
        ),
        label: const Text(
          'Adicionar mais produtos',
          style: TextStyle(
            color: AppColors.bluePrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildObservacoes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OBSERVAÇÕES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textSection,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: TextField(
              controller: _obsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Alguma observação para o pedido?',
                hintStyle: TextStyle(color: AppColors.textEmpty),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(String tipoLocal) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: AppColors.white,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 12, color: AppColors.textSection),
              ),
              Text(
                'R\$ ${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _proximo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bluePrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(
                tipoLocal == 'restaurante' ? 'Escolher Mesa' : 'Pagamento',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
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
