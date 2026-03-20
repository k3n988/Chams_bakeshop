import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';

import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/seller_remittance_viewmodel.dart';

import '../../../../features/auth/view/login_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({super.key});

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
            onPressed: () async {
              Navigator.pop(ctx);
              context.read<AuthViewModel>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
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
    final vm   = context.watch<SellerRemittanceViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        children: [
          // ── Avatar & name ────────────────────────────────────
          _ProfileCard(user: user),
          const SizedBox(height: 16),

          // ── Stats card ───────────────────────────────────────
          _StatsCard(vm: vm),
          const SizedBox(height: 16),

          // ── Info card ─────────────────────────────────────────
          _InfoCard(),
          const SizedBox(height: 24),

          // ── Logout ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout,
                  color: AppColors.danger, size: 18),
              label: const Text('Sign Out',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: AppColors.danger, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final dynamic user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.seller,
              AppColors.seller.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.seller.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              user.name.isNotEmpty ? user.name[0] : 'S',
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(user.name,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(user.email,
              style: const TextStyle(
                  fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🏪', style: TextStyle(fontSize: 13)),
                SizedBox(width: 6),
                Text('Pandesal Seller',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ]),
      );
}

// ── Stats card ────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final SellerRemittanceViewModel vm;
  const _StatsCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('THIS WEEK\'S STATS'),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCell(
                    value: '${vm.totalPiecesSold}',
                    label: 'Pieces Sold',
                    color: AppColors.success),
                Container(
                    width: 1, height: 44, color: AppColors.border),
                _StatCell(
                    value: formatCurrency(vm.totalActualRemittance),
                    label: 'Remitted',
                    color: AppColors.seller),
                Container(
                    width: 1, height: 44, color: AppColors.border),
                _StatCell(
                    value: '${vm.daysRemitted}',
                    label: 'Days',
                    color: const Color(0xFF1976D2)),
              ],
            ),
          ],
        ),
      );
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color  color;
  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint)),
        ],
      );
}

// ── Info card ─────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('HOW IT WORKS'),
            const SizedBox(height: 14),
            _InfoRow(
                icon: Icons.wb_sunny_outlined,
                color: AppColors.seller,
                title: 'Morning Session',
                desc:
                    'Input your plantsa count and subra before going out to sell.'),
            const Divider(height: 20, color: AppColors.border),
            _InfoRow(
                icon: Icons.calculate_outlined,
                color: const Color(0xFF1976D2),
                title: 'Formula',
                desc:
                    '(Plantsa × 25 + Subra) × ₱5 = Expected remittance.'),
            const Divider(height: 20, color: AppColors.border),
            _InfoRow(
                icon: Icons.payments_outlined,
                color: AppColors.success,
                title: 'Evening Remittance',
                desc:
                    'Declare returns and submit actual cash collected. Variance is tracked.'),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   desc;
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.text)),
                const SizedBox(height: 3),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
}

// ── Shared ────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: AppColors.seller,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
                letterSpacing: 0.8)),
      ]);
}