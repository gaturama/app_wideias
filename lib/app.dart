import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/storage_provider.dart';
import 'providers/pedidos_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/cadastro/cadastro_screen.dart';
import 'screens/localizacao/localizacao_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/credito/credito_screen.dart';
import 'screens/historico/historico_screen.dart';
import 'screens/perfil/perfil_screen.dart';
import 'screens/produto/produto_screen.dart';
import 'screens/carrinho/carrinho_screen.dart';
import 'screens/descricao_produto/descricao_produto_screen.dart';
import 'screens/mesa/mesa_screen.dart';
import 'screens/pagamento/pagamento_screen.dart';
import 'screens/dividir_conta/dividir_conta_screen.dart';
import 'screens/pix/pix_screen.dart';
import 'screens/qr_code/qr_code_screen.dart';
import 'screens/qr_scanner/qr_scanner_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..carregarSessao()),
        ChangeNotifierProvider(create: (_) => StorageProvider()..carregar()),
        ChangeNotifierProvider(create: (_) => PedidosProvider()),
      ],
      child: MaterialApp(
        title: 'Wideias',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: AppColors.bluePrimary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/cadastro': (_) => const CadastroScreen(),
          '/localizacao': (_) => const LocalizacaoScreen(),
          '/home': (_) => const HomeScreen(),
          '/credito': (_) => const CreditoScreen(),
          '/historico': (_) => const HistoricoScreen(),
          '/perfil': (_) => const PerfilScreen(),
          '/produto': (_) => const ProdutoScreen(),
          '/carrinho': (_) => const CarrinhoScreen(),
          '/descricao-produto': (_) => const DescricaoProdutoScreen(),
          '/mesa': (_) => const MesaScreen(),
          '/pagamento': (_) => const PagamentoScreen(),
          '/dividir-conta': (_) => const DividirContaScreen(),
          '/pix':        (_) => const PixScreen(),
          '/qr-code':    (_) => const QrCodeScreen(),
          '/qr-scanner': (_) => const QrScannerScreen(),
        },
      ),
    );
  }
}
