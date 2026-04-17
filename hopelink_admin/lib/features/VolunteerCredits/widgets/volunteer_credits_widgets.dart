import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopelink_admin/features/Jobs/widgets/job_atoms.dart';
import 'package:hopelink_admin/features/Jobs/widgets/job_theme.dart';
import 'package:hopelink_admin/features/VolunteerCredits/controllers/volunteer_credits_controller.dart';
import 'package:hopelink_admin/features/VolunteerCredits/models/volunteer_credit_model.dart';

class CreditSourceToggle extends StatelessWidget {
  final VolunteerCreditSource value;
  final ValueChanged<VolunteerCreditSource> onChanged;

  const CreditSourceToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: VolunteerCreditSource.values.map((source) {
        final active = value == source;
        final color = source == VolunteerCreditSource.job ? jGreen : jBlue;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(source),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? color.withOpacity(0.12) : jSurf,
                borderRadius: jR10,
                border: Border.all(
                  color: active ? color.withOpacity(0.35) : jBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    source == VolunteerCreditSource.job
                        ? Icons.work_history_rounded
                        : Icons.event_available_rounded,
                    size: 14,
                    color: active ? color : jSub,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    source.label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? jText : jSub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class CreditStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const CreditStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: jSurf,
          borderRadius: jR12,
          border: Border.all(color: jBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: jR10,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.firaCode(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: jText,
                  ),
                ),
                Text(label, style: jMonoSm()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VolunteerEntryCard extends StatelessWidget {
  final VolunteerCreditEntry entry;
  final VolunteerCreditsController ctrl;
  final bool selected;
  final VoidCallback onTap;

  const VolunteerEntryCard({
    super.key,
    required this.entry,
    required this.ctrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = entry.creditsGranted ? jGreen : jAmber;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.08) : jSurf,
          borderRadius: jR12,
          border: Border.all(
            color: selected ? accent.withOpacity(0.35) : jBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            _CreditAvatar(user: entry.user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.user.name,
                          style: jH3(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _CreditPill(
                        label: entry.creditsGranted
                            ? '${entry.creditHoursGranted}h granted'
                            : 'Pending',
                        color: accent,
                        icon: entry.creditsGranted
                            ? Icons.verified_rounded
                            : Icons.schedule_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.user.email,
                    style: jMonoSm(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _TinyMeta(
                        icon: Icons.workspace_premium_rounded,
                        value: entry.user.rating.toStringAsFixed(1),
                        color: jBlue,
                      ),
                      const SizedBox(width: 8),
                      _TinyMeta(
                        icon: Icons.timer_outlined,
                        value: '${entry.user.totalVolunteerHours}h',
                        color: jTeal,
                      ),
                      const Spacer(),
                      Text(entry.timelineLabel, style: jMonoSm()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VolunteerCreditDetailPanel extends StatelessWidget {
  final VolunteerCreditEntry entry;
  final VolunteerCreditSourceOption? source;
  final VolunteerCreditsController ctrl;

  const VolunteerCreditDetailPanel({
    super.key,
    required this.entry,
    required this.source,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isJob = entry.source == VolunteerCreditSource.job;
      final actionLoading = ctrl.actionLoadingId.value == entry.id;
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFF080D1A),
          border: Border(left: BorderSide(color: jBorder)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [jGreen, jBlue]),
                      borderRadius: jR12,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.user.name, style: jH2()),
                        Text(
                          source?.title ?? 'Selected source',
                          style: jMonoSm(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _CreditPill(
                    label: isJob ? 'Job volunteer' : 'Event participant',
                    color: isJob ? jGreen : jBlue,
                    icon: isJob
                        ? Icons.work_history_rounded
                        : Icons.event_available_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricBlock(
                      label: 'Credit Hours',
                      value: '${entry.creditHoursGranted}h',
                      color: entry.creditsGranted ? jGreen : jAmber,
                      icon: entry.creditsGranted
                          ? Icons.verified_rounded
                          : Icons.pending_actions_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricBlock(
                      label: 'Volunteer Hours',
                      value: '${entry.user.totalVolunteerHours}h',
                      color: jTeal,
                      icon: Icons.timer_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricBlock(
                      label: 'Rating',
                      value: entry.user.rating.toStringAsFixed(1),
                      color: jBlue,
                      icon: Icons.star_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DetailSection(
                title: 'Volunteer Info',
                icon: Icons.person_outline_rounded,
                color: jBlue,
                child: Column(
                  children: [
                    JInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: entry.user.email,
                    ),
                    if ((entry.user.phone ?? '').isNotEmpty)
                      JInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: entry.user.phone!,
                      ),
                    JInfoRow(
                      icon: Icons.event_available_rounded,
                      label: 'Status',
                      value: entry.status,
                    ),
                    if (entry.attendance != null)
                      JInfoRow(
                        icon: entry.attendance!
                            ? Icons.check_circle_outline_rounded
                            : Icons.cancel_outlined,
                        label: 'Attendance',
                        value: entry.attendance! ? 'Attended' : 'Not marked',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (entry.user.skills.isNotEmpty)
                _DetailSection(
                  title: 'Skills',
                  icon: Icons.auto_awesome_rounded,
                  color: jTeal,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.user.skills
                        .map((skill) => SkillChip(label: skill))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 14),
              _DetailSection(
                title: 'Timeline',
                icon: Icons.schedule_rounded,
                color: jAmber,
                child: Column(
                  children: [
                    JInfoRow(
                      icon: Icons.approval_outlined,
                      label: 'Approved At',
                      value: ctrl.formatDateTime(entry.approvedAt),
                    ),
                    JInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Created At',
                      value: ctrl.formatDateTime(entry.createdAt),
                    ),
                    if (entry.enrollmentDate != null)
                      JInfoRow(
                        icon: Icons.login_rounded,
                        label: 'Enrollment Date',
                        value: ctrl.formatDateTime(entry.enrollmentDate),
                      ),
                    JInfoRow(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Credits Granted At',
                      value: ctrl.formatDateTime(entry.creditGrantedAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              JBtn(
                label: entry.creditsGranted
                    ? 'Credit Hours Already Granted'
                    : 'Grant Credit Hours',
                icon: entry.creditsGranted
                    ? Icons.check_circle_rounded
                    : Icons.workspace_premium_rounded,
                color: entry.creditsGranted ? jTeal : jGreen,
                loading: actionLoading,
                onTap: entry.creditsGranted || actionLoading
                    ? null
                    : () => ctrl.grantCredits(entry),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class CreditEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const CreditEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: jSurf2,
              shape: BoxShape.circle,
              border: Border.all(color: jBorder2),
            ),
            child: Icon(icon, color: jMuted, size: 30),
          ),
          const SizedBox(height: 16),
          Text(title, style: jH2()),
          const SizedBox(height: 6),
          Text(subtitle, style: jMonoSm(), textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

class CreditSourceDropdown extends StatelessWidget {
  final List<VolunteerCreditSourceOption> options;
  final VolunteerCreditSourceOption? selected;
  final ValueChanged<VolunteerCreditSourceOption?> onChanged;

  const CreditSourceDropdown({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: jSurf,
        borderRadius: jR10,
        border: Border.all(color: jBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VolunteerCreditSourceOption>(
          value: selected,
          dropdownColor: jSurf2,
          isExpanded: true,
          iconEnabledColor: jSub,
          style: GoogleFonts.inter(fontSize: 13, color: jText),
          hint: Text('Select source', style: jMonoSm()),
          items: options.map((option) {
            return DropdownMenuItem<VolunteerCreditSourceOption>(
              value: option,
              child: Row(
                children: [
                  Icon(
                    option.source == VolunteerCreditSource.job
                        ? Icons.work_outline_rounded
                        : Icons.event_note_rounded,
                    size: 14,
                    color: option.source == VolunteerCreditSource.job
                        ? jGreen
                        : jBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(option.title, overflow: TextOverflow.ellipsis),
                  ),
                  if (option.creditHours != null)
                    Text(
                      '${option.creditHours}h',
                      style: jMonoSm().copyWith(color: jGreen),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class CreditSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const CreditSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: JField(
        controller: controller,
        label: 'Search',
        hint: 'Find volunteer by name, email, skill...',
        required: false,
        prefix: const Icon(Icons.search_rounded, color: jMuted, size: 16),
        onChanged: onChanged,
      ),
    );
  }
}

class _CreditAvatar extends StatelessWidget {
  final VolunteerCreditUser user;
  const _CreditAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final image = user.profileImage;
    if (image != null && image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          image,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsBox(),
        ),
      );
    }
    return _initialsBox();
  }

  Widget _initialsBox() {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [jGreen, jBlue]),
        borderRadius: jR12,
      ),
      child: Center(
        child: Text(
          user.initials,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TinyMeta extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _TinyMeta({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(value, style: GoogleFonts.firaCode(fontSize: 10, color: color)),
      ],
    );
  }
}

class _CreditPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _CreditPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: jR20,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.firaCode(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricBlock({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: jR10,
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.firaCode(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: jText,
            ),
          ),
          Text(label, style: jMonoSm()),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: jSurf,
        borderRadius: jR12,
        border: Border.all(color: jBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: jR8,
                ),
                child: Icon(icon, color: color, size: 13),
              ),
              const SizedBox(width: 8),
              Text(title, style: jH3()),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
