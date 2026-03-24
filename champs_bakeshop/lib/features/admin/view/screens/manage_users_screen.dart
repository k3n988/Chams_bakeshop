// ignore_for_file: unused_import
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/admin_user_viewmodel.dart';
import 'admin_user_detail_screen.dart';

// ── Keys must match what every profile screen saves ───────────
const _kPhotoKey = 'profile_photo_path';
const _kNameKey  = 'profile_display_name';

// ══════════════════════════════════════════════════════════════
//  MANAGE USERS SCREEN
// ══════════════════════════════════════════════════════════════
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() =>
      _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _selectedRole = 'all';

  final Map<String, String?> _displayNames = {};
  final Map<String, String?> _photoPaths   = {};
  bool _profilesLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadProfiles());
  }

  Future<void> _loadProfiles() async {
    final users =
        context.read<AdminUserViewModel>().nonAdminUsers;
    final prefs = await SharedPreferences.getInstance();
    final names  = <String, String?>{};
    final photos = <String, String?>{};
    for (final u in users) {
      names[u.id]  =
          prefs.getString('${_kNameKey}_${u.id}');
      photos[u.id] =
          prefs.getString('${_kPhotoKey}_${u.id}');
    }
    if (!mounted) return;
    setState(() {
      _displayNames
        ..clear()
        ..addAll(names);
      _photoPaths
        ..clear()
        ..addAll(photos);
      _profilesLoaded = true;
    });
  }

  Future<void> _reloadProfiles() async {
    setState(() => _profilesLoaded = false);
    await _loadProfiles();
  }

  String _displayName(UserModel u) =>
      (_displayNames[u.id]?.isNotEmpty == true)
          ? _displayNames[u.id]!
          : u.name;

  String? _photoPath(UserModel u) => _photoPaths[u.id];

  // ── Role helpers ──────────────────────────────────────────
  static const _roles = [
    ('all',          'All'),
    ('master_baker', 'Master Baker'),
    ('helper',       'Helper'),
    ('packer',       'Packer'),
    ('seller',       'Seller'),
  ];

  Color _roleColor(String role) {
    switch (role) {
      case 'master_baker': return AppColors.masterBaker;
      case 'helper':       return AppColors.helper;
      case 'packer':       return AppColors.packer;
      case 'seller':       return AppColors.seller;
      default:             return const Color(0xFFFF8C00);
    }
  }

  // ── Dialogs ───────────────────────────────────────────────
  void _showDialog(BuildContext context, {UserModel? user}) {
    final nameCtrl  =
        TextEditingController(text: user?.name  ?? '');
    final emailCtrl =
        TextEditingController(text: user?.email ?? '');
    final passCtrl  =
        TextEditingController(text: user?.password ?? '');
    String role  = user?.role ?? 'helper';
    final isEdit = user != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isEdit
                    ? Icons.edit_outlined
                    : Icons.person_add_outlined,
                color: const Color(0xFFFF8C00), size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEdit ? 'Edit User' : 'Add New User',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.primaryDark),
            ),
          ]),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              const SizedBox(height: 4),
              _DialogField(
                controller: nameCtrl,
                label: 'Full Name',
                hint: 'e.g. JUAN DELA CRUZ',
                icon: Icons.person_outline,
                caps: TextCapitalization.characters,
              ),
              const SizedBox(height: 14),
              _DialogField(
                controller: emailCtrl,
                label: 'Email',
                hint: 'email@champs.com',
                icon: Icons.mail_outline,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _DialogField(
                controller: passCtrl,
                label: 'Password',
                icon: Icons.lock_outline,
                obscure: true,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined)),
                items: const [
                  DropdownMenuItem(
                      value: 'master_baker',
                      child: Text('Master Baker')),
                  DropdownMenuItem(
                      value: 'helper',
                      child: Text('Helper')),
                  DropdownMenuItem(
                      value: 'packer',
                      child: Text('Packer')),
                  DropdownMenuItem(
                      value: 'seller',
                      child: Text('Seller')),
                ],
                onChanged: (v) =>
                    setDlg(() => role = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    emailCtrl.text.trim().isEmpty ||
                    passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                    content:
                        Text('All fields are required'),
                    backgroundColor: AppColors.danger,
                  ));
                  return;
                }
                final vm =
                    context.read<AdminUserViewModel>();
                final messenger =
                    ScaffoldMessenger.of(context);
                bool ok;
                if (isEdit) {
                  ok = await vm.updateUser(user.copyWith(
                    name:     nameCtrl.text
                        .trim()
                        .toUpperCase(),
                    email:    emailCtrl.text
                        .trim()
                        .toLowerCase(),
                    password: passCtrl.text,
                    role:     role,
                  ));
                } else {
                  ok = await vm.addUser(
                      name:     nameCtrl.text.trim(),
                      email:    emailCtrl.text.trim(),
                      password: passCtrl.text,
                      role:     role);
                }
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                  messenger.showSnackBar(SnackBar(
                      content: Text(isEdit
                          ? 'User updated!'
                          : 'User added!'),
                      backgroundColor: AppColors.success));
                  await _reloadProfiles();
                }
              },
              child:
                  Text(isEdit ? 'Save Changes' : 'Add User'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  AppColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline,
                color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Remove User',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.primaryDark)),
        ]),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary),
            children: [
              const TextSpan(
                  text: 'Are you sure you want to remove '),
              TextSpan(
                text: user.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text),
              ),
              const TextSpan(
                  text:
                      '? This action cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await context
                  .read<AdminUserViewModel>()
                  .deleteUser(user.id);
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('${user.name} removed'),
                      backgroundColor: AppColors.danger));
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewUser(
      BuildContext context, UserModel user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              AdminUserDetailScreen(user: user)),
    );
    await _reloadProfiles();
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final allUsers =
        context.watch<AdminUserViewModel>().nonAdminUsers;
    final filtered = _selectedRole == 'all'
        ? allUsers
        : allUsers
            .where((u) => u.role == _selectedRole)
            .toList();

    final counts = <String, int>{};
    for (final u in allUsers) {
      counts[u.role] = (counts[u.role] ?? 0) + 1;
    }

    return RefreshIndicator(
      color: const Color(0xFFFF8C00),
      onRefresh: () async {
        await context
            .read<AdminUserViewModel>()
            .loadUsers();
        await _reloadProfiles();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────
            SectionHeader(
              title: 'User Management',
              subtitle: 'Manage bakery staff accounts',
              trailing: FilledButton.icon(
                onPressed: () => _showDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add User'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFF8C00),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Staff summary ──────────────────────────────
            _StaffSummaryRow(counts: counts),
            const SizedBox(height: 16),

            // ── Role filter chips ──────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _roles.map((r) {
                  final rKey   = r.$1;
                  final rLabel = r.$2;
                  final isAll  = rKey == 'all';
                  final count  = isAll
                      ? allUsers.length
                      : (counts[rKey] ?? 0);
                  final sel = _selectedRole == rKey;
                  final color = isAll
                      ? const Color(0xFFFF8C00)
                      : _roleColor(rKey);

                  return Padding(
                    padding:
                        const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(rLabel,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: sel
                                      ? Colors.white
                                      : AppColors
                                          .textSecondary)),
                          if (count > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1),
                              decoration: BoxDecoration(
                                color: sel
                                    ? Colors.white
                                        .withValues(
                                            alpha: 0.25)
                                    : color.withValues(
                                        alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(
                                        10),
                              ),
                              child: Text('$count',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.w800,
                                      color: sel
                                          ? Colors.white
                                          : color)),
                            ),
                          ],
                        ],
                      ),
                      selected: sel,
                      onSelected: (_) => setState(
                          () => _selectedRole = rKey),
                      backgroundColor: Colors.white,
                      selectedColor: color,
                      checkmarkColor: Colors.white,
                      showCheckmark: false,
                      side: BorderSide(
                          color: sel
                              ? color
                              : AppColors.border,
                          width: 1.4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── User list ──────────────────────────────────
            if (filtered.isEmpty)
              _EmptyRoleState(role: _selectedRole)
            else
              ...filtered.map((u) => _UserCard(
                    user:        u,
                    displayName: _displayName(u),
                    photoPath:   _photoPath(u),
                    roleColor:   _roleColor(u.role),
                    onView:  () => _viewUser(context, u),
                    onEdit:  () =>
                        _showDialog(context, user: u),
                    onDelete: () =>
                        _confirmDelete(context, u),
                  )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STAFF SUMMARY ROW
// ══════════════════════════════════════════════════════════════
class _StaffSummaryRow extends StatelessWidget {
  final Map<String, int> counts;
  const _StaffSummaryRow({required this.counts});

  int get _total =>
      counts.values.fold(0, (s, v) => s + v);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color:
                    Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround,
          children: [
            _SummaryCell(
                label: 'Total',
                value: '$_total',
                color: const Color(0xFFFF8C00)),
            _VDivider(),
            _SummaryCell(
                label: 'Bakers',
                value: '${counts['master_baker'] ?? 0}',
                color: AppColors.masterBaker),
            _VDivider(),
            _SummaryCell(
                label: 'Helpers',
                value: '${counts['helper'] ?? 0}',
                color: AppColors.helper),
            _VDivider(),
            _SummaryCell(
                label: 'Packers',
                value: '${counts['packer'] ?? 0}',
                color: AppColors.packer),
            _VDivider(),
            _SummaryCell(
                label: 'Sellers',
                value: '${counts['seller'] ?? 0}',
                color: AppColors.seller),
          ],
        ),
      );
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.border);
}

