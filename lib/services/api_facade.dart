// lib/services/api_facade.dart

import '../models/user_model.dart';
import '../utils/api_service.dart';

/// Facade Pattern: Simplifica operações complexas da API
///
/// A classe ApiFacade fornece uma interface unificada e simplificada
/// para interações com a API, abstraindo a complexidade das chamadas
/// HTTP e combinando múltiplos serviços (auth, users, etc.)
class ApiFacade {
  // Singleton instance
  static final ApiFacade _instance = ApiFacade._internal();

  factory ApiFacade() {
    return _instance;
  }

  ApiFacade._internal();

  // ========================================
  // Authentication Operations
  // ========================================

  /// Realiza login e retorna token + informações do usuário
  Future<ApiResponse<LoginResult>> login({required String email, required String password}) async {
    try {
      final result = await ApiService.login(email: email, password: password);

      if (result['success'] == true) {
        final token = result['data']['access_token'] as String;
        final payload = ApiService.decodeJwtPayload(token);

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
      }

      return ApiResponse.error(result['error'] ?? 'Falha no login');
    } catch (e) {
      return ApiResponse.error('Erro ao fazer login: $e');
    }
  }

  /// Registra um novo usuário
  Future<ApiResponse<void>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? photo,
  }) async {
    try {
      final result = await ApiService.register(email: email, password: password, firstName: firstName, lastName: lastName, photo: photo);

      if (result['success'] == true) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(result['error'] ?? 'Falha no registro');
    } catch (e) {
      return ApiResponse.error('Erro ao registrar: $e');
    }
  }

  // ========================================
  // User Management Operations
  // ========================================

  /// Busca todos os usuários (requer admin)
  Future<ApiResponse<List<User>>> getAllUsers(String token) async {
    try {
      final result = await ApiService.getAllUsers(token);

      if (result['success'] == true) {
        final List<dynamic> usersData = result['data'];

        final users =
            usersData.map((userData) {
              return User(
                id: userData['id'].toString(),
                email: userData['email'],
                name: userData['full_name'] ?? 'Sem nome',
                firstName: userData['full_name']?.split(' ').first,
                lastName: userData['full_name']?.split(' ').skip(1).join(' '),
                photo: userData['profile_image_url'],
                role: userData['role']['name'] == 'admin' ? UserRole.admin : UserRole.user,
              );
            }).toList();

        return ApiResponse.success(users);
      }

      return ApiResponse.error(result['error'] ?? 'Falha ao buscar usuários');
    } catch (e) {
      return ApiResponse.error('Erro ao buscar usuários: $e');
    }
  }

  /// Atualiza um usuário (requer admin)
  Future<ApiResponse<void>> updateUser({
    required String token,
    required int userId,
    String? fullName,
    String? profileImageUrl,
    String? password,
  }) async {
    try {
      final result = await ApiService.updateUser(
        token: token,
        userId: userId,
        fullName: fullName,
        profileImageUrl: profileImageUrl,
        password: password,
      );

      if (result['success'] == true) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(result['error'] ?? 'Falha ao atualizar usuário');
    } catch (e) {
      return ApiResponse.error('Erro ao atualizar usuário: $e');
    }
  }

  /// Deleta um usuário (requer admin)
  Future<ApiResponse<void>> deleteUser({required String token, required int userId}) async {
    try {
      final result = await ApiService.deleteUser(token: token, userId: userId);

      if (result['success'] == true) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(result['error'] ?? 'Falha ao deletar usuário');
    } catch (e) {
      return ApiResponse.error('Erro ao deletar usuário: $e');
    }
  }

  // ========================================
  // Media Management Operations
  // ========================================

  /// Busca todas as mídias
  Future<ApiResponse<List<dynamic>>> getAllMidias({String? tipo, String? status}) async {
    try {
      final result = await ApiService.getAllMidias(tipo: tipo, status: status);

      if (result['success'] == true) {
        final List<dynamic> midiasData = result['data'];
        return ApiResponse.success(midiasData);
      }

      return ApiResponse.error(result['error'] ?? 'Falha ao buscar mídias');
    } catch (e) {
      return ApiResponse.error('Erro ao buscar mídias: $e');
    }
  }

  /// Cria uma nova mídia
  Future<ApiResponse<dynamic>> createMidia({
    required String titulo,
    required String tipo,
    String? genero,
    int? ano,
    String? status,
    double? avaliacao,
    String? capa,
  }) async {
    try {
      final result = await ApiService.createMidia(
        titulo: titulo,
        tipo: tipo,
        genero: genero,
        ano: ano,
        status: status,
        avaliacao: avaliacao,
        capa: capa,
      );

      if (result['success'] == true) {
        return ApiResponse.success(result['data']);
      }

      return ApiResponse.error(result['error'] ?? 'Falha ao criar mídia');
    } catch (e) {
      return ApiResponse.error('Erro ao criar mídia: $e');
    }
  }

  /// Atualiza uma mídia
  Future<ApiResponse<dynamic>> updateMidia({
    required int midiaId,
    String? titulo,
    String? tipo,
    String? genero,
    int? ano,
    String? status,
    double? avaliacao,
    String? capa,
  }) async {
    try {
      final result = await ApiService.updateMidia(
        midiaId: midiaId,
        titulo: titulo,
        tipo: tipo,
        genero: genero,
        ano: ano,
        status: status,
        avaliacao: avaliacao,
        capa: capa,
      );

      if (result['success'] == true) {
        return ApiResponse.success(result['data']);
      }

      return ApiResponse.error(result['error'] ?? 'Falha ao atualizar mídia');
    } catch (e) {
      return ApiResponse.error('Erro ao atualizar mídia: $e');
    }
  }

  /// Deleta uma mídia
  Future<ApiResponse<void>> deleteMidia(int midiaId) async {
    try {
      final result = await ApiService.deleteMidia(midiaId);

      if (result['success'] == true) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(result['error'] ?? 'Falha ao deletar mídia');
    } catch (e) {
      return ApiResponse.error('Erro ao deletar mídia: $e');
    }
  }

  // ========================================
  // Batch Operations (Facade benefit)
  // ========================================

  /// Operação combinada: Login + buscar dados completos do usuário
  Future<ApiResponse<UserSession>> loginAndFetchProfile({required String email, required String password}) async {
    // 1. Faz login
    final loginResponse = await login(email: email, password: password);

    if (!loginResponse.success) {
      return ApiResponse.error(loginResponse.error!);
    }

    // 2. Se for admin, busca lista de usuários
    List<User>? allUsers;
    if (loginResponse.data!.user.role == UserRole.admin) {
      final usersResponse = await getAllUsers(loginResponse.data!.token);
      if (usersResponse.success) {
        allUsers = usersResponse.data;
      }
    }

    return ApiResponse.success(UserSession(token: loginResponse.data!.token, user: loginResponse.data!.user, allUsers: allUsers));
  }
}

// ========================================
// Data Transfer Objects
// ========================================

/// Resultado do login
class LoginResult {
  final String token;
  final User user;

  LoginResult({required this.token, required this.user});
}

/// Sessão completa do usuário
class UserSession {
  final String token;
  final User user;
  final List<User>? allUsers;

  UserSession({required this.token, required this.user, this.allUsers});
}

/// Resposta genérica da API
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse._({required this.success, this.data, this.error});

  factory ApiResponse.success(T data) {
    return ApiResponse._(success: true, data: data);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(success: false, error: error);
  }
}
