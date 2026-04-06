// ─────────────────────────────────────────────────────────────
//  WIDGETS  —  org_events_widgets.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/org_events_controller.dart';
import '../models/org_event_model.dart';


// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
const kOeBg      = Color(0xFF06080F);
const kOeSurf    = Color(0xFF0B1120);
const kOeSurf2   = Color(0xFF0F172A);
const kOeSurf3   = Color(0xFF152035);
const kOeBorder  = Color(0xFF1C2E4A);
const kOeBorder2 = Color(0xFF243655);
const kOeGreen   = Color(0xFF10D078);
const kOeBlue    = Color(0xFF3B82F6);
const kOeAmber   = Color(0xFFF59E0B);
const kOeRed     = Color(0xFFEF4444);
const kOeIndigo  = Color(0xFF6366F1);
const kOeText    = Colors.white;
const kOeSub     = Color(0xFF7C93B8);
const kOeMuted   = Color(0xFF3B506E);

// ─────────────────────────────────────────────────────────────
//  STATUS CONFIG
// ─────────────────────────────────────────────────────────────
class _StatusCfg {
  final Color color;
  final IconData icon;
  const _StatusCfg(this.color, this.icon);
}

_StatusCfg statusConfig(String status) {
  switch (status.toLowerCase()) {
    case 'published': return const _StatusCfg(kOeBlue,   Icons.public_rounded);
    case 'ongoing':   return const _StatusCfg(kOeGreen,  Icons.play_circle_rounded);
    case 'completed': return const _StatusCfg(kOeAmber,  Icons.check_circle_rounded);
    case 'cancelled': return const _StatusCfg(kOeRed,    Icons.cancel_rounded);
    default:          return const _StatusCfg(kOeMuted,  Icons.drafts_rounded);
  }
}

// ─────────────────────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(
            color: cfg.color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: cfg.color.withOpacity(0.7), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          status.statusLabel,
          style: GoogleFonts.ibmPlexMono(
              fontSize: 10, color: cfg.color, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STAT SUMMARY CARD
// ─────────────────────────────────────────────────────────────
class OeStatCard extends StatefulWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accent;

  const OeStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  State<OeStatCard> createState() => _OeStatCardState();
}

class _OeStatCardState extends State<OeStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _hovered ? kOeSurf3 : kOeSurf,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? widget.accent.withOpacity(0.3) : kOeBorder,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: widget.accent.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))]
              : [],
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: widget.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: widget.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.value,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kOeText,
                  letterSpacing: -0.5,
                )),
            Text(widget.label,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 11, color: kOeSub)),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EVENT GRID CARD
// ─────────────────────────────────────────────────────────────
class EventGridCard extends StatefulWidget {
  final OrgEvent event;
  final OrgEventsController ctrl;
  final VoidCallback onTap;

  const EventGridCard({
    super.key,
    required this.event,
    required this.ctrl,
    required this.onTap,
  });

  @override
  State<EventGridCard> createState() => _EventGridCardState();
}

