// lib/features/admin/view/screens/christmas_bonus_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/user_model.dart';
import '../../viewmodel/admin_user_viewmodel.dart';

// ─────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────

/// One bonus entry: who, when, how much, and a note
class BonusEntry {
  final String id;
  final String userId;
  final String userName;
  final String role;       // 'master_baker' | 'helper'
  final String date;       // yyyy-MM-dd
  final double amount;
  final String? note;

  BonusEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.date,
    required this.amount,
    this.note,
  });

  BonusEntry copyWith({double? amount, String? note}) => BonusEntry(
        id:       id,
        userId:   userId,
        userName: userName,
        role:     role,
        date:     date,
        amount:   amount ?? this.amount,
        note:     note ?? this.note,
      );
}

// ─────────────────────────────────────────────────────────────
//  SIMPLE IN-MEMORY VIEW MODEL  (replace with Supabase later)
// ─────────────────────────────────────────────────────────────

class ChristmasBonusViewModel extends ChangeNotifier {
  // Map key: "$userId|$date"
  final Map<String, BonusEntry> _entries = {};
  List<UserModel> _workers = [];
  bool isLoading = false;

  List<UserModel> get workers => _workers;

  List<BonusEntry> get allEntries => _entries.values.toList();

  // Total for a specific month (1-12) and year
  double monthTotal(int month, int year) => _entries.values
      .where((e) {
        final d = DateTime.tryParse(e.date);
        return d != null && d.month == month && d.year == year;
      })
      .fold(0.0, (s, e) => s + e.amount);

  // Entries for a specific month
  List<BonusEntry> entriesForMonth(int month, int year) =>
      _entries.values.where((e) {
        final d = DateTime.tryParse(e.date);
        return d != null && d.month == month && d.year == year;
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  double workerTotal(String userId) => _entries.values
      .where((e) => e.userId == userId)
      .fold(0.0, (s, e) => s + e.amount);

  double workerMonthTotal(String userId, int month, int year) =>
      _entries.values
          .where((e) {
            final d = DateTime.tryParse(e.date);
            return e.userId == userId &&
                d != null &&
                d.month == month &&
                d.year == year;
          })
          .fold(0.0, (s, e) => s + e.amount);

  BonusEntry? getEntry(String userId, String date) =>
      _entries['$userId|$date'];

  void setWorkers(List<UserModel> users) {
    _workers = users
        .where((u) => u.role == 'master_baker' || u.role == 'helper')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  void upsertEntry({
    required String userId,
    required String userName,
    required String role,
    required String date,
    required double amount,
    String? note,
  }) {
    final key = '$userId|$date';
    _entries[key] = BonusEntry(
      id:       key,
      userId:   userId,
      userName: userName,
      role:     role,
      date:     date,
      amount:   amount,
      note:     note,
    );
    notifyListeners();
  }

  void removeEntry(String userId, String date) {
    _entries.remove('$userId|$date');
    notifyListeners();
  }

  // All distinct dates that have any bonus entry
  List<String> datesForMonth(int month, int year) {
    final dates = <String>{};
    for (final e in _entries.values) {
      final d = DateTime.tryParse(e.date);
      if (d != null && d.month == month && d.year == year) {
        dates.add(e.date);
      }
    }
    return dates.toList()..sort();
  }
}

// ─────────────────────────────────────────────────────────────
//  ROOT SCREEN
// ─────────────────────────────────────────────────────────────

class ChristmasBonusScreen extends StatelessWidget {
  const ChristmasBonusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChristmasBonusViewModel(),
      child: const _ChristmasBonusBody(),
    );
  }
}

class _ChristmasBonusBody extends StatefulWidget {
  const _ChristmasBonusBody();

  @override
  State<_ChristmasBonusBody> createState() => _ChristmasBonusBodyState();
}

class _ChristmasBonusBodyState extends State<_ChristmasBonusBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;

  static const _months = [
    'January', 'February', 'March', 'April',
    'May',     'June',     'July',  'August',
    'September','October', 'November','December',
  ];

