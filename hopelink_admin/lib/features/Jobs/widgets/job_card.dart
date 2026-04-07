// ─────────────────────────────────────────────────────────────
//  WIDGET  —  job_card.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/job_controller.dart';
import '../models/job_model.dart';
import 'job_atoms.dart';

import 'job_theme.dart';

class JobCard extends StatefulWidget {
  final VolunteerJob job;
  final JobController ctrl;
  final VoidCallback onViewApplications;

  const JobCard({
    super.key,
    required this.job,
    required this.ctrl,
    required this.onViewApplications,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final j   = widget.job;
    final st  = jobStatusTheme(j.status);
    final jt  = jobTypeTheme(j.jobType);

    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _hov ? jSurf2 : jSurf,
          borderRadius: jR14,
          border: Border.all(
              color: _hov ? st.color.withOpacity(0.3) : jBorder),
          boxShadow: _hov ? jGlow(st.color) : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon box
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          st.color.withOpacity(0.18),
                          st.color.withOpacity(0.05)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: jR10,
                      border: Border.all(color: st.color.withOpacity(0.25)),
                    ),
                    child: Icon(_categoryIcon(j.category),
                        size: 20, color: st.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(j.title,
                            style: jH3().copyWith(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(j.organizationName,
                            style: jMonoSm()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  JobStatusBadge(status: j.status),
                ],
              ),
            ),

            // ── Description ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(j.description,
                  style: jBodySm(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),

            // ── Chips row ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Wrap(spacing: 6, runSpacing: 4, children: [
                JobTypeBadge(type: j.jobType),
                _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: j.location.displayCity),
                _InfoChip(
                    icon: Icons.school_rounded,
                    label: '${j.creditHours}h credit'),
                if (j.certificateProvided)
                  _InfoChip(
                      icon: Icons.verified_rounded,
                      label: 'Certificate',
                      color: jIndigo),
              ]),
            ),

            // ── Skills row ────────────────────────────────────
            if (j.requiredSkills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: j.requiredSkills.take(4).map((s) =>
                    SkillChip(label: s, color: jBlue),
                  ).toList(),
                ),
              ),

            // ── Footer ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(children: [
                // Positions
                _PositionsFill(job: j, statusColor: st.color),
                const Spacer(),
                // Deadline
                _DeadlinePill(job: j),
                const SizedBox(width: 10),
                // View applications button
                JBtn(
                  label: 'Applications',
                  icon: Icons.people_alt_rounded,
                  ghost: true,
                  height: 36,
                  onTap: widget.onViewApplications,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'technology':       return Icons.computer_rounded;
      case 'marketing':        return Icons.campaign_rounded;
      case 'education':        return Icons.school_rounded;
      case 'community service': return Icons.volunteer_activism_rounded;
      case 'health':           return Icons.health_and_safety_rounded;
      case 'environment':      return Icons.eco_rounded;
      case 'design':           return Icons.palette_rounded;
      case 'finance':          return Icons.account_balance_rounded;
      default:                 return Icons.work_outline_rounded;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? jSub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: jSurf3,
        borderRadius: jR6,
        border: Border.all(color: jBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: c),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.firaCode(fontSize: 9, color: c)),
      ]),
    );
  }
}

class _PositionsFill extends StatelessWidget {
  final VolunteerJob job;
  final Color statusColor;
  const _PositionsFill({required this.job, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final pct = job.fillRate / 100;
    return SizedBox(
      width: 140,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            '${job.positionsFilled}/${job.positionsAvailable} filled',
            style: GoogleFonts.firaCode(fontSize: 10, color: statusColor),
          ),
          Text(
            '${job.positionsLeft} left',
            style: GoogleFonts.firaCode(fontSize: 9, color: jMuted),
          ),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: jR20,
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: jBorder2,
            valueColor: AlwaysStoppedAnimation(statusColor),
          ),
        ),
      ]),
    );
  }
}

class _DeadlinePill extends StatelessWidget {
  final VolunteerJob job;
  const _DeadlinePill({required this.job});

  @override
  Widget build(BuildContext context) {
    final expired = job.isExpired;
    final days    = job.daysLeft;
    final color   = expired ? jMuted : days <= 7 ? jRose : days <= 30 ? jAmber : jGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: jR8,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(expired ? Icons.event_busy_rounded : Icons.event_rounded,
            size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          expired ? 'Expired' : days == 0 ? 'Today' : '${days}d',
          style: GoogleFonts.firaCode(
              fontSize: 9, color: color, fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}
