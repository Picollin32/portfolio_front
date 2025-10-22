import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/media_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/admin_screen.dart';
import 'utils/app_theme.dart';
import 'config/config.dart';
import 'widgets/environment_banner.dart';

void main() {
  // Imprime informações de configuração
  Config.printConfig();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider()), ChangeNotifierProvider(create: (_) => MediaProvider())],
      child: MaterialApp(
        title: 'Meu Portfólio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/portfolio': (context) => const PortfolioScreen(),
          '/admin': (context) => const AdminScreen(),
          '/jogos': (context) => const CategoryPlaceholder(title: 'Jogos'),
          '/filmes': (context) => const CategoryPlaceholder(title: 'Filmes'),
          '/series': (context) => const CategoryPlaceholder(title: 'Séries'),
        },
        // EnvironmentBanner agora dentro do builder
        builder: (context, child) {
          return EnvironmentBanner(showDebugInfo: false, child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}

// Placeholder screens - These will be replaced with full implementations
class CategoryPlaceholder extends StatelessWidget {
  final String title;

  const CategoryPlaceholder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text('Tela de $title em construção')));
  }
}
