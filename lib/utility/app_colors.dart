// lib/utility/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF2196F3); // Colors.blue.shade600
  static const Color accentBlue = Color(0xFF1976D2); // Colors.blue.shade800
  static const Color lightBlue = Color(0xFFE3F2FD); // Colors.blue.shade50
  static const Color textMutedColor = Color(0xFF757575); // Colors.grey.shade600
  static const Color salesAccentColor = Color(
    0xFF4CAF50,
  ); // Colors.green.shade600
  static const Color buttonPrimaryColor = Color(
    0xFF1565C0,
  ); // Colors.blue.shade700
  static const Color orangeAccent = Color(
    0xFFFF9800,
  ); // For general orange accents
  static const Color redAccent = Color(0xFFFF5252); // For delete/error accents
  static const Color white = Colors.white;
  static const Color black87 = Colors.black87;
  static Color grey300 = Colors.grey.shade300;
  static Color grey500 = Colors.grey.shade500;
  static Color orange100 = Colors.orange.shade100;
  static Color orange600 = Colors.orange.shade600;

  static const Color backgroundColor = Color(
    0xFFE3F2FD,
  ); // Very light Blue (your _backgroundColor)
  static const Color cardColor = Colors.white; // Pure white for cards
  static const Color textColorPrimary = Color(
    0xFF212121,
  ); // Almost black for main text
  static const Color textColorSecondary = Color(
    0xFF757575,
  ); // Medium grey for secondary text
  static const Color successColor = Color(
    0xFF4CAF50,
  ); // Green for "Approved" status
  static const Color pendingColor = Color(
    0xFFFFC107,
  ); // Amber for "Pending" status
  static const Color errorColor = Color(
    0xFFEF5350,
  ); // Red for errors/urgent status
  static const Color actionButtonColor = Color(
    0xFF1565C0,
  ); // Darker Blue for main action button
  static const Color infoChipColorFrom = Color(
    0xFF42A5F5,
  ); // Medium blue for 'from' chip
  static const Color infoChipColorTo = Color(0xFF4CAF50); // Green for 'to' chip
  static Color transparent = Colors.transparent; // Added transparent

  static const Color secondaryBlue = Color(
    0xFF557BBB,
  ); // Background color in filter section
  static const Color filterButtonActive = Color(
    0xFF2196F3,
  ); // MyStyle().odien2 equivalent

  // General UI colors

  static Color grey100 = Colors.grey.shade100;
  static Color blueGrey = Colors.blueGrey;
}
