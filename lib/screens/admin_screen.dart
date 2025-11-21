import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/admin_header.dart';
import '../widgets/user_form_dialog.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'all'; // values: 'all', 'admin', 'user'

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final users = await authProvider.getAllUsers();

    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  List<User> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();
    final queryFiltered =
        query.isEmpty
            ? _users
            : _users.where((user) {
              // Pesquisa por nome, email ou id
              final id = user.id.toLowerCase();
              final name = user.name.toLowerCase();
              final email = user.email.toLowerCase();
              return id.contains(query) || name.contains(query) || email.contains(query);
            }).toList();

    if (_roleFilter == 'all') return queryFiltered;

    return queryFiltered.where((user) {
      final roleName = user.role.name.toLowerCase();
      if (_roleFilter == 'admin') return roleName == 'admin';
      if (_roleFilter == 'user') return roleName == 'user';
      return true;
    }).toList();
  }

  Future<void> _showUserDialog({User? user}) async {
    final result = await showDialog<bool>(context: context, builder: (context) => UserFormDialog(user: user));

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Text(
              'Tem certeza que deseja excluir o usuário "${user.name.length > 50 ? '${user.name.substring(0, 50)}...' : user.name}"?\n\n'
              'Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.deleteUser(user.id);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuário excluído com sucesso!'), backgroundColor: Colors.green));
        _loadUsers();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Erro ao excluir usuário'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _resetPassword(User user) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Redefinir Senha - ${user.name.length > 30 ? '${user.name.substring(0, 30)}...' : user.name}',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user.email}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Nova Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'Mínimo 8 caracteres',
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty && controller.text.length >= 8) {
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('A senha deve ter pelo menos 8 caracteres'), backgroundColor: Colors.orange),
                    );
                  }
                },
                child: const Text('Redefinir'),
              ),
            ],
          ),
    );

    if (confirmed != true || controller.text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();

    // Usa o método updateUser com password
    final result = await authProvider.updateUser(user.id, {'password': controller.text});

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Senha redefinida com sucesso!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Erro ao redefinir senha'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
        automaticallyImplyLeading: false, // Remove o botão de voltar
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Admin Header - Non-fixed, placed inside body
                    AdminHeader(user: currentUser),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar usuário por nome, email ou id...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),

                    // Inline Filter Chips (Todos / Admin / Usuários)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Todos'),
                            selected: _roleFilter == 'all',
                            onSelected: (_) => setState(() => _roleFilter = 'all'),
                          ),
                          ChoiceChip(
                            label: const Text('Administradores'),
                            selected: _roleFilter == 'admin',
                            onSelected: (_) => setState(() => _roleFilter = 'admin'),
                          ),
                          ChoiceChip(
                            label: const Text('Usuários'),
                            selected: _roleFilter == 'user',
                            onSelected: (_) => setState(() => _roleFilter = 'user'),
                          ),
                        ],
                      ),
                    ),

                    // Stats Cards (Row on wide, Grid on small)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child:
                          isWide
                              ? SizedBox(
                                height: 96,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        context,
                                        'Total de Usuários',
                                        _users.length.toString(),
                                        Icons.people,
                                        Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        context,
                                        'Filtrados',
                                        _filteredUsers.length.toString(),
                                        Icons.filter_list,
                                        Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        context,
                                        'Admins',
                                        _users.where((u) => u.role.name.toLowerCase() == 'admin').length.toString(),
                                        Icons.admin_panel_settings,
                                        Colors.purple,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        context,
                                        'Usuários',
                                        _users.where((u) => u.role.name.toLowerCase() == 'user').length.toString(),
                                        Icons.person,
                                        Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _buildStatCard(context, 'Total de Usuários', _users.length.toString(), Icons.people, Colors.blue),
                                  _buildStatCard(context, 'Filtrados', _filteredUsers.length.toString(), Icons.filter_list, Colors.green),
                                  _buildStatCard(
                                    context,
                                    'Admins',
                                    _users.where((u) => u.role.name.toLowerCase() == 'admin').length.toString(),
                                    Icons.admin_panel_settings,
                                    Colors.purple,
                                  ),
                                  _buildStatCard(
                                    context,
                                    'Usuários',
                                    _users.where((u) => u.role.name.toLowerCase() == 'user').length.toString(),
                                    Icons.person,
                                    Colors.orange,
                                  ),
                                ],
                              ),
                    ),

                    // Users List
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child:
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : _filteredUsers.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_searchQuery.isEmpty ? Icons.people_outline : Icons.search_off, size: 64, color: Colors.grey),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty ? 'Nenhum usuário cadastrado' : 'Nenhum usuário encontrado',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _searchQuery.isEmpty ? 'Adicione seu primeiro usuário' : 'Tente outro termo de busca',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                                : RefreshIndicator(
                                  onRefresh: _loadUsers,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    itemCount: _filteredUsers.length,
                                    itemBuilder: (context, index) {
                                      final user = _filteredUsers[index];
                                      return _buildUserCard(user);
                                    },
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Usuário'),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey))),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final roleLower = user.role.name.toLowerCase();
    Color chipColor;
    if (roleLower == 'admin') {
      chipColor = Colors.purple;
    } else if (roleLower == 'user') {
      chipColor = Colors.orange;
    } else {
      chipColor = Colors.blueGrey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: user.photo != null ? NetworkImage(user.photo!) : null,
              child:
                  user.photo == null
                      ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.email,
                          style: const TextStyle(fontSize: 13, color: Color.fromARGB(221, 255, 255, 255)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: chipColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          user.role.name.toUpperCase(),
                          style: TextStyle(fontSize: 12, color: chipColor.withOpacity(0.9), fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (user.id.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Chip(
                            label: Text('ID: ${user.id}', overflow: TextOverflow.ellipsis, maxLines: 1),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showUserDialog(user: user);
                    break;
                  case 'reset':
                    _resetPassword(user);
                    break;
                  case 'delete':
                    _deleteUser(user);
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Editar')]),
                    ),
                    const PopupMenuItem(
                      value: 'reset',
                      child: Row(children: [Icon(Icons.lock_reset, size: 20), SizedBox(width: 12), Text('Redefinir Senha')]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  // filter drawer removed; method intentionally deleted
}
