// ─────────────────────────────────────────────────────────────
//  WIDGET  —  application_widgets.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/job_controller.dart';
import '../models/job_model.dart';
import 'job_atoms.dart';
import 'job_theme.dart';

// ─────────────────────────────────────────────────────────────
//  APPLICATION CARD  (in the applications list)
// ─────────────────────────────────────────────────────────────
class ApplicationCard extends StatefulWidget {
  final JobApplication application;
  final JobController ctrl;
  final VoidCallback onTap;
  final bool isSelected;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.ctrl,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<ApplicationCard> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final a    = widget.application;
    final snap = a.applicantSnapshot;
    final st   = appStatusTheme(a.status);

    return MouseRegion(
      onEnter:  (_) => setState(() => _hov = true),
      onExit:   (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? jGreen.withOpacity(0.06)
                : _hov ? jSurf2 : jSurf,
            borderRadius: jR12,
            border: Border.all(
              color: widget.isSelected
                  ? jGreen.withOpacity(0.3)
                  : _hov ? st.color.withOpacity(0.2) : jBorder,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            // Avatar
            _ApplicantAvatar(snapshot: snap, size: 44),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(snap.fullName,
                          style: jH3(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    AppStatusBadge(status: a.status),
                  ]),
                  const SizedBox(height: 3),
                  Text(snap.email,
                      style: jMonoSm(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    _MiniStat(
                        icon: Icons.access_time_rounded,
                        label: '${snap.totalVolunteerHours}h exp',
                        color: jBlue),
                    const SizedBox(width: 8),
                    _MiniStat(
                        icon: Icons.star_rounded,
                        label: snap.rating.toStringAsFixed(1),
                        color: jAmber),
                    const Spacer(),
                    Text(
                      widget.ctrl.formatDate(a.createdAt),
                      style: jMonoSm(),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 16, color: jMuted),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  APPLICATION DETAIL PANEL
// ─────────────────────────────────────────────────────────────
class ApplicationDetailPanel extends StatefulWidget {
  final JobApplication application;
  final JobController ctrl;

  const ApplicationDetailPanel({
    super.key,
    required this.application,
    required this.ctrl,
  });

  @override
  State<ApplicationDetailPanel> createState() =>
      _ApplicationDetailPanelState();
}

class _ApplicationDetailPanelState extends State<ApplicationDetailPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final a    = widget.application;
    final snap = a.applicantSnapshot;
    final st   = appStatusTheme(a.status);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF080D1A),
            border: Border(left: BorderSide(color: jBorder)),
          ),
          child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: jBorder))),
              child: Row(children: [
                const Icon(Icons.person_rounded, color: jGreen, size: 16),
                const SizedBox(width: 8),
                Text('Application Details', style: jH3()),
                const Spacer(),
                JIconBtn(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  onTap: () => widget.ctrl.selectedApplication.value = null,
                ),
              ]),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Applicant header card ───────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            st.color.withOpacity(0.08),
                            jSurf2,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: jR14,
                        border: Border.all(color: st.color.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        _ApplicantAvatar(snapshot: snap, size: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(snap.fullName, style: jH2()),
                              const SizedBox(height: 2),
                              Text(snap.email,
                                  style: jMonoSm().copyWith(
                                      color: jSub)),
                              const SizedBox(height: 8),
                              AppStatusBadge(status: a.status),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Stats row
                    Row(children: [
                      _StatCard(
                        label: 'Volunteer Hours',
                        value: '${snap.totalVolunteerHours}h',
                        icon: Icons.access_time_rounded,
                        color: jBlue,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Rating',
                        value: snap.rating.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                        color: jAmber,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Applied',
                        value: widget.ctrl.formatDate(a.createdAt),
                        icon: Icons.calendar_today_rounded,
                        color: jTeal,
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // ── Why Hire ─────────────────────────────
                    _SectionLabel('Why Should We Hire?', Icons.lightbulb_rounded, jAmber),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: jAmber.withOpacity(0.04),
                        borderRadius: jR10,
                        border: Border.all(color: jAmber.withOpacity(0.15)),
                      ),
                      child: Text(a.whyHire,
                          style: jBodySm().copyWith(height: 1.6)),
                    ),
                    const SizedBox(height: 14),

                    // ── Experience ────────────────────────────
                    _SectionLabel('Experience', Icons.work_rounded, jBlue),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: jBlue.withOpacity(0.04),
                        borderRadius: jR10,
                        border: Border.all(color: jBlue.withOpacity(0.15)),
                      ),
                      child: Text(a.experience,
                          style: jBodySm().copyWith(height: 1.6)),
                    ),
                    const SizedBox(height: 14),

                    // ── Skills ────────────────────────────────
                    if (a.skills.isNotEmpty) ...[
                      _SectionLabel('Mentioned Skills', Icons.bolt_rounded, jTeal),
                      Wrap(spacing: 6, runSpacing: 6,
                          children: a.skills.map((s) =>
                              SkillChip(label: s, color: jTeal)).toList()),
                      const SizedBox(height: 14),
                    ],

                    // ── Bio ───────────────────────────────────
                    if (snap.bio.isNotEmpty) ...[
                      _SectionLabel('Bio', Icons.person_rounded, jIndigo),
                      Text(snap.bio,
                          style: jBodySm().copyWith(color: jSub, height: 1.6)),
                      const SizedBox(height: 14),
                    ],

                    // ── Resume ────────────────────────────────
                    if (a.resumeOriginalName != null) ...[
                      _SectionLabel('Resume', Icons.description_rounded, jSub),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: jSurf2,
                          borderRadius: jR10,
                          border: Border.all(color: jBorder2),
                        ),
                        child: Row(children: [
                          const Icon(Icons.picture_as_pdf_rounded,
                              color: jRose, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              a.resumeOriginalName!,
                              style: GoogleFonts.firaCode(
                                  fontSize: 11, color: jText),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Action buttons ────────────────────────
                    if (a.status == ApplicationStatus.pending)
                      _ActionButtons(application: a, ctrl: widget.ctrl),

                    if (a.status != ApplicationStatus.pending)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: st.color.withOpacity(0.06),
                          borderRadius: jR10,
                          border: Border.all(
                              color: st.color.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          Icon(st.icon, color: st.color, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'This application has been ${a.status.label.toLowerCase()}.',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: st.color),
                          ),
                        ]),
                      ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ACTION BUTTONS  (approve / reject)
// ─────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final JobApplication application;
  final JobController ctrl;

  const _ActionButtons({
    required this.application,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = ctrl.appActionLoading.value == application.id;
      return Row(children: [
        Expanded(
          child: JBtn(
            label: 'Approve',
            icon: Icons.check_circle_rounded,
            color: jGreen,
            loading: loading,
            onTap: loading
                ? null
                : () => ctrl.approveApplication(application.id),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: JBtn(
            label: 'Reject',
            icon: Icons.cancel_rounded,
            color: jRose,
            loading: loading,
            onTap: loading
                ? null
                : () => ctrl.rejectApplication(application.id),
          ),
        ),
      ]);
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────
class _ApplicantAvatar extends StatelessWidget {
  final ApplicantSnapshot snapshot;
  final double size;
  const _ApplicantAvatar({required this.snapshot, required this.size});

  @override
  Widget build(BuildContext context) {
    final img = snapshot.profileImage;
    if (img != null && img.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 3),
        child: Image.network(
          img,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Initials(snapshot: snapshot, size: size),
        ),
      );
    }
    return _Initials(snapshot: snapshot, size: size);
  }
}

class _Initials extends StatelessWidget {
  final ApplicantSnapshot snapshot;
  final double size;
  const _Initials({required this.snapshot, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [jGreen, jBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Center(
        child: Text(snapshot.initials,
            style: GoogleFonts.outfit(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            )),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniStat({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(label, style: GoogleFonts.firaCode(fontSize: 10, color: color)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: jR10,
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 5),
          Text(value,
              style: GoogleFonts.firaCode(
                  fontSize: 13,
                  color: jText,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: jMonoSm()),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _SectionLabel(this.text, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: jR6,
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 7),
        Text(text,
            style: jH3().copyWith(fontSize: 11, color: jSub)),
      ]),
    );
  }
}
