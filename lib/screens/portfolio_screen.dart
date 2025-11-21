import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../providers/auth_provider.dart';
import '../models/media_item_model.dart';
import '../models/user_model.dart';
import '../widgets/media_card.dart';
import '../widgets/protected_route.dart';
import '../widgets/media_form_dialog.dart';
import '../widgets/user_avatar.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    // Configura o token no MediaProvider após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

      if (authProvider.token != null) {
        mediaProvider.setToken(authProvider.token);
      }
    });
  }

  void _showMediaDialog(BuildContext context, MediaItem? media) async {
    final result = await showDialog(context: context, builder: (context) => MediaFormDialog(media: media));

    // Se retornou true, recarrega a lista do provider
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
            content: Text('Deseja realmente excluir "${media.title.length > 50 ? '${media.title.substring(0, 50)}...' : media.title}"?'),
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
          final displayTitle = media.title.length > 30 ? '${media.title.substring(0, 30)}...' : media.title;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ "$displayTitle" excluída com sucesso')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erro ao excluir: $e')));
        }
      }
    }
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Saída'),
            content: const Text('Deseja realmente sair do sistema?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Sair'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
      child: Consumer2<MediaProvider, AuthProvider>(
        builder: (context, mediaProvider, authProvider, child) {
          final recentItems = mediaProvider.getRecent();
          final games = mediaProvider.getRecentByType(MediaType.game);
          final movies = mediaProvider.getRecentByType(MediaType.movie);
          final series = mediaProvider.getRecentByType(MediaType.series);
          final isAdmin = authProvider.user?.role == UserRole.admin;

          return Scaffold(
            body: SingleChildScrollView(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User Header - Non-fixed, scrolls with content
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            // User Avatar
                            UserAvatar(photoUrl: authProvider.user?.photo, fallbackText: authProvider.user?.name ?? 'U', radius: 24),
                            const SizedBox(width: 12),
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authProvider.user?.name ?? 'Usuário',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    authProvider.user?.email ?? '',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons
                            if (isAdmin) ...[
                              IconButton(
                                icon: const Icon(Icons.admin_panel_settings_outlined),
                                tooltip: 'Painel Admin',
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/admin');
                                },
                              ),
                              const SizedBox(width: 4),
                            ],
                            // Logout Button
                            ElevatedButton.icon(
                              onPressed: () => _handleLogout(context, authProvider),
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('Sair'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Hero Section with gradient - CENTERED
                      Center(
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 800),
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                        Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                              blurRadius: 30,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.collections_rounded, size: 56, color: Colors.white),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Meu Universo de Mídia',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Minhas jornadas por jogos, filmes e séries, tudo em um só lugar.',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          _buildStatChip(context, Icons.videogame_asset_rounded, 'Jogos', games.length, MediaType.game),
                                          _buildStatChip(context, Icons.movie_rounded, 'Filmes', movies.length, MediaType.movie),
                                          _buildStatChip(context, Icons.tv_rounded, 'Séries', series.length, MediaType.series),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Recently Added
                      if (recentItems.isNotEmpty) ...[
                        _buildSectionHeader(context, 'Adicionados Recentemente', Icons.fiber_new),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recentItems.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: MediaCard(
                                  item: recentItems[index],
                                  width: 180,
                                  onTap: () => _showMediaDialog(context, recentItems[index]),
                                  onDelete: () => _handleDelete(context, recentItems[index]),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      // Latest Games
                      if (games.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'Últimos Jogos Concluídos',
                          Icons.videogame_asset,
                          onViewAll: () => Navigator.pushNamed(context, '/jogos'),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: games.length.clamp(0, 6),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: MediaCard(
                                  item: games[index],
                                  width: 180,
                                  showGenre: true,
                                  onTap: () => _showMediaDialog(context, games[index]),
                                  onDelete: () => _handleDelete(context, games[index]),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      // Latest Movies
                      if (movies.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'Últimos Filmes Vistos',
                          Icons.movie,
                          onViewAll: () => Navigator.pushNamed(context, '/filmes'),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: movies.length.clamp(0, 6),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: MediaCard(
                                  item: movies[index],
                                  width: 180,
                                  showGenre: true,
                                  onTap: () => _showMediaDialog(context, movies[index]),
                                  onDelete: () => _handleDelete(context, movies[index]),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      // Latest Series
                      if (series.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'Últimas Séries Finalizadas',
                          Icons.tv,
                          onViewAll: () => Navigator.pushNamed(context, '/series'),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: series.length.clamp(0, 6),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: MediaCard(
                                  item: series[index],
                                  width: 180,
                                  showGenre: true,
                                  onTap: () => _showMediaDialog(context, series[index]),
                                  onDelete: () => _handleDelete(context, series[index]),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), blurRadius: 20, spreadRadius: 3)],
              ),
              child: FloatingActionButton(
                onPressed: () => _showMediaDialog(context, null),
                tooltip: 'Adicionar Mídia',
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add_rounded, size: 32),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, {VoidCallback? onViewAll}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 1.5),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 15, spreadRadius: 2)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), blurRadius: 12, spreadRadius: 1),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  if (onViewAll != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextButton.icon(
                        onPressed: onViewAll,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Ver Todos'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label, int count, MediaType type) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: InkWell(
            onTap: () {
              // Navegar para a página correspondente
              switch (type) {
                case MediaType.game:
                  Navigator.pushNamed(context, '/jogos');
                  break;
                case MediaType.movie:
                  Navigator.pushNamed(context, '/filmes');
                  break;
                case MediaType.series:
                  Navigator.pushNamed(context, '/series');
                  break;
              }
            },
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                    Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), width: 1.5),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
