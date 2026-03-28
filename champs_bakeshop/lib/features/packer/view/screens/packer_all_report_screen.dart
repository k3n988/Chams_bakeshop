import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/packer_production_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/packer_service.dart';

class PackerAllReportScreen extends StatefulWidget {
  const PackerAllReportScreen({super.key});

  @override
  State<PackerAllReportScreen> createState() => _PackerAllReportScreenState();
}

class _PackerAllReportScreenState extends State<PackerAllReportScreen> {
  final _service = PackerService();

  bool   _isLoading = false;
  String? _error;

  List<UserModel> _packers = [];
  Map<String, List<PackerProductionModel>> _data = {};

  // Locked to today — packers cannot navigate to other dates
  final String _todayStr =
      DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final db = context.read<DatabaseService>();
      final packers = await db.getUsersByRole('packer');
      _packers = packers;

      final newData = <String, List<PackerProductionModel>>{};
      await Future.wait(packers.map((p) async {
        final prods = await _service.getProductionsByDate(
          packerId: p.id,
          date: _todayStr,
        );
        newData[p.id] = prods;
      }));

      setState(() { _data = newData; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePkrs = _packers
        .where((p) => (_data[p.id] ?? []).isNotEmpty)
        .toList();
    final totalBundles = _data.values
        .fold(0, (sum, prods) => sum + prods.fold(0, (s, p) => s + p.bundleCount));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.packer),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Packer Daily Report',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
            Text(_todayStr,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          // "TODAY" lock badge — shows that date is fixed
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.packer.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.packer.withValues(alpha: 0.25)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline_rounded,
                  size: 11, color: AppColors.packer),
              SizedBox(width: 4),
              Text('TODAY ONLY',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.packer,
                      letterSpacing: 0.4)),
            ]),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.packer,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Info notice ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Showing today's production only. Pull down to refresh.",
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.info.withValues(alpha: 0.85)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Summary banner ──────────────────────────────
              if (!_isLoading && _error == null && totalBundles > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.packer,
                        AppColors.packer.withValues(alpha: 0.75)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.packer.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOTAL BUNDLES TODAY',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6)),
                            const SizedBox(height: 4),
                            Text('$totalBundles bundles',
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ]),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Active Packers',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${activePkrs.length}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Content ─────────────────────────────────────
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(
                        color: AppColors.packer, strokeWidth: 2.5),
                  ),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.cloud_off_outlined,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Failed to load. Pull down to retry.',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.danger)),
                    ),
                  ]),
                )
              else if (_packers.isEmpty || totalBundles == 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48,
                          color: AppColors.textHint.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text('No entries recorded yet today',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),
                )
              else
                Column(
                  children: activePkrs.map((packer) {
                    final prods = _data[packer.id] ?? [];
                    final bundles =
                        prods.fold(0, (s, p) => s + p.bundleCount);

                    // Group by product name
                    final byProduct = <String, int>{};
                    for (final p in prods) {
                      byProduct[p.productName] =
                          (byProduct[p.productName] ?? 0) + p.bundleCount;
                    }

                    return _PackerCard(
                      packer:    packer,
                      bundles:   bundles,
                      byProduct: byProduct,
                      rank:      activePkrs.indexOf(packer) + 1,
                      isTop:     activePkrs.indexOf(packer) == 0 &&
                                 activePkrs.length > 1,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PACKER CARD — bundles only, no salary shown
// ─────────────────────────────────────────────────────────────
class _PackerCard extends StatelessWidget {
  final UserModel        packer;
  final int              bundles;
  final Map<String, int> byProduct;
  final int              rank;
  final bool             isTop;

  const _PackerCard({
    required this.packer,
    required this.bundles,
    required this.byProduct,
    required this.rank,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop
              ? AppColors.packer.withValues(alpha: 0.35)
              : AppColors.border,
          width: isTop ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────────
            Row(children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.packer.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  packer.name.isNotEmpty
                      ? packer.name[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.packer),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(packer.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                      if (isTop) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFFF9800)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: const Text('TOP TODAY',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE65100),
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text('#$rank · Packer',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint)),
                  ],
                ),
              ),

              // Bundle count badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.packer.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.packer.withValues(alpha: 0.20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$bundles',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.packer)),
                    const Text('bundles',
                        style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ]),

            // ── Product breakdown ────────────────────────────
            if (byProduct.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: byProduct.entries.map((e) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${e.key}: ${e.value}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
