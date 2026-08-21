import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

const _darkText = Color(0xFF1A1A1A);
const _orange = Color(0xFFFF7A00);

class ValeProfileButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;

  const ValeProfileButton({
    super.key,
    required this.onTap,
    this.accentColor = AppColors.danger,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long_outlined,
                    color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Vale',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _darkText)),
                    SizedBox(height: 2),
                    Text('View your borrowed items from the store',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textHint.withValues(alpha: 0.5), size: 20),
            ]),
          ),
        ),
      );
}

void showMyValeSheet({
  required BuildContext context,
  required String userId,
  required String userName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Provider.value(
      value: context.read<DatabaseService>(),
      child: _MyValeSheet(userId: userId, userName: userName),
    ),
  );
}

class _MyValeSheet extends StatefulWidget {
  final String userId;
  final String userName;

  const _MyValeSheet({
    required this.userId,
    required this.userName,
  });

  @override
  State<_MyValeSheet> createState() => _MyValeSheetState();
}

class _MyValeSheetState extends State<_MyValeSheet> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final db = context.read<DatabaseService>();
      final rows = await db.getValeEntriesByUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _entries = rows
            .where((r) => !(r['is_settled'] as bool? ?? false))
            .toList()
          ..sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
      });
    } catch (_) {
      if (mounted) setState(() => _entries = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _total => _entries.fold(
        0.0,
        (sum, entry) => sum + ((entry['price'] as num?)?.toDouble() ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.danger, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Vale',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _darkText,
                            letterSpacing: -0.3)),
                    Text(widget.userName,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ),
              if (!_loading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _total > 0
                        ? AppColors.danger.withValues(alpha: 0.08)
                        : AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _total > 0
                          ? AppColors.danger.withValues(alpha: 0.25)
                          : AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    formatCurrency(_total),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _total > 0
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                  ),
                ),
            ]),
          ),
          const Divider(height: 20, color: AppColors.border),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.danger, strokeWidth: 2.5),
                  )
                : _entries.isEmpty
                    ? const _EmptyValeState()
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: _entries.length + 1,
                        itemBuilder: (_, i) {
                          if (i == _entries.length) {
                            return _ValeTotalBanner(total: _total);
                          }

                          final entry = _entries[i];
                          final name =
                              entry['product_name'] as String? ?? '-';
                          final price =
                              (entry['price'] as num?)?.toDouble() ?? 0;
                          final date = (entry['date'] ?? '') as String;

                          return _ValeEntryRow(
                            name: name,
                            price: price,
                            date: date,
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyValeState extends StatelessWidget {
  const _EmptyValeState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 40, color: AppColors.success),
            ),
            const SizedBox(height: 14),
            const Text('No outstanding vale',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _darkText)),
            const SizedBox(height: 4),
            const Text('You have no borrowed items from the store.',
                style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
        ),
      );
}

class _ValeTotalBanner extends StatelessWidget {
  final double total;

  const _ValeTotalBanner({required this.total});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_orange, Color(0xFFFFA03A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _orange.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL VALE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.8)),
                SizedBox(height: 2),
                Text('Amount to settle',
                    style: TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
            Text(
              formatCurrency(total),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5),
            ),
          ],
        ),
      );
}

class _ValeEntryRow extends StatelessWidget {
  final String name;
  final double price;
  final String date;

  const _ValeEntryRow({
    required this.name,
    required this.price,
    required this.date,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.danger, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _darkText)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 11, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint)),
                  ]),
                ],
              ),
            ),
            Text(
              formatCurrency(price),
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.danger),
            ),
          ]),
        ),
      );
}
