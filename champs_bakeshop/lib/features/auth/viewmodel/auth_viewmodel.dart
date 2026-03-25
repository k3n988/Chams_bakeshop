import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/database_service.dart';

// Keys used to persist the session
const _kUserId       = 'session_user_id';
const _kUserName     = 'session_user_name';
const _kUserEmail    = 'session_user_email';
const _kUserPassword = 'session_user_password';
const _kUserRole     = 'session_user_role';
const _kUserPhoto    = 'session_user_photo';

class AuthViewModel extends ChangeNotifier {
  final DatabaseService _db;

  AuthViewModel(this._db);

  UserModel? _currentUser;
  bool       _isLoading    = false;
  String?    _errorMessage;
  String?    _localPhotoPath;

  UserModel? get currentUser    => _currentUser;
  bool       get isLoading      => _isLoading;
  String?    get errorMessage   => _errorMessage;
  bool       get isLoggedIn     => _currentUser != null;
  String?    get localPhotoPath => _localPhotoPath;

  // ── Try to restore session on app start ──────────────────
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final id    = prefs.getString(_kUserId);
    if (id == null) return false;

    _currentUser = UserModel(
      id:       id,
      name:     prefs.getString(_kUserName)     ?? '',
      email:    prefs.getString(_kUserEmail)    ?? '',
      password: prefs.getString(_kUserPassword) ?? '',
      role:     prefs.getString(_kUserRole)     ?? '',
    );
    _localPhotoPath = prefs.getString(_kUserPhoto);
    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password, String selectedRole) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _db.authenticateUser(
        email.trim().toLowerCase(),
        password,
        selectedRole,
      );

      if (user == null) {
        _errorMessage = 'Invalid credentials or wrong role selected.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      await _saveSession(user);
      // load persisted photo for this user
      final prefs = await SharedPreferences.getInstance();
      _localPhotoPath = prefs.getString('${_kUserPhoto}_${user.id}');
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      debugPrint('STACK: $stackTrace');

      _errorMessage = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser    = null;
    _errorMessage   = null;
    _localPhotoPath = null;
    await _clearSession();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Update name and/or password ──────────────────────────
  Future<String?> updateProfile({
    required String name,
    required String password,
  }) async {
    if (_currentUser == null) return 'Not logged in';
    try {
      final updated = _currentUser!.copyWith(
        name:     name.trim().isEmpty     ? null : name.trim(),
        password: password.trim().isEmpty ? null : password.trim(),
      );
      await _db.updateUser(updated);
      _currentUser = updated;
      await _saveSession(updated);
      notifyListeners();
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // ── Save local profile photo path ────────────────────────
  Future<void> setLocalPhoto(String path) async {
    _localPhotoPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_kUserPhoto}_${_currentUser!.id}', path);
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId,       user.id);
    await prefs.setString(_kUserName,     user.name);
    await prefs.setString(_kUserEmail,    user.email);
    await prefs.setString(_kUserPassword, user.password);
    await prefs.setString(_kUserRole,     user.role);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserName);
    await prefs.remove(_kUserEmail);
    await prefs.remove(_kUserPassword);
    await prefs.remove(_kUserRole);
  }
}
