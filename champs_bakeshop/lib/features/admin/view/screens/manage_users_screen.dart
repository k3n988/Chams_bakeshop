import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/admin_user_viewmodel.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  void _showDialog(BuildContext context, {UserModel? user}) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passCtrl = TextEditingController(text: user?.password ?? '');
    String role = user?.role ?? 'helper';
    final isEdit = user != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit User' : 'Add New User',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. JUAN', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'email@champs.com', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 14),
                // FIX 1: 'value' → 'initialValue'
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'master_baker', child: Text('Master Baker')),
                    DropdownMenuItem(value: 'helper', child: Text('Helper')),
                  ],
                  onChanged: (v) => setState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All fields are required'), backgroundColor: AppColors.danger));
                  return;
                }
                final vm = context.read<AdminUserViewModel>();
                // FIX 2: Capture messenger before async gap to avoid use_build_context_synchronously
                final messenger = ScaffoldMessenger.of(context);
                bool ok;
                if (isEdit) {
                  // FIX 3: Remove unnecessary '!' — Dart already knows user is non-null here
                  ok = await vm.updateUser(user.copyWith(
                    name: nameCtrl.text.trim().toUpperCase(),
                    email: emailCtrl.text.trim().toLowerCase(),
                    password: passCtrl.text,
                    role: role,
                  ));
                } else {
                  ok = await vm.addUser(name: nameCtrl.text.trim(), email: emailCtrl.text.trim(), password: passCtrl.text, role: role);
                }
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                  messenger.showSnackBar(
                    SnackBar(content: Text(isEdit ? 'User updated!' : 'User added!'), backgroundColor: AppColors.success));
                }
              },
              child: Text(isEdit ? 'Save' : 'Add User'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Remove ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await context.read<AdminUserViewModel>().deleteUser(user.id);
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.name} removed'), backgroundColor: AppColors.info));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<AdminUserViewModel>().nonAdminUsers;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'User Management',
            subtitle: 'Manage bakery staff accounts',
            trailing: ElevatedButton.icon(
              onPressed: () => _showDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add User'),
            ),
          ),
          if (users.isEmpty)
            const EmptyState(message: 'No users added yet')
          else
            ...users.map((u) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: CircleAvatar(
                  // FIX 4: withOpacity → withValues()
                  backgroundColor: u.isMasterBaker
                      ? AppColors.masterBaker.withValues(alpha: 0.12)
                      : AppColors.helper.withValues(alpha: 0.12),
                  child: Text(u.name[0], style: TextStyle(fontWeight: FontWeight.w700, color: u.isMasterBaker ? AppColors.masterBaker : AppColors.helper)),
                ),
                title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 4),
                  Text(u.email, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  RoleBadge(role: u.role),
                ]),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20), onPressed: () => _showDialog(context, user: u)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20), onPressed: () => _confirmDelete(context, u)),
                ]),
              ),
            )),
        ],
      ),
    );
  }
}