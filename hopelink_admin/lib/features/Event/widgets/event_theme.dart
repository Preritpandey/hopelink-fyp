// ─────────────────────────────────────────────────────────────
//  THEME  —  event_theme.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ──────────────────────────────────────────────────
const evBg = Color(0xFF07090E); // near-black bg
const evSurf = Color(0xFF0D1117); // card surface
const evSurf2 = Color(0xFF111820); // hover / elevated
const evSurf3 = Color(0xFF162030); // deepest surface
const evBorder = Color(0xFF1A2840);
const evBorder2 = Color(0xFF213352);

// Accents
const evBlue = Color(0xFF3B82F6); // primary / links
const evGreen = Color(0xFF10B981); // success / approved
const evAmber = Color(0xFFF59E0B); // warning / pending
const evRed = Color(0xFFF43F5E); // danger / rejected
const evPurple = Color(0xFF8B5CF6); // secondary / attended
const evSky = Color(0xFF38BDF8); // info

// Text
const evText = Color(0xFFF0F4FF);
const evTextSub = Color(0xFF6B8AAE);
const evTextMute = Color(0xFF334D6E);

// ── Typography ────────────────────────────────────────────────
TextStyle evHeadingXl() => GoogleFonts.manrope(
  fontSize: 22,
  fontWeight: FontWeight.w800,
  color: evText,
  letterSpacing: -0.6,
);

TextStyle evHeadingLg() => GoogleFonts.manrope(
  fontSize: 17,
  fontWeight: FontWeight.w700,
  color: evText,
  letterSpacing: -0.3,
);

TextStyle evHeadingMd() => GoogleFonts.manrope(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  color: evText,
);

TextStyle evHeadingSm() => GoogleFonts.manrope(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: evText,
);

TextStyle evBodyMd() =>
    GoogleFonts.inter(fontSize: 13, color: evText, height: 1.5);

TextStyle evBodySm() =>
    GoogleFonts.inter(fontSize: 12, color: evTextSub, height: 1.5);

TextStyle evBodyXs() => GoogleFonts.inter(fontSize: 11, color: evTextMute);

TextStyle evMono() => GoogleFonts.jetBrainsMono(
  fontSize: 11,
  color: evTextSub,
  letterSpacing: 0.2,
);

TextStyle evMonoSm() =>
    GoogleFonts.jetBrainsMono(fontSize: 10, color: evTextMute);

// ── Radii ─────────────────────────────────────────────────────
const evR4 = BorderRadius.all(Radius.circular(4));
const evR6 = BorderRadius.all(Radius.circular(6));
const evR8 = BorderRadius.all(Radius.circular(8));
const evR10 = BorderRadius.all(Radius.circular(10));
const evR12 = BorderRadius.all(Radius.circular(12));
const evR14 = BorderRadius.all(Radius.circular(14));
const evR16 = BorderRadius.all(Radius.circular(16));
const evR20 = BorderRadius.all(Radius.circular(20));

// ── Shadows ───────────────────────────────────────────────────
List<BoxShadow> evGlowShadow(Color color, {double spread = 0}) => [
  BoxShadow(
    color: color.withOpacity(0.18),
    blurRadius: 20,
    spreadRadius: spread,
    offset: const Offset(0, 6),
  ),
];

List<BoxShadow> evSubtleShadow() => [
  BoxShadow(
    color: Colors.black.withOpacity(0.25),
    blurRadius: 12,
    offset: const Offset(0, 4),
  ),
];

// ── Status Colors ─────────────────────────────────────────────
class VolunteerStatusTheme {
  final Color color;
  final String label;
  const VolunteerStatusTheme(this.color, this.label);
}

VolunteerStatusTheme volunteerStatus(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return const VolunteerStatusTheme(evAmber, 'Pending');
    case 'approved':
      return const VolunteerStatusTheme(evGreen, 'Approved');
    case 'rejected':
      return const VolunteerStatusTheme(evRed, 'Rejected');
    case 'attended':
      return const VolunteerStatusTheme(evPurple, 'Attended');
    default:
      return VolunteerStatusTheme(evTextMute, status);
  }
}
