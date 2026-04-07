// ─────────────────────────────────────────────────────────────
//  TOKENS  —  campaign_theme.dart
//  Single source of truth for colours, text styles, radii
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ───────────────────────────────────────────────────
const cBg      = Color(0xFF07090E);   // near-black bg
const cSurf    = Color(0xFF0D1117);   // card surface
const cSurf2   = Color(0xFF111820);   // hover / elevated
const cSurf3   = Color(0xFF162030);   // deepest surface
const cBorder  = Color(0xFF1A2840);
const cBorder2 = Color(0xFF213352);

// Accents
const cEmerald  = Color(0xFF10B981);  // progress / success
const cSky      = Color(0xFF38BDF8);  // links / info
const cViolet   = Color(0xFF8B5CF6);  // featured / special
const cAmber    = Color(0xFFF59E0B);  // warnings / days-left
const cRose     = Color(0xFFF43F5E);  // danger / cancelled
const cOrange   = Color(0xFFF97316);  // paused

// Text
const cText     = Color(0xFFF0F4FF);
const cTextSub  = Color(0xFF6B8AAE);
const cTextMute = Color(0xFF334D6E);

// ── Typography ────────────────────────────────────────────────
TextStyle headingXl() => GoogleFonts.manrope(
    fontSize: 22, fontWeight: FontWeight.w800,
    color: cText, letterSpacing: -0.6);

TextStyle headingLg() => GoogleFonts.manrope(
    fontSize: 17, fontWeight: FontWeight.w700,
    color: cText, letterSpacing: -0.3);

TextStyle headingMd() => GoogleFonts.manrope(
    fontSize: 14, fontWeight: FontWeight.w700, color: cText);

TextStyle bodyMd() =>
    GoogleFonts.inter(fontSize: 13, color: cText, height: 1.5);

TextStyle bodySm() =>
    GoogleFonts.inter(fontSize: 12, color: cTextSub, height: 1.5);

TextStyle bodyXs() =>
    GoogleFonts.inter(fontSize: 11, color: cTextMute);

TextStyle mono() => GoogleFonts.jetBrainsMono(
    fontSize: 11, color: cTextSub, letterSpacing: 0.2);

TextStyle monoSm() => GoogleFonts.jetBrainsMono(
    fontSize: 10, color: cTextMute);

// ── Radii ─────────────────────────────────────────────────────
const r4  = BorderRadius.all(Radius.circular(4));
const r6  = BorderRadius.all(Radius.circular(6));
const r8  = BorderRadius.all(Radius.circular(8));
const r10 = BorderRadius.all(Radius.circular(10));
const r12 = BorderRadius.all(Radius.circular(12));
const r14 = BorderRadius.all(Radius.circular(14));
const r16 = BorderRadius.all(Radius.circular(16));
const r20 = BorderRadius.all(Radius.circular(20));

// ── Status config ─────────────────────────────────────────────
class StatusTheme {
  final Color color;
  final IconData icon;
  final String label;
  const StatusTheme(this.color, this.icon, this.label);
}

StatusTheme campaignStatus(String status) {
  switch (status.toLowerCase()) {
    case 'active':    return const StatusTheme(cEmerald, Icons.bolt_rounded,          'Active');
    case 'completed': return const StatusTheme(cSky,     Icons.check_circle_rounded,  'Completed');
    case 'paused':    return const StatusTheme(cOrange,  Icons.pause_circle_rounded,  'Paused');
    case 'cancelled': return const StatusTheme(cRose,    Icons.cancel_rounded,        'Cancelled');
    default:          return const StatusTheme(cTextMute, Icons.circle_outlined,      'Unknown');
  }
}

// ── Shadows ───────────────────────────────────────────────────
List<BoxShadow> glowShadow(Color color, {double spread = 0}) => [
      BoxShadow(
        color: color.withOpacity(0.18),
        blurRadius: 20,
        spreadRadius: spread,
        offset: const Offset(0, 6),
      ),
    ];

List<BoxShadow> subtleShadow() => [
      BoxShadow(
        color: Colors.black.withOpacity(0.25),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
