import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/cart_item_model.dart';
import '../../models/produto_model.dart';
import '../../providers/storage_provider.dart';
import '../../widgets/custom_alert.dart';

class ProdutoScreen extends StatefulWidget {
  const ProdutoScreen({super.key});

  @override
  State<ProdutoScreen> createState() => _ProdutoScreenState();
}

class _ProdutoScreenState extends State<ProdutoScreen> {
  List<ProdutoModel> _produtos = [];
  List<CartItemModel> _cart = [];
  bool _loading = true;

  final List<Map<String, dynamic>> _mockProdutos = [
    {
      'id': 'p1',
      'name': 'Pizza Marguerita',
      'price': 49.90,
      'description': 'Molho de tomate, mussarela, manjericão e azeite.',
    },
    {
      'id': 'p2',
      'name': 'Hambúrguer Clássico',
      'price': 32.90,
      'description':
          'Carne de 180g artesanal, queijo cheddar, alface, tomate e maionese especial.',
    },
    {
      'id': 'p3',
      'name': 'Batata Frita',
      'price': 18.90,
      'description': 'Crocante e temperada.',
    },
    {
      'id': 'p4',
      'name': 'Coca-Cola 600ml',
      'price': 9.90,
      'description': 'Gelada.',
    },
    {
      'id': 'p5',
      'name': 'Sorvete de Chocolate',
      'price': 14.90,
      'description': 'Delicioso sorvete de chocolate.',
    },
    {
      'id': 'p6',
      'name': 'Água Mineral',
      'price': 5.00,
      'description': 'Sem gás, 500ml.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['cart'] != null) {
        setState(() {
          _cart = List<CartItemModel>.from(args['cart']);
        });
      }
    });
  }

  void _carregarProdutos() {
    setState(() {
      _produtos = _mockProdutos.map((e) => ProdutoModel.fromJson(e)).toList();
      _loading = false;
    });
  }

  void _adicionarAoCarrinho(ProdutoModel produto) {
    Navigator.of(context)
        .pushNamed(
          '/descricao-produto',
          arguments: {
            'produto': produto,
            'cart': _cart,
            'tipoLocal': context.read<StorageProvider>().tipoLocal,
            'locationId': context.read<StorageProvider>().locationId,
            'editar': false,
          },
        )
        .then((result) {
          if (result is Map && result['cart'] != null) {
            setState(() {
              _cart = List<CartItemModel>.from(result['cart']);
            });
          }
        });
  }

  void _irParaCarrinho() {
    Navigator.of(
      context,
    ).pushNamed('/carrinho', arguments: {'cart': _cart}).then((result) {
      if (result is List<CartItemModel>) {
        setState(() => _cart = result);
      }
    });
  }

  double get _total => _cart.fold(0, (sum, item) => sum + item.precoTotal);

  int get _totalItens => _cart.fold(0, (sum, item) => sum + item.qty);

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.bluePrimary,
                    ),
                  )
                : _produtos.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 48,
                          color: AppColors.textEmpty,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nenhum produto disponível',
                          style: TextStyle(color: AppColors.textEmpty),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _produtos.length,
                    itemBuilder: (_, i) => _buildProdutoCard(_produtos[i]),
                  ),
          ),
        ],
      ),
      bottomSheet: _cart.isNotEmpty ? _buildCartFooter() : null,
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
            child: _circle(150, AppColors.circleDeco1),
          ),
          Positioned(
            bottom: -20,
            left: -30,
            child: _circle(110, AppColors.circleDeco2),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Produtos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_cart.isNotEmpty)
                GestureDetector(
                  onTap: _irParaCarrinho,
                  child: Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$_totalItens',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildProdutoCard(ProdutoModel produto) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.badgeBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fastfood_outlined,
              color: AppColors.bluePrimary,
              size: 32,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              produto.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${produto.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.bluePrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton(
                onPressed: () => _adicionarAoCarrinho(produto),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'ADICIONAR',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCartFooter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _irParaCarrinho,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$_totalItens',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.bluePrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_totalItens item${_totalItens > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'R\$ ${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.bluePrimary,
                  ),
                ),
                const SizedBox(width: 12),
                const Row(
                  children: [
                    Text(
                      'Ver carrinho',
                      style: TextStyle(
                        color: AppColors.bluePrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.bluePrimary,
                      size: 16,
                    ),
                  ],
                ),
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
