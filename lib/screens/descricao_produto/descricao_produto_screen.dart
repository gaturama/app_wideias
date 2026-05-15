import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/cart_item_model.dart';
import '../../models/produto_model.dart';
import '../../widgets/custom_alert.dart';

class _Ingrediente {
  final String id;
  final String nome;
  bool incluso;
  final bool removable;
  _Ingrediente({required this.id, required this.nome,
      required this.incluso, required this.removable});
}

class _Adicional {
  final String id;
  final String nome;
  final double preco;
  bool selecionado;
  _Adicional({required this.id, required this.nome,
      required this.preco, this.selecionado = false});
}

class DescricaoProdutoScreen extends StatefulWidget {
  const DescricaoProdutoScreen({super.key});

  @override
  State<DescricaoProdutoScreen> createState() =>
      _DescricaoProdutoScreenState();
}

class _DescricaoProdutoScreenState extends State<DescricaoProdutoScreen> {
  ProdutoModel?       _produto;
  CartItemModel?      _itemEditando;
  int                 _editIndex = -1;
  List<CartItemModel> _cart      = [];
  bool                _editar    = false;
  bool                _loading   = true;

  final _obsCtrl = TextEditingController();
  final List<_Ingrediente> _ingredientes = [];
  final List<_Adicional>   _adicionais   = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args == null) { Navigator.of(context).pop(); return; }

    _produto      = args['produto'] is ProdutoModel
        ? args['produto']
        : ProdutoModel.fromJson(args['produto'] as Map<String, dynamic>);
    _editar       = args['editar']    as bool?  ?? false;
    _editIndex    = args['editIndex'] as int?   ?? -1;
    _cart         = List<CartItemModel>.from(args['cart'] ?? []);

    if (_editar && args['produtoEditado'] != null) {
      _itemEditando = args['produtoEditado'] is CartItemModel
          ? args['produtoEditado']
          : null;
      if (_itemEditando?.observacao != null) {
        _obsCtrl.text = _itemEditando!.observacao!;
      }
    }

    _carregarMock();
  }

  void _carregarMock() {
    // Mock — substitua por chamada real à API
    _ingredientes.addAll([
      _Ingrediente(id: 'i1', nome: 'Alface',  incluso: true,  removable: true),
      _Ingrediente(id: 'i2', nome: 'Tomate',  incluso: true,  removable: true),
      _Ingrediente(id: 'i3', nome: 'Cebola',  incluso: true,  removable: true),
    ]);
    _adicionais.addAll([
      _Adicional(id: 'a1', nome: 'Bacon crocante', preco: 5.00),
      _Adicional(id: 'a2', nome: 'Ovo frito',       preco: 3.00),
      _Adicional(id: 'a3', nome: 'Cheddar extra',   preco: 4.00),
    ]);

    // Restaurar edição
    if (_editar && _itemEditando != null) {
      for (final rem in _itemEditando!.ingredientesRemovidos) {
        for (final ing in _ingredientes) {
          if (ing.id == rem.id) ing.incluso = false;
        }
      }
      for (final sel in _itemEditando!.adicionais) {
        for (final add in _adicionais) {
          if (add.id == sel.id) add.selecionado = true;
        }
      }
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  double get _extraAdicionais =>
      _adicionais.where((a) => a.selecionado)
          .fold(0.0, (s, a) => s + a.preco);

  double get _precoTotal =>
      (_produto?.price ?? 0) + _extraAdicionais;

  void _adicionarAoCarrinho() {
    if (_produto == null) return;

    final item = CartItemModel(
      cartEntryId: _editar && _itemEditando != null
          ? _itemEditando!.cartEntryId
          : '${_produto!.id}-${DateTime.now().millisecondsSinceEpoch}',
      id:       _produto!.id,
      name:     _produto!.name,
      imageUrl: _produto!.imageUrl,
      price:    _produto!.price,
      qty:      _editar && _itemEditando != null ? _itemEditando!.qty : 1,
      observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      ingredientesRemovidos: _ingredientes
          .where((i) => i.removable && !i.incluso)
          .map((i) => IngredienteRemovido(id: i.id, name: i.nome))
          .toList(),
      adicionais: _adicionais
          .where((a) => a.selecionado)
          .map((a) => AdicionalSelecionado(
                id: a.id, nome: a.nome, preco: a.preco))
          .toList(),
    );

    final novoCart = List<CartItemModel>.from(_cart);
    if (_editar && _editIndex >= 0 && _editIndex < novoCart.length) {
      novoCart[_editIndex] = item;
    } else {
      novoCart.add(item);
    }

    Navigator.of(context).pop({'cart': novoCart});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _produto == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.bluePrimary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Imagem placeholder
                  Center(
                    child: Container(
                      width: 120, height: 120,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.fastfood_outlined,
                          color: AppColors.bluePrimary, size: 56),
                    ),
                  ),
                  Text(_produto!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  Text(_produto!.description ?? 'Produto delicioso',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSection)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.sell_outlined,
                          size: 14, color: AppColors.textSection),
                      const SizedBox(width: 4),
                      Text(
                        'Preço base: R\$ ${_produto!.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textEmpty),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_ingredientes.any((i) => i.removable)) ...[
                    _buildSectionTitle('Ingredientes', 'Toque para remover'),
                    ..._ingredientes
                        .where((i) => i.removable)
                        .map((i) => _buildIngredienteRow(i)),
                    const SizedBox(height: 16),
                  ],

                  if (_adicionais.isNotEmpty) ...[
                    _buildSectionTitle('Adicionais', 'Toque para adicionar'),
                    ..._adicionais.map((a) => _buildAdicionalRow(a)),
                    const SizedBox(height: 16),
                  ],

                  _buildSectionTitle('Observações', null),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder,
                          width: 1.5),
                    ),
                    child: TextField(
                      controller: _obsCtrl,
                      maxLines:   3,
                      decoration: const InputDecoration(
                        hintText: 'Ex: sem cebola, pouco molho...',
                        hintStyle:
                            TextStyle(color: AppColors.textEmpty),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFooter(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.bluePrimary,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Stack(
        children: [
          Positioned(top: -20, right: -30,
              child: _circle(120, AppColors.circleDeco1)),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                ),
              ),
              Expanded(
                child: Text(
                  _editar ? 'Editar Produto' : (_produto?.name ?? ''),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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

  Widget _buildSectionTitle(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            )),
        if (subtitle != null)
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textEmpty)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildIngredienteRow(_Ingrediente ing) {
    return GestureDetector(
      onTap: () => setState(() => ing.incluso = !ing.incluso),
      child: AnimatedOpacity(
        opacity: ing.incluso ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: ing.incluso
                      ? AppColors.greenSuccess
                      : AppColors.redError,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(ing.nome,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ing.incluso
                      ? AppColors.badgeBg
                      : AppColors.redErrorBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ing.incluso ? 'Incluso' : 'Removido',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ing.incluso
                        ? AppColors.greenSuccess
                        : AppColors.redError,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdicionalRow(_Adicional add) {
    return GestureDetector(
      onTap: () => setState(() => add.selecionado = !add.selecionado),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: add.selecionado ? AppColors.badgeBg : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: add.selecionado
                ? AppColors.bluePrimary
                : AppColors.cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: add.selecionado
                    ? AppColors.bluePrimary
                    : AppColors.textEmpty,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(add.nome,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary)),
            ),
            Text('+R\$ ${add.preco.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  color: add.selecionado
                      ? AppColors.bluePrimary
                      : AppColors.textSection,
                )),
            const SizedBox(width: 8),
            if (add.selecionado)
              const Icon(Icons.check_circle,
                  color: AppColors.bluePrimary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TOTAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.textSection,
                  )),
              Text('R\$ ${_precoTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  )),
              if (_extraAdicionais > 0)
                Text('+R\$ ${_extraAdicionais.toStringAsFixed(2)} em adicionais',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSection)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _adicionarAoCarrinho,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bluePrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: Icon(_editar
                  ? Icons.check : Icons.shopping_bag_outlined),
              label: Text(_editar ? 'Salvar' : 'Adicionar',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}