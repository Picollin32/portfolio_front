import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/user_avatar.dart';

class PortfolioHeader extends StatelessWidget {
  final User? user;

  const PortfolioHeader({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          // User Avatar
          UserAvatar(photoUrl: user?.photo, fallbackText: user?.name ?? 'U', radius: 20),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.name ?? 'Usuário',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(user?.email ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Admin Button (only for admins)
              if (user?.role == UserRole.admin) ...[
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  tooltip: 'Painel Admin',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/admin');
                  },
                ),
                Container(width: 1, height: 24, color: Theme.of(context).dividerColor, margin: const EdgeInsets.symmetric(horizontal: 4)),
              ],

              // Logout Button
              ElevatedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sair'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sair'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}
