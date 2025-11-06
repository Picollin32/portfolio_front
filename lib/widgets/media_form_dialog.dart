import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'dart:convert' show base64Decode, base64Encode;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import '../models/media_item_model.dart';
import '../utils/api_service.dart';

class MediaFormDialog extends StatefulWidget {
  final MediaItem? media;

  const MediaFormDialog({super.key, this.media});

  @override
  State<MediaFormDialog> createState() => _MediaFormDialogState();
}

class _MediaFormDialogState extends State<MediaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  final _yearController = TextEditingController();
  final _imageController = TextEditingController();

  MediaType? _selectedType;
  double _rating = 0.0;
  String _selectedBadge = 'Nenhum';
  bool _isLoading = false;
  bool _ratingTouched = false; // Controla se o usuário já interagiu com avaliação

  // Opções dinâmicas da API
  List<String> _statusOptions = ['Nenhum'];

  @override
  void initState() {
    super.initState();
    if (widget.media != null) {
      _titleController.text = widget.media!.title;
      _genreController.text = widget.media!.genre ?? '';
      _yearController.text = widget.media!.year?.toString() ?? '';
      _imageController.text = widget.media!.image;
      _selectedType = widget.media!.type;
      _rating = widget.media!.rating;
      _selectedBadge = widget.media!.badge ?? 'Nenhum';
    }
    // Carrega opções de status se já tiver tipo selecionado
    if (_selectedType != null) {
      _loadStatusOptions();
    }
  }

  Future<void> _loadStatusOptions() async {
    if (_selectedType == null) return;

    final tipo = _typeToString(_selectedType!);
    try {
      final result = await ApiService.getStatusPorTipo(tipo);
      if (result['success'] == true && mounted) {
        setState(() {
          final List<dynamic> data = result['data'];
          if (data.isNotEmpty) {
            _statusOptions = ['Nenhum', ...data.map((e) => e.toString())];
          } else {
            // Se API retornar vazio, usa fallback
            _statusOptions = _getStaticBadgeOptions();
          }

          // Se o status atual não está nas opções, adiciona
          if (_selectedBadge != 'Nenhum' && !_statusOptions.contains(_selectedBadge)) {
            _statusOptions.add(_selectedBadge);
          }
        });
      } else {
        // Se API falhar, usa fallback estático
        if (mounted) {
          setState(() {
            _statusOptions = _getStaticBadgeOptions();
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar status: $e');
      // Em caso de erro, usa fallback estático
      if (mounted) {
        setState(() {
          _statusOptions = _getStaticBadgeOptions();
        });
      }
    }
  }

  List<String> _getStaticBadgeOptions() {
    // Opções estáticas de fallback baseadas nos mockados originais
    switch (_selectedType) {
      case MediaType.game:
        return ['Nenhum', 'Zerado', 'Platinado', 'Abandonado', 'Jogando', 'Em andamento'];
      case MediaType.movie:
        return ['Nenhum', 'Assistido', 'Favorito', 'Para Reassistir'];
      case MediaType.series:
        return ['Nenhum', 'Finalizada', 'Assistindo', 'Pausada', 'Abandonada'];
      default:
        return ['Nenhum'];
    }
  }

  String _typeToString(MediaType type) {
    switch (type) {
      case MediaType.game:
        return 'Jogo';
      case MediaType.movie:
        return 'Filme';
      case MediaType.series:
        return 'Série';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  List<String> _getBadgeOptions() {
    // Retorna as opções carregadas da API ou fallback para opções estáticas
    if (_statusOptions.length > 1) {
      return _statusOptions;
    }

    // Se ainda não carregou da API, retorna fallback estático
    return _getStaticBadgeOptions();
  }

  Future<void> _submit() async {
    // Valida avaliação antes do form
    if (_rating == 0.0) {
      setState(() {
        _ratingTouched = true; // Marca para mostrar erro
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Selecione uma avaliação')));
      return;
    }

    // Valida o formulário
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Preencha todos os campos obrigatórios')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Converte MediaType para string em português
      String tipoString;
      switch (_selectedType!) {
        case MediaType.game:
          tipoString = 'Jogo';
          break;
        case MediaType.movie:
          tipoString = 'Filme';
          break;
        case MediaType.series:
          tipoString = 'Série';
          break;
      }

      if (widget.media == null) {
        // CRIAR nova mídia
        final result = await ApiService.createMidia(
          titulo: _titleController.text.trim(),
          tipo: tipoString,
          genero: _genreController.text.trim().isNotEmpty ? _genreController.text.trim() : null,
          ano: _yearController.text.trim().isNotEmpty ? int.tryParse(_yearController.text.trim()) : null,
          status: _selectedBadge != 'Nenhum' ? _selectedBadge : null,
          avaliacao: _rating,
          capa: _imageController.text.trim().isNotEmpty ? _imageController.text.trim() : null,
        );

        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Mídia criada com sucesso!')));
            Navigator.of(context).pop(true); // Retorna true para indicar sucesso
          }
        } else {
          throw Exception(result['error'] ?? 'Erro ao criar mídia');
        }
      } else {
        // ATUALIZAR mídia existente
        final result = await ApiService.updateMidia(
          midiaId: widget.media!.id,
          titulo: _titleController.text.trim(),
          tipo: tipoString,
          genero: _genreController.text.trim().isNotEmpty ? _genreController.text.trim() : null,
          ano: _yearController.text.trim().isNotEmpty ? int.tryParse(_yearController.text.trim()) : null,
          status: _selectedBadge != 'Nenhum' ? _selectedBadge : null,
          avaliacao: _rating,
          capa: _imageController.text.trim().isNotEmpty ? _imageController.text.trim() : null,
        );

        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Mídia atualizada com sucesso!')));
            Navigator.of(context).pop(true); // Retorna true para indicar sucesso
          }
        } else {
          throw Exception(result['error'] ?? 'Erro ao atualizar mídia');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erro: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickLocalFile() async {
    try {
      debugPrint('🖼️ Abrindo FilePicker...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Precisa dos bytes para converter em base64
        withReadStream: false,
      );

      debugPrint('📁 FilePicker result: ${result != null ? "Arquivo selecionado" : "Nenhum arquivo"}');

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.single;
        final fileName = picked.name;
        final fileSize = picked.size;

        debugPrint('Arquivo: $fileName');
        debugPrint('Tamanho original: ${(fileSize / 1024).toStringAsFixed(1)} KB');

        // Obter bytes da imagem
        final bytes = picked.bytes;
        if (bytes == null) {
          throw Exception('Não foi possível ler os dados da imagem');
        }

        // Mostrar loading enquanto processa
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('⏳ Comprimindo "$fileName"...'), duration: const Duration(seconds: 2)));
        }

        // Comprimir e converter para base64
        final compressedBytes = await _compressImage(bytes);
        final base64String = base64Encode(compressedBytes);
        final extension = picked.extension?.toLowerCase() ?? 'jpeg';
        final mimeType = 'image/$extension';
        final dataUri = 'data:$mimeType;base64,$base64String';

        final compressedSize = compressedBytes.length;
        final compressionRate = ((1 - compressedSize / fileSize) * 100).toStringAsFixed(1);

        debugPrint('Tamanho comprimido: ${(compressedSize / 1024).toStringAsFixed(1)} KB');
        debugPrint('Compressão: $compressionRate%');

        if (mounted) {
          setState(() {
            _imageController.text = dataUri;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ "$fileName" carregada (${(compressedSize / 1024).toStringAsFixed(1)} KB)'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('ℹ️ Usuário cancelou a seleção');
      }
    } catch (e, st) {
      debugPrint('❌ Erro ao selecionar arquivo: $e');
      debugPrint('Stack trace: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erro ao selecionar arquivo: $e')));
      }
    }
  }

  Future<List<int>> _compressImage(List<int> bytes) async {
    try {
      // Converte para Uint8List
      final uint8bytes = Uint8List.fromList(bytes);

      // Decodifica a imagem
      final image = img.decodeImage(uint8bytes);
      if (image == null) {
        throw Exception('Não foi possível decodificar a imagem');
      }

      // Redimensiona se for muito grande (máx 800px na maior dimensão)
      img.Image resized = image;
      if (image.width > 800 || image.height > 800) {
        if (image.width > image.height) {
          resized = img.copyResize(image, width: 800);
        } else {
          resized = img.copyResize(image, height: 800);
        }
      }

      // Codifica como JPEG com qualidade 85 (bom equilíbrio qualidade/tamanho)
      final compressed = img.encodeJpg(resized, quality: 85);

      return compressed;
    } catch (e) {
      debugPrint('Erro na compressão, usando imagem original: $e');
      return bytes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.media != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Dialog(
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 800,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEdit ? 'Editar Item' : 'Adicionar Novo Item',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(key: _formKey, child: isMobile ? _buildMobileLayout() : _buildDesktopLayout()),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('Cancelar')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child:
                            _isLoading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(isEdit ? 'Atualizar' : 'Adicionar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildTypeSelector(),
              const SizedBox(height: 16),
              _buildGenreField(),
              const SizedBox(height: 16),
              _buildYearField(),
              const SizedBox(height: 16),
              _buildBadgeSelector(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildRatingSelector(), const SizedBox(height: 16), _buildImageField()],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleField(),
        const SizedBox(height: 16),
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildGenreField(),
        const SizedBox(height: 16),
        _buildYearField(),
        const SizedBox(height: 16),
        _buildBadgeSelector(),
        const SizedBox(height: 16),
        _buildRatingSelector(),
        const SizedBox(height: 16),
        _buildImageField(),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Título *', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Nome do jogo, filme ou série',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Título é obrigatório';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo *', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<MediaType>(
          value: _selectedType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorStyle: const TextStyle(fontSize: 12),
          ),
          hint: const Text('Selecione o tipo'),
          validator: (value) {
            if (value == null) {
              return 'Tipo é obrigatório';
            }
            return null;
          },
          items: const [
            DropdownMenuItem(
              value: MediaType.game,
              child: Row(children: [Icon(Icons.videogame_asset, size: 20), SizedBox(width: 8), Text('Jogo')]),
            ),
            DropdownMenuItem(
              value: MediaType.movie,
              child: Row(children: [Icon(Icons.movie, size: 20), SizedBox(width: 8), Text('Filme')]),
            ),
            DropdownMenuItem(value: MediaType.series, child: Row(children: [Icon(Icons.tv, size: 20), SizedBox(width: 8), Text('Série')])),
          ],
          onChanged: (MediaType? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedType = newValue;
                // Reset badge when type changes
                _selectedBadge = 'Nenhum';
              });
              // Carrega os status da API
              _loadStatusOptions();
            }
          },
        ),
      ],
    );
  }

  Widget _buildGenreField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gênero', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _genreController,
          decoration: InputDecoration(
            hintText: 'Ex: Action/Adventure, Sci-Fi, Drama',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildYearField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ano', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _yearController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final year = int.tryParse(value);
              if (year == null || year < 1900 || year > DateTime.now().year + 5) {
                return 'Ano inválido';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBadgeSelector() {
    final options = _getBadgeOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedBadge,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items:
              options.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedBadge = newValue;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Avaliação *', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  (_rating == 0.0 && _ratingTouched)
                      ? Theme.of(context).colorScheme.error.withOpacity(0.5)
                      : Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ...List.generate(5, (index) {
                final starValue = (index + 1).toDouble();
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = starValue;
                        _ratingTouched = true;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        starValue <= _rating ? Icons.star : Icons.star_border,
                        size: 32,
                        color:
                            starValue <= _rating
                                ? const Color(0xFFFFB800) // Gold color for filled stars
                                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text(
                _rating > 0.0 ? '${_rating.toStringAsFixed(1)}/5' : 'Clique para avaliar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      (_rating == 0.0 && _ratingTouched)
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        if (_rating == 0.0 && _ratingTouched)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Text('Avaliação é obrigatória', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Capa', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _imageController,
                decoration: InputDecoration(
                  hintText: 'URL ou caminho da imagem',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                maxLines: 2,
                validator: null, // Capa não é obrigatória
                onChanged: (value) {
                  // Force rebuild to show/hide preview
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: _pickLocalFile, icon: const Icon(Icons.upload_file), label: const Text('Selecionar arquivo')),
          ],
        ),
        if (_imageController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).dividerColor)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Builder(
                builder: (context) {
                  final text = _imageController.text;
                  // Data URI (base64)
                  if (text.startsWith('data:')) {
                    try {
                      final comma = text.indexOf(',');
                      if (comma != -1) {
                        final data = text.substring(comma + 1);
                        final bytes = base64Decode(data);
                        return Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImageError(context),
                        );
                      }
                    } catch (_) {
                      return _buildImageError(context);
                    }
                  }

                  // Try local file path (only on non-web platforms)
                  if (!kIsWeb) {
                    try {
                      final file = File(text);
                      if (file.existsSync()) {
                        return Image.file(file, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildImageError(context));
                      }
                    } catch (_) {}
                  }

                  // Try asset
                  try {
                    return Image.asset(text, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildImageError(context));
                  } catch (_) {}

                  // Fallback to network
                  return Image.network(text, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildImageError(context));
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageError(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 8),
            Text('Imagem não encontrada', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
