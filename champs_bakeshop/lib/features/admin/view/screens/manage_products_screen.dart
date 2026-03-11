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
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product != null ? product.pricePerSack.toStringAsFixed(0) : '');
    final isEdit = product != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Product' : 'Add Product',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name', hintText: 'e.g. Otap', prefixIcon: Icon(Icons.bakery_dining_outlined))),
          const SizedBox(height: 14),
          TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price per Sack (₱)', hintText: '580', prefixIcon: Icon(Icons.attach_money))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceCtrl.text);
              if (nameCtrl.text.trim().isEmpty || price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid input'), backgroundColor: AppColors.danger));
                return;
              }
              final vm = context.read<AdminProductViewModel>();
              bool ok = isEdit
                  ? await vm.updateProduct(product!.copyWith(name: nameCtrl.text.trim(), pricePerSack: price))
                  : await vm.addProduct(name: nameCtrl.text.trim(), pricePerSack: price);
              if (ok && ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Updated!' : 'Added!'), backgroundColor: AppColors.success));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: 'Products',
          subtitle: 'Manage bakery products & pricing',
          trailing: ElevatedButton.icon(onPressed: () => _showDialog(context), icon: const Icon(Icons.add, size: 18), label: const Text('Add Product')),
        ),
        if (vm.products.isEmpty)
          const EmptyState(message: 'No products yet')
        else
          ...vm.products.map((p) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('🍞', style: TextStyle(fontSize: 22)))),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${formatCurrency(p.pricePerSack)} / sack', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20), onPressed: () => _showDialog(context, product: p)),
                IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20), onPressed: () async {
                  await context.read<AdminProductViewModel>().deleteProduct(p.id);
                }),
              ]),
            ),
          )),
      ]),
    );
  }
}
