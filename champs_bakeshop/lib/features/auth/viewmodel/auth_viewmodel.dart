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
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e, stackTrace) {
      // Shows the REAL error on screen so you can diagnose it
      debugPrint('LOGIN ERROR: $e');
      debugPrint('STACK: $stackTrace');

      _errorMessage = 'Error: ${e.toString()}';
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