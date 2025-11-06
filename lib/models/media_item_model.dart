class MediaItem {
  final int id;
  final String title;
  final MediaType type;
  final double rating; // Mudado de int para double (0-5)
  final String image;
  final String? status; // Mudado de badge para status
  final String? genre;
  final int? year;

  MediaItem({
    required this.id,
    required this.title,
    required this.type,
    required this.rating,
    required this.image,
    this.status,
    this.genre,
    this.year,
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': title, // Backend usa 'titulo'
      'tipo': _typeToBackend(type), // Backend usa 'tipo'
      'avaliacao': rating, // Backend usa 'avaliacao'
      'capa': image, // Backend usa 'capa'
      'status': status,
      'genero': genre, // Backend usa 'genero'
      'ano': year, // Backend usa 'ano'
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as int,
      title: json['titulo'] as String, // Backend retorna 'titulo'
      type: _typeFromBackend(json['tipo'] as String?), // Backend retorna 'tipo'
      rating: (json['avaliacao'] as num?)?.toDouble() ?? 0.0, // Backend retorna 'avaliacao'
      image: json['capa'] as String? ?? '', // Backend retorna 'capa'
      status: json['status'] as String?,
      genre: json['genero'] as String?, // Backend retorna 'genero'
      year: json['ano'] as int?, // Backend retorna 'ano'
    );
  }

  // Conversão de tipo para o formato do backend
  static String _typeToBackend(MediaType type) {
    switch (type) {
      case MediaType.game:
        return 'Jogo';
      case MediaType.movie:
        return 'Filme';
      case MediaType.series:
        return 'Série';
    }
  }

  // Conversão de tipo do formato do backend
  static MediaType _typeFromBackend(String? type) {
    switch (type?.toLowerCase()) {
      case 'jogo':
        return MediaType.game;
      case 'filme':
        return MediaType.movie;
      case 'série':
      case 'serie':
        return MediaType.series;
      default:
        return MediaType.game;
    }
  }

  MediaItem copyWith({int? id, String? title, MediaType? type, double? rating, String? image, String? status, String? genre, int? year}) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      image: image ?? this.image,
      status: status ?? this.status,
      genre: genre ?? this.genre,
      year: year ?? this.year,
    );
  }

  // Getter para badge (compatibilidade com código antigo)
  String? get badge => status;

  String get typeLabel {
    switch (type) {
      case MediaType.game:
        return 'Jogo';
      case MediaType.movie:
        return 'Filme';
      case MediaType.series:
        return 'Série';
    }
  }

  String get detailPath {
    switch (type) {
      case MediaType.game:
        return '/jogos/$id';
      case MediaType.movie:
        return '/filmes/$id';
      case MediaType.series:
        return '/series/$id';
    }
  }
}

enum MediaType { game, movie, series }
