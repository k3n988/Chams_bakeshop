import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/utils/helpers.dart';

class AdminUserViewModel extends ChangeNotifier {
  final DatabaseService _db;

  List<UserModel> _users = [];
  bool _isLoading = false;

  AdminUserViewModel(this._db);

  List<UserModel> get users => _users;
  List<UserModel> get nonAdminUsers => _users.where((u) => !u.isAdmin).toList();
  List<UserModel> get helpers => _users.where((u) => u.isHelper).toList();
  List<UserModel> get masterBakers => _users.where((u) => u.isMasterBaker).toList();
  bool get isLoading => _isLoading;

  Map<String, String> get userNameMap => {for (final u in _users) u.id: u.name};
  Map<String, String> get userRoleMap => {for (final u in _users) u.id: u.role};

  String getUserName(String id) =>
      _users.where((u) => u.id == id).firstOrNull?.name ?? '?';

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    _users = await _db.getAllUsers();
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> addUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      final existing = await _db.getUserByEmail(normalizedEmail);
      if (existing != null) {
        return 'Email already exists.';
      }
      final user = UserModel(
        id: generateId('u'),
        name: name.toUpperCase(),
        email: normalizedEmail,
        password: password,
        role: role,
      );
      await _db.insertUser(user);
      await loadUsers();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateUser(UserModel user) async {
    try {
      await _db.updateUser(user);
      await loadUsers();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteUser(String id) async {
    try {
      await _db.deleteUser(id);
      await loadUsers();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
