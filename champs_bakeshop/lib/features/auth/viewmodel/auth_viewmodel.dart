import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/database_service.dart';

class AuthViewModel extends ChangeNotifier {
  final DatabaseService _db;

  AuthViewModel(this._db);

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  /// Authenticates against the public.users table directly.
  /// No Supabase Auth required — perfect for internal staff apps.
  Future<bool> login(String email, String password, String selectedRole) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Query public.users — matches email + password + role in one call
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
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}