  @override
  void initState() {
    super.initState();
    final currentMonth = DateTime.now().month - 1;
    _tabController = TabController(
      length: 12,
      vsync: this,
      initialIndex: currentMonth,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWorkers());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    final userVm = context.read<AdminUserViewModel>();
    await userVm.loadUsers();
    if (!mounted) return;
    context.read<ChristmasBonusViewModel>().setWorkers(userVm.users);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFC62828).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🎄', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Christmas Bonus',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              Text('Track holiday bonuses per worker',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400)),
            ],
          ),
        ]),
        actions: [
          // Year switcher
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => setState(() => _selectedYear--),
                child: const Icon(Icons.chevron_left,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              Text('$_selectedYear',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.primaryDark)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _selectedYear++),
                child: const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.primary),
              ),
            ]),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabAlignment: TabAlignment.start,
          tabs: _months.map((m) => Tab(text: m.substring(0, 3))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          12,
          (i) => _MonthBonusTab(
            month: i + 1,
            year: _selectedYear,
            monthName: _months[i],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MONTHLY TAB  — the main spreadsheet-like view
// ─────────────────────────────────────────────────────────────

class _MonthBonusTab extends StatelessWidget {
  final int    month;
  final int    year;
  final String monthName;

  const _MonthBonusTab({
    required this.month,
    required this.year,
    required this.monthName,
  });

  @override
  Widget build(BuildContext context) {
    final vm      = context.watch<ChristmasBonusViewModel>();
    final workers = vm.workers;
    final total   = vm.monthTotal(month, year);
    final entries = vm.entriesForMonth(month, year);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Month hero ───────────────────────────────────────
        _MonthHeroCard(
          monthName: monthName,
          year:      year,
          total:     total,
          count:     entries.length,
          workers:   workers.length,
        ),
        const SizedBox(height: 16),

        // ── Add bonus button ─────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: workers.isEmpty
                ? null
                : () => _showAddBonusDialog(context, vm, workers),
            icon:  const Icon(Icons.add, size: 18),
            label: const Text('Add Bonus Entry',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Worker summary ───────────────────────────────────
        if (workers.isNotEmpty) ...[
          _WorkerSummaryCard(
              workers: workers, vm: vm, month: month, year: year),
          const SizedBox(height: 16),
        ],

        // ── Entries list ─────────────────────────────────────
        if (entries.isEmpty)
          _EmptyState(monthName: monthName)
        else ...[
          _SectionLabel('BONUS ENTRIES — $monthName $year'),
          const SizedBox(height: 10),
          ...entries.map((e) => _BonusEntryCard(
                entry: e,
                onEdit: () => _showEditDialog(context, vm, e, workers),
                onDelete: () => _confirmDelete(context, vm, e),
              )),
        ],
      ]),
    );
  }

  // ── Add dialog ──────────────────────────────────────────────
  void _showAddBonusDialog(BuildContext context, ChristmasBonusViewModel vm,
      List<UserModel> workers) {
    String? selectedUserId;
    String? selectedUserName;
    String? selectedRole;
    final amountCtrl = TextEditingController();
    final noteCtrl   = TextEditingController();
    DateTime selectedDate = DateTime(year, month, 1);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC62828).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🎄', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            const Text('Add Bonus Entry',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const SizedBox(height: 12),

              // Worker picker
              const _FieldLabel('Worker'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedUserId,
                isExpanded: true,
                decoration: _inputDec(hint: 'Select worker'),
                items: workers.map((w) {
                  final roleLabel = w.role == 'master_baker'
                      ? '👨‍🍳 Baker'
                      : '🧑‍🍳 Helper';
                  return DropdownMenuItem(
                    value: w.id,
                    child: Text('$roleLabel — ${w.name}',
                        style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (v) {
                  final worker = workers.firstWhere((w) => w.id == v);
                  setDlg(() {
                    selectedUserId   = v;
                    selectedUserName = worker.name;
                    selectedRole     = worker.role;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Date
              const _FieldLabel('Date'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(year, month, 1),
                    lastDate: DateTime(year, month,
                        DateUtils.getDaysInMonth(year, month)),
                  );
                  if (picked != null) setDlg(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: AppColors.border, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.background,
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(selectedDate.toString().split(' ')[0],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              const _FieldLabel('Bonus Amount (₱)'),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: _inputDec(hint: '0.00', prefix: '₱ '),
              ),
              const SizedBox(height: 12),

              // Note (optional)
              const _FieldLabel('Note (optional)'),
              const SizedBox(height: 6),
              TextField(
                controller: noteCtrl,
                decoration: _inputDec(hint: 'e.g. Christmas 2025'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828)),
              onPressed: () {
                if (selectedUserId == null) return;
                final amount =
                    double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amount <= 0) return;
                vm.upsertEntry(
                  userId:   selectedUserId!,
                  userName: selectedUserName!,
                  role:     selectedRole!,
                  date:     selectedDate.toString().split(' ')[0],
                  amount:   amount,
                  note:     noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit dialog ─────────────────────────────────────────────
  void _showEditDialog(BuildContext context, ChristmasBonusViewModel vm,
      BonusEntry entry, List<UserModel> workers) {
    final amountCtrl =
        TextEditingController(text: entry.amount.toStringAsFixed(2));
    final noteCtrl =
        TextEditingController(text: entry.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_outlined,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(entry.userName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              Text(entry.date,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w400)),
            ]),
          ),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          const _FieldLabel('Bonus Amount (₱)'),
          const SizedBox(height: 6),
          TextField(
            controller: amountCtrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDec(hint: '0.00', prefix: '₱ '),
          ),
          const SizedBox(height: 12),
          const _FieldLabel('Note (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: noteCtrl,
            decoration: _inputDec(hint: 'e.g. Christmas 2025'),
            maxLines: 2,
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () {
              final amount =
                  double.tryParse(amountCtrl.text.trim()) ?? 0;
              if (amount <= 0) return;
              vm.upsertEntry(
                userId:   entry.userId,
                userName: entry.userName,
                role:     entry.role,
                date:     entry.date,
                amount:   amount,
                note:     noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ── Delete confirm ──────────────────────────────────────────
  void _confirmDelete(BuildContext context, ChristmasBonusViewModel vm,
      BonusEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: const Text('Remove Entry',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
            children: [
              const TextSpan(text: 'Remove bonus entry for '),
              TextSpan(
                  text: entry.userName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              TextSpan(text: ' on ${entry.date}?'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              vm.removeEntry(entry.userId, entry.date);
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MONTH HERO CARD
// ─────────────────────────────────────────────────────────────

class _MonthHeroCard extends StatelessWidget {
  final String monthName;
  final int    year;
  final double total;
  final int    count;
  final int    workers;
  const _MonthHeroCard({
    required this.monthName,
    required this.year,
    required this.total,
    required this.count,
    required this.workers,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC62828), Color(0xFFE53935)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC62828).withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('🎄', style: TextStyle(fontSize: 38)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('$monthName $year',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(total),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  _HeroPill(
                      icon: Icons.receipt_outlined,
                      text: '$count entries'),
                  const SizedBox(width: 8),
                  _HeroPill(
                      icon: Icons.group_outlined,
                      text: '$workers workers'),
                ]),
              ]),
            ),
          ],
        ),
      );
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _HeroPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  WORKER SUMMARY CARD  — like the Excel totals per row
// ─────────────────────────────────────────────────────────────

class _WorkerSummaryCard extends StatelessWidget {
  final List<UserModel>         workers;
  final ChristmasBonusViewModel vm;
  final int month;
  final int year;
  const _WorkerSummaryCard({
    required this.workers,
    required this.vm,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final bakers  = workers.where((w) => w.role == 'master_baker').toList();
    final helpers = workers.where((w) => w.role == 'helper').toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Container(
              width: 3, height: 14,
              decoration: BoxDecoration(
                  color: const Color(0xFFC62828),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            const Text('WORKER TOTALS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHint,
                    letterSpacing: 0.8)),
          ]),
        ),

        if (bakers.isNotEmpty) ...[
          _RoleHeader(label: '👨‍🍳  Master Bakers', color: AppColors.masterBaker),
          ...bakers.map((w) => _WorkerRow(
                worker: w,
                amount: vm.workerMonthTotal(w.id, month, year),
                allTime: vm.workerTotal(w.id),
              )),
        ],

        if (helpers.isNotEmpty) ...[
          _RoleHeader(label: '🧑‍🍳  Helpers', color: AppColors.info),
          ...helpers.map((w) => _WorkerRow(
                worker: w,
                amount: vm.workerMonthTotal(w.id, month, year),
                allTime: vm.workerTotal(w.id),
              )),
        ],

        // Grand total row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3F3),
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MONTH TOTAL',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFFC62828))),
              Text(
                formatCurrency(vm.monthTotal(month, year)),
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFFC62828)),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _RoleHeader extends StatelessWidget {
  final String label;
  final Color  color;
  const _RoleHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: color.withValues(alpha: 0.05),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
      );
}

class _WorkerRow extends StatelessWidget {
  final UserModel worker;
  final double    amount;
  final double    allTime;
  const _WorkerRow({
    required this.worker,
    required this.amount,
    required this.allTime,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          // Initials avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(worker.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text('All-time: ${formatCurrency(allTime)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
            ]),
          ),
          Text(
            amount > 0 ? formatCurrency(amount) : '—',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: amount > 0
                    ? const Color(0xFFC62828)
                    : AppColors.textHint),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  BONUS ENTRY CARD  — individual entry row
// ─────────────────────────────────────────────────────────────

class _BonusEntryCard extends StatelessWidget {
  final BonusEntry   entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _BonusEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isBaker = entry.role == 'master_baker';
    final roleColor = isBaker ? AppColors.masterBaker : AppColors.info;
    final roleLabel = isBaker ? '👨‍🍳 Baker' : '🧑‍🍳 Helper';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(children: [
        // Left: avatar
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFC62828).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            entry.userName.isNotEmpty
                ? entry.userName[0].toUpperCase()
                : '?',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: Color(0xFFC62828)),
          ),
        ),
        const SizedBox(width: 12),

        // Middle: info
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Text(entry.userName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.text)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(roleLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: roleColor)),
              ),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 11, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(entry.date,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint)),
              if (entry.note != null) ...[
                const SizedBox(width: 8),
                const Text('•',
                    style: TextStyle(color: AppColors.textHint)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(entry.note!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ]),
          ]),
        ),

        // Right: amount + actions
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            formatCurrency(entry.amount),
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFFC62828)),
          ),
          const SizedBox(height: 4),
          Row(children: [
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.edit_outlined,
                    size: 14, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.delete_outline,
                    size: 14, color: AppColors.danger),
              ),
            ),
          ]),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String monthName;
  const _EmptyState({required this.monthName});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFC62828).withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Text('🎁', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 16),
          Text('No bonus entries for $monthName',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          const Text('Tap "Add Bonus Entry" to record a bonus',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  SHARED SMALL HELPERS
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: const Color(0xFFC62828),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary));
}

InputDecoration _inputDec({String? hint, String? prefix}) =>
    InputDecoration(
      hintText:   hint,
      prefixText: prefix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFFC62828), width: 1.5)),
      filled:     true,
      fillColor:  AppColors.background,
    );