import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/features/Profile/controllers/saved_causes_controller.dart';
import 'package:hope_link/features/Profile/models/saved_cause_model.dart';
import 'package:intl/intl.dart';

import '../../Donate Funds/pages/event_details_page.dart';
import '../../Donate Funds/widgets/save_cause_button.dart';

class SavedCausesPage extends StatelessWidget {
  const SavedCausesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SavedCausesController>()
        ? Get.find<SavedCausesController>()
        : Get.put(SavedCausesController());

    if (!controller.isLoading.value &&
        controller.savedCauses.isEmpty &&
        controller.errorMessage.value.isEmpty) {
      Future.microtask(controller.fetchSavedCauses);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Saved Causes',
          style: AppTextStyle.h4.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey[900]),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColorToken.primary.color,
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.savedCauses.isEmpty) {
          return _StateMessage(
            title: 'Could not load saved causes',
            subtitle: controller.errorMessage.value,
            actionLabel: 'Try Again',
            onTap: controller.fetchSavedCauses,
          );
        }

        if (controller.savedCauses.isEmpty) {
          return _StateMessage(
            title: 'Nothing saved yet',
            subtitle:
                'Bookmark campaigns, events, and volunteer roles to build your personal shortlist here.',
            actionLabel: 'Refresh',
            onTap: controller.fetchSavedCauses,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchSavedCauses,
          color: AppColorToken.primary.color,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: controller.savedCauses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = controller.savedCauses[index];
              return _SavedCauseTile(entry: entry);
            },
          ),
        );
      }),
    );
  }
}

class _SavedCauseTile extends StatelessWidget {
  final SavedCauseEntry entry;

  const _SavedCauseTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _openEntry,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _TypeBadge(postType: entry.postType),
                        Text(
                          'Saved ${DateFormat('MMM d, yyyy').format(entry.savedAt)}',
                          style: AppTextStyle.bodySmall.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SaveCauseButton(
                    postType: entry.postType,
                    postId: entry.postId,
                    isSaved: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.title,
                style: AppTextStyle.h4.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: Colors.grey[700],
                  height: 1.45,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _metaLine,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColorToken.primary.color,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    switch (entry.postType) {
      case 'campaign':
        return entry.campaign?.description ?? '';
      case 'event':
        return entry.event?.description ?? '';
      case 'volunteerJob':
        return entry.volunteerJob?.description ?? '';
      default:
        return '';
    }
  }

  String get _metaLine {
    switch (entry.postType) {
      case 'campaign':
        return entry.campaign?.organization.organizationName ?? 'Campaign';
      case 'event':
        return entry.event?.organizer.organizationName.isNotEmpty == true
            ? entry.event!.organizer.organizationName
            : entry.event?.location.city ?? 'Event';
      case 'volunteerJob':
        return entry.volunteerJob?.organizationName ?? 'Volunteer Opportunity';
      default:
        return '';
    }
  }

  void _openEntry() {
    switch (entry.postType) {
      case 'campaign':
        if (entry.campaign != null) {
          Get.toNamed('/campaign-details', arguments: entry.campaign);
        }
        break;
      case 'event':
        if (entry.event != null) {
          Get.to(() => EventDetailsPage(event: entry.event!));
        }
        break;
      case 'volunteerJob':
        if (entry.volunteerJob != null) {
          Get.toNamed('/volunteer-job-details', arguments: entry.volunteerJob);
        }
        break;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String postType;

  const _TypeBadge({required this.postType});

  @override
  Widget build(BuildContext context) {
    Color color = AppColorToken.primary.color;
    String label = 'Saved';

    switch (postType) {
      case 'campaign':
        color = const Color(0xFF0E9F6E);
        label = 'Campaign';
        break;
      case 'event':
        color = const Color(0xFF2563EB);
        label = 'Event';
        break;
      case 'volunteerJob':
        color = const Color(0xFFF59E0B);
        label = 'Volunteer Role';
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyle.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final Future<void> Function() onTap;

  const _StateMessage({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColorToken.primary.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.bookmarks_outlined,
                color: AppColorToken.primary.color,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: AppTextStyle.h4.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyle.bodyMedium.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorToken.primary.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
