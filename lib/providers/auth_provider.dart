import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _setLoading(true);
      _currentUser = await _authService.getUserData(uid);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential?.user != null) {
        await _loadUserData(credential!.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? profileImageUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final credential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        profileImageUrl: profileImageUrl,
      );
      
      if (credential?.user != null) {
        await _loadUserData(credential!.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    File? profileImage,
  }) async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      String? imageUrl;
      if (profileImage != null) {
        imageUrl = await _authService.uploadProfileImage(profileImage);
      }

      await _authService.updateUserProfile(
        uid: _currentUser!.uid,
        name: name,
        profileImageUrl: imageUrl,
      );

      // Refresh user data
      await _loadUserData(_currentUser!.uid);
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      if (_currentUser != null) {
        await _authService.updateUserOnlineStatus(_currentUser!.uid, isOnline);
        _currentUser = _currentUser!.copyWith(
          isOnline: isOnline,
          lastSeen: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> updateFCMToken(String token) async {
    try {
      if (_currentUser != null) {
        await _authService.updateFCMToken(_currentUser!.uid, token);
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
