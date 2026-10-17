import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Soft Minimalist Slate Theme — Design Token System
// ─────────────────────────────────────────────────────────────────────────────

/// Global color tokens for the Soft Minimalist Slate theme.
/// These values are the single source of truth for every surface, text,
/// accent, and status color in the app. Reference them directly rather than
/// using hard-coded hex values anywhere in the widget tree.
abstract class SlateTokens {
  // ── Light mode surfaces ──
  static const Color bgCanvasLight      = Color(0xFFF8FAFC); // Main chat feed bg
  static const Color bgSurfaceLight     = Color(0xFFFFFFFF); // Sidebars, headers, incoming bubbles
  static const Color bgElevatedLight    = Color(0xFFF1F5F9); // Input bar, popovers, hover
  static const Color bgGlassLight       = Color(0xD9F8FAFC); // rgba(248,250,252,0.85) → 0xD9 ≈ 217 ≈ 0.85 opacity

  // ── Dark mode surfaces ──
  static const Color bgCanvasDark       = Color(0xFF0B0F19);
  static const Color bgSurfaceDark      = Color(0xFF111827);
  static const Color bgElevatedDark     = Color(0xFF1E293B);
  static const Color bgGlassDark        = Color(0xD90B0F19); // rgba(11,15,25,0.85)

  // ── Accent ──
  static const Color accentPrimaryLight = Color(0xFF4F46E5); // Indigo 600
  static const Color accentPrimaryDark  = Color(0xFF6366F1); // Indigo 500
  static const Color accentSubtleLight  = Color(0xFFEEF2FF);
  static const Color accentSubtleDark   = Color(0xFF1E1B4B);

  // ── Text ──
  static const Color textPrimaryLight   = Color(0xFF0F172A);
  static const Color textPrimaryDark    = Color(0xFFF8FAFC);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textSecondaryDark  = Color(0xFF94A3B8);
  static const Color textMutedLight     = Color(0xFF94A3B8);
  static const Color textMutedDark      = Color(0xFF64748B);
  static const Color textOnAccent       = Color(0xFFFFFFFF);

  // ── Borders ──
  static const Color borderSubtleLight  = Color(0xFFE2E8F0);
  static const Color borderSubtleDark   = Color(0xFF1E293B);

  // ── Status ──
  static const Color statusOnlineLight  = Color(0xFF10B981); // Emerald
  static const Color statusOnlineDark   = Color(0xFF34D399);
  static const Color statusDangerLight  = Color(0xFFEF4444);
  static const Color statusDangerDark   = Color(0xFFF87171);
}

