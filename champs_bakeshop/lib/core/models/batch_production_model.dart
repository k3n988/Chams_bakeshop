// lib/core/models/batch_production_model.dart

import 'package:flutter/material.dart';

/// Represents a single batch entry before it is committed to [ProductionModel].
/// Used by the helper's Add Production form as a staging item.
class BatchProductionItem {
  final String productId;
  int sacks;
  final TimeOfDay timestamp;

  // Category breakdown — optional, collected at the batch level
  int? cat60;
  int? cat36;
  int? cat48;
  int? subra;
  int? saka;

  BatchProductionItem({
    required this.productId,
    required this.sacks,
    required this.timestamp,
    this.cat60,
    this.cat36,
    this.cat48,
    this.subra,
    this.saka,
  });

  /// Merges another batch into this one (same productId).
  void mergeWith(BatchProductionItem other) {
    sacks  += other.sacks;
    cat60   = (cat60  ?? 0) + (other.cat60  ?? 0);
    cat36   = (cat36  ?? 0) + (other.cat36  ?? 0);
    cat48   = (cat48  ?? 0) + (other.cat48  ?? 0);
    subra   = (subra  ?? 0) + (other.subra  ?? 0);
    saka    = (saka   ?? 0) + (other.saka   ?? 0);
  }

  BatchProductionItem copyWith({
    String?   productId,
    int?      sacks,
    TimeOfDay? timestamp,
    int?      cat60,
    int?      cat36,
    int?      cat48,
    int?      subra,
    int?      saka,
  }) =>
      BatchProductionItem(
        productId: productId ?? this.productId,
        sacks:     sacks     ?? this.sacks,
        timestamp: timestamp ?? this.timestamp,
        cat60:     cat60     ?? this.cat60,
        cat36:     cat36     ?? this.cat36,
        cat48:     cat48     ?? this.cat48,
        subra:     subra     ?? this.subra,
        saka:      saka      ?? this.saka,
      );

  /// Summary string shown in the batch list tile (e.g. "60: 3 · 36: 2").
  String get categorySummary {
    final parts = <String>[
      if (cat60 != null && cat60! > 0) '60: $cat60',
      if (cat36 != null && cat36! > 0) '36: $cat36',
      if (cat48 != null && cat48! > 0) '48: $cat48',
      if (subra != null && subra! > 0) 'Subra: $subra',
      if (saka  != null && saka!  > 0) 'Saka: $saka',
    ];
    return parts.join(' · ');
  }

  bool get hasCategories =>
      (cat60 ?? 0) > 0 ||
      (cat36 ?? 0) > 0 ||
      (cat48 ?? 0) > 0 ||
      (subra ?? 0) > 0 ||
      (saka  ?? 0) > 0;
}