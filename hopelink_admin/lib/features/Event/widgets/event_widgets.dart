import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
const kEvBg = Color(0xFF07091A);
const kEvSurface = Color(0xFF0C1128);
const kEvSurf2 = Color(0xFF111830);
const kEvSurf3 = Color(0xFF162040);
const kEvBorder = Color(0xFF1B2A4A);
const kEvBorder2 = Color(0xFF243558);
const kEvAccent = Color(0xFF7C5CFC); // violet
const kEvAccent2 = Color(0xFF00D9B8); // teal
const kEvGold = Color(0xFFFFB347);
const kEvRed = Color(0xFFFF4757);
const kEvText = Colors.white;
const kEvSub = Color(0xFF7B91B8);
const kEvMuted = Color(0xFF3A4E6E);

// ─────────────────────────────────────────────────────────────
//  WIZARD PROGRESS BAR
// ─────────────────────────────────────────────────────────────
class EventWizardProgress extends StatelessWidget {
  final int current;
  final int total;
  final List<String> labels;
  final List<IconData> icons;

  const EventWizardProgress({
    super.key,
    required this.current,
    required this.total,
    required this.labels,
    required this.icons,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final done = i < current;
        final active = i == current;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: done || active
                            ? LinearGradient(
                                colors: done
                                    ? [kEvAccent2, const Color(0xFF00B896)]
                                    : [kEvAccent, const Color(0xFFAA88FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: done || active ? null : kEvSurf2,
                        border: Border.all(
                          color: done
                              ? kEvAccent2
                              : active
                              ? kEvAccent
                              : kEvBorder2,
                          width: 1.5,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: kEvAccent.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : done
                            ? [
                                BoxShadow(
                                  color: kEvAccent2.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: done
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : Icon(
                                icons[i],
                                color: active ? Colors.white : kEvMuted,
                                size: 16,
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: GoogleFonts.sora(
                        fontSize: 10,
                        color: done
                            ? kEvAccent2
                            : active
                            ? Colors.white
                            : kEvMuted,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Connector
              if (i < total - 1)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: done
                            ? const LinearGradient(
                                colors: [kEvAccent2, kEvAccent],
                              )
                            : null,
                        color: done ? null : kEvBorder2,
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
//  EVENT FORM FIELD
// ─────────────────────────────────────────────────────────────
class EvField extends StatefulWidget {
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
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;

  const EvField({
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
    this.validator,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  State<EvField> createState() => _EvFieldState();
}

class _EvFieldState extends State<EvField> {
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
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: GoogleFonts.sora(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _focused ? kEvAccent.withOpacity(0.9) : kEvSub,
                letterSpacing: 0.2,
              ),
            ),
            if (widget.required)
              const Text(' *', style: TextStyle(color: kEvRed, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: kEvAccent.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            onChanged: widget.onChanged,
            style: GoogleFonts.sora(
              fontSize: 13,
              color: kEvText,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.sora(fontSize: 13, color: kEvMuted),
              prefixIcon: widget.prefix,
              suffixIcon: widget.suffix,
              filled: true,
              fillColor: _focused ? const Color(0xFF0F1830) : kEvSurface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kEvBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kEvAccent, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kEvRed, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kEvRed, width: 1.5),
              ),
              errorStyle: GoogleFonts.sora(fontSize: 11, color: kEvRed),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            validator:
                widget.validator ??
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
//  OPTION CHIP SELECTOR  (Category / Event Type)
// ─────────────────────────────────────────────────────────────
class EvChipSelector<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final void Function(T) onSelect;

  const EvChipSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: kEvSub,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = opt == selected;
            return _ChipOption(
              label: labelOf(opt),
              selected: isSelected,
              onTap: () => onSelect(opt),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ChipOption extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  State<_ChipOption> createState() => _ChipOptionState();
}

class _ChipOptionState extends State<_ChipOption> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? const LinearGradient(
                    colors: [kEvAccent, Color(0xFFAA88FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.selected
                ? null
                : _h
                ? kEvSurf3
                : kEvSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.selected
                  ? kEvAccent
                  : _h
                  ? kEvAccent.withOpacity(0.3)
                  : kEvBorder,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: kEvAccent.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.sora(
              fontSize: 12,
              color: widget.selected
                  ? Colors.white
                  : _h
                  ? Colors.white
                  : kEvSub,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SKILL CHIP ROW
// ─────────────────────────────────────────────────────────────
class SkillChip extends StatefulWidget {
  final String label;
  final VoidCallback onRemove;
  const SkillChip({super.key, required this.label, required this.onRemove});
  @override
  State<SkillChip> createState() => _SkillChipState();
}

class _SkillChipState extends State<SkillChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: kEvAccent2.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _h
                ? kEvAccent2.withOpacity(0.6)
                : kEvAccent2.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.sora(
                fontSize: 11,
                color: kEvAccent2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: kEvAccent2.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 9,
                  color: kEvAccent2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SUGGESTION CHIP  (tappable suggestion)
// ─────────────────────────────────────────────────────────────
class SuggestionChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const SuggestionChip({super.key, required this.label, required this.onTap});
  @override
  State<SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<SuggestionChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _h ? kEvSurf3 : kEvSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _h ? kEvBorder2 : kEvBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 11,
                color: _h ? kEvAccent : kEvMuted,
              ),
              const SizedBox(width: 3),
              Text(
                widget.label,
                style: GoogleFonts.sora(
                  fontSize: 11,
                  color: _h ? Colors.white : kEvSub,
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
//  PRIMARY BUTTON
// ─────────────────────────────────────────────────────────────
class EvPrimaryBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final bool secondary;

  const EvPrimaryBtn({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.secondary = false,
  });

  @override
  State<EvPrimaryBtn> createState() => _EvPrimaryBtnState();
}

class _EvPrimaryBtnState extends State<EvPrimaryBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  bool _h = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTapDown: (_) => _anim.forward(),
        onTapUp: (_) {
          _anim.reverse();
          if (!widget.loading) widget.onTap?.call();
        },
        onTapCancel: () => _anim.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: widget.secondary
                  ? null
                  : LinearGradient(
                      colors: _h && !widget.loading
                          ? [const Color(0xFF9C7DFF), kEvAccent2]
                          : [kEvAccent, const Color(0xFF9C7DFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: widget.secondary ? (_h ? kEvSurf3 : kEvSurf2) : null,
              borderRadius: BorderRadius.circular(12),
              border: widget.secondary
                  ? Border.all(
                      color: _h ? kEvAccent.withOpacity(0.4) : kEvBorder2,
                    )
                  : null,
              boxShadow: !widget.secondary && _h && !widget.loading
                  ? [
                      BoxShadow(
                        color: kEvAccent.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : !widget.secondary
                  ? [
                      BoxShadow(
                        color: kEvAccent.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        widget.secondary ? kEvAccent : Colors.white,
                      ),
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 16,
                      color: widget.secondary ? kEvSub : Colors.white,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.secondary
                          ? (_h ? Colors.white : kEvSub)
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
//  ALERT BAR  (error / success)
// ─────────────────────────────────────────────────────────────
class EvAlertBar extends StatelessWidget {
  final String message;
  final bool isError;
  const EvAlertBar({super.key, required this.message, this.isError = true});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    final color = isError ? kEvRed : kEvAccent2;
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(message),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.sora(fontSize: 12.5, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────────
class EvSectionLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  const EvSectionLabel({super.key, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kEvAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 14, color: kEvAccent),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            text,
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kEvText,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  INFO CARD  (success screen detail row)
// ─────────────────────────────────────────────────────────────
class EvInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const EvInfoRow({
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: kEvSurf3,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: kEvSub),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    color: kEvMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: valueColor ?? kEvText,
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
//  IMAGE PREVIEW GRID ITEM
// ─────────────────────────────────────────────────────────────
class ImagePreviewTile extends StatefulWidget {
  final String name;
  final VoidCallback onRemove;
  const ImagePreviewTile({
    super.key,
    required this.name,
    required this.onRemove,
  });
  @override
  State<ImagePreviewTile> createState() => _ImagePreviewTileState();
}

class _ImagePreviewTileState extends State<ImagePreviewTile> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: _h ? kEvSurf3 : kEvSurf2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _h ? kEvAccent.withOpacity(0.3) : kEvBorder,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_rounded, color: kEvAccent, size: 28),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      widget.name,
                      style: GoogleFonts.sora(fontSize: 9, color: kEvSub),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _h ? kEvRed : kEvRed.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