class _EventGridCardState extends State<EventGridCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e   = widget.event;
    final cfg = statusConfig(e.status);

    return MouseRegion(
      onEnter:  (_) => setState(() => _hovered = true),
      onExit:   (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _hovered ? kOeSurf3 : kOeSurf,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? cfg.color.withOpacity(0.35) : kOeBorder,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: cfg.color.withOpacity(0.07), blurRadius: 24, offset: const Offset(0, 8))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image / Placeholder ───────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: _EventImageBanner(event: e, height: 130),
              ),

              // ── Content ───────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Status
                      Row(children: [
                        Expanded(
                          child: Text(
                            e.title,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kOeText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: e.status),
                      ]),
                      const SizedBox(height: 8),

                      // Meta chips row
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        _MiniChip(
                          icon: Icons.folder_outlined,
                          label: e.category,
                          color: kOeIndigo,
                        ),
                        _MiniChip(
                          icon: Icons.schedule_rounded,
                          label: e.eventType.replaceAll('-', ' '),
                          color: kOeBlue,
                        ),
                      ]),
                      const SizedBox(height: 10),

                      // Location
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: kOeMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            e.location.displayCity,
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 11, color: kOeSub),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),

                      // Date range
                      Row(children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 11, color: kOeMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.ctrl.formatShortDate(e.startDate)} → ${widget.ctrl.formatDate(e.endDate)}',
                          style: GoogleFonts.ibmPlexMono(
                              fontSize: 10, color: kOeSub),
                        ),
                      ]),

                      const Spacer(),

                      // Footer
                      Row(children: [
                        _FooterStat(
                          icon: Icons.group_rounded,
                          value: '${e.volunteerCount}',
                          label: 'Volunteers',
                          color: kOeGreen,
                        ),
                        const SizedBox(width: 10),
                        _FooterStat(
                          icon: Icons.image_rounded,
                          value: '${e.images.length}',
                          label: 'Photos',
                          color: kOeIndigo,
                        ),
                        const Spacer(),
                        if (e.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kOeAmber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: kOeAmber.withOpacity(0.3)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.star_rounded,
                                  size: 9, color: kOeAmber),
                              const SizedBox(width: 3),
                              Text('Featured',
                                  style: GoogleFonts.ibmPlexMono(
                                      fontSize: 9, color: kOeAmber)),
                            ]),
                          ),
                      ]),
                    ],
                  ),
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
//  EVENT LIST ROW
// ─────────────────────────────────────────────────────────────
class EventListRow extends StatefulWidget {
  final OrgEvent event;
  final OrgEventsController ctrl;
  final VoidCallback onTap;

  const EventListRow({
    super.key,
    required this.event,
    required this.ctrl,
    required this.onTap,
  });

  @override
  State<EventListRow> createState() => _EventListRowState();
}

class _EventListRowState extends State<EventListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e   = widget.event;
    final cfg = statusConfig(e.status);

    return MouseRegion(
      onEnter:  (_) => setState(() => _hovered = true),
      onExit:   (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered ? kOeSurf3 : kOeSurf,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? cfg.color.withOpacity(0.3) : kOeBorder,
            ),
          ),
          child: Row(children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64, height: 64,
                child: _EventImageBanner(event: e, height: 64),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(e.title,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kOeText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    StatusBadge(status: e.status),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    _MiniChip(icon: Icons.folder_outlined, label: e.category, color: kOeIndigo),
                    const SizedBox(width: 6),
                    _MiniChip(icon: Icons.schedule_rounded, label: e.eventType.replaceAll('-', ' '), color: kOeBlue),
                  ]),
                  const SizedBox(height: 5),
                  Text(
                    '${e.location.displayCity}  ·  ${widget.ctrl.formatDate(e.startDate)} → ${widget.ctrl.formatDate(e.endDate)}',
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 10, color: kOeSub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _FooterStat(
                    icon: Icons.group_rounded,
                    value: '${e.volunteerCount}',
                    label: 'volunteers',
                    color: kOeGreen),
                const SizedBox(height: 4),
                _FooterStat(
                    icon: Icons.image_rounded,
                    value: '${e.images.length}',
                    label: 'images',
                    color: kOeIndigo),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: kOeMuted, size: 18),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EVENT IMAGE BANNER  (handles missing images gracefully)
// ─────────────────────────────────────────────────────────────
class _EventImageBanner extends StatelessWidget {
  final OrgEvent event;
  final double height;
  const _EventImageBanner({required this.event, required this.height});

  @override
  Widget build(BuildContext context) {
    final img = event.primaryImage;
    final cfg = statusConfig(event.status);

    if (img != null) {
      return Image.network(
        img.url,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Placeholder(event: event, height: height, cfg: cfg),
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _Placeholder(event: event, height: height, cfg: cfg);
        },
      );
    }
    return _Placeholder(event: event, height: height, cfg: cfg);
  }
}

class _Placeholder extends StatelessWidget {
  final OrgEvent event;
  final double height;
  final _StatusCfg cfg;
  const _Placeholder({required this.event, required this.height, required this.cfg});