class _SummaryCell extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _SummaryCell(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) =>
      Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500)),
      ]);
}

// ══════════════════════════════════════════════════════════════
//  USER CARD
// ══════════════════════════════════════════════════════════════
class _UserCard extends StatelessWidget {
  final UserModel    user;
  final String       displayName;
  final String?      photoPath;
  final Color        roleColor;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.displayName,
    required this.photoPath,
    required this.roleColor,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  String get _initial =>
      displayName.isNotEmpty
          ? displayName[0].toUpperCase()
          : '?';

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color:
                    Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(children: [
            // ── Avatar ─────────────────────────────────
            _UserAvatar(
              photoPath: photoPath,
              initial:   _initial,
              bg: roleColor.withValues(alpha: 0.13),
              fg: roleColor,
            ),
            const SizedBox(width: 12),

            // ── Info ───────────────────────────────────
            Expanded(
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                Text(displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.text)),
                if (displayName != user.name) ...[
                  const SizedBox(height: 1),
                  Text(user.name,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 3),
                Text(user.email,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor
                        .withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                        color: roleColor
                            .withValues(alpha: 0.25)),
                  ),
                  child: Text(user.roleDisplay,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: roleColor,
                          letterSpacing: 0.3)),
                ),
              ]),
            ),

            // ── Actions ────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                    icon: Icons.bar_chart_outlined,
                    color: const Color(0xFFFF8C00),
                    tooltip: 'View Stats',
                    onTap: onView),
                _ActionBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    tooltip: 'Edit',
                    onTap: onEdit),
                _ActionBtn(
                    icon: Icons.delete_outline,
                    color: AppColors.danger,
                    tooltip: 'Remove',
                    onTap: onDelete),
              ],
            ),
          ]),
        ),
      );
}

