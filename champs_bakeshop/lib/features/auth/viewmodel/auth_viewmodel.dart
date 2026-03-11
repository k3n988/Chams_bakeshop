import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/database_service.dart';

class AuthViewModel extends ChangeNotifier {
  final DatabaseService _db;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel(this._db);

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (role.isEmpty) {
        _errorMessage = 'Please select a role first.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (email.trim().isEmpty) {
        _errorMessage = 'Please enter your email.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (password.isEmpty) {
        _errorMessage = 'Please enter your password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = await _db.authenticateUser(
          email.trim().toLowerCase(), password, role);

      if (user == null) {
        _errorMessage = 'Invalid credentials or role mismatch.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
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
