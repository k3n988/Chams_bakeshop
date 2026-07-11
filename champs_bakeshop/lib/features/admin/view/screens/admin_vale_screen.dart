import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/network_utils.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../../auth/view/login_screen.dart';
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
  late DateTime _selectedWeekStart = _startOfWeek(DateTime.now());

  static DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _monthName(int month) => _monthNames[month - 1];

  String _weekLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    if (start.month == end.month && start.year == end.year) {
      return '${_monthName(start.month)} ${start.day}-${end.day}, ${start.year}';
    }
    return '${_monthName(start.month)} ${start.day} - ${_monthName(end.month)} ${end.day}, ${end.year}';
  }

  bool get _isSelectedWeekCurrent =>
      _selectedWeekStart.isAtSameMomentAs(_startOfWeek(DateTime.now()));

  void _changeWeek(int direction) {
    setState(() {
      _selectedWeekStart =
          _selectedWeekStart.add(Duration(days: 7 * direction));
    });
  }

  Future<void> _pickWeek() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedWeekStart,
      currentDate: today,
      firstDate: DateTime(today.year - 2, 1, 1),
      lastDate: DateTime(today.year + 1, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kOrange,
            onPrimary: Colors.white,
            onSurface: AppColors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _selectedWeekStart = _startOfWeek(picked));
  }

  Future<void> _logout() async {
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

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
    final authVm = context.watch<AuthViewModel>();
    final isCashier = authVm.currentUser?.isCashier == true;
    final visibleUsers =
        vm.nonAdminUsers.where((u) => u.role != 'cashier').toList();
    final visibleUserIds = visibleUsers.map((u) => u.id).toSet();
    final weekStart = _selectedWeekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));
    bool isInSelectedWeek(ValeEntry e) {
      final parsed = DateTime.tryParse(e.date);
      if (parsed == null) return false;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      return !day.isBefore(weekStart) && !day.isAfter(weekEnd);
    }

    final visibleActiveEntries = vm.activeEntries
        .where((e) => visibleUserIds.contains(e.userId) && isInSelectedWeek(e))
        .toList();
    final visibleSettledEntries = vm.entries
        .where((e) => e.isSettled && visibleUserIds.contains(e.userId))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final settledThisWeek = visibleSettledEntries.where((e) {
      return isInSelectedWeek(e);
    }).toList();
    double weekUserTotal(String userId) => visibleActiveEntries
        .where((e) => e.userId == userId)
        .fold(0.0, (s, e) => s + e.price);
    final lockedUserIds = vm.paidUserIdsForWeek(weekStart);

    // Filter users
    var users = visibleUsers;
    if (_selectedRole != 'all') {
      users = users.where((u) => u.role == _selectedRole).toList();
    }
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      users = users.where((u) => u.name.toLowerCase().contains(query)).toList();
    }

    // Sort: users with vale > 0 first (desc total), then zero
    users.sort((a, b) {
      final ta = weekUserTotal(a.id);
      final tb = weekUserTotal(b.id);
      if (ta > 0 && tb == 0) return -1;
      if (ta == 0 && tb > 0) return 1;
      return tb.compareTo(ta);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: isCashier
          ? AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Vale',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Settled history',
                  icon: const Icon(Icons.history_outlined, color: _kOrange),
                  onPressed: settledThisWeek.isEmpty
                      ? null
                      : () => _showSettledHistorySheet(
                          context, settledThisWeek, vm),
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout, color: AppColors.danger),
                  onPressed: _logout,
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
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
                        child: Stack(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.store,
                                      color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Weekly Outstanding Vale',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatCurrency(visibleActiveEntries
                                            .fold(0.0, (s, e) => s + e.price)),
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
                                      '${visibleActiveEntries.length}',
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
                            if (!isCashier)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: IconButton(
                                  tooltip: 'Settled history',
                                  onPressed: settledThisWeek.isEmpty
                                      ? null
                                      : () => _showSettledHistorySheet(
                                          context, settledThisWeek, vm),
                                  icon: const Icon(
                                    Icons.history_outlined,
                                    color: Colors.white,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
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

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _kOrange.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Previous week',
                              onPressed: () => _changeWeek(-1),
                              icon: const Icon(
                                Icons.chevron_left,
                                color: _kOrange,
                                size: 18,
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: _pickWeek,
                                borderRadius: BorderRadius.circular(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_outlined,
                                      color: _kOrange,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _weekLabel(weekStart),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _kOrange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (_isSelectedWeekCurrent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _kOrange,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'THIS WEEK',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Next week',
                              onPressed: () => _changeWeek(1),
                              icon: Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: _kOrange,
                              ),
                            ),
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
                                final total = weekUserTotal(user.id);
                                final hasResto = visibleActiveEntries.any((e) =>
                                    e.userId == user.id &&
                                    e.productName
                                        .trim()
                                        .toLowerCase()
                                        .contains('resto'));
                                return _UserCard(
                                  user: user,
                                  total: total,
                                  hasResto: hasResto,
                                  isLocked: lockedUserIds.contains(user.id),
                                  roleColor: _roleColor(user.role),
                                  roleLabel: _roleLabel(user.role),
                                  onTap: () =>
                                      _showUserValeSheet(
                                          context, user.id, weekStart),
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

  void _showUserValeSheet(
      BuildContext context, String userId, DateTime weekStart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserValeSheet(userId: userId, weekStart: weekStart),
    );
  }
}

// ─── User Card ──────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final dynamic user;
  final double total;
  final bool hasResto;
  final bool isLocked;
  final Color roleColor;
  final String roleLabel;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.total,
    required this.hasResto,
    required this.isLocked,
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
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.textHint.withValues(alpha: 0.03)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLocked
                    ? AppColors.textHint.withValues(alpha: 0.18)
                    : total > 0
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
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
                          if (hasResto)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Resto',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          if (isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.textHint
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_outline,
                                      size: 10, color: AppColors.textHint),
                                  SizedBox(width: 3),
                                  Text(
                                    'Locked',
                                    style: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
                        color: hasResto ? AppColors.danger : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasResto
                          ? 'Resto'
                          : total > 0
                              ? 'outstanding'
                              : 'no vale',
                      style: TextStyle(
                        fontSize: 10,
                        color: hasResto
                            ? AppColors.danger
                            : total > 0
                            ? AppColors.success.withValues(alpha: 0.7)
                            : AppColors.success.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                if (isLocked)
                  Icon(Icons.lock_outline,
                      color: AppColors.textHint.withValues(alpha: 0.65),
                      size: 18)
                else
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

void _showSettledHistorySheet(
    BuildContext context, List<ValeEntry> entries, AdminValeViewModel vm) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F4F0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Settled Vale This Week',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Text(
                      '${entries.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _SettledHistorySection(
                  entries: entries,
                  userNameOf: vm.userName,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─── User Vale Sheet ─────────────────────────────────────────────────────────

class _SettledHistorySection extends StatelessWidget {
  final List<ValeEntry> entries;
  final String Function(String userId) userNameOf;

  const _SettledHistorySection({
    required this.entries,
    required this.userNameOf,
  });

  @override
  Widget build(BuildContext context) {
    final recent = entries.take(8).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_outlined,
                  color: AppColors.success, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Settled History',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(
              '${entries.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ...recent.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.productName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${userNameOf(e.userId)} • ${e.date}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatCurrency(e.price),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () async {
                        final vm = context.read<AdminValeViewModel>();
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await vm.restoreEntry(e.id);
                        messenger.showSnackBar(SnackBar(
                          content: Text(ok
                              ? 'Vale restored.'
                              : 'Failed to restore vale.'),
                          backgroundColor:
                              ok ? AppColors.success : AppColors.danger,
                        ));
                      },
                      icon: const Icon(Icons.restore_outlined,
                          size: 18, color: AppColors.info),
                      tooltip: 'Restore',
                    ),
                  ]),
                ),
              )),
        ],
      ),
    );
  }
}

