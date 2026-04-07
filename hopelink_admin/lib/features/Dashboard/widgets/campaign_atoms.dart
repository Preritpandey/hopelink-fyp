// ─────────────────────────────────────────────────────────────
//  ATOMS  —  campaign_atoms.dart
//  Tiny reusable building blocks: buttons, badges, chips, fields
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'campaign_theme.dart';

// ─────────────────────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────────────────────
class CampaignStatusBadge extends StatelessWidget {
  final String status;
  const CampaignStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final t = campaignStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: t.color.withOpacity(0.1),
        borderRadius: r20,
        border: Border.all(color: t.color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.color,
            boxShadow: [BoxShadow(color: t.color.withOpacity(0.8), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 5),
        Text(t.label,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 10, color: t.color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PROGRESS BAR
// ─────────────────────────────────────────────────────────────
class CampaignProgressBar extends StatelessWidget {
  final double percent;   // 0–100
  final double height;
  final bool showLabel;

  const CampaignProgressBar({
    super.key,
    required this.percent,
    this.height = 6,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct     = percent.clamp(0.0, 100.0);
    final color   = pct >= 75 ? cEmerald : pct >= 40 ? cSky : cViolet;
    final fraction = pct / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: r20,
          child: Stack(children: [
            Container(
              height: height,
              color: cBorder2,
            ),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: r20,
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                  ),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.4), blurRadius: 6),
                  ],
                ),
              ),
            ),
          ]),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text('${pct.toStringAsFixed(1)}% funded',
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: color)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ICON CHIP
// ─────────────────────────────────────────────────────────────
class IconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const IconChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: r6,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.jetBrainsMono(fontSize: 9, color: color)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DAYS-LEFT PILL
// ─────────────────────────────────────────────────────────────
class DaysLeftPill extends StatelessWidget {
  final int days;
  final bool expired;

  const DaysLeftPill({super.key, required this.days, required this.expired});

  @override
  Widget build(BuildContext context) {
    final color = expired
        ? cTextMute
        : days <= 7
            ? cRose
            : days <= 30
                ? cAmber
                : cEmerald;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: r6,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          expired ? Icons.flag_rounded : Icons.timer_rounded,
          size: 10, color: color,
        ),
        const SizedBox(width: 4),
        Text(
          expired ? 'Ended' : days == 0 ? 'Ends today' : '${days}d left',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 9, color: color, fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  GRADIENT BUTTON
// ─────────────────────────────────────────────────────────────
class GradBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final bool ghost;
  final Color? accentColor;

  const GradBtn({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.ghost = false,
    this.accentColor,
  });

  @override
  State<GradBtn> createState() => _GradBtnState();
}

class _GradBtnState extends State<GradBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  bool _hov = false;

  @override
  void initState() {
    super.initState();
    _anim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_anim);
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? cEmerald;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTapDown:   (_) => _anim.forward(),
        onTapUp:     (_) { _anim.reverse(); widget.onTap?.call(); },
        onTapCancel: ()  => _anim.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: widget.ghost ? null : LinearGradient(
                colors: _hov
                    ? [accent, accent.withOpacity(0.7)]
                    : [accent.withOpacity(0.85), accent.withOpacity(0.6)],
              ),
              color: widget.ghost
                  ? (_hov ? cSurf3 : cSurf2)
                  : null,
              borderRadius: r10,
              border: widget.ghost
                  ? Border.all(color: _hov ? cBorder2 : cBorder)
                  : null,
              boxShadow: !widget.ghost && _hov
                  ? glowShadow(accent)
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                          widget.ghost ? cTextSub : Colors.white),
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 14,
                        color: widget.ghost ? (_hov ? cText : cTextSub) : Colors.white),
                    const SizedBox(width: 7),
                  ],
                  Text(widget.label,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.ghost
                            ? (_hov ? cText : cTextSub)
                            : Colors.white,
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ICON BUTTON
// ─────────────────────────────────────────────────────────────
class CIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  const CIconBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  @override
  State<CIconBtn> createState() => _CIconBtnState();
}

class _CIconBtnState extends State<CIconBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final ac = widget.activeColor ?? cEmerald;
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
              color: widget.active
                  ? ac.withOpacity(0.12)
                  : _h ? cSurf3 : cSurf2,
              borderRadius: r8,
              border: Border.all(
                  color: widget.active
                      ? ac.withOpacity(0.3)
                      : _h ? cBorder2 : cBorder),
            ),
            child: Icon(widget.icon,
                size: 16,
                color: widget.active ? ac : _h ? cText : cTextSub),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ALERT INLINE
// ─────────────────────────────────────────────────────────────
class CAlertInline extends StatelessWidget {
  final String message;
  final bool isError;
  const CAlertInline({super.key, required this.message, this.isError = true});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    final c = isError ? cRose : cEmerald;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: r10,
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: c, size: 15),
        const SizedBox(width: 9),
        Expanded(
          child: Text(message,
              style: GoogleFonts.inter(fontSize: 12.5, color: c)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SHIMMER SKELETON
// ─────────────────────────────────────────────────────────────
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? radius;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius});
  @override State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04 + _a.value * 0.05),
          borderRadius: widget.radius ?? r8,
        ),
      ),
    );
  }
}

class SkeletonCampaignCard extends StatelessWidget {
  const SkeletonCampaignCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cSurf,
        borderRadius: r16,
        border: Border.all(color: cBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: double.infinity, height: 140, radius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerBox(width: double.infinity, height: 14),
              const SizedBox(height: 8),
              ShimmerBox(width: 160, height: 10),
              const SizedBox(height: 12),
              ShimmerBox(width: double.infinity, height: 5, radius: r20),
              const SizedBox(height: 10),
              Row(children: [
                ShimmerBox(width: 60, height: 10),
                const Spacer(),
                ShimmerBox(width: 40, height: 10),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}
