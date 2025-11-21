import 'package:flutter/material.dart';
import '../models/media_item_model.dart';
import '../utils/api_service.dart';

class MediaProvider with ChangeNotifier {
  List<MediaItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String? _token; // Token JWT para autenticação

  List<MediaItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MediaProvider();

  /// Define o token de autenticação
  void setToken(String? token) {
    _token = token;
    if (token != null) {
      loadFromApi(); // Recarrega dados quando o token é definido
    }
  }

  /// Carrega todas as mídias da API (requer autenticação)
  Future<void> loadFromApi({String? tipo, String? status}) async {
    if (_token == null) {
      _error = 'Usuário não autenticado';
      debugPrint('❌ Token não disponível');
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getAllMidias(token: _token!, tipo: tipo, status: status);

      if (result['success'] == true) {
        final List<dynamic> data = result['data'];
        _items = data.map((json) => MediaItem.fromJson(json)).toList();
        _error = null;
      } else {
        _error = result['error'] ?? 'Erro ao carregar mídias';
        debugPrint('❌ Erro ao carregar mídias: $_error');
      }
    } catch (e) {
      _error = 'Erro de conexão: $e';
      debugPrint('❌ Erro ao carregar mídias: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<MediaItem> getAll() {
    return [..._items];
  }

  MediaItem? getById(int id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  List<MediaItem> getByType(MediaType type) {
    return _items.where((item) => item.type == type).toList();
  }

  /// Cria uma nova mídia na API (requer autenticação)
  Future<MediaItem?> create(MediaItem item) async {
    if (_token == null) {
      _error = 'Usuário não autenticado';
      debugPrint('❌ Token não disponível');
      return null;
    }

    try {
      final jsonData = item.toJson();

      final result = await ApiService.createMidia(
        token: _token!,
        titulo: jsonData['titulo'],
        tipo: jsonData['tipo'],
        genero: jsonData['genero'],
        ano: jsonData['ano'],
        status: jsonData['status'],
        avaliacao: jsonData['avaliacao'],
        capa: jsonData['capa'],
      );

      if (result['success'] == true) {
        final newItem = MediaItem.fromJson(result['data']);
        _items.add(newItem);
        notifyListeners();
        return newItem;
      } else {
        _error = result['error'];
        debugPrint('❌ Erro ao criar mídia: $_error');
        return null;
      }
    } catch (e) {
      _error = 'Erro ao criar mídia: $e';
      debugPrint('❌ $_error');
      return null;
    }
  }

  /// Atualiza uma mídia na API (requer autenticação)
  Future<MediaItem?> update(int id, MediaItem updates) async {
    if (_token == null) {
      _error = 'Usuário não autenticado';
      debugPrint('❌ Token não disponível');
      return null;
    }

    try {
      final jsonData = updates.toJson();

      final result = await ApiService.updateMidia(
        token: _token!,
        midiaId: id,
        titulo: jsonData['titulo'],
        tipo: jsonData['tipo'],
        genero: jsonData['genero'],
        ano: jsonData['ano'],
        status: jsonData['status'],
        avaliacao: jsonData['avaliacao'],
        capa: jsonData['capa'],
      );

      if (result['success'] == true) {
        final updatedItem = MediaItem.fromJson(result['data']);
        final index = _items.indexWhere((item) => item.id == id);
        if (index != -1) {
          _items[index] = updatedItem;
          notifyListeners();
        }
        return updatedItem;
      } else {
        _error = result['error'];
        debugPrint('❌ Erro ao atualizar mídia: $_error');
        return null;
      }
    } catch (e) {
      _error = 'Erro ao atualizar mídia: $e';
      debugPrint('❌ $_error');
      return null;
    }
  }

  /// Deleta uma mídia na API (requer autenticação)
  Future<bool> delete(int id) async {
    if (_token == null) {
      _error = 'Usuário não autenticado';
      debugPrint('❌ Token não disponível');
      return false;
    }

    try {
      final result = await ApiService.deleteMidia(_token!, id);

      if (result['success'] == true) {
        _items.removeWhere((item) => item.id == id);
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        debugPrint('❌ Erro ao deletar mídia: $_error');
        return false;
      }
    } catch (e) {
      _error = 'Erro ao deletar mídia: $e';
      debugPrint('❌ $_error');
      return false;
    }
  }

  List<MediaItem> search(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _items.where((item) {
      return item.title.toLowerCase().contains(lowercaseQuery) || (item.genre?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  List<MediaItem> getRecent({int limit = 6}) {
    final sorted = [..._items]..sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
    return sorted.take(limit).toList();
  }

  List<MediaItem> getRecentByType(MediaType type, {int limit = 4}) {
    return getByType(type).take(limit).toList();
  }
}
