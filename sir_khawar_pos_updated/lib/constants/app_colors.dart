// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ── Top Header Bar & Navigation ──────────────────────────────
  static const Color headerBg          = Color(0xFF0F1E33); // Darkest Navy
  static const Color sidebarBg         = Color(0xFF1B324B); // Dark Slate Blue
  static const Color sidebarActive     = Color(0xFF3B6A8E); // Selected item background
  static const Color sidebarInactive   = Color(0xFFA0B2C6); // Muted text/icons in sidebar

  // ── App Surfaces & Canvas ───────────────────────────────────
  static const Color background        = Color(0xFFF4F7FB); // Very soft light gray-blue
  static const Color cardBg            = Color(0xFFFFFFFF); // Pure White cards
  static const Color border            = Color(0xFFE2E8F0); // Subtle divider/border color

  // ── Typography Colors ────────────────────────────────────────
  static const Color textPrimary       = Color(0xFF0F1E2E); // Dark charcoal titles & numbers
  static const Color textSecondary     = Color(0xFF8A9BA8); // Muted subtext & table headers

  // ── Financial / Status Accents ───────────────────────────────
  static const Color cashGreen         = Color(0xFF2E7D32); // Positive / Cash green
  static const Color bankBlue          = Color(0xFF3B6A8E); // Bank accent blue
  static const Color expenseRed        = Color(0xFFC62828); // Expense / Negative red
  static const Color pendingOrange     = Color(0xFFD97706); // Warning / Pending orange

  // ── Banner / Alert Colors ────────────────────────────────────
  static const Color bannerBg          = Color(0xFFFFF9E6); // Light yellow banner fill
  static const Color bannerBorder      = Color(0xFFFFE599); // Light yellow border
  static const Color bannerText        = Color(0xFF7A5C00); // Dark gold banner text
}