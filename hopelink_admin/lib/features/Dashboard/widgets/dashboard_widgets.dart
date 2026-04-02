import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/campaign_controller.dart';
import '../models/campaign_model.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
const kBg = Color(0xFF070C18);
const kSurface = Color(0xFF0D1628);

const kSurface2 = Color(0xFF111F38);

const kBorder = Color(0xFF182840);
const kBorder2 = Color(0xFF1E3050);
const kAccent = Color(0xFF00C896);
const kAccent2 = Color(0xFF0099FF);
const kPurple = Color(0xFFB47FFF);
const kAmber = Color(0xFFFFB347);
const kRed = Color(0xFFFF4C6A);
const kText = Colors.white;
const kTextSub = Color(0xFF6B8AB8);
const kTextMuted = Color(0xFF374F72);

// ─────────────────────────────────────────────────────────────
//  STAT CARD
// ─────────────────────────────────────────────────────────────
class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final Color accent;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    required this.icon,
    required this.accent,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _hovered ? kSurface2 : kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? widget.accent.withOpacity(0.3) : kBorder,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.accent.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 20),
                ),
                const Spacer(),
                if (widget.sub != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: kAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.sub!,
                      style: GoogleFonts.dmMono(fontSize: 10, color: kAccent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: kText,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: GoogleFonts.dmSans(fontSize: 12, color: kTextSub),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CAMPAIGN CARD
// ─────────────────────────────────────────────────────────────
class CampaignCard extends StatefulWidget {
  final Campaign campaign;
  final CampaignController ctrl;
  final VoidCallback onTap;

  const CampaignCard({
    super.key,
    required this.campaign,
    required this.ctrl,
    required this.onTap,
  });

  @override
  State<CampaignCard> createState() => _CampaignCardState();
}

class _CampaignCardState extends State<CampaignCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    final pct = c.progressPercent;
    final statusColor = c.isActive ? kAccent : kAmber;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _hovered ? kSurface2 : kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? kAccent.withOpacity(0.25) : kBorder,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: kAccent.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(c.status, statusColor),
                  ],
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  c.description,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: kTextSub,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.ctrl.formatCurrency(c.currentAmount),
                          style: GoogleFonts.dmMono(
                            fontSize: 12,
                            color: kAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: GoogleFonts.dmMono(
                            fontSize: 11,
                            color: kTextSub,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: kBorder2,
                        valueColor: AlwaysStoppedAnimation(
                          pct >= 100 ? kAccent : kAccent2,
                        ),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of ${widget.ctrl.formatCurrency(c.targetAmount)} goal',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: kTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Footer
                Row(
                  children: [
                    _IconChip(
                      icon: Icons.update_rounded,
                      label: '${c.updates.length} updates',
                      color: kAccent2,
                    ),
                    const SizedBox(width: 8),
                    _IconChip(
                      icon: Icons.help_outline_rounded,
                      label: '${c.faqs.length} FAQs',
                      color: kPurple,
                    ),
                    const Spacer(),
                    Text(
                      widget.ctrl.formatDate(c.endDate),
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        color: kTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusPill(this.status, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.7), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: GoogleFonts.dmMono(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _IconChip({
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WIZARD STEP HEADER
// ─────────────────────────────────────────────────────────────
class WizardStepHeader extends StatelessWidget {
  final int current;
  final List<String> steps;

  const WizardStepHeader({
    super.key,
    required this.current,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i < current;
        final active = i == current;
        final color = done || active ? kAccent : kTextMuted;

        return Expanded(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: done
                          ? kAccent
                          : active
                          ? kAccent.withOpacity(0.15)
                          : kSurface2,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done || active ? kAccent : kBorder2,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 15,
                            )
                          : Text(
                              '${i + 1}',
                              style: GoogleFonts.dmMono(
                                fontSize: 12,
                                color: active ? kAccent : kTextMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: color,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 1.5,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: done
                            ? const LinearGradient(colors: [kAccent, kAccent2])
                            : null,
                        color: done ? null : kBorder2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FORM FIELD BUILDER
// ─────────────────────────────────────────────────────────────
Widget dashField(
  TextEditingController ctrl, {
  required String label,
  String? hint,
  bool required = true,
  int maxLines = 1,
  TextInputType? keyboardType,
  Widget? suffix,
  bool readOnly = false,
  VoidCallback? onTap,
  String? Function(String?)? validator,
  List<TextInputFormatter>? inputFormatters,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextSub,
              letterSpacing: 0.3,
            ),
          ),
          if (required)
            const Text(' *', style: TextStyle(color: kRed, fontSize: 12)),
        ],
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        inputFormatters: inputFormatters,
        style: GoogleFonts.dmSans(fontSize: 13, color: kText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted),
          suffixIcon: suffix,
          filled: true,
          fillColor: kSurface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorder2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kRed, width: 1.5),
          ),
          errorStyle: GoogleFonts.dmSans(fontSize: 11, color: kRed),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
        validator:
            validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                      ? '$label is required'
                      : null
                : null),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
//  PRIMARY BUTTON
// ─────────────────────────────────────────────────────────────
class PrimaryBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final Color? color;

  const PrimaryBtn({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.color,
  });

  @override
  State<PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<PrimaryBtn> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? kAccent;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _h && !widget.loading
                  ? [c, kAccent2]
                  : [c.withOpacity(0.9), c],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _h
                ? [
                    BoxShadow(
                      color: c.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: Colors.black),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  GHOST BUTTON
// ─────────────────────────────────────────────────────────────
class GhostBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const GhostBtn({super.key, required this.label, this.onTap, this.icon});

  @override
  State<GhostBtn> createState() => _GhostBtnState();
}

class _GhostBtnState extends State<GhostBtn> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: _h ? kSurface2 : kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _h ? kAccent.withOpacity(0.3) : kBorder2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 15, color: _h ? kAccent : kTextSub),
                const SizedBox(width: 7),
              ],
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: _h ? Colors.white : kTextSub,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? sub;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.sub, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kText,
                letterSpacing: -0.5,
              ),
            ),
            if (sub != null)
              Text(
                sub!,
                style: GoogleFonts.dmSans(fontSize: 12, color: kTextSub),
              ),
          ],
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TOAST  (snackbar-style notification)
// ─────────────────────────────────────────────────────────────
void showToast(String message, {bool error = false}) {
  final color = error ? kRed : kAccent;
  ScaffoldMessenger.of(Get.context!).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.black,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  NAV ITEM
// ─────────────────────────────────────────────────────────────
class NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.active
                ? kAccent.withOpacity(0.1)
                : _h
                ? kSurface2
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.active
                  ? kAccent.withOpacity(0.25)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.active
                    ? kAccent
                    : _h
                    ? Colors.white
                    : kTextMuted,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
                  color: widget.active
                      ? kText
                      : _h
                      ? Colors.white
                      : kTextSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