// ─────────────────────────────────────────────────────────────────────────────
// Light Theme
// ─────────────────────────────────────────────────────────────────────────────
final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Inter',

  colorScheme: const ColorScheme.light(
    primary:        SlateTokens.accentPrimaryLight,
    onPrimary:      SlateTokens.textOnAccent,
    primaryContainer: SlateTokens.accentSubtleLight,
    secondary:      SlateTokens.accentPrimaryLight,
    onSecondary:    SlateTokens.textOnAccent,
    surface:        SlateTokens.bgSurfaceLight,
    onSurface:      SlateTokens.textPrimaryLight,
    surfaceContainerHighest: SlateTokens.bgElevatedLight,
    outline:        SlateTokens.borderSubtleLight,
    error:          SlateTokens.statusDangerLight,
  ),

  scaffoldBackgroundColor: SlateTokens.bgCanvasLight,

  // AppBar — glass header
  appBarTheme: const AppBarTheme(
    backgroundColor:    SlateTokens.bgSurfaceLight,
    foregroundColor:    SlateTokens.textPrimaryLight,
    elevation:          0,
    scrolledUnderElevation: 0,
    shadowColor:        Colors.transparent,
    titleTextStyle: TextStyle(
      color:       SlateTokens.textPrimaryLight,
      fontSize:    16,
      fontWeight:  FontWeight.w600,
      letterSpacing: 0,
      fontFamily: 'Inter',
    ),
    iconTheme: IconThemeData(color: SlateTokens.accentPrimaryLight, size: 22),
  ),

  // Bottom navigation
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor:     SlateTokens.bgSurfaceLight,
    selectedItemColor:   SlateTokens.accentPrimaryLight,
    unselectedItemColor: SlateTokens.textMutedLight,
    type:                BottomNavigationBarType.fixed,
    elevation:           0,
    selectedLabelStyle:  TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 11),
  ),

  // Cards / surface containers
  cardTheme: CardThemeData(
    color:        SlateTokens.bgSurfaceLight,
    elevation:    0,
    shape:        RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: SlateTokens.borderSubtleLight),
    ),
  ),

  // Dividers
  dividerTheme: const DividerThemeData(
    color:     SlateTokens.borderSubtleLight,
    thickness: 1,
    space:     1,
  ),

  // Input fields
  inputDecorationTheme: InputDecorationTheme(
    filled:        true,
    fillColor:     SlateTokens.bgElevatedLight,
    hintStyle:     const TextStyle(color: SlateTokens.textMutedLight, fontSize: 15),
    border:        OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide:   const BorderSide(color: SlateTokens.borderSubtleLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide:   const BorderSide(color: SlateTokens.borderSubtleLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide:   const BorderSide(color: SlateTokens.accentPrimaryLight, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),

  // Elevated buttons → accent-primary
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SlateTokens.accentPrimaryLight,
      foregroundColor: SlateTokens.textOnAccent,
      elevation:       0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),

  // Text buttons
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: SlateTokens.accentPrimaryLight,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  ),

  // Floating action button
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: SlateTokens.accentPrimaryLight,
    foregroundColor: SlateTokens.textOnAccent,
    elevation:       4,
    shape: CircleBorder(),
  ),

  // Progress indicators
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: SlateTokens.accentPrimaryLight,
  ),

  // Chips (filter pills)
  chipTheme: ChipThemeData(
    backgroundColor:       SlateTokens.bgElevatedLight,
    selectedColor:         SlateTokens.accentSubtleLight,
    labelStyle:            const TextStyle(
      color: SlateTokens.textSecondaryLight, fontSize: 13, fontWeight: FontWeight.w500,
    ),
    side:                  const BorderSide(color: SlateTokens.borderSubtleLight),
    shape:                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    padding:               const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),

  // Dialog
  dialogTheme: DialogThemeData(
    backgroundColor: SlateTokens.bgSurfaceLight,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: const TextStyle(
      color: SlateTokens.textPrimaryLight, fontSize: 17, fontWeight: FontWeight.w600,
    ),
    contentTextStyle: const TextStyle(
      color: SlateTokens.textSecondaryLight, fontSize: 14, height: 1.5,
    ),
  ),

  // Text theme
  textTheme: const TextTheme(
    displayMedium: TextStyle(
      color: SlateTokens.textPrimaryLight, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.5,
    ),
    headlineSmall: TextStyle(
      color: SlateTokens.textSecondaryLight, fontSize: 20, fontWeight: FontWeight.w400,
    ),
    titleMedium: TextStyle(
      color: SlateTokens.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5,
    ),
    bodyLarge: TextStyle(
      color: SlateTokens.textPrimaryLight, fontSize: 15, fontWeight: FontWeight.w400, height: 1.45,
    ),
    bodyMedium: TextStyle(
      color: SlateTokens.textSecondaryLight, fontSize: 14, fontWeight: FontWeight.w400, height: 1.45,
    ),
    bodySmall: TextStyle(
      color: SlateTokens.textMutedLight, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.02,
    ),
    labelSmall: TextStyle(
      color: SlateTokens.textMutedLight, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.04,
    ),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Dark Theme
// ─────────────────────────────────────────────────────────────────────────────
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Inter',

  colorScheme: const ColorScheme.dark(
    primary:        SlateTokens.accentPrimaryDark,
    onPrimary:      SlateTokens.textOnAccent,
    primaryContainer: SlateTokens.accentSubtleDark,
    secondary:      SlateTokens.accentPrimaryDark,
    onSecondary:    SlateTokens.textOnAccent,
    surface:        SlateTokens.bgSurfaceDark,
    onSurface:      SlateTokens.textPrimaryDark,
    surfaceContainerHighest: SlateTokens.bgElevatedDark,
    outline:        SlateTokens.borderSubtleDark,
    error:          SlateTokens.statusDangerDark,
  ),

  scaffoldBackgroundColor: SlateTokens.bgCanvasDark,

  appBarTheme: const AppBarTheme(
    backgroundColor:    SlateTokens.bgSurfaceDark,
    foregroundColor:    SlateTokens.textPrimaryDark,
    elevation:          0,
    scrolledUnderElevation: 0,
    shadowColor:        Colors.transparent,
    titleTextStyle: TextStyle(
      color:       SlateTokens.textPrimaryDark,
      fontSize:    16,
      fontWeight:  FontWeight.w600,
      letterSpacing: 0,
      fontFamily: 'Inter',
    ),
    iconTheme: IconThemeData(color: SlateTokens.accentPrimaryDark, size: 22),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor:     SlateTokens.bgSurfaceDark,
    selectedItemColor:   SlateTokens.accentPrimaryDark,
    unselectedItemColor: SlateTokens.textMutedDark,
    type:                BottomNavigationBarType.fixed,
    elevation:           0,
    selectedLabelStyle:  TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 11),
  ),

  cardTheme: CardThemeData(
    color:     SlateTokens.bgSurfaceDark,
    elevation: 0,
    shape:     RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: SlateTokens.borderSubtleDark),
    ),
  ),

  dividerTheme: const DividerThemeData(
    color:     SlateTokens.borderSubtleDark,
    thickness: 1,
    space:     1,
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled:     true,
    fillColor:  SlateTokens.bgElevatedDark,
    hintStyle:  const TextStyle(color: SlateTokens.textMutedDark, fontSize: 15),
    border:     OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide:   const BorderSide(color: SlateTokens.borderSubtleDark),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide:   const BorderSide(color: SlateTokens.borderSubtleDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide:   const BorderSide(color: SlateTokens.accentPrimaryDark, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SlateTokens.accentPrimaryDark,
      foregroundColor: SlateTokens.textOnAccent,
      elevation:       0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: SlateTokens.accentPrimaryDark,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: SlateTokens.accentPrimaryDark,
    foregroundColor: SlateTokens.textOnAccent,
    elevation:       4,
    shape: CircleBorder(),
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: SlateTokens.accentPrimaryDark,
  ),

  chipTheme: ChipThemeData(
    backgroundColor:   SlateTokens.bgElevatedDark,
    selectedColor:     SlateTokens.accentSubtleDark,
    labelStyle:        const TextStyle(
      color: SlateTokens.textSecondaryDark, fontSize: 13, fontWeight: FontWeight.w500,
    ),
    side:              const BorderSide(color: SlateTokens.borderSubtleDark),
    shape:             RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    padding:           const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: SlateTokens.bgSurfaceDark,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: const TextStyle(
      color: SlateTokens.textPrimaryDark, fontSize: 17, fontWeight: FontWeight.w600,
    ),
    contentTextStyle: const TextStyle(
      color: SlateTokens.textSecondaryDark, fontSize: 14, height: 1.5,
    ),
  ),

  textTheme: const TextTheme(
    displayMedium: TextStyle(
      color: SlateTokens.textPrimaryDark, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.5,
    ),
    headlineSmall: TextStyle(
      color: SlateTokens.textSecondaryDark, fontSize: 20, fontWeight: FontWeight.w400,
    ),
    titleMedium: TextStyle(
      color: SlateTokens.textPrimaryDark, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5,
    ),
    bodyLarge: TextStyle(
      color: SlateTokens.textPrimaryDark, fontSize: 15, fontWeight: FontWeight.w400, height: 1.45,
    ),
    bodyMedium: TextStyle(
      color: SlateTokens.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.w400, height: 1.45,
    ),
    bodySmall: TextStyle(
      color: SlateTokens.textMutedDark, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.02,
    ),
    labelSmall: TextStyle(
      color: SlateTokens.textMutedDark, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.04,
    ),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Theme-aware helpers — call from build() via context
// ─────────────────────────────────────────────────────────────────────────────
extension SlateContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgCanvas   => isDark ? SlateTokens.bgCanvasDark   : SlateTokens.bgCanvasLight;
  Color get bgSurface  => isDark ? SlateTokens.bgSurfaceDark  : SlateTokens.bgSurfaceLight;
  Color get bgElevated => isDark ? SlateTokens.bgElevatedDark : SlateTokens.bgElevatedLight;
  Color get bgGlass    => isDark ? SlateTokens.bgGlassDark    : SlateTokens.bgGlassLight;

  Color get accent        => isDark ? SlateTokens.accentPrimaryDark  : SlateTokens.accentPrimaryLight;
  Color get accentSubtle  => isDark ? SlateTokens.accentSubtleDark   : SlateTokens.accentSubtleLight;

  Color get textPrimary   => isDark ? SlateTokens.textPrimaryDark   : SlateTokens.textPrimaryLight;
  Color get textSecondary => isDark ? SlateTokens.textSecondaryDark : SlateTokens.textSecondaryLight;
  Color get textMuted     => isDark ? SlateTokens.textMutedDark     : SlateTokens.textMutedLight;

  Color get borderSubtle  => isDark ? SlateTokens.borderSubtleDark  : SlateTokens.borderSubtleLight;
  Color get statusOnline  => isDark ? SlateTokens.statusOnlineDark  : SlateTokens.statusOnlineLight;
  Color get statusDanger  => isDark ? SlateTokens.statusDangerDark  : SlateTokens.statusDangerLight;
}
