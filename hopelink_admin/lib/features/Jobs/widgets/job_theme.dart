import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/job_model.dart';

// ── Palette ───────────────────────────────────────────────────
const jBg = Color(0xFF05080F);
const jSurf = Color(0xFF0A1120);
const jSurf2 = Color(0xFF0F1A2E);
const jSurf3 = Color(0xFF152238);
const jBorder = Color(0xFF182A42);
const jBorder2 = Color(0xFF1F3450);

const jGreen = Color(0xFF34D399);
const jBlue = Color(0xFF60A5FA);
const jIndigo = Color(0xFF818CF8);
const jAmber = Color(0xFFFBBF24);
const jRose = Color(0xFFF87171);
const jTeal = Color(0xFF2DD4BF);
const jOrange = Color(0xFFFB923C);

const jText = Color(0xFFF1F5FF);
const jSub = Color(0xFF6B8AAE);
const jMuted = Color(0xFF334E6E);

// ── Typography ────────────────────────────────────────────────
TextStyle jH1() => GoogleFonts.outfit(
  fontSize: 22,
  fontWeight: FontWeight.w800,
  color: jText,
  letterSpacing: -0.5,
);

TextStyle jH2() => GoogleFonts.outfit(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: jText,
  letterSpacing: -0.2,
);

TextStyle jH3() =>
    GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: jText);

TextStyle jBody() => GoogleFonts.inter(fontSize: 13, color: jText, height: 1.5);

TextStyle jBodySm() =>
    GoogleFonts.inter(fontSize: 12, color: jSub, height: 1.5);

TextStyle jMono() =>
    GoogleFonts.firaCode(fontSize: 11, color: jSub, letterSpacing: 0.2);

TextStyle jMonoSm() =>
    GoogleFonts.firaCode(fontSize: 10, color: jMuted, letterSpacing: 0.2);

// ── Radii ─────────────────────────────────────────────────────
const jR4 = BorderRadius.all(Radius.circular(4));
const jR6 = BorderRadius.all(Radius.circular(6));
const jR8 = BorderRadius.all(Radius.circular(8));
const jR10 = BorderRadius.all(Radius.circular(10));
const jR12 = BorderRadius.all(Radius.circular(12));
const jR14 = BorderRadius.all(Radius.circular(14));
const jR16 = BorderRadius.all(Radius.circular(16));
const jR20 = BorderRadius.all(Radius.circular(20));

// ── Status configs ────────────────────────────────────────────
class _JobStatusTheme {
  final Color color;
  final IconData icon;
  const _JobStatusTheme(this.color, this.icon);
}

_JobStatusTheme jobStatusTheme(JobStatus s) {
  switch (s) {
    case JobStatus.open:
      return const _JobStatusTheme(jGreen, Icons.check_circle_rounded);
    case JobStatus.closed:
      return const _JobStatusTheme(jMuted, Icons.lock_rounded);
    case JobStatus.paused:
      return const _JobStatusTheme(jAmber, Icons.pause_circle_rounded);
  }
}

_JobStatusTheme appStatusTheme(ApplicationStatus s) {
  switch (s) {
    case ApplicationStatus.pending:
      return const _JobStatusTheme(jAmber, Icons.schedule_rounded);
    case ApplicationStatus.approved:
      return const _JobStatusTheme(jGreen, Icons.check_circle_rounded);
    case ApplicationStatus.rejected:
      return const _JobStatusTheme(jRose, Icons.cancel_rounded);
  }
}

_JobStatusTheme jobTypeTheme(JobType t) {
  switch (t) {
    case JobType.remote:
      return const _JobStatusTheme(jBlue, Icons.wifi_rounded);
    case JobType.onsite:
      return const _JobStatusTheme(jTeal, Icons.location_on_rounded);
    case JobType.hybrid:
      return const _JobStatusTheme(jIndigo, Icons.merge_type_rounded);
  }
}

// ── Shadows ───────────────────────────────────────────────────
List<BoxShadow> jGlow(Color c, {double radius = 16}) => [
  BoxShadow(
    color: c.withOpacity(0.15),
    blurRadius: radius,
    offset: const Offset(0, 5),
  ),
];

List<BoxShadow> jSubtle() => [
  BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 10,
    offset: const Offset(0, 3),
  ),
];
