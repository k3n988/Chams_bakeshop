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
  final bool   isDeleted;

  const ValeEntry({
    required this.id,
    required this.userId,
    required this.productName,
    required this.price,
    required this.date,
    required this.createdBy,
    required this.isSettled,
    this.isDeleted = false,
  });

  factory ValeEntry.fromMap(Map<String, dynamic> m) {
    final rawPrice = m['price'];
    final rawDate = m['date'];
    final rawSettled = m['is_settled'];
    final rawDeleted = m['is_deleted'];

    return ValeEntry(
      id: m['id']?.toString() ?? '',
      userId: m['user_id']?.toString() ?? '',
      productName: m['product_name']?.toString() ?? '',
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '') ?? 0,
      date: rawDate is DateTime
          ? rawDate.toIso8601String().substring(0, 10)
          : rawDate?.toString() ?? '',
      createdBy: m['created_by']?.toString() ?? '',
      isSettled: rawSettled is bool
          ? rawSettled
          : rawSettled?.toString().toLowerCase() == 'true',
      isDeleted: rawDeleted is bool
          ? rawDeleted
          : rawDeleted?.toString().toLowerCase() == 'true',
    );
  }
}

class AdminValeViewModel extends ChangeNotifier {
  final DatabaseService _db;

  AdminValeViewModel(this._db);

  List<UserModel>  _users   = [];
  List<ValeEntry>  _entries = [];
  final Map<String, Set<String>> _paidUserIdsByWeek = {};
  bool   _isLoading = false;
  String? _error;
  String? _lastActionError;

  List<UserModel>  get users     => _users;
  List<ValeEntry>  get entries   => _entries;
  bool             get isLoading => _isLoading;
  String?          get error     => _error;
  String?          get lastActionError => _lastActionError;

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

  double userTotalForWeek(String userId, DateTime weekStart) =>
      userEntriesForWeek(userId, weekStart)
          .fold(0.0, (s, e) => s + e.price);

  /// Grand total of all unsettled vale
  double get grandTotal =>
      activeEntries.fold(0.0, (s, e) => s + e.price);

  String _dateStr(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Unsettled entries for one user, newest first
  List<ValeEntry> userEntries(String userId) => activeEntries
      .where((e) => e.userId == userId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<ValeEntry> userEntriesForWeek(String userId, DateTime weekStart) {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 6));

    return userEntries(userId).where((entry) {
      final parsed = DateTime.tryParse(entry.date);
      if (parsed == null) return false;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

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

  Future<bool> isUserPaidForWeek(String userId, DateTime weekStart) async {
    final weekStartStr = _dateStr(weekStart);
    final paidIds = await _db.getPaidUserIds(weekStartStr);
    _paidUserIdsByWeek[weekStartStr] = paidIds;
    return paidIds.contains(userId);
  }

  Set<String> paidUserIdsForWeek(DateTime weekStart) {
    final weekStartStr = _dateStr(weekStart);
    final cached = _paidUserIdsByWeek[weekStartStr];
    if (cached != null) return cached;

    _db.getPaidUserIds(weekStartStr).then((ids) {
      _paidUserIdsByWeek[weekStartStr] = ids;
      notifyListeners();
    }).catchError((_) {});
    return const {};
  }

  Future<bool> deleteEntry(String id) async {
    try {
      _lastActionError = null;
      await _db.deleteValeEntry(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _lastActionError = e.toString();
      return false;
    }
  }

  Future<bool> settleEntry(String id) async {
    try {
      _lastActionError = null;
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
          isDeleted:   false,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _lastActionError = e.toString();
      return false;
    }
  }

  Future<bool> markEntryDeleted(String id) async {
    try {
      _lastActionError = null;
      await _db.markValeEntryDeleted(id);
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
          isDeleted:   true,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _lastActionError = e.toString();
      return false;
    }
  }

  Future<bool> restoreEntry(String id) async {
    try {
      _lastActionError = null;
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
          isDeleted:   false,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _lastActionError = e.toString();
      return false;
    }
  }

  Future<bool> settleAllForUser(String userId, {DateTime? weekStart}) async {
    try {
      if (weekStart == null) {
        await _db.settleAllValeByUser(userId);
      } else {
        for (final entry in userEntriesForWeek(userId, weekStart)) {
          await _db.settleValeEntry(entry.id);
        }
      }
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> consumeAmountForUser(String userId, double amount) async {
    return consumeAmountForUserEntries(userEntries(userId), amount);
  }

  Future<bool> consumeAmountForUserForWeek(
    String userId,
    double amount,
    DateTime weekStart,
  ) async {
    return consumeAmountForUserEntries(
      userEntriesForWeek(userId, weekStart),
      amount,
    );
  }

  Future<bool> consumeAmountForUserEntries(
    List<ValeEntry> entries,
    double amount,
  ) async {
    if (amount <= 0) return true;
    try {
      final active = entries
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
