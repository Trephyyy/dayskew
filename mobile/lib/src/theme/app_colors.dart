import 'package:flutter/material.dart';

/// DaySkew neo-brutal palette, per the AGENTS.md design system.
abstract final class AppColors {
  static const Color canvas = Color(0xFF0F1117);
  static const Color canvasLight = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFF171A23);
  static const Color border = Color(0xFF2E3444);

  static const Color lockedBase = Color(0xFF000000);
  static const Color lockedBorder = Color(0xFFFFFFFF);

  static const Color high = Color(0xFFEC3750); // Hack Club crimson
  static const Color medium = Color(0xFFFF8C37); // electric amber
  static const Color low = Color(0xFF33D6A6); // cyber mint
  static const Color conflict = Color(0xFFF5A623); // arcade gold

  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textMuted = Color(0xFF9AA3B5);

  static const Color shadow = Color(0xFF000000);

  /// Returns the tier color for a task priority (1 = high, 2 = medium, 3 = low).
  static Color forPriority(int priority) {
    switch (priority) {
      case 1:
        return high;
      case 2:
        return medium;
      default:
        return low;
    }
  }

  static const String priorityLabel1 = 'HIGH';
  static const String priorityLabel2 = 'MED';
  static const String priorityLabel3 = 'LOW';

  static String priorityLabel(int priority) {
    switch (priority) {
      case 1:
        return priorityLabel1;
      case 2:
        return priorityLabel2;
      default:
        return priorityLabel3;
    }
  }
}