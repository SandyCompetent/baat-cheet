import 'package:flutter/material.dart';

/// Helper to generate initials from display name or email prefix.
/// Rules:
/// - "Sandeep" -> "S"
/// - "Sandeep Malviya" -> "SM"
/// - "sandy.competent@gmail.com" -> "SC"
String getInitials(String displayName, String email) {
  final name = displayName.trim();
  final isDefaultGuest = name == 'Guest User' || name == 'Guest' || name == 'User';

  if (name.isNotEmpty && !isDefaultGuest) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
  }

  // Fallback to email
  final cleanEmail = email.trim();
  if (cleanEmail.isNotEmpty) {
    final emailPrefix = cleanEmail.split('@').first;
    final emailParts = emailPrefix.split(RegExp(r'[._\-]')).where((p) => p.isNotEmpty).toList();
    if (emailParts.length >= 2) {
      return '${emailParts[0][0]}${emailParts[1][0]}'.toUpperCase();
    } else if (emailParts.isNotEmpty) {
      return emailParts[0][0].toUpperCase();
    }
  }

  // Final fallback
  if (name.isNotEmpty) {
    return name[0].toUpperCase();
  }

  return 'C';
}

/// Deterministically generates a vibrant background color for a given seed string.
Color getAvatarColor(String seed) {
  const palette = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF0D9488), // Teal
    Color(0xFF9333EA), // Purple
    Color(0xFF2563EB), // Blue
    Color(0xFFD97706), // Amber
    Color(0xFFE11D48), // Rose
    Color(0xFF059669), // Emerald
    Color(0xFF7C3AED), // Violet
    Color(0xFF0284C7), // Sky
    Color(0xFFEA580C), // Orange
  ];
  if (seed.isEmpty) return palette[0];
  int hash = 0;
  for (int i = 0; i < seed.length; i++) {
    hash = seed.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final index = hash.abs() % palette.length;
  return palette[index];
}
