import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/media_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/category_screen.dart';
import 'models/media_item_model.dart';
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
        onGenerateRoute: (settings) {
          // Custom page transitions
          Widget page;
          switch (settings.name) {
            case '/':
              page = const SplashScreen();
              break;
            case '/login':
              page = const LoginScreen();
              break;
            case '/register':
              page = const RegisterScreen();
              break;
            case '/portfolio':
              page = const PortfolioScreen();
              break;
            case '/admin':
              page = const AdminScreen();
              break;
            case '/jogos':
              page = const CategoryScreen(type: MediaType.game, title: 'Jogos', icon: Icons.videogame_asset_rounded);
              break;
            case '/filmes':
              page = const CategoryScreen(type: MediaType.movie, title: 'Filmes', icon: Icons.movie_rounded);
              break;
            case '/series':
              page = const CategoryScreen(type: MediaType.series, title: 'Séries', icon: Icons.tv_rounded);
              break;
            default:
              page = const SplashScreen();
          }

          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => page,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.05);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

              return FadeTransition(opacity: fadeAnimation, child: SlideTransition(position: offsetAnimation, child: child));
            },
            transitionDuration: const Duration(milliseconds: 400),
            settings: settings,
          );
        },
        // EnvironmentBanner agora dentro do builder
        builder: (context, child) {
          return EnvironmentBanner(showDebugInfo: false, child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}
