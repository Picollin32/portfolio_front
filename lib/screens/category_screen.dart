import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../providers/auth_provider.dart';
import '../models/media_item_model.dart';
import '../models/user_model.dart';
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

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
      child: Consumer2<MediaProvider, AuthProvider>(
        builder: (context, mediaProvider, authProvider, child) {
          final allItems = mediaProvider.getByType(widget.type);
          final filteredItems = _getFilteredAndSortedItems(allItems);
          final isAdmin = authProvider.user?.role == UserRole.admin;

          return Scaffold(
            appBar: AppBar(
              title: Row(children: [Icon(widget.icon, size: 24), const SizedBox(width: 12), Text(widget.title)]),
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Adicionar ${widget.title}',
                    onPressed: () => _showMediaDialog(context, null),
                  ),
              ],
            ),
            body: Column(
              children: [
                // Search and Filter Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar ${widget.title.toLowerCase()}...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Sort Options
                      Row(
                        children: [
                          const Text('Ordenar por:'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Recentes'),
                                  selected: _sortBy == 'recent',
                                  onSelected: (_) => setState(() => _sortBy = 'recent'),
                                ),
                                ChoiceChip(
                                  label: const Text('Título'),
                                  selected: _sortBy == 'title',
                                  onSelected: (_) => setState(() => _sortBy = 'title'),
                                ),
                                ChoiceChip(
                                  label: const Text('Avaliação'),
                                  selected: _sortBy == 'rating',
                                  onSelected: (_) => setState(() => _sortBy = 'rating'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)),
                  child: Row(
                    children: [
                      Icon(widget.icon, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${filteredItems.length} ${filteredItems.length == 1 ? 'item' : 'itens'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(de ${allItems.length} no total)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
                                    onTap: isAdmin ? () => _showMediaDialog(context, filteredItems[index]) : null,
                                    onDelete: isAdmin ? () => _handleDelete(context, filteredItems[index]) : null,
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
