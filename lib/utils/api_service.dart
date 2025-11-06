import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class ApiService {
  // Configuração da URL base da API
  // Usa automaticamente a URL correta baseada no ambiente (dev/prod)
  static String get baseUrl => Config.apiUrl;

  // Headers padrão para requisições
  static Map<String, String> get _headers => {'Content-Type': 'application/json', 'Accept': 'application/json'};

  // Headers com autenticação
  static Map<String, String> _authHeaders(String token) => {..._headers, 'Authorization': 'Bearer $token'};

  /// Login do usuário
  /// Retorna um mapa com 'success' (bool) e 'data' ou 'error'
  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    try {
      print('🔐 Tentando login com email: $email');
      print('🌐 URL: $baseUrl/auth/login');

      // FastAPI OAuth2PasswordRequestForm espera form-data, não JSON
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'username': email, // OAuth2 usa 'username' mesmo sendo email
              'password': password,
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Tempo de conexão esgotado');
            },
          );

      print('📡 Status da resposta: ${response.statusCode}');
      print('📄 Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Login bem-sucedido!');
        return {
          'success': true,
          'data': {'access_token': data['access_token'], 'token_type': data['token_type']},
        };
      } else if (response.statusCode == 401) {
        print('❌ Credenciais inválidas (401)');
        return {'success': false, 'error': 'Email ou senha incorretos'};
      } else {
        print('❌ Erro no servidor: ${response.statusCode}');
        return {'success': false, 'error': 'Erro no servidor: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro de conexão: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Decodifica o JWT token para obter informações do usuário
  /// Nota: Esta é uma decodificação básica sem validação de assinatura
  static Map<String, dynamic>? decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Busca dados do usuário (exemplo de requisição autenticada)
  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/me'), headers: _authHeaders(token)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Não autenticado'};
      } else {
        return {'success': false, 'error': 'Erro ao buscar perfil: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Registro de novo usuário (se disponível no backend)
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? photo,
  }) async {
    try {
      print('📝 Tentando registrar usuário: $email');
      print('🌐 URL: $baseUrl/auth/register');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'password': password,
              'first_name': firstName,
              'last_name': lastName,
              if (photo != null) 'photo': photo,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');
      print('📄 Corpo da resposta: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Registro bem-sucedido!');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final errorDetail = data['detail'] ?? 'Dados inválidos ou usuário já existe';
        print('❌ Erro 400: $errorDetail');
        return {'success': false, 'error': errorDetail};
      } else {
        print('❌ Erro no servidor: ${response.statusCode}');
        return {'success': false, 'error': 'Erro no servidor: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro de conexão no registro: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Verifica se a API está online
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/docs')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // ADMIN ENDPOINTS - User Management
  // ============================================

  /// Lista todos os usuários (ADMIN ONLY)
  static Future<Map<String, dynamic>> getAllUsers(String token) async {
    try {
      print('👥 Buscando todos os usuários');
      print('🌐 URL: $baseUrl/users/');

      final response = await http.get(Uri.parse('$baseUrl/users/'), headers: _authHeaders(token)).timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        print('✅ ${data.length} usuários encontrados');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Não autenticado'};
      } else if (response.statusCode == 403) {
        return {'success': false, 'error': 'Acesso negado. Permissões de admin necessárias.'};
      } else {
        return {'success': false, 'error': 'Erro ao buscar usuários: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao buscar usuários: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Atualiza um usuário (ADMIN ONLY)
  static Future<Map<String, dynamic>> updateUser({
    required String token,
    required int userId,
    String? fullName,
    String? profileImageUrl,
    String? password,
  }) async {
    try {
      print('✏️ Atualizando usuário ID: $userId');
      print('🌐 URL: $baseUrl/users/$userId');

      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (profileImageUrl != null) body['profile_image_url'] = profileImageUrl;
      if (password != null) body['password'] = password;

      final response = await http
          .put(Uri.parse('$baseUrl/users/$userId'), headers: _authHeaders(token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Usuário atualizado com sucesso');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Não autenticado'};
      } else if (response.statusCode == 403) {
        return {'success': false, 'error': 'Acesso negado'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Usuário não encontrado'};
      } else {
        return {'success': false, 'error': 'Erro ao atualizar usuário: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao atualizar usuário: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Deleta um usuário (ADMIN ONLY)
  static Future<Map<String, dynamic>> deleteUser({required String token, required int userId}) async {
    try {
      print('🗑️ Deletando usuário ID: $userId');
      print('🌐 URL: $baseUrl/users/$userId');

      final response = await http
          .delete(Uri.parse('$baseUrl/users/$userId'), headers: _authHeaders(token))
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Usuário deletado com sucesso');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Não autenticado'};
      } else if (response.statusCode == 403) {
        return {'success': false, 'error': 'Acesso negado'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Usuário não encontrado'};
      } else {
        return {'success': false, 'error': 'Erro ao deletar usuário: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao deletar usuário: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Redefine a senha de um usuário (ADMIN ONLY)
  static Future<Map<String, dynamic>> resetUserPassword({required String token, required int userId, required String newPassword}) async {
    try {
      print('🔑 Redefinindo senha do usuário ID: $userId');
      print('🌐 URL: $baseUrl/users/$userId/reset-password');

      final response = await http
          .put(
            Uri.parse('$baseUrl/users/$userId/reset-password'),
            headers: _authHeaders(token),
            body: jsonEncode({'new_password': newPassword}),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Senha redefinida com sucesso');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Não autenticado'};
      } else if (response.statusCode == 403) {
        return {'success': false, 'error': 'Acesso negado'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Usuário não encontrado'};
      } else {
        return {'success': false, 'error': 'Erro ao redefinir senha: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao redefinir senha: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // ============================================
  // MEDIA ENDPOINTS - Mídias (Jogos, Filmes, Séries)
  // ============================================

  /// Lista todas as mídias
  static Future<Map<String, dynamic>> getAllMidias({String? tipo, String? status}) async {
    try {
      print('🎮 Buscando todas as mídias');

      String url = '$baseUrl/midias/';
      final queryParams = <String>[];
      if (tipo != null) queryParams.add('tipo=$tipo');
      if (status != null) queryParams.add('status=$status');
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('🌐 URL: $url');

      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        print('✅ ${data.length} mídias encontradas');
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Erro ao buscar mídias: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao buscar mídias: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Busca uma mídia por ID
  static Future<Map<String, dynamic>> getMidiaById(int midiaId) async {
    try {
      print('🎮 Buscando mídia ID: $midiaId');
      print('🌐 URL: $baseUrl/midias/$midiaId');

      final response = await http.get(Uri.parse('$baseUrl/midias/$midiaId'), headers: _headers).timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Mídia encontrada');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Mídia não encontrada'};
      } else {
        return {'success': false, 'error': 'Erro ao buscar mídia: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao buscar mídia: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Cria uma nova mídia
  static Future<Map<String, dynamic>> createMidia({
    required String titulo,
    required String tipo,
    String? genero,
    int? ano,
    String? status,
    double? avaliacao,
    String? capa,
  }) async {
    try {
      print('➕ Criando nova mídia: $titulo');
      print('🌐 URL: $baseUrl/midias/');

      final body = <String, dynamic>{
        'titulo': titulo,
        'tipo': tipo,
        if (genero != null) 'genero': genero,
        if (ano != null) 'ano': ano,
        if (status != null) 'status': status,
        if (avaliacao != null) 'avaliacao': avaliacao,
        if (capa != null) 'capa': capa,
      };

      final response = await http
          .post(Uri.parse('$baseUrl/midias/'), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Mídia criada com sucesso');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final errorDetail = data['detail'] ?? 'Dados inválidos';
        print('❌ Erro 400: $errorDetail');
        return {'success': false, 'error': errorDetail};
      } else {
        return {'success': false, 'error': 'Erro ao criar mídia: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao criar mídia: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Atualiza uma mídia
  static Future<Map<String, dynamic>> updateMidia({
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
      print('✏️ Atualizando mídia ID: $midiaId');
      print('🌐 URL: $baseUrl/midias/$midiaId');

      final body = <String, dynamic>{};
      if (titulo != null) body['titulo'] = titulo;
      if (tipo != null) body['tipo'] = tipo;
      if (genero != null) body['genero'] = genero;
      if (ano != null) body['ano'] = ano;
      if (status != null) body['status'] = status;
      if (avaliacao != null) body['avaliacao'] = avaliacao;
      if (capa != null) body['capa'] = capa;

      final response = await http
          .put(Uri.parse('$baseUrl/midias/$midiaId'), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Mídia atualizada com sucesso');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Mídia não encontrada'};
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final errorDetail = data['detail'] ?? 'Dados inválidos';
        return {'success': false, 'error': errorDetail};
      } else {
        return {'success': false, 'error': 'Erro ao atualizar mídia: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao atualizar mídia: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Deleta uma mídia
  static Future<Map<String, dynamic>> deleteMidia(int midiaId) async {
    try {
      print('🗑️ Deletando mídia ID: $midiaId');
      print('🌐 URL: $baseUrl/midias/$midiaId');

      final response = await http.delete(Uri.parse('$baseUrl/midias/$midiaId'), headers: _headers).timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Mídia deletada com sucesso');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Mídia não encontrada'};
      } else {
        return {'success': false, 'error': 'Erro ao deletar mídia: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao deletar mídia: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // ============================================
  // MEDIA CONFIG ENDPOINTS - Configurações de Mídias
  // ============================================

  /// Busca todos os tipos de mídia disponíveis
  static Future<Map<String, dynamic>> getTiposMidia() async {
    try {
      print('📋 Buscando tipos de mídia');
      print('🌐 URL: $baseUrl/midias/tipos');

      final response = await http.get(Uri.parse('$baseUrl/midias/tipos'), headers: _headers).timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        print('✅ ${data.length} tipos encontrados');
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Erro ao buscar tipos: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao buscar tipos: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Busca os status disponíveis para um tipo de mídia
  static Future<Map<String, dynamic>> getStatusPorTipo(String tipo) async {
    try {
      print('📋 Buscando status para tipo: $tipo');
      print('🌐 URL: $baseUrl/midias/status/$tipo');

      final response = await http.get(Uri.parse('$baseUrl/midias/status/$tipo'), headers: _headers).timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        print('✅ ${data.length} status encontrados');
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Erro ao buscar status: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao buscar status: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Busca os gêneros comuns para um tipo de mídia
  static Future<Map<String, dynamic>> getGenerosPorTipo(String tipo) async {
    try {
      print('📋 Buscando gêneros para tipo: $tipo');
      print('🌐 URL: $baseUrl/midias/generos/$tipo');

      final response = await http.get(Uri.parse('$baseUrl/midias/generos/$tipo'), headers: _headers).timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        print('✅ ${data.length} gêneros encontrados');
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Erro ao buscar gêneros: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao buscar gêneros: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  /// Busca toda a configuração de mídias de uma vez
  static Future<Map<String, dynamic>> getMidiasConfig() async {
    try {
      print('📋 Buscando configuração completa de mídias');
      print('🌐 URL: $baseUrl/midias/config');

      final response = await http.get(Uri.parse('$baseUrl/midias/config'), headers: _headers).timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Configuração carregada com sucesso');
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Erro ao buscar configuração: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erro ao buscar configuração: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }
}
