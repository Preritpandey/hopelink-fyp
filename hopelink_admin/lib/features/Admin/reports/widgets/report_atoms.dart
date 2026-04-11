// ─────────────────────────────────────────────────────────────
//  ATOMS  —  report_atoms.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'report_theme.dart';

// ─────────────────────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────────────────────
class ReportStatusBadge extends StatelessWidget {
  final String status;
  const ReportStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'approved': return rGreen;
      case 'rejected': return rRed;
      default:         return rGold;
    }
  }

  IconData get _icon {
    switch (status.toLowerCase()) {
      case 'approved': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default:         return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: rR20,
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _color.withOpacity(0.7), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          status[0].toUpperCase() + status.substring(1),
          style: GoogleFonts.sourceCodePro(
              fontSize: 10, color: _color, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ACTION BUTTON  (Approve / Reject)
// ─────────────────────────────────────────────────────────────
class ReportActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;
  final bool ghost;

  const ReportActionBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.loading = false,
    this.ghost = false,
  });

  @override
  State<ReportActionBtn> createState() => _ReportActionBtnState();
}

class _ReportActionBtnState extends State<ReportActionBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _scale;
  bool _h = false;

  @override
  void initState() {
    super.initState();
    _ac    = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_ac);
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(
        onTapDown:   (_) => _ac.forward(),
        onTapUp:     (_) { _ac.reverse(); if (!widget.loading) widget.onTap?.call(); },
        onTapCancel: ()  => _ac.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              gradient: widget.ghost ? null : LinearGradient(
                colors: _h && !widget.loading
                    ? [c, c.withOpacity(0.65)]
                    : [c.withOpacity(0.85), c.withOpacity(0.55)],
              ),
              color: widget.ghost ? (_h ? rSurf3 : rSurf2) : null,
              borderRadius: rR10,
              border: widget.ghost
                  ? Border.all(color: _h ? rBorder2 : rBorder)
                  : null,
              boxShadow: !widget.ghost && _h && !widget.loading
                  ? rGlow(c) : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (widget.loading)
                SizedBox(
                  width: 15, height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                        widget.ghost ? rSub : Colors.white),
                  ),
                )
              else ...[
                Icon(widget.icon, size: 14,
                    color: widget.ghost ? (_h ? rText : rSub) : Colors.white),
                const SizedBox(width: 7),
                Text(widget.label,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.ghost ? (_h ? rText : rSub) : Colors.white,
                    )),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ICON BUTTON
// ─────────────────────────────────────────────────────────────
class RIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const RIconBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  State<RIconBtn> createState() => _RIconBtnState();
}

class _RIconBtnState extends State<RIconBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit:  (_) => setState(() => _h = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _h ? (c?.withOpacity(0.1) ?? rSurf3) : rSurf2,
              borderRadius: rR8,
              border: Border.all(
                  color: _h ? (c?.withOpacity(0.4) ?? rBorder2) : rBorder),
            ),
            child: Icon(widget.icon, size: 16,
                color: c ?? (_h ? rText : rSub)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  INFO CHIP
// ─────────────────────────────────────────────────────────────
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: rR8,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.sourceCodePro(fontSize: 10, color: color)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SKELETON CARD
// ─────────────────────────────────────────────────────────────
class SkeletonReportCard extends StatefulWidget {
  const SkeletonReportCard({super.key});
  @override State<SkeletonReportCard> createState() => _SkeletonReportCardState();
}

class _SkeletonReportCardState extends State<SkeletonReportCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Widget _box(double w, double h) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03 + _a.value * 0.05),
        borderRadius: rR8,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rSurf,
        borderRadius: rR14,
        border: Border.all(color: rBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _box(40, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(double.infinity, 13),
              const SizedBox(height: 6),
              _box(140, 10),
            ]),
          ),
          const SizedBox(width: 12),
          _box(60, 22),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _box(80, 10),
          const SizedBox(width: 10),
          _box(60, 10),
          const SizedBox(width: 10),
          _box(70, 10),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────
class ReportEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const ReportEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: rGold.withOpacity(0.07),
            shape: BoxShape.circle,
            border: Border.all(color: rGold.withOpacity(0.2)),
          ),
          child: Icon(icon, color: rGold, size: 30),
        ),
        const SizedBox(height: 18),
        Text(title, style: rH1()),
        const SizedBox(height: 6),
        Text(subtitle, style: rBodySm(), textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 22), action!],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  GRADIENT DIVIDER
// ─────────────────────────────────────────────────────────────
class RDivider extends StatelessWidget {
  const RDivider({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.transparent, rBorder, Colors.transparent],
      ),
    ),
  );
}
