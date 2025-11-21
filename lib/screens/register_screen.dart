import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _photoBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _photoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'As senhas não coincidem';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'A senha deve ter pelo menos 6 caracteres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.register(
      RegisterData(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        photo: _photoBase64,
      ),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pushReplacementNamed(context, '/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso! Faça login para continuar.'), backgroundColor: Colors.green),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['error'] ?? 'Erro ao cadastrar usuário';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
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
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back button
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                          Text('Criar Conta', style: Theme.of(context).textTheme.headlineMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Cadastre-se para criar seu próprio portfólio de mídia', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),

                      // Photo upload
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppTheme.slate700,
                                  backgroundImage:
                                      _photoBase64 != null
                                          ? (() {
                                            try {
                                              final comma = _photoBase64!.indexOf(',');
                                              if (comma != -1) {
                                                final data = _photoBase64!.substring(comma + 1);
                                                return MemoryImage(base64Decode(data));
                                              }
                                            } catch (_) {}
                                            return null;
                                          })()
                                          : null,
                                  child: _photoBase64 == null ? const Icon(Icons.add_a_photo_rounded, size: 32) : null,
                                ),
                              ),
                            ),
                            if (_photoBase64 != null)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), blurRadius: 8)],
                                  ),
                                  child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Foto do Perfil (opcional)', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                      const SizedBox(height: 24),

                      // Name fields
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                hintText: 'João',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Obrigatório';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(labelText: 'Sobrenome', hintText: 'Silva'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Obrigatório';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'seu@email.com',
                          prefixIcon: Icon(Icons.mail_outline),
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
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
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
                      const SizedBox(height: 16),

                      // Confirm Password field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Senha',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, confirme sua senha';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.red400.withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.red400),
                          ),
                          child: Text(_errorMessage!, style: TextStyle(color: AppTheme.red400), textAlign: TextAlign.center),
                        ),

                      // Register button
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
                          onPressed: _isLoading ? null : _handleRegister,
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
                                    'Criar Conta',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Já tem uma conta? ', style: Theme.of(context).textTheme.bodyMedium),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Fazer login'),
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
    );
  }
}
