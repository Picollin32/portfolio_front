// lib/services/auth_strategy.dart

import 'dart:convert';
import '../models/user_model.dart';
import 'api_facade.dart';

/// Strategy Pattern: Define interface para diferentes estratégias de login
///
/// Permite implementar diferentes métodos de autenticação de forma
/// intercambiável (email/senha, token, biometria, etc.)
abstract class LoginStrategy {
  Future<ApiResponse<LoginResult>> login(Map<String, dynamic> credentials);
}

/// Estratégia de login com email e senha
class EmailPasswordLoginStrategy implements LoginStrategy {
  final ApiFacade _apiFacade = ApiFacade();

  @override
  Future<ApiResponse<LoginResult>> login(Map<String, dynamic> credentials) async {
    final email = credentials['email'] as String;
    final password = credentials['password'] as String;

    return await _apiFacade.login(email: email, password: password);
  }
}

/// Estratégia de login com token (para sessões persistidas)
class TokenLoginStrategy implements LoginStrategy {
  @override
  Future<ApiResponse<LoginResult>> login(Map<String, dynamic> credentials) async {
    final token = credentials['token'] as String;

    // Valida e decodifica o token
    try {
      final payload = _decodeToken(token);

      if (payload != null) {
        final userEmail = payload['sub'] as String;
        final userRole = payload['role'] as String;

        return ApiResponse.success(
          LoginResult(
            token: token,
            user: User(
              id: userEmail,
              email: userEmail,
              name: userRole == 'admin' ? 'Administrador' : 'Usuário',
              role: userRole == 'admin' ? UserRole.admin : UserRole.user,
            ),
          ),
        );
      }

      return ApiResponse.error('Token inválido');
    } catch (e) {
      return ApiResponse.error('Erro ao validar token: $e');
    }
  }

  Map<String, dynamic>? _decodeToken(String token) {
    // Implementação simplificada - use uma biblioteca JWT real em produção
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));

      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

/// Estratégia de login local/offline (fallback)
class LocalLoginStrategy implements LoginStrategy {
  @override
  Future<ApiResponse<LoginResult>> login(Map<String, dynamic> credentials) async {
    final email = credentials['email'] as String;
    final password = credentials['password'] as String;

    // Fallback apenas para admin
    if (email == 'admin@portfolio.com' && password == 'admin123') {
      return ApiResponse.success(
        LoginResult(token: 'local-admin-token', user: User(id: 'admin', email: email, name: 'Administrador', role: UserRole.admin)),
      );
    }

    return ApiResponse.error('Credenciais inválidas');
  }
}

/// Factory para criar estratégias de login
class LoginStrategyFactory {
  static LoginStrategy create(LoginType type) {
    switch (type) {
      case LoginType.emailPassword:
        return EmailPasswordLoginStrategy();
      case LoginType.token:
        return TokenLoginStrategy();
      case LoginType.local:
        return LocalLoginStrategy();
    }
  }
}

enum LoginType { emailPassword, token, local }