// ── Avatar ────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String? photoPath;
  final String  initial;
  final Color   bg, fg;
  const _UserAvatar({
    required this.photoPath,
    required this.initial,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null &&
        File(photoPath!).existsSync();
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        image: hasPhoto
            ? DecorationImage(
                image: FileImage(File(photoPath!)),
                fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(initial,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: fg)),
    );
  }
}

// ── Action button ─────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       tooltip;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 19, color: color),
          ),
        ),
      );
}

// ── Empty state ───────────────────────────────────────────────
class _EmptyRoleState extends StatelessWidget {
  final String role;
  const _EmptyRoleState({required this.role});

  String get _label {
    switch (role) {
      case 'master_baker': return 'Master Bakers';
      case 'helper':       return 'Helpers';
      case 'packer':       return 'Packers';
      case 'seller':       return 'Sellers';
      default:             return 'Users';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(Icons.people_outline,
              size: 44,
              color: AppColors.textHint
                  .withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Text('No $_label yet',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint)),
          const SizedBox(height: 4),
          Text('Tap "+ Add User" to add a $_label',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint)),
        ]),
      );
}

// ── Dialog text field ─────────────────────────────────────────
class _DialogField extends StatefulWidget {
  final TextEditingController controller;
  final String                label;
  final String?               hint;
  final IconData              icon;
  final bool                  obscure;
  final TextInputType         keyboard;
  final TextCapitalization    caps;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint    = null,
    this.obscure = false,
    this.keyboard = TextInputType.text,
    this.caps     = TextCapitalization.none,
  });

  @override
  State<_DialogField> createState() =>
      _DialogFieldState();
}

class _DialogFieldState extends State<_DialogField> {
  late bool _obs;

  @override
  void initState() {
    super.initState();
    _obs = widget.obscure;
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller:         widget.controller,
        obscureText:        _obs,
        keyboardType:       widget.keyboard,
        textCapitalization: widget.caps,
        decoration: InputDecoration(
          labelText:  widget.label,
          hintText:   widget.hint,
          prefixIcon: Icon(widget.icon),
          suffixIcon: widget.obscure
              ? IconButton(
                  icon: Icon(_obs
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                      size: 20),
                  onPressed: () =>
                      setState(() => _obs = !_obs),
                )
              : null,
        ),
      );
}