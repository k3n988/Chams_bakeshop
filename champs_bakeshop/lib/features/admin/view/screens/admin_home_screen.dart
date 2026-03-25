import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import 'dart:math' as math;
import '../../viewmodel/admin_user_viewmodel.dart';
import '../../viewmodel/admin_production_viewmodel.dart';
import '../../viewmodel/admin_payroll_viewmodel.dart';

class AdminHomeScreen extends StatelessWidget {
  final void Function(int) onNavigate;
  const AdminHomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final userVM    = context.watch<AdminUserViewModel>();
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
          SizedBox(
            height: 110,
            child: Row(children: [
              Expanded(
                child: _StatCard(
                  icon:  Icons.layers_outlined,
                  label: 'Total Bundles',
                  value: '${prodVM.weekTotalBundles}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon:  Icons.payments_outlined,
                  label: 'Baker/Helper Payroll',
                  value: formatCurrency(payrollVM.totalPayroll),
                  color: const Color(0xFF388E3C),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: Row(children: [
              Expanded(
                child: _StatCard(
                  icon:  Icons.inventory_2_outlined,
                  label: 'Packer Payroll',
                  value: formatCurrency(payrollVM.totalPayrollPacker),
                  color: AppColors.packer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon:  Icons.storefront_outlined,
                  label: 'Seller Payroll',
                  value: formatCurrency(payrollVM.totalPayrollSeller),
                  color: AppColors.seller,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Staff breakdown ───────────────────────────────
          const _SectionLabel('STAFF BREAKDOWN'),
          const SizedBox(height: 12),
          _StaffBreakdownCard(userVM: userVM),
          const SizedBox(height: 20),

          // ── Packed this week ──────────────────────────────
          const _SectionLabel('PACKED THIS WEEK — BY PRODUCT'),
          const SizedBox(height: 12),
          _PackedTodayCard(prodVM: prodVM),
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
// ── Staff breakdown card ──────────────────────────────────────
// Replace the entire _StaffBreakdownCard class and its helpers
// (_StaffRow, _LegendDot) with the code below.
// Also add the new _DonutPainter class anywhere in the file.

class _StaffBreakdownCard extends StatefulWidget {
  final AdminUserViewModel userVM;
  const _StaffBreakdownCard({required this.userVM});

  @override
  State<_StaffBreakdownCard> createState() => _StaffBreakdownCardState();
}

class _StaffBreakdownCardState extends State<_StaffBreakdownCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _sweep = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bakers  = widget.userVM.masterBakers.length;
    final helpers = widget.userVM.helpers.length;
    final packers =
        widget.userVM.nonAdminUsers.where((u) => u.isPacker).length;
    final sellers =
        widget.userVM.nonAdminUsers.where((u) => u.isSeller).length;
    final total   = widget.userVM.nonAdminUsers.length;

    // Build segments list: label, count, color
 // First list (for dominant role detection) — around line where segments is defined:
final segments = <_Segment>[
  _Segment('Master Bakers', bakers,  '👨‍🍳', const Color(0xFF2979FF)), // Blue
  _Segment('Helpers',       helpers, '🧑‍🍳', const Color(0xFFFF6D00)), // Orange
  _Segment('Packers',       packers, '📦',  const Color(0xFFF50057)), // Pink
  _Segment('Sellers',       sellers, '🥖',  const Color(0xFF00C853)), // Green
].where((s) => s.count > 0).toList();

    // Dominant role for center label
    final dominant = total > 0
        ? (segments..sort((a, b) => b.count.compareTo(a.count))).first
        : null;
    // Re-sort back to original order after finding dominant
    segments.sort((a, b) {
      const order = ['Master Bakers', 'Helpers', 'Packers', 'Sellers'];
      return order.indexOf(a.label).compareTo(order.indexOf(b.label));
    });

    final pct = dominant != null && total > 0
        ? ((dominant.count / total) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sub-header
          const Text(
            'How your staff splits across roles',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // ── Chart + legend row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut chart
              SizedBox(
                width: 130,
                height: 130,
                child: AnimatedBuilder(
                  animation: _sweep,
                  builder: (_, __) => CustomPaint(
                    painter: _DonutPainter(
                      segments:  segments,
                      total:     total,
                      progress:  _sweep.value,
                      strokeWidth: 22,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            dominant?.label.split(' ').first ?? '—',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Legend
              Expanded(
                child: Column(
                  children: [
                    // Second list (inside the Legend Column):
for (final seg in [
  _Segment('Master Bakers', bakers,  '👨‍🍳', const Color(0xFF2979FF)), // Blue
  _Segment('Helpers',       helpers, '🧑‍🍳', const Color(0xFFFF6D00)), // Orange
  _Segment('Packers',       packers, '📦',  const Color(0xFFF50057)), // Pink
  _Segment('Sellers',       sellers, '🥖',  const Color(0xFF00C853)), // Green
]) ...[
                      _LegendRow(seg: seg, total: total),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Total staff footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Staff',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Data model for a donut segment ───────────────────────────
class _Segment {
  final String label;
  final int    count;
  final String emoji;
  final Color  color;
  const _Segment(this.label, this.count, this.emoji, this.color);
}

// ── Legend row (replaces old _StaffRow + _LegendDot) ─────────
class _LegendRow extends StatelessWidget {
  final _Segment seg;
  final int      total;
  const _LegendRow({required this.seg, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Colored dot
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: seg.color, shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        // Label
        Expanded(
          child: Text(
            seg.label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Count badge
        Text(
          '${seg.count}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: seg.color,
          ),
        ),
      ],
    );
  }
}

// ── Custom donut chart painter ────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<_Segment> segments;
  final int            total;
  final double         progress;   // 0.0 → 1.0  (animation)
  final double         strokeWidth;

  const _DonutPainter({
    required this.segments,
    required this.total,
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width / 2;
    final cy     = size.height / 2;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect   = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background track
    final trackPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color       = const Color(0xFFF0F0F0);
    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    if (total == 0) return;

    // Start from top (−90°)
    double startAngle = -math.pi / 2;
    const gap = 0.04; // radians between segments

    for (final seg in segments) {
      final fraction   = seg.count / total;
      final sweepAngle = fraction * 2 * math.pi * progress;

      if (sweepAngle < 0.01) continue;

      final paint = Paint()
        ..style           = PaintingStyle.stroke
        ..strokeWidth     = strokeWidth
        ..strokeCap       = StrokeCap.round
        ..color           = seg.color;

      canvas.drawArc(
          rect, startAngle + gap / 2, sweepAngle - gap, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.total != total;
}

// ── Packed today card ─────────────────────────────────────────
class _PackedTodayCard extends StatelessWidget {
  final AdminProductionViewModel prodVM;
  const _PackedTodayCard({required this.prodVM});

  @override
  Widget build(BuildContext context) {
    final byProduct = prodVM.weekPackedByProduct;
    final total     = prodVM.weekTotalBundles;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: prodVM.isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            )
          : byProduct.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No packing recorded this week.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textHint),
                    ),
                  ),
                )
              : Column(
                  children: [
                    // ── Per-product rows ─────────────────────
                    ...byProduct.entries.map((e) =>
                        _ProductBundleRow(
                          name:    e.key,
                          bundles: e.value,
                          total:   total,
                        )),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // ── Total footer ─────────────────────────
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bundles',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF1A1A1A))),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text('$total',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppColors.primary,
                                  letterSpacing: -0.3)),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}

class _ProductBundleRow extends StatelessWidget {
  final String name;
  final int    bundles;
  final int    total;

  const _ProductBundleRow({
    required this.name,
    required this.bundles,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final frac = total > 0 ? bundles / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Dot
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            // Product name
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
            ),
            // Bundle count
            Text('$bundles bundle${bundles == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
          ]),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 5,
              backgroundColor:
                  AppColors.primary.withValues(alpha: 0.08),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
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