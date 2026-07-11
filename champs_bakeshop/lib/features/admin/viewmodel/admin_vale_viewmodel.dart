import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/utils/helpers.dart';

class ValeEntry {
  final String id;
  final String userId;
  final String productName;
  final double price;
  final String date;
  final String createdBy;
  final bool   isSettled;

  const ValeEntry({
    required this.id,
    required this.userId,
    required this.productName,
    required this.price,
    required this.date,
    required this.createdBy,
    required this.isSettled,
  });

  factory ValeEntry.fromMap(Map<String, dynamic> m) => ValeEntry(
    id:          m['id'] as String,
    userId:      m['user_id'] as String,
    productName: m['product_name'] as String,
    price:       (m['price'] as num).toDouble(),
    date:        m['date'] as String,
    createdBy:   m['created_by'] as String? ?? '',
    isSettled:   (m['is_settled'] as bool?) ?? false,
  );
}

class AdminValeViewModel extends ChangeNotifier {
  final DatabaseService _db;

  AdminValeViewModel(this._db);

  List<UserModel>  _users   = [];
  List<ValeEntry>  _entries = [];
  bool   _isLoading = false;
  String? _error;

  List<UserModel>  get users     => _users;
  List<ValeEntry>  get entries   => _entries;
  bool             get isLoading => _isLoading;
  String?          get error     => _error;

  /// All non-admin users
  List<UserModel> get nonAdminUsers =>
      _users.where((u) => !u.isAdmin).toList();

  /// Unsettled entries only
  List<ValeEntry> get activeEntries =>
      _entries.where((e) => !e.isSettled).toList();

  /// Total unsettled vale per user
  double userTotal(String userId) => activeEntries
      .where((e) => e.userId == userId)
      .fold(0.0, (s, e) => s + e.price);

  /// Grand total of all unsettled vale
  double get grandTotal =>
      activeEntries.fold(0.0, (s, e) => s + e.price);

  /// Unsettled entries for one user, newest first
  List<ValeEntry> userEntries(String userId) => activeEntries
      .where((e) => e.userId == userId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  Future<void> load() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _db.getAllUsers(),
        _db.getAllValeEntries(),
      ]);
      _users   = results[0] as List<UserModel>;
      _entries = (results[1] as List<Map<String, dynamic>>)
          .map(ValeEntry.fromMap)
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addEntry({
    required String userId,
    required String productName,
    required double price,
    required String createdBy,
    DateTime? date,
  }) async {
    try {
      final now = date ?? DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final entry = {
        'id':           generateId('vale'),
        'user_id':      userId,
        'product_name': productName.trim(),
        'price':        price,
        'date':         dateStr,
        'created_by':   createdBy,
        'is_settled':   false,
      };
      await _db.insertValeEntry(entry);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    try {
      await _db.deleteValeEntry(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> settleEntry(String id) async {
    try {
      await _db.settleValeEntry(id);
      final idx = _entries.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _entries[idx] = ValeEntry(
          id:          _entries[idx].id,
          userId:      _entries[idx].userId,
          productName: _entries[idx].productName,
          price:       _entries[idx].price,
          date:        _entries[idx].date,
          createdBy:   _entries[idx].createdBy,
          isSettled:   true,
        );
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> restoreEntry(String id) async {
    try {
      await _db.restoreValeEntry(id);
      final idx = _entries.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _entries[idx] = ValeEntry(
          id:          _entries[idx].id,
          userId:      _entries[idx].userId,
          productName: _entries[idx].productName,
          price:       _entries[idx].price,
          date:        _entries[idx].date,
          createdBy:   _entries[idx].createdBy,
          isSettled:   false,
        );
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> settleAllForUser(String userId) async {
    try {
      await _db.settleAllValeByUser(userId);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> consumeAmountForUser(String userId, double amount) async {
    if (amount <= 0) return true;
    try {
      final active = userEntries(userId)
        ..sort((a, b) => a.date.compareTo(b.date));
      var remaining = amount;

      for (final entry in active) {
        if (remaining <= 0) break;
        if (remaining >= entry.price) {
          await _db.settleValeEntry(entry.id);
          remaining -= entry.price;
        } else {
          await _db.updateValeEntryPrice(entry.id, entry.price - remaining);
          remaining = 0;
        }
      }

      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  String userName(String userId) =>
      _users.where((u) => u.id == userId).firstOrNull?.name ?? '?';
}
