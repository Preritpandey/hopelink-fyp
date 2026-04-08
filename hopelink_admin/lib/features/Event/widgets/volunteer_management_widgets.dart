// ─────────────────────────────────────────────────────────────
//  WIDGETS  —  volunteer_management_widgets.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopelink_admin/features/Event/models/event_volunteer_model.dart';
import 'package:hopelink_admin/features/Event/models/org_event_model.dart';

import '../controllers/org_events_controller.dart';
import 'event_theme.dart';
import 'event_components.dart';

// ─────────────────────────────────────────────────────────────
//  VOLUNTEER MANAGEMENT PANEL
// ─────────────────────────────────────────────────────────────
class VolunteerManagementPanel extends StatefulWidget {
  final OrgEvent event;
  final OrgEventsController ctrl;

  const VolunteerManagementPanel({
    required this.event,
    required this.ctrl,
    super.key,
  });

  @override
  State<VolunteerManagementPanel> createState() =>
      _VolunteerManagementPanelState();
}

class _VolunteerManagementPanelState extends State<VolunteerManagementPanel> {
  late String selectedFilter; // pending, approved, rejected, attended

  @override
  void initState() {
    super.initState();
    selectedFilter = 'pending';
    _loadVolunteers();
  }

  void _loadVolunteers() {
    widget.ctrl.fetchEventVolunteers(widget.event.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: evSurf,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────
          _buildHeader(),

          // ── Filter Tabs ──────────────────────────────────────
          _buildFilterTabs(),

          // ── Content ──────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (widget.ctrl.isLoadingVolunteers.value) {
                return Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(evBlue),
                    ),
                  ),
                );
              }

              if (widget.ctrl.volunteersError.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: evRed, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        widget.ctrl.volunteersError.value,
                        textAlign: TextAlign.center,
                        style: evBodySm().copyWith(color: evTextSub),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadVolunteers,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: evBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final filtered = _getFilteredVolunteers();
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, color: evTextMute, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No $selectedFilter volunteers',
                        style: evHeadingMd(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applications will appear here',
                        style: evBodySm().copyWith(color: evTextSub),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemBuilder: (ctx, idx) {
                  final volunteer = filtered[idx];
                  return VolunteerCard(
                    volunteer: volunteer,
                    ctrl: widget.ctrl,
                    onAction: _loadVolunteers,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: evBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [evBlue, evBlue]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.people_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Volunteer Applicants', style: evHeadingMd()),
              Text(
                'Manage event applications',
                style: evBodyXs().copyWith(color: evTextSub),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18, color: evBlue),
            onPressed: _loadVolunteers,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['pending', 'approved', 'rejected', 'attended'];
    final labels = ['Pending', 'Approved', 'Rejected', 'Attended'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: evBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(filters.length, (idx) {
            final filter = filters[idx];
            final label = labels[idx];
            final isActive = selectedFilter == filter;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => selectedFilter = filter),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: evBodySm().copyWith(
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive ? evBlue : evTextSub,
                      ),
                    ),
                    if (isActive)
                      Container(
                        height: 3,
                        width: 24,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: evBlue,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  List<EventVolunteer> _getFilteredVolunteers() {
    return widget.ctrl.eventVolunteers
        .where((v) => v.status == selectedFilter)
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────
//  VOLUNTEER CARD
// ─────────────────────────────────────────────────────────────
class VolunteerCard extends StatelessWidget {
  final EventVolunteer volunteer;
  final OrgEventsController ctrl;
  final VoidCallback onAction;

  const VolunteerCard({
    required this.volunteer,
    required this.ctrl,
    required this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: evBorder),
        borderRadius: evR10,
        color: evSurf2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with profile info ─────────────────────
          Row(
            children: [
              // Profile picture
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: evBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: volunteer.userId.profilePicture != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          volunteer.userId.profilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              volunteer.userId.name[0].toUpperCase(),
                              style: evHeadingMd().copyWith(color: evBlue),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          volunteer.userId.name[0].toUpperCase(),
                          style: evHeadingMd().copyWith(color: evBlue),
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Volunteer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteer.userId.name,
                      style: evBodySm().copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      volunteer.userId.email,
                      style: evMono().copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status badge
              EventStatusBadge(status: volunteer.status),
            ],
          ),

          // ── Skills & Contact ─────────────────────────────
          if (volunteer.userId.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: volunteer.userId.skills.take(3).map((skill) {
                return EventTag(label: skill, color: evBlue);
              }).toList(),
            ),
          ],

          if (volunteer.userId.phone != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_rounded, size: 14, color: evTextMute),
                const SizedBox(width: 6),
                Text(
                  volunteer.userId.phone!,
                  style: evBodyXs().copyWith(color: evTextSub),
                ),
              ],
            ),
          ],

          // ── Applied date ──────────────────────────────────
          const SizedBox(height: 8),
          Text(
            'Applied on ${_formatDate(volunteer.appliedAt)}',
            style: evBodyXs().copyWith(color: evTextMute),
          ),

          // ── Action buttons ────────────────────────────────
          const SizedBox(height: 12),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Obx(() {
      final isLoading = ctrl.volunteerActionLoading.contains(volunteer.id);

      switch (volunteer.status) {
        case 'pending':
          return Row(
            children: [
              Expanded(
                child: EventBtn(
                  label: 'Reject',
                  ghost: true,
                  accentColor: evRed,
                  loading: isLoading,
                  onTap: isLoading
                      ? null
                      : () => _showRejectDialog(Get.context!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: EventBtn(
                  label: 'Approve',
                  accentColor: evGreen,
                  loading: isLoading,
                  onTap: isLoading ? null : () => _approveVolunteer(),
                ),
              ),
              const SizedBox(width: 8),
              EventBtn(
                label: 'View Profile',
                icon: Icons.person,
                ghost: true,
                onTap: () => _showProfileDialog(),
                accentColor: evBlue,
              ),
            ],
          );

        case 'approved':
          return Row(
            children: [
              Expanded(
                child: EventBtn(
                  label: 'Mark Attended',
                  accentColor: evBlue,
                  loading: isLoading,
                  onTap: isLoading ? null : () => _markAttended(),
                ),
              ),
              const SizedBox(width: 8),
              EventBtn(
                label: 'View Profile',
                icon: Icons.person,
                ghost: true,
                onTap: () => _showProfileDialog(),
                accentColor: evBlue,
              ),
            ],
          );

        default:
          return EventBtn(
            label: 'View Profile',

            icon: Icons.person,
            ghost: true,
            onTap: () => _showProfileDialog(),
            accentColor: evBlue,
          );
      }
    });
  }

  void _approveVolunteer() {
    ctrl
        .updateVolunteerStatus(
          ctrl.selectedEvent.value?.id ?? '',
          volunteer.id,
          'approved',
        )
        .then((_) => onAction());
  }

  void _markAttended() {
    ctrl
        .updateVolunteerStatus(
          ctrl.selectedEvent.value?.id ?? '',
          volunteer.id,
          'attended',
        )
        .then((_) => onAction());
  }

  void _showRejectDialog(BuildContext context) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: evSurf,
        title: Text('Reject Application?', style: evHeadingMd()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You can optionally add a note for the applicant',
              style: evBodyXs().copyWith(color: evTextSub),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              style: evBodySm(),
              decoration: InputDecoration(
                hintText: 'Rejection reason (optional)...',
                hintStyle: evBodySm().copyWith(color: evTextMute),
                border: OutlineInputBorder(
                  borderRadius: evR8,
                  borderSide: const BorderSide(color: evBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: evR8,
                  borderSide: BorderSide(color: evBlue.withOpacity(0.6)),
                ),
                filled: true,
                fillColor: evSurf2,
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: evBodySm()),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              ctrl
                  .updateVolunteerStatus(
                    ctrl.selectedEvent.value?.id ?? '',
                    volunteer.id,
                    'rejected',
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                  )
                  .then((_) => onAction());
            },
            child: Text('Reject', style: evBodySm().copyWith(color: evRed)),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: Get.context!,
      builder: (ctx) => VolunteerProfileDialog(volunteer: volunteer),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────
//  VOLUNTEER PROFILE DIALOG
// ─────────────────────────────────────────────────────────────
class VolunteerProfileDialog extends StatelessWidget {
  final EventVolunteer volunteer;

  const VolunteerProfileDialog({required this.volunteer, super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: evR12),
      backgroundColor: evSurf,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: evBlue.withOpacity(0.1),
                    borderRadius: evR12,
                  ),
                  child: volunteer.userId.profilePicture != null
                      ? ClipRRect(
                          borderRadius: evR12,
                          child: Image.network(
                            volunteer.userId.profilePicture!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            volunteer.userId.name[0].toUpperCase(),
                            style: evHeadingXl().copyWith(color: evBlue),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(volunteer.userId.name, style: evHeadingMd()),
                      EventStatusBadge(status: volunteer.status),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: evText),
                  onPressed: () => Get.back(),
                  iconSize: 20,
                ),
              ],
            ),

            const SizedBox(height: 20),
            EventDivider(),
            const SizedBox(height: 20),

            // ── Contact Info ──────────────────────────────────
            EventDetailRow(
              icon: Icons.email,
              label: 'Email',
              value: volunteer.userId.email,
            ),
            if (volunteer.userId.phone != null)
              EventDetailRow(
                icon: Icons.phone,
                label: 'Phone',
                value: volunteer.userId.phone!,
              ),

            const SizedBox(height: 20),

            // ── Bio ───────────────────────────────────────────
            if (volunteer.userId.bio != null &&
                volunteer.userId.bio!.isNotEmpty) ...[
              Text(
                'Bio',
                style: evBodySm().copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                volunteer.userId.bio!,
                style: evBodyXs().copyWith(color: evTextSub),
              ),
              const SizedBox(height: 20),
            ],

            // ── Skills ────────────────────────────────────────
            if (volunteer.userId.skills.isNotEmpty) ...[
              Text(
                'Skills',
                style: evBodySm().copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: volunteer.userId.skills
                    .map((skill) => EventTag(label: skill, color: evBlue))
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],

            // ── Timeline ──────────────────────────────────────
            Text(
              'Timeline',
              style: evBodySm().copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _buildTimelineItem(
              'Applied',
              _formatDateTime(volunteer.appliedAt),
              evAmber,
            ),
            if (volunteer.approvedAt != null)
              _buildTimelineItem(
                'Approved',
                _formatDateTime(volunteer.approvedAt!),
                evGreen,
              ),

            const SizedBox(height: 20),

            // ── Close Button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: EventBtn(
                label: 'Close',
                accentColor: evBlue,
                onTap: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String label, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text('$label: $time', style: evBodyXs().copyWith(color: evTextSub)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
