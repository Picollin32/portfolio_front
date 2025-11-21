import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));

    _animationController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
    } else if (authProvider.isAdmin) {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/portfolio');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 60, spreadRadius: 10),
                          ],
                        ),
                        child: Icon(Icons.collections_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Meu Portfólio',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
