// lib/features/helper/viewmodel/batch_production_viewmodel.dart

import 'package:flutter/material.dart';
import '../../../core/models/batch_production_model.dart';
import '../../../core/services/database_service.dart';

class BatchProductionViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final String currentUserId;

  BatchProductionViewModel({
    required DatabaseService db,
    required this.currentUserId,
  }) : _db = db;

  // ── State ────────────────────────────────────────────────

  DateTime selectedDate = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String? selectedBakerId;

  List<Map<String, String>> masterBakers = [];
  List<Map<String, String>> products     = [];

  final List<BatchProductionItem> batches = [];
  int? editingIndex;

  String? currentProductId;
  int     currentSacks = 1;

  final cat60Ctrl  = TextEditingController();
  final cat36Ctrl  = TextEditingController();
  final cat48Ctrl  = TextEditingController();
  final subraCtrl  = TextEditingController();
  final sakaCtrl   = TextEditingController();

  bool isLoading  = true;
  bool isSaving   = false;
  String? errorMessage;
  bool    saveSuccess = false;

  // ── Computed ─────────────────────────────────────────────

  String get formattedDate => selectedDate.toString().split(' ')[0];
  int get totalSacks => batches.fold(0, (sum, b) => sum + b.sacks);
  bool get canSave => !isSaving && batches.isNotEmpty && selectedBakerId != null;
  bool get isEditing => editingIndex != null;

  // ── Init / Dispose ───────────────────────────────────────

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final allUsers = await _db.getAllUsers();
      masterBakers = allUsers
          .where((u) => u.role == 'master_baker')
          .map((u) => {'id': u.id, 'name': u.name})
          .toList();

      final allProducts = await _db.getAllProducts();
      products = allProducts
          .map((p) => {'id': p.id, 'name': p.name})
          .toList();

      if (products.isNotEmpty) {
        currentProductId = products.first['id'];
      }
    } catch (e) {
      errorMessage = 'Error loading data: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    cat60Ctrl.dispose();
    cat36Ctrl.dispose();
    cat48Ctrl.dispose();
    subraCtrl.dispose();
    sakaCtrl.dispose();
    super.dispose();
  }

  // ── Date / Baker / Product ───────────────────────────────

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setBaker(String? id) {
    selectedBakerId = id;
    notifyListeners();
  }

  void setProduct(String? id) {
    currentProductId = id;
    notifyListeners();
  }

  // ── Sacks counter ────────────────────────────────────────

  void incrementSacks() {
    currentSacks++;
    notifyListeners();
  }

  void decrementSacks() {
    if (currentSacks > 1) {
      currentSacks--;
      notifyListeners();
    }
  }

  // ── Batch CRUD ───────────────────────────────────────────

  String? addOrUpdateBatch() {
    if (currentProductId == null) return 'Please select a product first.';

    final batch = BatchProductionItem(
      productId: currentProductId!,
      sacks:     currentSacks,
      timestamp: TimeOfDay.now(),
      cat60:     int.tryParse(cat60Ctrl.text),
      cat36:     int.tryParse(cat36Ctrl.text),
      cat48:     int.tryParse(cat48Ctrl.text),
      subra:     int.tryParse(subraCtrl.text),
      saka:      int.tryParse(sakaCtrl.text),
    );

    if (editingIndex != null) {
      batches[editingIndex!] = batch;
      editingIndex = null;
    } else {
      batches.add(batch);
    }

    _resetForm();
    notifyListeners();
    return null;
  }

  void editBatch(int index) {
    final b = batches[index];
    editingIndex     = index;
    currentProductId = b.productId;
    currentSacks     = b.sacks;
    cat60Ctrl.text   = b.cat60?.toString() ?? '';
    cat36Ctrl.text   = b.cat36?.toString() ?? '';
    cat48Ctrl.text   = b.cat48?.toString() ?? '';
    subraCtrl.text   = b.subra?.toString() ?? '';
    sakaCtrl.text    = b.saka?.toString()  ?? '';
    notifyListeners();
  }

  void removeBatch(int index) {
    batches.removeAt(index);
    if (editingIndex == index) {
      editingIndex = null;
      _resetForm();
    }
    notifyListeners();
  }

  void cancelEdit() {
    editingIndex = null;
    _resetForm();
    notifyListeners();
  }

  void _resetForm() {
    currentProductId = products.isNotEmpty ? products.first['id'] : null;
    currentSacks     = 1;
    cat60Ctrl.clear();
    cat36Ctrl.clear();
    cat48Ctrl.clear();
    subraCtrl.clear();
    sakaCtrl.clear();
  }

  // ── Save ─────────────────────────────────────────────────

  /// Inserts one row per batch into the helper_batches table.
  /// Returns an error message on failure, null on success.
  Future<String?> save() async {
    if (selectedBakerId == null) return 'Please select a Master Baker.';
    if (batches.isEmpty)         return 'Add at least one batch to the list.';

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      for (final batch in batches) {
        final row = {
          'id':             '${DateTime.now().millisecondsSinceEpoch}_${batch.productId}',
          'date':           formattedDate,
          'helper_id':      currentUserId,
          'master_baker_id': selectedBakerId!,
          'product_id':     batch.productId,
          'cat60':          batch.cat60,
          'cat36':          batch.cat36,
          'cat48':          batch.cat48,
          'subra':          batch.subra,
          'saka':           batch.saka,
        };
        await _db.insertHelperBatch(row);
      }

      saveSuccess = true;
      return null;
    } catch (e) {
      errorMessage = 'Error saving batch: $e';
      return errorMessage;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  String getProductName(String id) => products
      .firstWhere((p) => p['id'] == id, orElse: () => {'name': 'Unknown'})['name']!;
}