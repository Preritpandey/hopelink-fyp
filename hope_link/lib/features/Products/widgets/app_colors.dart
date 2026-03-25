import 'package:flutter/material.dart';

/// Central color palette for HopeLink / Helping Hands.
/// Warm humanitarian theme — earthy terracotta, sage green, warm cream.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFB85C38); // Terracotta
  static const Color primaryLight = Color(0xFFD4845C); // Light terracotta
  static const Color primaryDark = Color(0xFF8C3D20); // Deep terracotta

  static const Color accent = Color(0xFF5F8B4C); // Sage green
  static const Color accentLight = Color(0xFF87B56E); // Light sage

  // ── Backgrounds ────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFAF6F1); // Warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ── Text ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D2016); // Deep warm brown
  static const Color textSecondary = Color(0xFF6B5344); // Medium brown
  static const Color textMuted = Color(0xFF9B8578); // Muted brown

  // ── UI Elements ────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEDE5DC);
  static const Color shimmer = Color(0xFFEDE5DC);
  static const Color starColor = Color(0xFFE8A838);
  static const Color errorColor = Color(0xFFD94F3D);
  static const Color successColor = Color(0xFF5F8B4C);

  // ── Shadows ────────────────────────────────────────────────────────────
  static const Color shadow = Color(0x14B85C38); // Terracotta tinted shadow

  // ── Gradients ─────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x88000000)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB85C38), Color(0xFF8C3D20)],
  );
}
