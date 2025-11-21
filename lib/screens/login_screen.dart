import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(_emailController.text, _passwordController.text);

      if (!mounted) return;

      if (success) {
        // Navigate based on user role
        if (authProvider.isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/portfolio');
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Email ou senha incorretos. Verifique se o backend está rodando.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao conectar com o servidor. Verifique se o backend está rodando em http://localhost:8000';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.15),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Card(
                  elevation: 20,
                  shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.surface.withOpacity(0.9),
                          Theme.of(context).colorScheme.surface.withOpacity(0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Icon with glow effect
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                                ),
                                boxShadow: [
                                  BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                                ],
                              ),
                              child: const Icon(Icons.collections_rounded, size: 48, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Title
                          Text(
                            'Meu Portfólio',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Entre na sua conta para gerenciar seu universo de mídia',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'seu@email.com',
                              prefixIcon: const Icon(Icons.mail_outline_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira seu email';
                              }
                              if (!value.contains('@')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira sua senha';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.red400.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.red400.withOpacity(0.5), width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: AppTheme.red400, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppTheme.red400))),
                                ],
                              ),
                            ),

                          // Login button
                          Container(
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                      : const Text(
                                        'Entrar',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Não tem uma conta? ', style: Theme.of(context).textTheme.bodyMedium),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                child: Text(
                                  'Cadastre-se',
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
