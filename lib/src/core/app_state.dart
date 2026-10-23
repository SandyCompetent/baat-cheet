import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/public_api_rag_service.dart';
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

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    // 1. Initialize persistent storage
    await StorageService.init();
    GeminiService.instance.loadFromStorage();
    PublicApiRagService.instance.loadFromStorage();

    // 2. Load stored theme mode
    final storedMode = StorageService.getThemeMode();
    _themeMode = switch (storedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    // 3. Initial display name defaults to Guest User for unauthenticated visitors
    _displayName = 'Guest User';

    // 4. Listen to Firebase auth state changes
    try {
      final auth = _auth;
      final initialUser = auth?.currentUser;
      if (initialUser != null && !initialUser.isAnonymous) {
        _firebaseUser = initialUser;
        _isGuest = false;
        _displayName = (initialUser.displayName != null &&
                initialUser.displayName!.trim().isNotEmpty)
            ? initialUser.displayName!.trim()
            : (initialUser.email?.split('@').first ?? 'User');
        unawaited(
          _syncAuthenticatedUserProfile(initialUser).then((_) {
            notifyListeners();
          }),
        );
      } else {
        _isGuest = true;
        _displayName = 'Guest User';
      }

      if (auth != null) {
        _authSub = auth.authStateChanges().listen((user) async {
          _firebaseUser = user;
          if (user != null && !user.isAnonymous) {
            _isGuest = false;
            await _syncAuthenticatedUserProfile(user);
          } else {
            _isGuest = true;
            _displayName = 'Guest User';
          }
          notifyListeners();
        });
      }
    } catch (_) {
      // Offline or mock environment fallback
    }

    notifyListeners();
  }

  Future<void> _syncAuthenticatedUserProfile(User user) async {
    String? name = user.displayName;
    if (name == null || name.trim().isEmpty) {
      final fs = _firestore;
      if (fs != null) {
        try {
          final doc = await fs
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 3));
          if (doc.exists) {
            final data = doc.data();
            final fsName = data?['displayName'] as String?;
            if (fsName != null && fsName.trim().isNotEmpty) {
              name = fsName.trim();
              try {
                await user.updateDisplayName(name);
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    }

    _displayName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (user.email?.split('@').first ?? 'User');
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

    final auth = _auth;
    final user = auth?.currentUser ?? _firebaseUser;
    if (user != null && !user.isAnonymous) {
      // Authenticated user: persist to Firebase Auth and Firestore
      try {
        await user.updateDisplayName(trimmed);
        await user.reload();
        _firebaseUser = auth?.currentUser ?? user;
      } catch (e) {
        debugPrint('Auth profile update error: $e');
      }

      final fs = _firestore;
      if (fs != null) {
        try {
          String validName = trimmed;
          if (validName.length > 100) {
            validName = validName.substring(0, 100);
          }
          await fs.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'displayName': validName,
            'isOnline': true,
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore profile update error: $e');
        }
      }
    } else {
      // Unauthenticated user: temporary in-memory display name while using the app
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
    _isGuest = true;
    _firebaseUser = null;
    _displayName = 'Guest User';
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
