import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/admin_product_viewmodel.dart';

class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  void _showDialog(BuildContext context, {ProductModel? product}) {
    final nameCtrl  = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(
        text: product != null ? product.pricePerSack.toStringAsFixed(0) : '');
    final bonusCtrl = TextEditingController(
        text: product != null ? product.bonusPerSack.toStringAsFixed(0) : '');
    final masterBakerIncentiveCtrl = TextEditingController(
        text: product != null
            ? product.masterBakerIncentivePerSack.toStringAsFixed(0)
            : '');
    final isEdit = product != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEdit ? 'Edit Product' : 'Add Product',
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.primaryDark),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Product Name ──
          TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Product Name',
              hintText: 'e.g. Otap',
              prefixIcon: Icon(Icons.bakery_dining_outlined),
            ),
          ),
          const SizedBox(height: 14),

          // ── Price per Sack ──
          TextField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price per Sack (₱)',
              hintText: '580',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 14),

          // ── Bonus per Sack (new) ──
          TextField(
            controller: bonusCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Bonus per Sack (₱)',
              hintText: '32',
              prefixIcon: Icon(Icons.card_giftcard_outlined),
              helperText: 'Shared bonus for workers per sack produced',
              helperStyle: TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: masterBakerIncentiveCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Master Baker Incentive per Sack (₱)',
              hintText: 'Enter amount',
              prefixIcon: Icon(Icons.workspace_premium_outlined),
              helperText: 'Added only to the master baker salary',
              helperStyle: TextStyle(fontSize: 11),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceCtrl.text);
              final bonus = double.tryParse(bonusCtrl.text) ?? 0;
              final masterBakerIncentive =
                  double.tryParse(masterBakerIncentiveCtrl.text);

              if (nameCtrl.text.trim().isEmpty ||
                  price == null ||
                  price <= 0 ||
                  masterBakerIncentive == null ||
                  masterBakerIncentive < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Product name, price, and master baker incentive are required'),
                    backgroundColor: AppColors.danger));
                return;
              }

              final vm = context.read<AdminProductViewModel>();
              final messenger = ScaffoldMessenger.of(context);

              bool ok = isEdit
                  ? await vm.updateProduct(product.copyWith(
                      name: nameCtrl.text.trim(),
                      pricePerSack: price,
                      bonusPerSack: bonus,
                      masterBakerIncentivePerSack: masterBakerIncentive,
                    ))
                  : await vm.addProduct(
                      name: nameCtrl.text.trim(),
                      pricePerSack: price,
                      bonusPerSack: bonus,
                      masterBakerIncentivePerSack: masterBakerIncentive,
                    );

              if (ok && ctx.mounted) {
                Navigator.pop(ctx);
                messenger.showSnackBar(SnackBar(
                    content: Text(isEdit ? 'Updated!' : 'Added!'),
                    backgroundColor: AppColors.success));
              }
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminProductViewModel>();
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Products',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                color: AppColors.text)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _showDialog(context),
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Add Product'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (vm.products.isEmpty)
          const EmptyState(message: 'No products yet')
        else
          ...vm.products.map((p) => Card(
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shadowColor: Colors.black12,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                        child: Text('🍞', style: TextStyle(fontSize: 22))),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatCurrency(p.pricePerSack)} / sack',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                      // Show master baker incentive only if set
                      if (p.masterBakerIncentivePerSack > 0)
                        Text(
                          '+ ${formatCurrency(p.masterBakerIncentivePerSack)} master baker incentive / sack',
                          style: const TextStyle(
                              color: AppColors.masterBaker,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primary, size: 20),
                        onPressed: () => _showDialog(context, product: p)),
                    IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger, size: 20),
                        onPressed: () async {
                          await context
                              .read<AdminProductViewModel>()
                              .deleteProduct(p.id);
                        }),
                  ]),
                ),
              )),
      ]),
      ),
    );
  }
}
