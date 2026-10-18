import 'package:chatbud/src/core/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_theme_mode': 'system',
      'guest_display_name': 'Guest Explorer',
    });
    await AppState.instance.initialize();
  });

  group('AppState Tests', () {
    test('Initial state loads guest defaults correctly', () {
      final state = AppState.instance;
      expect(state.isGuest, true);
      expect(state.isLoggedIn, false);
      expect(state.displayName, 'Guest User');
      expect(state.email, 'guest@chatbud.local');
      expect(state.themeMode, ThemeMode.system);
    });

    test('setThemeMode updates themeMode and notifies listeners', () {
      final state = AppState.instance;
      bool notified = false;
      state.addListener(() {
        notified = true;
      });

      state.setThemeMode(ThemeMode.dark);

      expect(state.themeMode, ThemeMode.dark);
      expect(notified, true);
    });

    test('updateDisplayName modifies display name for guest user', () async {
      final state = AppState.instance;
      bool notified = false;
      state.addListener(() {
        notified = true;
      });

      await state.updateDisplayName('Nightwing');

      expect(state.displayName, 'Nightwing');
      expect(notified, true);
    });

    test('signOut resets user to guest state', () async {
      final state = AppState.instance;
      await state.signOut();

      expect(state.isGuest, true);
      expect(state.isLoggedIn, false);
      expect(state.firebaseUser, isNull);
    });
  });
}
