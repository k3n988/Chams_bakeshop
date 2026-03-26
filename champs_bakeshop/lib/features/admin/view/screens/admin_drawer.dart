import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../../auth/view/login_screen.dart';
import '../../viewmodel/admin_user_viewmodel.dart';
import '../../viewmodel/admin_product_viewmodel.dart';
// ── Use 'as' prefix so Dart knows exactly which file each class comes from ──
import 'manage_users_screen.dart'    as users_screen;
import 'manage_products_screen.dart' as products_screen;
import 'christmas_bonus_screen.dart' as bonus_screen;

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  void _openPage(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        context.watch<AuthViewModel>().currentUser;
    final userVM =
        context.watch<AdminUserViewModel>();
    final productVM =
        context.watch<AdminProductViewModel>();

    if (user == null) return const SizedBox();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(children: [
        // ── Gradient header ───────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 20,
            20,
            24,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF7A00),
                Color(0xFFFFA03A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white
                        .withValues(alpha: 0.5),
                    width: 2),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF7A00)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.25),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Text('Admin (Owner)',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ]),
        ),

        // ── Menu ─────────────────────────────────────
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(vertical: 8),
            children: [
              const _SectionLabel('MANAGEMENT'),

              _DrawerItem(
                icon:       Icons.people_outlined,
                color:      AppColors.masterBaker,
                label:      'Manage Users',
                subtitle:
                    '${userVM.nonAdminUsers.length} staff members',
                badge:
                    '${userVM.nonAdminUsers.length}',
                badgeColor: AppColors.masterBaker,
                onTap: () => _openPage(
                  context,
                  _Wrapped(
                    title: 'User Management',
                    // ← explicit prefix, no ambiguity
                    child:
                        users_screen.ManageUsersScreen(),
                  ),
                ),
              ),

              _DrawerItem(
                icon:       Icons.inventory_2_outlined,
                color:      AppColors.info,
                label:      'Manage Products',
                subtitle:
                    '${productVM.products.length} products',
                badge: '${productVM.products.length}',
                badgeColor: AppColors.info,
                onTap: () => _openPage(
                  context,
                  _Wrapped(
                    title: 'Products',
                    child: products_screen
                        .ManageProductsScreen(),
                  ),
                ),
              ),

              _DrawerItem(
                icon:       Icons.card_giftcard_outlined,
                color:      Color(0xFFC62828),
                label:      'Christmas Bonus',
                subtitle:   'Track holiday bonuses per worker',
                onTap: () => _openPage(
                  context,
                  _Wrapped(
                    title: 'Christmas Bonus',
                    child: bonus_screen.ChristmasBonusScreen(),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Divider(height: 1),
              ),

              const _SectionLabel('STAFF ROLES'),

              _RoleRow(
                  emoji: '👨‍🍳',
                  label: 'Master Bakers',
                  count: userVM.masterBakers.length,
                  color: AppColors.masterBaker),
              _RoleRow(
                  emoji: '🧑‍🍳',
                  label: 'Helpers',
                  count: userVM.helpers.length,
                  color: AppColors.helper),
              _RoleRow(
                  emoji: '📦',
                  label: 'Packers',
                  count: userVM.nonAdminUsers
                      .where((u) => u.isPacker)
                      .length,
                  color: AppColors.packer),
              _RoleRow(
                  emoji: '🥖',
                  label: 'Sellers',
                  count: userVM.nonAdminUsers
                      .where((u) => u.isSeller)
                      .length,
                  color: AppColors.seller),
            ],
          ),
        ),

        // ── Logout ───────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1),
        ),
        InkWell(
          onTap: () => _logout(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.danger
                      .withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout,
                    color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('Log Out',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger)),
                    Text('Sign out of admin panel',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.danger),
            ]),
          ),
        ),
        SizedBox(
            height:
                MediaQuery.of(context).padding.bottom +
                    8),
      ]),
    );
  }
}

// ── Wrapped screen ────────────────────────────────────────────
class _Wrapped extends StatelessWidget {
  final String title;
  final Widget child;
  const _Wrapped(
      {required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF8F4F0),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
                height: 1,
                color: Colors.black
                    .withValues(alpha: 0.04)),
          ),
        ),
        body: child,
      );
}

// ── Private sub-widgets ───────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
                letterSpacing: 1.0)),
      );
}

class _DrawerItem extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       label, subtitle;
  final String?      badge;
  final Color?       badgeColor;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color:
                      color.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child:
                    Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w700,
                            color: AppColors.text)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11,
                            color:
                                AppColors.textHint)),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? color)
                        .withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(badge!,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color:
                              badgeColor ?? color)),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 16,
                  color: AppColors.textHint),
            ]),
          ),
        ),
      );
}

class _RoleRow extends StatelessWidget {
  final String emoji, label;
  final int    count;
  final Color  color;
  const _RoleRow({
    required this.emoji,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 6),
        child: Row(children: [
          Text(emoji,
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ]),
      );
}