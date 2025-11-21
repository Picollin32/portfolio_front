import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/user_avatar.dart';

class AdminHeader extends StatelessWidget {
  final User? user;

  const AdminHeader({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: (isDark ? Colors.black : const Color(0xFF4F46E5)).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.2), width: 1),
        ),
        child: Row(
          children: [
            // User Avatar with glow effect
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)],
              ),
              child: UserAvatar(
                photoUrl: user?.photo,
                fallbackText: user?.name ?? 'A',
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.name ?? 'Administrador',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings, size: 12, color: Colors.white.withOpacity(0.95)),
                            const SizedBox(width: 4),
                            Text(
                              user?.role.name.toUpperCase() ?? 'ADMIN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.95),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user?.email ?? '',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Portfolio Button
                Material(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/portfolio');
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.home_outlined, color: Colors.white.withOpacity(0.95), size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Logout Button
                Material(
                  color: Colors.red.shade600.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _handleLogout(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout, size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          const Text('Sair', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
