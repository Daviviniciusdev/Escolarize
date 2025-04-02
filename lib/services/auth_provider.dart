// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;
  bool _initialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;

  // Private method to setup auth state listener
  void _setupAuthListener() {
    _authService.authStateChanges.listen((user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Public method to initialize auth state
  Future<void> initializeAuth() async {
    if (_initialized) return;

    try {
      _isLoading = true;

      // Setup listener first
      _setupAuthListener();

      // Then get current user
      _user = await _authService.getCurrentUser();
      _initialized = true;
    } catch (e) {
      print('Error initializing auth: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    if (!_initialized) await initializeAuth();

    try {
      _isLoading = true;
      notifyListeners();

      _user = await _authService.signIn(email, password);
      return _user != null;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _user = null;
      _initialized = false;
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (!_initialized) await initializeAuth();

    try {
      _isLoading = true;
      notifyListeners();

      _user = await _authService.getCurrentUser();
    } catch (e) {
      print('Error refreshing user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
