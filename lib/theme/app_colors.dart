import 'package:flutter/material.dart';

/// Centralized color definitions for the FixEasy app.
/// Use these colors throughout the app for consistent theming.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  /// Primary brand color (Teal/Cyan)
  static const Color primary = Color(0xFF09D1C7);

  /// Primary color variants
  static const Color primaryLight = Color(0xFF5CE1E6);
  static const Color primaryDark = Color(0xFF00A99D);

  /// Secondary color
  static const Color secondary = Color(0xFF00BFA5);

  /// Accent color for highlights
  static const Color accent = Color(0xFF00ACC1);

  /// Background colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color scaffoldBackground = Color(0xFFFAFAFA);

  /// Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;

  /// Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  /// Booking status colors
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusAccepted = Color(0xFF2196F3);
  static const Color statusInProgress = Color(0xFF9C27B0);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusCancelled = Color(0xFFF44336);

  /// Rating color
  static const Color rating = Color(0xFFFFC107);

  /// Divider and border colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);

  /// Shimmer colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  /// Gradient colors for welcome banner
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00BCD4), Color(0xFF009688)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
