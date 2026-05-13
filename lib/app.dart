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
        },
      ),
    );
  }
}
