// ─────────────────────────────────────────────────────────────
//  THEME  —  report_theme.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ───────────────────────────────────────────────────
const rBg      = Color(0xFF06080E);
const rSurf    = Color(0xFF0B1019);
const rSurf2   = Color(0xFF0F1825);
const rSurf3   = Color(0xFF152030);
const rBorder  = Color(0xFF192840);
const rBorder2 = Color(0xFF20344E);

const rGold    = Color(0xFFF59E0B);   // pending
const rGreen   = Color(0xFF10B981);   // approved / success
const rRed     = Color(0xFFEF4444);   // rejected / danger
const rBlue    = Color(0xFF3B82F6);   // info / links
const rIndigo  = Color(0xFF6366F1);   // accents
const rSlate   = Color(0xFF64748B);   // muted elements

const rText    = Color(0xFFF0F6FF);
const rSub     = Color(0xFF6A8AAE);
const rMuted   = Color(0xFF334A68);

// ── Typography ────────────────────────────────────────────────
TextStyle rDisplay() => GoogleFonts.bricolageGrotesque(
    fontSize: 24, fontWeight: FontWeight.w800,
    color: rText, letterSpacing: -0.6);

TextStyle rH1() => GoogleFonts.bricolageGrotesque(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: rText, letterSpacing: -0.3);

TextStyle rH2() => GoogleFonts.bricolageGrotesque(
    fontSize: 14, fontWeight: FontWeight.w700, color: rText);

TextStyle rH3() => GoogleFonts.bricolageGrotesque(
    fontSize: 12, fontWeight: FontWeight.w600, color: rText);

TextStyle rBody() => GoogleFonts.nunitoSans(fontSize: 13, color: rText, height: 1.5);

TextStyle rBodySm() => GoogleFonts.nunitoSans(fontSize: 12, color: rSub, height: 1.5);

TextStyle rMono() => GoogleFonts.sourceCodePro(
    fontSize: 11, color: rSub, letterSpacing: 0.2);

TextStyle rMonoSm() => GoogleFonts.sourceCodePro(
    fontSize: 10, color: rMuted, letterSpacing: 0.2);

// ── Radii ─────────────────────────────────────────────────────
const rR6  = BorderRadius.all(Radius.circular(6));
const rR8  = BorderRadius.all(Radius.circular(8));
const rR10 = BorderRadius.all(Radius.circular(10));
const rR12 = BorderRadius.all(Radius.circular(12));
const rR14 = BorderRadius.all(Radius.circular(14));
const rR16 = BorderRadius.all(Radius.circular(16));
const rR20 = BorderRadius.all(Radius.circular(20));

// ── Shadows ───────────────────────────────────────────────────
List<BoxShadow> rGlow(Color c) => [
  BoxShadow(color: c.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 5)),
];

List<BoxShadow> rSubtle() => [
  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3)),
];
