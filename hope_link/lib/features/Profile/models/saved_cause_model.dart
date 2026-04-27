import 'package:hope_link/features/Donate%20Funds/models/campaign_model.dart';
import 'package:hope_link/features/Donate%20Funds/models/event_model.dart';
import 'package:hope_link/features/Donate%20Funds/models/volunteer_job_model.dart';

class SavedCauseEntry {
  final String id;
  final String postId;
  final String postType;
  final DateTime savedAt;
  final Campaign? campaign;
  final Event? event;
  final VolunteerJob? volunteerJob;

  const SavedCauseEntry({
    required this.id,
    required this.postId,
    required this.postType,
    required this.savedAt,
    this.campaign,
    this.event,
    this.volunteerJob,
  });

  factory SavedCauseEntry.fromJson(Map<String, dynamic> json) {
    final postType = json['postType']?.toString() ?? '';
    final postJson = Map<String, dynamic>.from(json['post'] ?? const {});

    return SavedCauseEntry(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      postType: postType,
      savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      campaign: postType == 'campaign' ? Campaign.fromJson(postJson) : null,
      event: postType == 'event' ? Event.fromJson(postJson) : null,
      volunteerJob: postType == 'volunteerJob'
          ? VolunteerJob.fromJson(postJson)
          : null,
    );
  }

  String get title {
    switch (postType) {
      case 'campaign':
        return campaign?.title ?? '';
      case 'event':
        return event?.title ?? '';
      case 'volunteerJob':
        return volunteerJob?.title ?? '';
      default:
        return '';
    }
  }
}
