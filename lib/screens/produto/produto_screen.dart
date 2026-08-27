import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/product_service.dart';
import '../../models/cart_item_model.dart';
import '../../models/produto_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/storage_provider.dart';
import '../../widgets/bottom.nav_bar.dart';
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

  final ProductService _productService = ProductService();

  List<Map<String, dynamic>> _produtosApi = [];

  List<String> _grupos = [];

  String? _grupoSelecionado;
  String? _subgrupoSelecionado;

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

  Future<void> _carregarProdutos() async {
    try {
      final authProvider = context.read<AuthProvider>();

      final user = authProvider.user;

      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      if (user.token.isEmpty) {
        throw Exception('Token da sessão não encontrado.');
      }

      if (user.uid.isEmpty) {
        throw Exception('UID do cliente não encontrado.');
      }

      debugPrint('=== SESSÃO CARDÁPIO ===');

      debugPrint(
        'IDCliente disponível: '
        '${user.id.isNotEmpty}',
      );

      debugPrint(
        'UID disponível: '
        '${user.uid.isNotEmpty}',
      );

      debugPrint(
        'Token disponível: '
        '${user.token.isNotEmpty}',
      );

      final response = await _productService.getCardapio(
        appClienteToken: user.token,
        appClientUid: user.uid,
        cardapioId: '11588',
      );

      final cardapio = response['cardapio'] as Map<String, dynamic>?;

      if (cardapio == null) {
        throw Exception('Cardápio não encontrado.');
      }

      final produtos = (cardapio['produtos'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      final grupos = (cardapio['grupos'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      if (!mounted) {
        return;
      }

      setState(() {
        _produtosApi = produtos;

        _grupos = grupos
            .map((grupo) => grupo['Descricao']?.toString() ?? '')
            .where((descricao) => descricao.isNotEmpty)
            .toList();

        _aplicarFiltros();

        _loading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar cardápio: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _produtos = [];
      });
    }
  }

  void _aplicarFiltros() {
    Iterable<Map<String, dynamic>> filtrados = _produtosApi;

    if (_grupoSelecionado != null) {
      filtrados = filtrados.where(
        (produto) => produto['Grupo']?.toString() == _grupoSelecionado,
      );
    }

    if (_subgrupoSelecionado != null) {
      filtrados = filtrados.where(
        (produto) => produto['SubGrupo']?.toString() == _subgrupoSelecionado,
      );
    }

    _produtos = filtrados.map((produto) {
      return ProdutoModel.fromJson({
        'id': produto['ID'].toString(),
        'name': produto['Descricao']?.toString() ?? '',
        'price': (produto['Valor'] as num?)?.toDouble() ?? 0.0,
        'description': produto['SubGrupo']?.toString() ?? '',
      });
    }).toList();
  }

  List<String> get _subgruposDisponiveis {
    Iterable<Map<String, dynamic>> produtos = _produtosApi;

    if (_grupoSelecionado != null) {
      produtos = produtos.where(
        (produto) => produto['Grupo']?.toString() == _grupoSelecionado,
      );
    }

    return produtos
        .map((produto) => produto['SubGrupo']?.toString() ?? '')
        .where((subgrupo) => subgrupo.isNotEmpty)
        .toSet()
        .toList();
  }

  void _adicionarAoCarrinho(ProdutoModel produto) {
    final item = CartItemModel(
      cartEntryId: '${produto.id}-${DateTime.now().millisecondsSinceEpoch}',
      id: produto.id,
      name: produto.name,
      imageUrl: produto.imageUrl,
      price: produto.price,
      qty: 1,
    );
    setState(() => _cart.add(item));
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
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
      backgroundColor: AppColors.background,

      body: Column(
        children: [
          _buildHeader(),

          // Grupos e subgrupos
          if (!_loading) _buildCategorias(),

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
                    itemBuilder: (_, i) {
                      return _buildProdutoCard(_produtos[i]);
                    },
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
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -20,
            right: -50,
            child: _circle(150, AppColors.circleDeco1),
          ),
          Positioned(
            bottom: -5,
            left: -40,
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

  Widget _buildCategorias() {
    final subgrupos = _subgruposDisponiveis;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildCategoryChip(
                  texto: 'Todos',
                  selecionado: _grupoSelecionado == null,
                  onTap: () {
                    setState(() {
                      _grupoSelecionado = null;
                      _subgrupoSelecionado = null;

                      _aplicarFiltros();
                    });
                  },
                ),

                ..._grupos.map(
                  (grupo) => _buildCategoryChip(
                    texto: grupo,
                    selecionado: _grupoSelecionado == grupo,
                    onTap: () {
                      setState(() {
                        _grupoSelecionado = grupo;

                        // Sempre limpa o subgrupo
                        // quando troca o grupo.
                        _subgrupoSelecionado = null;

                        _aplicarFiltros();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          if (subgrupos.isNotEmpty) ...[
            const SizedBox(height: 10),

            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildSubCategoryChip(
                    texto: 'Todos',
                    selecionado: _subgrupoSelecionado == null,
                    onTap: () {
                      setState(() {
                        _subgrupoSelecionado = null;

                        _aplicarFiltros();
                      });
                    },
                  ),

                  ...subgrupos.map(
                    (subgrupo) => _buildSubCategoryChip(
                      texto: subgrupo,
                      selecionado: _subgrupoSelecionado == subgrupo,
                      onTap: () {
                        setState(() {
                          _subgrupoSelecionado = subgrupo;

                          _aplicarFiltros();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String texto,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: selecionado,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.bluePrimary,
        backgroundColor: AppColors.background,
        labelStyle: TextStyle(
          color: selecionado ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        side: BorderSide(
          color: selecionado ? AppColors.bluePrimary : AppColors.cardBorder,
        ),
      ),
    );
  }

  Widget _buildSubCategoryChip({
    required String texto,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: selecionado,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.bluePrimary.withOpacity(0.15),
        backgroundColor: AppColors.white,
        labelStyle: TextStyle(
          color: selecionado ? AppColors.bluePrimary : AppColors.textSection,
          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: selecionado ? AppColors.bluePrimary : AppColors.cardBorder,
        ),
      ),
    );
  }
}
