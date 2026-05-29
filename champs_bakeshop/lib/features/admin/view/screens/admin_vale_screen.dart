import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/network_utils.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../../core/services/packer_service.dart';
import '../../../../core/services/seller_service.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/admin_vale_viewmodel.dart';

// ── Orange palette — matches the admin dashboard ──────────────────────────────
const _kOrange      = Color(0xFFFF7A00);
const _kOrangeLight = Color(0xFFFFA03A);

class AdminValeScreen extends StatefulWidget {
  const AdminValeScreen({super.key});

  @override
  State<AdminValeScreen> createState() => _AdminValeScreenState();
}

class _AdminValeScreenState extends State<AdminValeScreen> {
  String _selectedRole = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'master_baker': return AppColors.masterBaker;
      case 'helper':       return AppColors.helper;
      case 'packer':       return AppColors.packer;
      case 'seller':       return AppColors.seller;
      default:             return AppColors.textHint;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'master_baker': return 'Baker';
      case 'helper':       return 'Helper';
      case 'packer':       return 'Packer';
      case 'seller':       return 'Seller';
      default:             return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminValeViewModel>();

    // Filter users
    var users = vm.nonAdminUsers;
    if (_selectedRole != 'all') {
      users = users.where((u) => u.role == _selectedRole).toList();
    }
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      users = users.where((u) => u.name.toLowerCase().contains(query)).toList();
    }

    // Sort: users with vale > 0 first (desc total), then zero
    users.sort((a, b) {
      final ta = vm.userTotal(a.id);
      final tb = vm.userTotal(b.id);
      if (ta > 0 && tb == 0) return -1;
      if (ta == 0 && tb > 0) return 1;
      return tb.compareTo(ta);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      body: RefreshIndicator(
        color: _kOrange,
        onRefresh: () => context.read<AdminValeViewModel>().load(),
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator(color: _kOrange))
            : CustomScrollView(
                slivers: [
                  // ── Grand Total Banner ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kOrange, _kOrangeLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _kOrange.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.store,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Outstanding Vale',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatCurrency(vm.grandTotal),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${vm.activeEntries.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'items',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Role Filter Chips ───────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _roleChip('all', 'All'),
                            const SizedBox(width: 8),
                            _roleChip('master_baker', 'Baker'),
                            const SizedBox(width: 8),
                            _roleChip('helper', 'Helper'),
                            const SizedBox(width: 8),
                            _roleChip('packer', 'Packer'),
                            const SizedBox(width: 8),
                            _roleChip('seller', 'Seller'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Search Field ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search employee...',
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textHint, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      size: 18, color: AppColors.textHint),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.border, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.border, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: _kOrange, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── User Cards ──────────────────────────────────────────
                  users.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 56,
                                    color: AppColors.textHint
                                        .withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                const Text('No employees found',
                                    style: TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final user = users[i];
                                final total = vm.userTotal(user.id);
                                return _UserCard(
                                  user: user,
                                  total: total,
                                  roleColor: _roleColor(user.role),
                                  roleLabel: _roleLabel(user.role),
                                  onTap: () =>
                                      _showUserValeSheet(context, user.id),
                                );
                              },
                              childCount: users.length,
                            ),
                          ),
                        ),
                ],
              ),
      ),
    );
  }

  Widget _roleChip(String role, String label) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kOrange : AppColors.border,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kOrange.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── User Vale Bottom Sheet ──────────────────────────────────────────────

  void _showUserValeSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserValeSheet(userId: userId),
    );
  }
}

