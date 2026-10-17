import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'storage_service.dart';

/// Central reactive application state for ChatBud.
/// Manages:
/// - Firebase Authentication synchronization & guest mode
/// - ThemeMode (system / light / dark) with persistent storage
/// - User profile display name & presence
class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  AppState._internal();

  User? _firebaseUser;
  bool _isGuest = true;
  String _displayName = 'Guest User';
  ThemeMode _themeMode = ThemeMode.system;
  StreamSubscription<User?>? _authSub;

  User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => !_isGuest && _firebaseUser != null;
  bool get isGuest => _isGuest;
  String get displayName => _displayName;
  String get email => _firebaseUser?.email ?? 'guest@chatbud.local';
  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    // 1. Initialize persistent storage
    await StorageService.init();

    // 2. Load stored theme mode
    final storedMode = StorageService.getThemeMode();
    _themeMode = switch (storedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    // 3. Load guest name if any
    _displayName = StorageService.getGuestName();

    // 4. Listen to Firebase auth state changes
    try {
      _firebaseUser = FirebaseAuth.instance.currentUser;
      if (_firebaseUser != null) {
        _isGuest = false;
        _displayName = _firebaseUser!.displayName ??
            _firebaseUser!.email?.split('@').first ??
            'User';
      }

      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        _firebaseUser = user;
        if (user != null) {
          _isGuest = false;
          _displayName = user.displayName ??
              user.email?.split('@').first ??
              'User';
        } else {
          _isGuest = true;
          _displayName = StorageService.getGuestName();
        }
        notifyListeners();
      });
    } catch (_) {
      // Offline or mock environment fallback
    }

    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    final modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    StorageService.setThemeMode(modeStr);
    notifyListeners();
  }

  Future<void> updateDisplayName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    _displayName = trimmed;

    if (_firebaseUser != null) {
      await _firebaseUser!.updateDisplayName(trimmed);
      await _firebaseUser!.reload();
    } else {
      await StorageService.setGuestName(trimmed);
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _isGuest = true;
    _firebaseUser = null;
    _displayName = StorageService.getGuestName();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
