import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/packer_salary_viewmodel.dart';
import '../../../auth/view/login_screen.dart';

class PackerProfileScreen extends StatelessWidget {
  const PackerProfileScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthViewModel>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser!;
    final vm   = context.watch<PackerSalaryViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top avatar section ────────────────────────────
            _AvatarSection(user: user),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Personal info ───────────────────────────
                  _PersonalInfoCard(user: user),
                  const SizedBox(height: 16),

                  // ── Earnings snapshot ───────────────────────
                  _EarningsSnapshotCard(vm: vm),
                  const SizedBox(height: 16),

                  // ── Settings menu ───────────────────────────
                  _SettingsMenu(),
                  const SizedBox(height: 24),

                  // ── Logout button ───────────────────────────
                  _LogoutButton(
                      onTap: () => _confirmLogout(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  AVATAR SECTION
// ══════════════════════════════════════════════════════════════
class _AvatarSection extends StatelessWidget {
  final dynamic user;
  const _AvatarSection({required this.user});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        child: Column(children: [
          // ── Name at top ─────────────────────────────────────
          Text(user.name,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: 0.5)),
          const SizedBox(height: 16),

          // ── Avatar circle ────────────────────────────────────
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.packer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.packer.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : 'P',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
              ),
              // Camera icon badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    size: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Name with edit icon ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(user.name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text)),
              const SizedBox(width: 6),
              const Icon(Icons.edit_outlined,
                  size: 15, color: AppColors.textHint),
            ],
          ),
          const SizedBox(height: 10),

          // ── Role badge ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.packer.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.packer.withValues(alpha: 0.25)),
            ),
            child: const Text('PACKER',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.packer,
                    letterSpacing: 1.5)),
          ),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  PERSONAL INFO CARD
// ══════════════════════════════════════════════════════════════
class _PersonalInfoCard extends StatelessWidget {
  final dynamic user;
  const _PersonalInfoCard({required this.user});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('PERSONAL INFORMATION'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Name',
                value: user.name,
                isFirst: true,
              ),
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'Role',
                value: 'packer',
              ),
              _InfoRow(
                icon: Icons.fingerprint,
                label: 'ID',
                value: user.id,
                isLast: true,
              ),
            ]),
          ),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final bool     isFirst;
  final bool     isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast  = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.packer.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 18, color: AppColors.packer),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 60,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
            ]),
          ),
          if (!isLast)
            Divider(
                height: 1,
                color: AppColors.border,
                indent: 66,
                endIndent: 16),
        ],
      );
}

// ══════════════════════════════════════════════════════════════
//  EARNINGS SNAPSHOT
// ══════════════════════════════════════════════════════════════
class _EarningsSnapshotCard extends StatelessWidget {
  final PackerSalaryViewModel vm;
  const _EarningsSnapshotCard({required this.vm});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('EARNINGS SNAPSHOT'),
          const SizedBox(height: 10),

          // ── Take-home gradient card ───────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.packer,
                  AppColors.packer.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.packer.withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Take-Home Pay',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(vm.netSalary),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Gross: ${formatCurrency(vm.grossSalary)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Stats row ─────────────────────────────────────────
          Row(children: [
            Expanded(
              child: _SnapshotStat(
                icon:  Icons.calendar_today_outlined,
                value: '${vm.daysWorked} days',
                label: 'Days Worked',
                color: AppColors.packer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SnapshotStat(
                icon:  Icons.inventory_2_outlined,
                value: '${vm.totalBundles}',
                label: 'Total Bundles',
                color: const Color(0xFF1976D2),
              ),
            ),
          ]),
        ],
      );
}

class _SnapshotStat extends StatelessWidget {
  final IconData icon;
  final String   value;
  final String   label;
  final Color    color;
  const _SnapshotStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint)),
            ],
          ),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  SETTINGS MENU
// ══════════════════════════════════════════════════════════════
class _SettingsMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: [
          _MenuItem(
            icon: Icons.person_outline,
            color: AppColors.packer,
            title: 'Edit Display Name',
            subtitle: 'Change how your name appears',
            isFirst: true,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.camera_alt_outlined,
            color: const Color(0xFF1976D2),
            title: 'Edit Profile Photo',
            subtitle: 'Upload or remove your photo',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.lock_outline,
            color: const Color(0xFF388E3C),
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.info_outline,
            color: AppColors.warning,
            title: 'About',
            subtitle: 'App version & info',
            isLast: true,
            onTap: () => _showAbout(context),
          ),
        ]),
      );

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Champ's Bakeshop",
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payroll System — Packer Module',
                style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text('Version 1.0.0',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       title;
  final String       subtitle;
  final bool         isFirst;
  final bool         isLast;
  final String?      trailingLabel;
  final Color?       trailingColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isFirst       = false,
    this.isLast        = false,
    this.trailingLabel,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.only(
              topLeft:     Radius.circular(isFirst ? 16 : 0),
              topRight:    Radius.circular(isFirst ? 16 : 0),
              bottomLeft:  Radius.circular(isLast ? 16 : 0),
              bottomRight: Radius.circular(isLast ? 16 : 0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint)),
                    ],
                  ),
                ),
                if (trailingLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (trailingColor ?? AppColors.success)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(trailingLabel!,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                trailingColor ?? AppColors.success)),
                  )
                else
                  Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textHint),
              ]),
            ),
          ),
          if (!isLast)
            Divider(
                height: 1,
                color: AppColors.border,
                indent: 70,
                endIndent: 16),
        ],
      );
}

// ── Logout button ─────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.logout,
              color: AppColors.danger, size: 18),
          label: const Text('Log Out',
              style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          style: OutlinedButton.styleFrom(
            side:
                const BorderSide(color: AppColors.danger, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onTap,
        ),
      );
}

// ── Shared ────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textHint,
            letterSpacing: 0.8),
      );
}