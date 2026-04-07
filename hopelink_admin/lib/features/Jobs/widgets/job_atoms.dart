// ─────────────────────────────────────────────────────────────
//  ATOMS  —  job_atoms.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/job_model.dart';
import 'job_theme.dart';

// ─────────────────────────────────────────────────────────────
//  STATUS BADGES
// ─────────────────────────────────────────────────────────────
class JobStatusBadge extends StatelessWidget {
  final JobStatus status;
  const JobStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final t = jobStatusTheme(status);
    return _Pill(label: status.label, color: t.color, icon: t.icon);
  }
}

class AppStatusBadge extends StatelessWidget {
  final ApplicationStatus status;
  const AppStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final t = appStatusTheme(status);
    return _Pill(label: status.label, color: t.color, icon: t.icon);
  }
}

class JobTypeBadge extends StatelessWidget {
  final JobType type;
  const JobTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final t = jobTypeTheme(type);
    return _Pill(label: type.label, color: t.color, icon: t.icon, small: true);
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool small;

  const _Pill({
    required this.label,
    required this.color,
    required this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final fs = small ? 9.0 : 10.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: jR20,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: small ? 9 : 10, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.firaCode(
                fontSize: fs,
                color: color,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRIMARY BUTTON
// ─────────────────────────────────────────────────────────────
class JBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final Color? color;
  final bool ghost;
  final double height;

  const JBtn({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.color,
    this.ghost = false,
    this.height = 42,
  });

  @override
  State<JBtn> createState() => _JBtnState();
}

class _JBtnState extends State<JBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _scale;
  bool _h = false;

  @override
  void initState() {
    super.initState();
    _ac    = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_ac);
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? jGreen;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(
        onTapDown:   (_) => _ac.forward(),
        onTapUp:     (_) { _ac.reverse(); widget.onTap?.call(); },
        onTapCancel: ()  => _ac.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: widget.ghost ? null : LinearGradient(
                colors: _h
                    ? [c, c.withOpacity(0.65)]
                    : [c.withOpacity(0.85), c.withOpacity(0.55)],
              ),
              color: widget.ghost ? (_h ? jSurf3 : jSurf2) : null,
              borderRadius: jR10,
              border: widget.ghost
                  ? Border.all(color: _h ? jBorder2 : jBorder)
                  : null,
              boxShadow: !widget.ghost && _h ? jGlow(c) : [],
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
                          widget.ghost ? jSub : Colors.white),
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 15,
                        color: widget.ghost ? (_h ? jText : jSub) : Colors.white),
                    const SizedBox(width: 7),
                  ],
                  Text(widget.label,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.ghost ? (_h ? jText : jSub) : Colors.white,
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
class JIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  const JIconBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  @override
  State<JIconBtn> createState() => _JIconBtnState();
}

class _JIconBtnState extends State<JIconBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final c = widget.activeColor ?? jGreen;
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
              color: widget.active ? c.withOpacity(0.12) : (_h ? jSurf3 : jSurf2),
              borderRadius: jR8,
              border: Border.all(
                  color: widget.active ? c.withOpacity(0.3) : (_h ? jBorder2 : jBorder)),
            ),
            child: Icon(widget.icon, size: 16,
                color: widget.active ? c : (_h ? jText : jSub)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FORM FIELD
// ─────────────────────────────────────────────────────────────
class JField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;

  const JField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.required = true,
    this.maxLines = 1,
    this.keyboardType,
    this.prefix,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.formatters,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
  });

  @override
  State<JField> createState() => _JFieldState();
}

