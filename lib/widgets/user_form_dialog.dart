import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/profile_photo_upload_widget.dart';

class UserFormDialog extends StatefulWidget {
  final User? user;

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _firstNameController.text = widget.user!.firstName ?? '';
      _lastNameController.text = widget.user!.lastName ?? '';
      _emailController.text = widget.user!.email;
      _photoUrl = widget.user!.photo;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.user != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();

    try {
      if (_isEditing) {
        // Update user
        final updates = {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'email': _emailController.text,
          'photo': _photoUrl,
        };

        // Only update password if provided
        if (_passwordController.text.isNotEmpty) {
          updates['password'] = _passwordController.text;
        }

        final result = await authProvider.updateUser(widget.user!.id, updates);

        if (mounted) {
          if (result['success'] == true) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Usuário atualizado com sucesso!'), backgroundColor: Colors.green));
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Erro ao atualizar usuário'), backgroundColor: Colors.red));
          }
        }
      } else {
        // Create new user
        final registerData = RegisterData(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          photo: _photoUrl,
        );

        final result = await authProvider.register(registerData);

        if (mounted) {
          if (result['success'] == true) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Usuário criado com sucesso!'), backgroundColor: Colors.green));
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Erro ao criar usuário'), backgroundColor: Colors.red));
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  Icon(_isEditing ? Icons.edit : Icons.person_add, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Editar Usuário' : 'Novo Usuário',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Photo Upload
                      Center(
                        child: Column(
                          children: [
                            ProfilePhotoUploadWidget(
                              imageUrl: _photoUrl,
                              onImageSelected: (String imageUrl) {
                                setState(() => _photoUrl = imageUrl);
                              },
                              size: 100,
                            ),
                            const SizedBox(height: 8),
                            Text('Foto de perfil (opcional)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // First Name
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o nome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Last Name
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Sobrenome',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o sobrenome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o email';
                          }
                          if (!value.contains('@')) {
                            return 'Por favor, insira um email válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Section
                      if (_isEditing) ...[
                        Text(
                          'Deixe em branco para manter a senha atual',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: _isEditing ? 'Nova Senha (opcional)' : 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          // Password is required for new users
                          if (!_isEditing && (value == null || value.isEmpty)) {
                            return 'Por favor, insira a senha';
                          }

                          // Validate password strength if provided
                          if (value != null && value.isNotEmpty && value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          // Confirm password is required when password is provided
                          if (_passwordController.text.isNotEmpty) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, confirme a senha';
                            }
                            if (value != _passwordController.text) {
                              return 'As senhas não coincidem';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer with buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child:
                        _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_isEditing ? 'Salvar' : 'Criar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
