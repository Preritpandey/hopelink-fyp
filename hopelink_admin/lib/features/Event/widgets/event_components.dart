// ─────────────────────────────────────────────────────────────
//  COMPONENTS  —  event_components.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'event_theme.dart';

// ─────────────────────────────────────────────────────────────
//  EVENT STATUS BADGE
// ─────────────────────────────────────────────────────────────
class EventStatusBadge extends StatelessWidget {
  final String status;
  final Color? customColor;

  const EventStatusBadge({super.key, required this.status, this.customColor});

  @override
  Widget build(BuildContext context) {
    final t = volunteerStatus(status);
    final color = customColor ?? t.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: evR20,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.8), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            t.label,
            style: evMono().copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EVENT BUTTON - Gradient with hover
// ─────────────────────────────────────────────────────────────
class EventBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final bool ghost;
  final Color? accentColor;

  const EventBtn({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.ghost = false,
    this.accentColor,
  });

  @override
  State<EventBtn> createState() => _EventBtnState();
}

class _EventBtnState extends State<EventBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  bool _hov = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? evBlue;

    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTapDown: (_) => _anim.forward(),
        onTapUp: (_) {
          _anim.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _anim.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: widget.ghost
                  ? null
                  : LinearGradient(
                      colors: _hov
                          ? [accent, accent.withOpacity(0.7)]
                          : [accent.withOpacity(0.85), accent.withOpacity(0.6)],
                    ),
              color: widget.ghost ? (_hov ? evSurf3 : evSurf2) : null,
              borderRadius: evR10,
              border: widget.ghost
                  ? Border.all(color: _hov ? evBorder2 : evBorder)
                  : null,
              boxShadow: !widget.ghost && _hov ? evGlowShadow(accent) : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        widget.ghost ? evTextSub : Colors.white,
                      ),
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 14,
                      color: widget.ghost
                          ? (_hov ? evText : evTextSub)
                          : Colors.white,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    widget.label,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.ghost
                          ? (_hov ? evText : evTextSub)
                          : Colors.white,
                    ),
                  ),
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
//  FORM FIELD - Themed input
// ─────────────────────────────────────────────────────────────
class EventFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool readOnly;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const EventFormField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.readOnly = false,
    this.keyboardType,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: evMonoSm().copyWith(letterSpacing: 0.4)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          keyboardType: keyboardType,
          onTap: onTap,
          validator: validator,
          style: evBodySm().copyWith(color: evText),
          decoration: InputDecoration(
            filled: true,
            fillColor: evSurf2,
            hintText: label,
            hintStyle: evBodySm().copyWith(color: evTextMute),
            border: OutlineInputBorder(
              borderRadius: evR10,
              borderSide: const BorderSide(color: evBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: evR10,
              borderSide: const BorderSide(color: evBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: evR10,
              borderSide: BorderSide(color: evBlue.withOpacity(0.6)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: evR10,
              borderSide: BorderSide(color: evRed.withOpacity(0.6)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: evR10,
              borderSide: BorderSide(color: evRed.withOpacity(0.8)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────────────────────
class EventSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool divider;

  const EventSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.divider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (divider) ...[
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, evBorder, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: evBlue),
              const SizedBox(width: 8),
            ],
            Text(title, style: evHeadingMd()),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DETAIL ROW
// ─────────────────────────────────────────────────────────────
class EventDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const EventDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: evSurf3, borderRadius: evR8),
            child: Icon(icon, size: 14, color: evTextSub),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: evMonoSm().copyWith(letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: evBodySm().copyWith(
                    color: valueColor ?? evText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TAG/CHIP
// ─────────────────────────────────────────────────────────────
class EventTag extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;
  final Color? color;
  final bool removable;

  const EventTag({
    super.key,
    required this.label,
    this.onRemove,
    this.color,
    this.removable = false,
  });

  @override
  Widget build(BuildContext context) {
    final tagColor = color ?? evBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        border: Border.all(color: tagColor),
        borderRadius: evR20,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: evBodySm().copyWith(color: tagColor)),
          if (removable && onRemove != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 14, color: tagColor),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DIVIDER
// ─────────────────────────────────────────────────────────────
class EventDivider extends StatelessWidget {
  const EventDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, evBorder, Colors.transparent],
        ),
      ),
    );
  }
}