class _JFieldState extends State<JField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(widget.label,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _focused ? jGreen.withOpacity(0.9) : jSub,
                letterSpacing: 0.2,
              )),
          if (widget.required)
            const Text(' *',
                style: TextStyle(color: jRose, fontSize: 11)),
        ]),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: jR10,
            boxShadow: _focused ? jGlow(jGreen, radius: 14) : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.formatters,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
            style: GoogleFonts.inter(fontSize: 13, color: jText),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.inter(fontSize: 13, color: jMuted),
              prefixIcon: widget.prefix,
              suffixIcon: widget.suffix,
              filled: true,
              fillColor: _focused ? const Color(0xFF0D1828) : jSurf,
              enabledBorder: OutlineInputBorder(
                borderRadius: jR10,
                borderSide: const BorderSide(color: jBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: jR10,
                borderSide: const BorderSide(color: jGreen, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: jR10,
                borderSide: const BorderSide(color: jRose, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: jR10,
                borderSide: const BorderSide(color: jRose, width: 1.5),
              ),
              errorStyle: GoogleFonts.inter(fontSize: 11, color: jRose),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
            validator: widget.validator ??
                (widget.required
                    ? (v) => (v == null || v.trim().isEmpty)
                        ? '${widget.label} is required'
                        : null
                    : null),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SKILL CHIP
// ─────────────────────────────────────────────────────────────
class SkillChip extends StatefulWidget {
  final String label;
  final VoidCallback? onRemove;
  final Color color;

  const SkillChip({
    super.key,
    required this.label,
    this.onRemove,
    this.color = jTeal,
  });

  @override
  State<SkillChip> createState() => _SkillChipState();
}

class _SkillChipState extends State<SkillChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.08),
          borderRadius: jR20,
          border: Border.all(
            color: _h
                ? widget.color.withOpacity(0.5)
                : widget.color.withOpacity(0.22),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.label,
              style: GoogleFonts.firaCode(
                  fontSize: 10,
                  color: widget.color,
                  fontWeight: FontWeight.w500)),
          if (widget.onRemove != null) ...[
            const SizedBox(width: 5),
            GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded,
                    size: 9, color: widget.color),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  INFO ROW  (label + value pair)
// ─────────────────────────────────────────────────────────────
class JInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const JInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: jSurf3, borderRadius: jR7),
          child: Icon(icon, size: 13, color: jSub),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.firaCode(
                  fontSize: 9, color: jMuted, letterSpacing: 0.5)),
          const SizedBox(height: 1),
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: valueColor ?? jText,
                fontWeight: FontWeight.w500,
              )),
        ]),
      ]),
    );
  }
}

const jR7 = BorderRadius.all(Radius.circular(7));

// ─────────────────────────────────────────────────────────────
//  ALERT
// ─────────────────────────────────────────────────────────────
class JAlert extends StatelessWidget {
  final String message;
  final bool isError;
  const JAlert({super.key, required this.message, this.isError = true});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    final c = isError ? jRose : jGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: jR10,
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: c, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: GoogleFonts.inter(fontSize: 12.5, color: c)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DIVIDER
// ─────────────────────────────────────────────────────────────
class JDivider extends StatelessWidget {
  const JDivider({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.transparent, jBorder, Colors.transparent],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  SKELETON
// ─────────────────────────────────────────────────────────────
class JSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? radius;
  const JSkeleton({super.key, required this.width, required this.height, this.radius});
  @override State<JSkeleton> createState() => _JSkeletonState();
}

class _JSkeletonState extends State<JSkeleton>
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
          color: Colors.white.withOpacity(0.03 + _a.value * 0.05),
          borderRadius: widget.radius ?? jR8,
        ),
      ),
    );
  }
}

class SkeletonJobCard extends StatelessWidget {
  const SkeletonJobCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: jSurf, borderRadius: jR14, border: Border.all(color: jBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          JSkeleton(width: 40, height: 40, radius: jR10),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            JSkeleton(width: 180, height: 13),
            const SizedBox(height: 6),
            JSkeleton(width: 100, height: 10),
          ]),
        ]),
        const SizedBox(height: 12),
        JSkeleton(width: double.infinity, height: 10),
        const SizedBox(height: 6),
        JSkeleton(width: 200, height: 10),
      ]),
    );
  }
}
