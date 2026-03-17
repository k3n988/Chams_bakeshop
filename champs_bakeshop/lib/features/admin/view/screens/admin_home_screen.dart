import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';

import '../../viewmodel/admin_user_viewmodel.dart';
import '../../viewmodel/admin_product_viewmodel.dart';
import '../../viewmodel/admin_production_viewmodel.dart';
import '../../viewmodel/admin_payroll_viewmodel.dart';

class AdminHomeScreen extends StatelessWidget {
  final void Function(int) onNavigate;
  const AdminHomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final userVM    = context.watch<AdminUserViewModel>();
    final productVM = context.watch<AdminProductViewModel>();
    final prodVM    = context.watch<AdminProductionViewModel>();
    final payrollVM = context.watch<AdminPayrollViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hero banner ──────────────────────────────
          _HeroBanner(),
          const SizedBox(height: 20),

          // ── Stats grid ───────────────────────────────
          const _SectionLabel('QUICK OVERVIEW'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _StatCard(
                icon:  Icons.people_outlined,
                label: 'Total Staff',
                value: '${userVM.nonAdminUsers.length}',
                color: AppColors.masterBaker,
              ),
              _StatCard(
                icon:  Icons.inventory_2_outlined,
                label: 'Products',
                value: '${productVM.products.length}',
                color: AppColors.info,
              ),
              _StatCard(
                icon:  Icons.bar_chart_outlined,
                label: 'Productions',
                value: '${prodVM.productions.length}',
                color: AppColors.primary,
              ),
              _StatCard(
                icon:  Icons.payments_outlined,
                label: 'Total Payroll',
                value: formatCurrency(payrollVM.totalPayroll),
                color: const Color(0xFF388E3C),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Staff breakdown ───────────────────────────
          const _SectionLabel('STAFF BREAKDOWN'),
          const SizedBox(height: 12),
          _StaffBreakdownCard(
            bakers:  userVM.masterBakers.length,
            helpers: userVM.nonAdminUsers.length -
                userVM.masterBakers.length,
            total:   userVM.nonAdminUsers.length,
          ),
          const SizedBox(height: 20),

          // ── Quick actions ─────────────────────────────
          const _SectionLabel('QUICK ACTIONS'),
          const SizedBox(height: 12),
          _ActionTile(
            icon:     Icons.people_outline,
            label:    'Manage Staff',
            subtitle: 'Add, edit, or remove employees',
            color:    AppColors.masterBaker,
            onTap:    () => onNavigate(1),
          ),
          _ActionTile(
            icon:     Icons.inventory_2_outlined,
            label:    'Products',
            subtitle: 'Manage bakery products & pricing',
            color:    AppColors.info,
            onTap:    () => onNavigate(2),
          ),
          _ActionTile(
            icon:     Icons.bar_chart_outlined,
            label:    'Production Reports',
            subtitle: 'View daily production history',
            color:    AppColors.primary,
            onTap:    () => onNavigate(3),
          ),
          _ActionTile(
            icon:     Icons.payments_outlined,
            label:    'Weekly Payroll',
            subtitle: 'Generate & manage payroll',
            color:    const Color(0xFF388E3C),
            onTap:    () => onNavigate(4),
          ),
          _ActionTile(
            icon:     Icons.card_giftcard_outlined,
            label:    'Christmas Bonus',
            subtitle: 'Track holiday bonuses per worker',
            color:    const Color(0xFFC62828),
            onTap:    () => onNavigate(5),
            isLast:   true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  HERO BANNER
// ─────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A00), Color(0xFFFFA03A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A00)
                  .withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good ${_greeting()}!',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text('Admin Dashboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(
                  'Manage your bakeshop operations',
                  style: TextStyle(
                      color:
                          Colors.white.withValues(alpha: 0.85),
                      fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('🧁',
                style: TextStyle(fontSize: 32)),
          ),
        ]),
      );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ─────────────────────────────────────────────────────────
//  STAT CARD
// ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: -0.5)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  STAFF BREAKDOWN CARD
// ─────────────────────────────────────────────────────────
class _StaffBreakdownCard extends StatelessWidget {
  final int bakers;
  final int helpers;
  final int total;

  const _StaffBreakdownCard({
    required this.bakers,
    required this.helpers,
    required this.total,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(children: [
          _StaffRow(
            label: '👨‍🍳  Master Bakers',
            value: '$bakers',
            color: AppColors.masterBaker,
          ),
          const SizedBox(height: 12),
          _StaffRow(
            label: '🧑‍🍳  Helpers',
            value: '$helpers',
            color: AppColors.info,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Staff',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text('$total',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 10),
          // Visual bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(children: [
              if (total > 0) ...[
                Flexible(
                  flex: bakers,
                  child: Container(
                    height: 6,
                    color: AppColors.masterBaker,
                  ),
                ),
                Flexible(
                  flex: helpers > 0 ? helpers : 0,
                  child: Container(
                    height: 6,
                    color: AppColors.info,
                  ),
                ),
              ] else
                Expanded(
                  child: Container(
                    height: 6,
                    color: AppColors.border,
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _LegendDot(color: AppColors.masterBaker,
                label: 'Bakers ($bakers)'),
            const SizedBox(width: 16),
            _LegendDot(color: AppColors.info,
                label: 'Helpers ($helpers)'),
          ]),
        ]),
      );
}

class _StaffRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StaffRow(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ],
      );
}

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendDot(
      {required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint)),
        ],
      );
}

// ─────────────────────────────────────────────────────────
//  ACTION TILE
// ─────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final String       subtitle;
  final Color        color;
  final VoidCallback onTap;
  final bool         isLast;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chevron_right,
                      color: color, size: 16),
                ),
              ]),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
                letterSpacing: 0.9)),
      ]);
}