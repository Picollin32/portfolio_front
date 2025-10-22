import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_facade.dart';
import '../services/auth_strategy.dart';

/// Observer Pattern + Singleton Pattern: Gerenciamento de autenticação
///
/// Esta classe implementa:
/// 1. Observer Pattern (ChangeNotifier) - notifica widgets sobre mudanças
/// 2. Singleton Pattern - garante uma única instância do serviço
/// 3. Strategy Pattern - diferentes métodos de login intercambiáveis
class AuthProvider with ChangeNotifier {
  // Singleton instance
  static final AuthProvider _instance = AuthProvider._internal();

  factory AuthProvider() {
    return _instance;
  }

  AuthProvider._internal() {
    _loadUser();
  }

  // ========================================
  // State Management
  // ========================================

  User? _user;
  String? _token;
  bool _isLoading = true;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isAdmin => _user?.role == UserRole.admin;

  // ========================================
  // Strategy Pattern: Login Strategies
  // ========================================

  late final LoginStrategy _loginStrategy;
  final ApiFacade _apiFacade = ApiFacade();

  /// Define a estratégia de login a ser usada
  void setLoginStrategy(LoginStrategy strategy) {
    _loginStrategy = strategy;
  }

  /// Login usando a estratégia definida
  Future<bool> loginWithStrategy(Map<String, dynamic> credentials) async {
    try {
      final result = await _loginStrategy.login(credentials);

      if (result.success && result.data != null) {
        _user = result.data!.user;
        _token = result.data!.token;

        await _saveUser(_user!);
        await _saveToken(_token!);

        // Observer Pattern: notifica observers
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // ========================================
  // Authentication Methods
  // ========================================

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      final savedToken = prefs.getString('token');

      if (userJson != null && savedToken != null) {
        _user = User.fromJson(jsonDecode(userJson));
        _token = savedToken;
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      print('🔑 AuthProvider.login() chamado');
      print('📧 Email: $email');

      // Usa ApiFacade para simplificar a chamada
      final result = await _apiFacade.login(email: email, password: password);

      if (result.success && result.data != null) {
        _user = result.data!.user;
        _token = result.data!.token;

        await _saveUser(_user!);
        await _saveToken(_token!);

        print('✅ Login bem-sucedido!');
        notifyListeners(); // Observer Pattern: notifica observers
        return true;
      }

      print('❌ Login falhou');
      return false;
    } catch (e) {
      debugPrint('❌ Login error: $e');

      // Fallback para login local usando Strategy Pattern
      setLoginStrategy(LoginStrategyFactory.create(LoginType.local));
      return await loginWithStrategy({'email': email, 'password': password});
    }
  }

  Future<Map<String, dynamic>> register(RegisterData registerData) async {
    try {
      print('📝 AuthProvider.register() chamado');
      print('📧 Email: ${registerData.email}');

      // Usa ApiFacade para simplificar a chamada
      final result = await _apiFacade.register(
        email: registerData.email,
        password: registerData.password,
        firstName: registerData.firstName,
        lastName: registerData.lastName,
        photo: registerData.photo,
      );

      if (result.success) {
        print('✅ Registro bem-sucedido!');
        return {'success': true};
      } else {
        print('❌ Registro falhou: ${result.error}');
        return {'success': false, 'error': result.error};
      }
    } catch (e) {
      print('❌ Erro no registro: $e');

      // Fallback para SharedPreferences (se API não estiver disponível)
      try {
        final prefs = await SharedPreferences.getInstance();
        final usersJson = prefs.getString('registeredUsers');

        List<dynamic> users = [];
        if (usersJson != null) {
          users = jsonDecode(usersJson);
        }

        // Check if email already exists
        if (users.any((u) => u['email'] == registerData.email)) {
          return {'success': false, 'error': 'Este email já está cadastrado'};
        }

        if (registerData.email == 'admin@portfolio.com') {
          return {'success': false, 'error': 'Este email não pode ser usado'};
        }

        // Create new user
        final newUser = {'id': DateTime.now().millisecondsSinceEpoch.toString(), ...registerData.toJson()};

        users.add(newUser);
        await prefs.setString('registeredUsers', jsonEncode(users));

        print('✅ Registro local bem-sucedido (fallback)');
        return {'success': true};
      } catch (fallbackError) {
        debugPrint('Erro no fallback de registro: $fallbackError');
        return {'success': false, 'error': 'Erro ao cadastrar usuário'};
      }
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateProfile(ProfileUpdateData updates) async {
    if (_user == null) {
      return {'success': false, 'error': 'Usuário não autenticado'};
    }

    try {
      // Admin update
      if (_user!.role == UserRole.admin) {
        _user = _user!.copyWith(photo: updates.photo);
        await _saveUser(_user!);
        notifyListeners();
        return {'success': true};
      }

      // Regular user update
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('registeredUsers');

      if (usersJson != null) {
        List<dynamic> users = jsonDecode(usersJson);
        final userIndex = users.indexWhere((u) => u['id'] == _user!.id);

        if (userIndex == -1) {
          return {'success': false, 'error': 'Usuário não encontrado'};
        }

        final storedUser = users[userIndex];

        // Check current password if changing password
        if (updates.newPassword != null) {
          if (updates.currentPassword == null) {
            return {'success': false, 'error': 'Senha atual é obrigatória'};
          }
          if (storedUser['password'] != updates.currentPassword) {
            return {'success': false, 'error': 'Senha atual incorreta'};
          }
          storedUser['password'] = updates.newPassword;
        }

        // Update photo
        if (updates.photo != null) {
          storedUser['photo'] = updates.photo;
        }

        users[userIndex] = storedUser;
        await prefs.setString('registeredUsers', jsonEncode(users));

        // Update current user session
        _user = _user!.copyWith(photo: storedUser['photo']);
        await _saveUser(_user!);
        notifyListeners();

        return {'success': true};
      }

      return {'success': false, 'error': 'Erro ao atualizar perfil'};
    } catch (e) {
      debugPrint('Update profile error: $e');
      return {'success': false, 'error': 'Erro ao atualizar perfil'};
    }
  }

  Future<List<User>> getAllUsers() async {
    if (_user == null || _user!.role != UserRole.admin || _token == null) {
      return [];
    }

    try {
      print('👥 AuthProvider.getAllUsers() chamado');

      // Usa ApiFacade para simplificar a chamada
      final result = await _apiFacade.getAllUsers(_token!);

      if (result.success && result.data != null) {
        print('✅ ${result.data!.length} usuários recebidos da API');
        return result.data!;
      }

      print('⚠️ Falha na API, usando fallback local');
    } catch (e) {
      print('❌ Erro ao buscar usuários da API: $e');
    }

    // Fallback para SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('registeredUsers');

      if (usersJson != null) {
        final List<dynamic> users = jsonDecode(usersJson);
        return users
            .map(
              (u) => User(
                id: u['id'],
                email: u['email'],
                name: '${u['firstName']} ${u['lastName']}',
                firstName: u['firstName'],
                lastName: u['lastName'],
                photo: u['photo'],
                role: UserRole.user,
              ),
            )
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Get all users error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> deleteUser(String userId) async {
    if (_user == null || _user!.role != UserRole.admin || _token == null) {
      return {'success': false, 'error': 'Acesso negado'};
    }

    try {
      print('🗑️ AuthProvider.deleteUser() chamado para userId: $userId');

      // Tenta deletar via API
      final userIdInt = int.tryParse(userId);
      if (userIdInt != null) {
        final result = await _apiFacade.deleteUser(token: _token!, userId: userIdInt);

        if (result.success) {
          print('✅ Usuário deletado via API');
          return {'success': true};
        }

        print('⚠️ Falha na API: ${result.error}');
      }
    } catch (e) {
      print('❌ Erro ao deletar via API: $e');
    }

    // Fallback para SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('registeredUsers');

      if (usersJson != null) {
        List<dynamic> users = jsonDecode(usersJson);
        users.removeWhere((u) => u['id'] == userId);
        await prefs.setString('registeredUsers', jsonEncode(users));
        return {'success': true};
      }

      return {'success': false, 'error': 'Usuário não encontrado'};
    } catch (e) {
      debugPrint('Delete user error: $e');
      return {'success': false, 'error': 'Erro ao deletar usuário'};
    }
  }

  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> updates) async {
    if (_user == null || _user!.role != UserRole.admin || _token == null) {
      return {'success': false, 'error': 'Acesso negado'};
    }

    try {
      print('✏️ AuthProvider.updateUser() chamado para userId: $userId');
      print('📝 Updates: $updates');

      // Tenta atualizar via API
      final userIdInt = int.tryParse(userId);
      if (userIdInt != null) {
        // Extrai os campos para o formato da API
        String? fullName;
        if (updates.containsKey('firstName') && updates.containsKey('lastName')) {
          fullName = '${updates['firstName']} ${updates['lastName']}';
        } else if (updates.containsKey('full_name')) {
          fullName = updates['full_name'];
        }

        final result = await _apiFacade.updateUser(
          token: _token!,
          userId: userIdInt,
          fullName: fullName,
          profileImageUrl: updates['photo'],
          password: updates['password'],
        );

        if (result.success) {
          print('✅ Usuário atualizado via API');
          return {'success': true};
        }

        print('⚠️ Falha na API: ${result.error}');
      }
    } catch (e) {
      print('❌ Erro ao atualizar via API: $e');
    }

    // Fallback para SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('registeredUsers');

      if (usersJson != null) {
        List<dynamic> users = jsonDecode(usersJson);
        final userIndex = users.indexWhere((u) => u['id'] == userId);

        if (userIndex == -1) {
          return {'success': false, 'error': 'Usuário não encontrado'};
        }

        users[userIndex] = {...users[userIndex], ...updates};
        await prefs.setString('registeredUsers', jsonEncode(users));
        return {'success': true};
      }

      return {'success': false, 'error': 'Usuário não encontrado'};
    } catch (e) {
      debugPrint('Update user error: $e');
      return {'success': false, 'error': 'Erro ao atualizar usuário'};
    }
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }
}
