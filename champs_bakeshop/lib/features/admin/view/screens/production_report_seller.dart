import 'package:flutter/material.dart';
import '../../../../core/utils/constants.dart';

/// Placeholder — full implementation coming soon
class ProductionReportSeller extends StatelessWidget {
  const ProductionReportSeller({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.seller.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Text('🥖',
                style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 16),
          const Text('Pandesal Reports',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          const Text('Coming soon',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint)),
        ],
      ),
    );
  }
}