class _UserValeSheet extends StatelessWidget {
  final String userId;
  final DateTime weekStart;

  const _UserValeSheet({required this.userId, required this.weekStart});

  @override
  Widget build(BuildContext context) {
    final vm      = context.watch<AdminValeViewModel>();
    final weekEnd = weekStart.add(const Duration(days: 6));
    final entries = vm.userEntries(userId).where((e) {
      final parsed = DateTime.tryParse(e.date);
      if (parsed == null) return false;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      return !day.isBefore(weekStart) && !day.isAfter(weekEnd);
    }).toList();
    final total   = entries.fold(0.0, (s, e) => s + e.price);
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
                              final confirm = await _confirmDialog(
                                context,
                                'Tangtanga ang Entry',
                                'Tangtangon ang "${e.productName}" (${formatCurrency(e.price)})?',
                              );
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
                            context, userId, adminId, vm, weekStart),
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
                            final ok = await vm.settleAllForUser(userId);
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

Future<void> _guardedShowAddValeDialog(
    BuildContext context,
    String userId,
    String adminId,
    AdminValeViewModel vm,
    DateTime weekStart) async {
  _showAddValeDialog(context, userId, adminId, vm, weekStart);
}

void _showAddValeDialog(
    BuildContext context,
    String userId,
    String adminId,
    AdminValeViewModel vm,
    DateTime weekStart) {
  final productCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool saving = false;

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
                      final requestedPrice =
                          double.parse(priceCtrl.text.trim());
                      setDialogState(() => saving = true);
                      final navigator = Navigator.of(context);
                      final isLocked =
                          await vm.isUserPaidForWeek(userId, weekStart);
                      final targetDate = isLocked
                          ? weekStart.add(const Duration(days: 7))
                          : weekStart;
                      final ok = await vm.addEntry(
                        userId:      userId,
                        productName: productCtrl.text,
                        price: requestedPrice,
                        createdBy: adminId,
                        date: targetDate,
                      );
                      if (!context.mounted) return;
                      navigator.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? isLocked
                                  ? 'Week locked. Vale added to next week!'
                                  : 'Vale entry added!'
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
  final VoidCallback? onDelete;

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
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline,
                    size: 18,
                    color: AppColors.danger.withValues(alpha: 0.7)),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