// ─── User Card ──────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final dynamic user;
  final double total;
  final Color roleColor;
  final String roleLabel;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.total,
    required this.roleColor,
    required this.roleLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: total > 0
                    ? AppColors.danger.withValues(alpha: 0.25)
                    : AppColors.border,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Total amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(total),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: total > 0
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total > 0 ? 'outstanding' : 'no vale',
                      style: TextStyle(
                        fontSize: 10,
                        color: total > 0
                            ? AppColors.danger.withValues(alpha: 0.7)
                            : AppColors.success.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    color: AppColors.textHint.withValues(alpha: 0.6),
                    size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── User Vale Sheet ─────────────────────────────────────────────────────────

class _UserValeSheet extends StatelessWidget {
  final String userId;
  static final PackerService _packerService = PackerService();
  static final SellerService _sellerService = SellerService();

  const _UserValeSheet({required this.userId});

  @override
  Widget build(BuildContext context) {
    final vm      = context.watch<AdminValeViewModel>();
    final entries = vm.userEntries(userId);
    final total   = vm.userTotal(userId);
    final name    = vm.userName(userId);
    final authVm  = context.read<AuthViewModel>();
    final adminId = authVm.currentUser?.id ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F4F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vale / Store Credit',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Total chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: total > 0
                            ? AppColors.danger.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: total > 0
                              ? AppColors.danger.withValues(alpha: 0.3)
                              : AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        formatCurrency(total),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: total > 0
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),

              // Entries list
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 48,
                                color: AppColors.success
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 10),
                            const Text(
                              'No outstanding vale',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: entries.length,
                        itemBuilder: (_, i) {
                          final e = entries[i];
                          return _EntryRow(
                            entry: e,
                            onDelete: () async {
                              final confirm =
                                  await _confirmDialog(context, 'Tangtanga ang Entry',
                                      'Tangtangon ang "${e.productName}" (${formatCurrency(e.price)})?');
                              if (confirm == true) {
                                await vm.deleteEntry(e.id);
                              }
                            },
                          );
                        },
                      ),
              ),

              // Bottom action buttons
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
                child: Row(
                  children: [
                    // Add Vale button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _guardedShowAddValeDialog(
                            context, userId, adminId, vm),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Vale'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                    if (total > 0) ...[
                      const SizedBox(width: 10),
                      // Settle All button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final confirm = await _confirmDialog(
                                context,
                                'I-settle Tanan',
                                'I-settle na ba ang tanang vale ni $name?\nTotal: ${formatCurrency(total)}');
                            if (confirm != true) return;
                            if (!await hasInternet()) {
                              messenger.showSnackBar(SnackBar(
                                content: const Text(kNoInternetMsg),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.all(12),
                              ));
                              return;
                            }
                            if (confirm == true) {
                              final ok =
                                  await vm.settleAllForUser(userId);
                              if (context.mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? 'All vale settled!'
                                        : 'Failed to settle vale.'),
                                    backgroundColor: ok
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                );
                                if (ok) Navigator.of(context).pop();
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline,
                              size: 18),
                          label: const Text('I-settle Tanan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: BorderSide(
                                color: AppColors.success.withValues(alpha: 0.6),
                                width: 1.5),
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDialog(
      BuildContext context, String title, String msg) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.text)),
        content: Text(msg,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textHint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Oo'),
          ),
        ],
      ),
    );
  }

  Future<double> _currentPayrollForUser(
      BuildContext context, AdminValeViewModel vm) async {
    final user = vm.users.where((u) => u.id == userId).firstOrNull;
    if (user == null) return 0;

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final weekStart =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    final weekEnd =
        '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';

    if (user.isPacker) {
      final prods = await _packerService.getProductionsByWeek(
        packerId: user.id,
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
      final bundles = prods.fold<int>(0, (s, p) => s + p.bundleCount);
      return bundles * AppConstants.packerRatePerBundle;
    }

    if (user.isSeller) {
      final remits = await _sellerService.getRemittancesByRange(
        sellerId: user.id,
        fromDate: weekStart,
        toDate: weekEnd,
      );
      return remits.fold<double>(0.0, (s, r) => s + r.salary);
    }

    final db = context.read<DatabaseService>();
    final payroll = context.read<PayrollService>();
    final products = await db.getAllProducts();
    final productions = await db.getProductionsByDateRange(weekStart, weekEnd);

    double gross = 0;
    for (final prod in productions) {
      final isMaster = prod.masterBakerId == user.id;
      final isHelper = prod.helperIds.contains(user.id);
      if (!isMaster && !isHelper) continue;

      final calc = payroll.computeDaily(prod, products);
      gross += isMaster
          ? calc.salaryPerWorker + calc.bakerIncentive
          : calc.salaryPerWorker;
    }
    return gross;
  }

  Future<void> _guardedShowAddValeDialog(
      BuildContext context,
      String userId,
      String adminId,
      AdminValeViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final currentPayroll = await _currentPayrollForUser(context, vm);
    if (!context.mounted) return;
    final currentOutstanding = vm.userTotal(userId);
    final remainingAllowance = currentPayroll - currentOutstanding;

    if (currentPayroll <= 0) {
      messenger.showSnackBar(const SnackBar(
        content: Text(
            'Dili pa pwede makadugang og vale. Wala pa siyay payroll/trabaho karong panahona.'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    if (remainingAllowance <= 0) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            'Vale blocked. Adding more would make payroll negative. Payroll limit: ${formatCurrency(currentPayroll)}.'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      return;
    }

    _showAddValeDialog(context, userId, adminId, vm);
  }

  Future<void> _showBlockingErrorDialog(
      BuildContext context, String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.text),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sige'),
          ),
        ],
      ),
    );
  }

  void _showAddValeDialog(BuildContext context, String userId,
      String adminId, AdminValeViewModel vm) {
    final productCtrl = TextEditingController();
    final priceCtrl   = TextEditingController();
    final formKey     = GlobalKey<FormState>();
    bool saving       = false;

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Add Vale Entry',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: productCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Product / Item',
                    prefixIcon: const Icon(Icons.shopping_bag_outlined,
                        size: 18, color: _kOrange),
                    filled: true,
                    fillColor: const Color(0xFFF8F4F0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.border, width: 1)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.border, width: 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _kOrange, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Enter product name'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price (₱)',
                    prefixIcon: const Icon(Icons.payments_outlined,
                        size: 18, color: _kOrange),
                    filled: true,
                    fillColor: const Color(0xFFF8F4F0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.border, width: 1)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.border, width: 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _kOrange, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter price';
                    }
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Enter valid price';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  saving ? null : () => Navigator.pop(dCtx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textHint)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final messenger = ScaffoldMessenger.of(context);
                      if (!await hasInternet()) {
                        messenger.showSnackBar(SnackBar(
                          content: const Text(kNoInternetMsg),
                          backgroundColor: AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.all(12),
                        ));
                        return;
                      }
                      final currentPayroll =
                          await _currentPayrollForUser(context, vm);
                      if (!dCtx.mounted) return;
                      if (currentPayroll <= 0) {
                        await _showBlockingErrorDialog(
                          dCtx,
                          'Dili Pwede ang Vale',
                          'Wala pay payroll o trabaho kining empleyadoha karong panahona, mao nga dili pa pwede makadugang og vale.',
                        );
                        return;
                      }
                      final currentOutstanding = vm.userTotal(userId);
                      final requestedPrice =
                          double.parse(priceCtrl.text.trim());
                      final remainingAllowance =
                          currentPayroll - currentOutstanding;
                      if (remainingAllowance <= 0) {
                        await _showBlockingErrorDialog(
                          dCtx,
                          'Naabot na ang Limit sa Vale',
                          'Ang kasamtangang wala pa nabayrang vale naabot na sa payroll limit nga ${formatCurrency(currentPayroll)} ani nga empleyado.',
                        );
                        return;
                      }
                      if (requestedPrice > remainingAllowance) {
                        await _showBlockingErrorDialog(
                          dCtx,
                          'Sobra ang Vale',
                          'Dili pwede makadugang og vale nga ${formatCurrency(requestedPrice)}.\n\n${formatCurrency(remainingAllowance)} nalang ang pwede karong payroll.',
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      final ok = await vm.addEntry(
                        userId:      userId,
                        productName: productCtrl.text,
                        price: requestedPrice,
                        createdBy: adminId,
                      );
                      if (!dCtx.mounted || !context.mounted) return;
                      Navigator.pop(dCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Vale entry added!'
                              : 'Failed to add entry.'),
                          backgroundColor: ok
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Entry Row ───────────────────────────────────────────────────────────────

class _EntryRow extends StatelessWidget {
  final ValeEntry entry;
  final VoidCallback onDelete;

  const _EntryRow({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            // Product icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 16, color: _kOrange),
            ),
            const SizedBox(width: 12),
            // Name + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.date,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              formatCurrency(entry.price),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 4),
            // Delete
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline,
                  size: 18,
                  color: AppColors.danger.withValues(alpha: 0.7)),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
