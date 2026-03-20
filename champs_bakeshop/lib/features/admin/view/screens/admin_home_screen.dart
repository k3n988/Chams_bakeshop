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

          // ── Hero banner ───────────────────────────────────
          _HeroBanner(),
          const SizedBox(height: 20),

          // ── Stats grid ────────────────────────────────────
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

          // ── Staff breakdown ───────────────────────────────
          const _SectionLabel('STAFF BREAKDOWN'),
          const SizedBox(height: 12),
          _StaffBreakdownCard(userVM: userVM),
          const SizedBox(height: 20),

          // ── Quick actions ─────────────────────────────────
          const _SectionLabel('QUICK ACTIONS'),
          const SizedBox(height: 12),

          // Row 1: Users + Products (open via drawer)
          Row(children: [
            Expanded(
              child: _QuickActionCard(
                icon:    Icons.people_outlined,
                label:   'Manage Users',
                color:   AppColors.masterBaker,
                onTap:   () => onNavigate(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon:    Icons.inventory_2_outlined,
                label:   'Products',
                color:   AppColors.info,
                onTap:   () => onNavigate(2),
              ),
            ),
          ]),
          const SizedBox(height: 12),

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

// ── Hero banner ───────────────────────────────────────────────
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
              color:
                  const Color(0xFFFF7A00).withValues(alpha: 0.3),
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
                        color:
                            Colors.white.withValues(alpha: 0.9),
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

// ── Stat card ─────────────────────────────────────────────────
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

// ── Staff breakdown card ──────────────────────────────────────
class _StaffBreakdownCard extends StatelessWidget {
  final AdminUserViewModel userVM;
  const _StaffBreakdownCard({required this.userVM});

  @override
  Widget build(BuildContext context) {
    final bakers   = userVM.masterBakers.length;
    final helpers  = userVM.helpers.length;
    final packers  = userVM.nonAdminUsers.where((u) => u.isPacker).length;
    final sellers  = userVM.nonAdminUsers.where((u) => u.isSeller).length;
    final total    = userVM.nonAdminUsers.length;

    return Container(
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
            color: AppColors.masterBaker),
        const SizedBox(height: 10),
        _StaffRow(
            label: '🧑‍🍳  Helpers',
            value: '$helpers',
            color: AppColors.helper),
        const SizedBox(height: 10),
        _StaffRow(
            label: '📦  Packers',
            value: '$packers',
            color: AppColors.packer),
        const SizedBox(height: 10),
        _StaffRow(
            label: '🥖  Sellers',
            value: '$sellers',
            color: AppColors.seller),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Staff',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            Text('$total',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.primaryDark)),
          ],
        ),
        const SizedBox(height: 10),
        // Progress bar (all 4 roles)
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: total > 0
              ? Row(children: [
                  if (bakers > 0)
                    Flexible(
                        flex: bakers,
                        child: Container(
                            height: 6,
                            color: AppColors.masterBaker)),
                  if (helpers > 0)
                    Flexible(
                        flex: helpers,
                        child: Container(
                            height: 6, color: AppColors.helper)),
                  if (packers > 0)
                    Flexible(
                        flex: packers,
                        child: Container(
                            height: 6, color: AppColors.packer)),
                  if (sellers > 0)
                    Flexible(
                        flex: sellers,
                        child: Container(
                            height: 6, color: AppColors.seller)),
                ])
              : Container(
                  height: 6, color: AppColors.border),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _LegendDot(
                color: AppColors.masterBaker,
                label: 'Bakers ($bakers)'),
            _LegendDot(
                color: AppColors.helper,
                label: 'Helpers ($helpers)'),
            _LegendDot(
                color: AppColors.packer,
                label: 'Packers ($packers)'),
            _LegendDot(
                color: AppColors.seller,
                label: 'Sellers ($sellers)'),
          ],
        ),
      ]),
    );
  }
}

class _StaffRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StaffRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
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
                  fontSize: 11, color: AppColors.textHint)),
        ],
      );
}

// ── Quick action card (2-up grid) ─────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: color.withValues(alpha: 0.20)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: color.withValues(alpha: 0.6)),
            ]),
          ),
        ),
      );
}

// ── Action tile ───────────────────────────────────────────────
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
                    ],
                  ),
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

// ── Section label ─────────────────────────────────────────────
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