  static const _categoryIcons = <String, IconData>{
    'education':    Icons.school_rounded,
    'health':       Icons.health_and_safety_rounded,
    'environment':  Icons.eco_rounded,
    'human-rights': Icons.gavel_rounded,
    'community':    Icons.people_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[event.category] ?? Icons.event_rounded;
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cfg.color.withOpacity(0.12),
            kOeSurf3,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        // Background pattern dots
        Positioned(
          right: 12, bottom: 8,
          child: Icon(icon, size: height * 0.45,
              color: cfg.color.withOpacity(0.08)),
        ),
        Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: cfg.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: cfg.color),
            ),
            const SizedBox(height: 6),
            Text('No Images',
                style: GoogleFonts.ibmPlexMono(
                    fontSize: 9, color: cfg.color.withOpacity(0.6))),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EVENT DETAIL DRAWER
// ─────────────────────────────────────────────────────────────
class EventDetailPanel extends StatefulWidget {
  final OrgEvent event;
  final OrgEventsController ctrl;

  const EventDetailPanel({
    super.key,
    required this.event,
    required this.ctrl,
  });

  @override
  State<EventDetailPanel> createState() => _EventDetailPanelState();
}

class _EventDetailPanelState extends State<EventDetailPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _anim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final e   = widget.event;
    final cfg = statusConfig(e.status);

    return SlideTransition(
      position: _slide,
      child: Container(
        width: 380,
        decoration: const BoxDecoration(
          color: kOeSurf2,
          border: Border(left: BorderSide(color: kOeBorder)),
        ),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: kOeBorder))),
              child: Row(children: [
                Expanded(
                  child: Text('Event Details',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kOeText,
                      )),
                ),
                IconButton(
                  onPressed: widget.ctrl.closeDetail,
                  icon: const Icon(Icons.close_rounded,
                      color: kOeSub, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: kOeSurf3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
            ),

            // ── Scrollable body ────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image carousel
                    if (e.hasImages) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 180,
                          child: Stack(children: [
                            Image.network(
                              e.images[_imageIndex].url,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _Placeholder(event: e, height: 180, cfg: cfg),
                            ),
                            if (e.images.length > 1) ...[
                              Positioned(
                                bottom: 8, right: 8,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(e.images.length, (i) =>
                                    GestureDetector(
                                      onTap: () => setState(() => _imageIndex = i),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        width: _imageIndex == i ? 16 : 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(left: 3),
                                        decoration: BoxDecoration(
                                          color: _imageIndex == i
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8, left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_imageIndex + 1}/${e.images.length}',
                                    style: GoogleFonts.ibmPlexMono(
                                        fontSize: 10, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _Placeholder(event: e, height: 120, cfg: cfg),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Title + status
                    Row(children: [
                      Expanded(
                        child: Text(e.title,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kOeText,
                            )),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    StatusBadge(status: e.status),
                    const SizedBox(height: 14),

                    // Description
                    Text(e.description,
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 12, color: kOeSub, height: 1.6)),
                    const SizedBox(height: 18),

                    _Divider(),

                    // Detail rows
                    _DetailRow(icon: Icons.category_rounded,        label: 'Category',     value: e.category),
                    _DetailRow(icon: Icons.event_repeat_rounded,    label: 'Event Type',   value: e.eventType.replaceAll('-', ' ')),
                    _DetailRow(icon: Icons.location_on_rounded,     label: 'Location',     value: '${e.location.address}, ${e.location.displayCity}'),
                    _DetailRow(icon: Icons.play_circle_outline,     label: 'Starts',       value: widget.ctrl.formatDate(e.startDate)),
                    _DetailRow(icon: Icons.stop_circle_outlined,    label: 'Ends',         value: widget.ctrl.formatDate(e.endDate)),
                    _DetailRow(icon: Icons.group_rounded,           label: 'Max Volunteers', value: '${e.maxVolunteers}'),
                    _DetailRow(icon: Icons.how_to_reg_rounded,      label: 'Eligibility',  value: e.eligibility),
                    _DetailRow(icon: Icons.people_alt_rounded,      label: 'Enrolled',     value: '${e.volunteerCount} volunteer${e.volunteerCount != 1 ? 's' : ''}', valueColor: kOeGreen),

                    if (e.parsedSkills.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _Divider(),
                      const SizedBox(height: 14),
                      Text('Required Skills',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kOeSub,
                            letterSpacing: 0.5,
                          )),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: e.parsedSkills.map((s) =>
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: kOeIndigo.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: kOeIndigo.withOpacity(0.25)),
                            ),
                            child: Text(s,
                                style: GoogleFonts.ibmPlexMono(
                                    fontSize: 10, color: kOeIndigo)),
                          ),
                        ).toList(),
                      ),
                    ],

                    const SizedBox(height: 14),
                    _Divider(),
                    const SizedBox(height: 10),

                    // Created / Updated
                    Text(
                      'Created ${widget.ctrl.formatDate(e.createdAt)}  ·  Updated ${widget.ctrl.formatDate(e.updatedAt)}',
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 9, color: kOeMuted),
                    ),
                    const SizedBox(height: 4),
                    _IdChip(id: e.id),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.transparent, kOeBorder, Colors.transparent],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
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
          decoration: BoxDecoration(
            color: kOeSurf3,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: kOeSub),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.ibmPlexMono(
                  fontSize: 9, color: kOeMuted, letterSpacing: 0.5)),
          const SizedBox(height: 1),
          Text(value,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: valueColor ?? kOeText,
                fontWeight: FontWeight.w500,
              )),
        ]),
      ]),
    );
  }
}

