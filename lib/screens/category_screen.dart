import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../providers/auth_provider.dart';
import '../models/media_item_model.dart';
import '../widgets/media_card.dart';
import '../widgets/media_form_dialog.dart';
import '../widgets/protected_route.dart';

class CategoryScreen extends StatefulWidget {
  final MediaType type;
  final String title;
  final IconData icon;

  const CategoryScreen({super.key, required this.type, required this.title, required this.icon});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _searchQuery = '';
  String _sortBy = 'recent'; // recent, title, rating

  void _showMediaDialog(BuildContext context, MediaItem? media) async {
    final result = await showDialog(context: context, builder: (context) => MediaFormDialog(media: media));

    if (result == true && context.mounted) {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      await mediaProvider.loadFromApi();
    }
  }

  Future<void> _handleDelete(BuildContext context, MediaItem media) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Text('Deseja realmente excluir "${media.title}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      try {
        await mediaProvider.delete(media.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ "${media.title}" excluída com sucesso')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erro ao excluir: $e')));
        }
      }
    }
  }

  List<MediaItem> _getFilteredAndSortedItems(List<MediaItem> items) {
    var filtered = items;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((item) {
            return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (item.genre?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'recent':
      default:
        // Sort by ID (higher ID = more recent)
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    return filtered;
  }

  Widget _buildChoiceChip(String label, String value) {
    final isSelected = _sortBy == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _sortBy = value),
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        side: BorderSide(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          width: isSelected ? 1.5 : 1,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        elevation: isSelected ? 6 : 0,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
      child: Consumer2<MediaProvider, AuthProvider>(
        builder: (context, mediaProvider, authProvider, child) {
          final allItems = mediaProvider.getByType(widget.type);
          final filteredItems = _getFilteredAndSortedItems(allItems);

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface.withOpacity(0.95),
                      Theme.of(context).colorScheme.surface.withOpacity(0.85),
                    ],
                  ),
                  border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), width: 1)),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 1),
                    ),
                    child: Icon(widget.icon, size: 22, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 0.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showMediaDialog(context, null),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text('Adicionar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Search and Filter Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.surface.withOpacity(0.6),
                        Theme.of(context).colorScheme.surface.withOpacity(0.4),
                      ],
                    ),
                    border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.15), width: 1)),
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Buscar ${widget.title.toLowerCase()}...',
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 15),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                            ),
                            suffixIcon:
                                _searchQuery.isNotEmpty
                                    ? IconButton(
                                      icon: Icon(Icons.clear_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Sort Options
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.sort_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Ordenar:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildChoiceChip('Recentes', 'recent'),
                                  _buildChoiceChip('Título', 'title'),
                                  _buildChoiceChip('Avaliação', 'rating'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
                      ],
                    ),
                    border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.icon, size: 20, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${filteredItems.length} ${filteredItems.length == 1 ? 'item' : 'itens'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'de ${allItems.length} no total',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Grid of Items
                Expanded(
                  child:
                      filteredItems.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(widget.icon, size: 80, color: Colors.grey.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty ? 'Nenhum item ainda' : 'Nenhum resultado encontrado',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty ? 'Adicione o primeiro item!' : 'Tente outro termo de busca',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                          : LayoutBuilder(
                            builder: (context, constraints) {
                              // Responsive grid columns
                              int crossAxisCount = 2;
                              if (constraints.maxWidth > 1200) {
                                crossAxisCount = 6;
                              } else if (constraints.maxWidth > 900) {
                                crossAxisCount = 5;
                              } else if (constraints.maxWidth > 600) {
                                crossAxisCount = 4;
                              } else if (constraints.maxWidth > 400) {
                                crossAxisCount = 3;
                              }

                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  return MediaCard(
                                    item: filteredItems[index],
                                    showGenre: true,
                                    onTap: () => _showMediaDialog(context, filteredItems[index]),
                                    onDelete: () => _handleDelete(context, filteredItems[index]),
                                  );
                                },
                              );
                            },
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
