import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/users_provider.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersState = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User & Role Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(usersProvider.notifier).loadUsers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      body: usersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading users: $err')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'System Users (${users.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showAddUserDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('New User'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DataTable(
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: users.map((user) {
                        final isAdmin = user.role.toLowerCase() == 'admin';
                        final isCashier = user.role.toLowerCase() == 'cashier';
                        final roleColor = isAdmin ? Colors.deepPurple : (isCashier ? Colors.blue : Colors.teal);

                        return DataRow(
                          cells: [
                            DataCell(Text('#${user.id}')),
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: roleColor.withValues(alpha: 0.2),
                                    child: Icon(
                                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                                      size: 18,
                                      color: roleColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  user.role.toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: roleColor),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  Icon(
                                    user.isActive ? Icons.check_circle : Icons.cancel,
                                    size: 16,
                                    color: user.isActive ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    user.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: user.isActive ? Colors.green.shade700 : Colors.red.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                    tooltip: 'Edit User',
                                    onPressed: () => _showEditUserDialog(context, ref, user),
                                  ),
                                  if (user.username != 'admin')
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      tooltip: 'Delete User',
                                      onPressed: () => _confirmDeleteUser(context, ref, user),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'cashier';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add New User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin (Full Access)')),
                  DropdownMenuItem(value: 'cashier', child: Text('Cashier (POS Billing Only)')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager (Inventory & Reports)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedRole = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final uname = usernameController.text.trim();
                final pwd = passwordController.text.trim();
                if (uname.isEmpty || pwd.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                await ref.read(usersProvider.notifier).addUser(
                  username: uname,
                  password: pwd,
                  role: selectedRole,
                );
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('User $uname created successfully!')),
                );
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, WidgetRef ref, AppUser user) {
    final passwordController = TextEditingController();
    String selectedRole = user.role;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Edit User: ${user.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password (Leave blank to keep current)',
                  prefixIcon: Icon(Icons.lock_reset),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedRole = val);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Account Status'),
                subtitle: Text(isActive ? 'Active' : 'Disabled'),
                value: isActive,
                onChanged: (val) => setState(() => isActive = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                await ref.read(usersProvider.notifier).updateUser(
                  id: user.id!,
                  password: passwordController.text.trim().isNotEmpty ? passwordController.text.trim() : null,
                  role: selectedRole,
                  isActive: isActive,
                );
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('User ${user.username} updated!')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "${user.username}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);
              await ref.read(usersProvider.notifier).deleteUser(user.id!);
              nav.pop();
              messenger.showSnackBar(
                SnackBar(content: Text('User ${user.username} deleted.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