class _IdChip extends StatelessWidget {
  final String id;
  const _IdChip({required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kOeSurf3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kOeBorder2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.tag_rounded, size: 11, color: kOeMuted),
        const SizedBox(width: 5),
        Text(id,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 9,
              color: kOeSub,
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SMALL HELPERS
// ─────────────────────────────────────────────────────────────
class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: GoogleFonts.ibmPlexMono(fontSize: 9, color: color)),
      ]),
    );
  }
}

class _FooterStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _FooterStat({required this.icon, required this.value,
      required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11, color: color, fontWeight: FontWeight.w600,
          )),
      const SizedBox(width: 2),
      Text(label,
          style: GoogleFonts.ibmPlexSans(fontSize: 10, color: kOeMuted)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  FILTER TAB
// ─────────────────────────────────────────────────────────────
class FilterTab extends StatefulWidget {
  final String label;
  final int count;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const FilterTab({
    super.key,
    required this.label,
    required this.count,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  State<FilterTab> createState() => _FilterTabState();
}

class _FilterTabState extends State<FilterTab> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: widget.active
                ? widget.accent.withOpacity(0.12)
                : _h
                    ? kOeSurf3
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.active
                  ? widget.accent.withOpacity(0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.label,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  color: widget.active ? kOeText : _h ? kOeText : kOeSub,
                  fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
                )),
            if (widget.count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.active
                      ? widget.accent.withOpacity(0.2)
                      : kOeSurf3,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${widget.count}',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 9,
                      color: widget.active ? widget.accent : kOeMuted,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────
class OeEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  const OeEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: kOeSurf3,
            shape: BoxShape.circle,
            border: Border.all(color: kOeBorder2),
          ),
          child: Icon(icon, color: kOeMuted, size: 30),
        ),
        const SizedBox(height: 18),
        Text(title,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kOeText,
            )),
        const SizedBox(height: 6),
        Text(subtitle,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 12, color: kOeSub),
            textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SKELETON LOADER
// ─────────────────────────────────────────────────────────────
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key});
  @override State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        final opacity = 0.04 + _shimmer.value * 0.06;
        return Container(
          decoration: BoxDecoration(
            color: kOeSurf,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kOeBorder),
          ),
          child: Column(children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SkeletonLine(width: double.infinity, height: 14, opacity: opacity),
                const SizedBox(height: 8),
                _SkeletonLine(width: 120, height: 10, opacity: opacity),
                const SizedBox(height: 8),
                _SkeletonLine(width: 80, height: 10, opacity: opacity),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;
  const _SkeletonLine({required this.width, required this.height, required this.opacity});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
