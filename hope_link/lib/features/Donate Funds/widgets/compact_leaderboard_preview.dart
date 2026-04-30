import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../controllers/volunteer_leaderboard_controller.dart';
import '../models/volunteer_leaderboard_model.dart';

class CompactLeaderboardPreview extends StatelessWidget {
  const CompactLeaderboardPreview({
    super.key,
    required this.controller,
    required this.onViewFullLeaderboard,
  });

  final VolunteerLeaderboardController controller;
  final VoidCallback onViewFullLeaderboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5EFE8)),
          boxShadow: [
            BoxShadow(
              color: AppColorToken.primary.color.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Obx(() {
          final items = controller.entries;
          final isInitialLoading =
              controller.isLoading.value && !controller.hasLoaded.value;
          final hasError = controller.errorMessage.value.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Volunteers',
                          style: AppTextStyle.h4.copyWith(
                            color: Colors.grey[900],
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        4.verticalSpace,
                        Text(
                          'A quick look at this week\'s leaders.',
                          style: AppTextStyle.bodySmall.copyWith(
                            color: Colors.grey[600],
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  12.horizontalSpace,
                  TextButton(
                    onPressed: onViewFullLeaderboard,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColorToken.primary.color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'View Full',
                      style: AppTextStyle.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              14.verticalSpace,
              if (isInitialLoading) _LeaderboardLoadingState(),
              if (!isInitialLoading && hasError)
                _LeaderboardMessageState(
                  icon: Icons.signal_wifi_connected_no_internet_4_rounded,
                  title: 'Leaderboard unavailable',
                  subtitle: controller.errorMessage.value,
                  actionLabel: 'Retry',
                  onPressed: controller.refreshLeaderboard,
                ),
              if (!isInitialLoading && !hasError && items.isEmpty)
                _LeaderboardMessageState(
                  icon: Icons.emoji_events_outlined,
                  title: 'No leaders yet',
                  subtitle: 'Volunteer rankings will appear once credits start rolling in.',
                ),
              if (!isInitialLoading && !hasError && items.isNotEmpty) ...[
                ...items.take(3).map(_LeaderboardTile.new),
                10.verticalSpace,
                _FooterRow(
                  totalUsers: controller.pagination.value?.totalUsers ?? items.length,
                  onViewFullLeaderboard: onViewFullLeaderboard,
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile(this.entry);

  final VolunteerLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBF9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EFE9)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _rankBackground(entry.rank),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '#${entry.rank}',
                style: AppTextStyle.caption.copyWith(
                  color: _rankForeground(entry.rank),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            10.horizontalSpace,
            _Avatar(imageUrl: entry.profileImage, name: entry.name),
            10.horizontalSpace,
            Expanded(
              child: Text(
                entry.name,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            10.horizontalSpace,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.totalCreditHours} hrs',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColorToken.primary.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                2.verticalSpace,
                Text(
                  '${entry.totalPoints} pts',
                  style: AppTextStyle.caption.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _rankBackground(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFF4CC);
      case 2:
        return const Color(0xFFEEF2F7);
      case 3:
        return const Color(0xFFFCE7D7);
      default:
        return AppColorToken.primary.color.withOpacity(0.1);
    }
  }

  Color _rankForeground(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFB7791F);
      case 2:
        return const Color(0xFF475569);
      case 3:
        return const Color(0xFFC05621);
      default:
        return AppColorToken.primary.color;
    }
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.totalUsers,
    required this.onViewFullLeaderboard,
  });

  final int totalUsers;
  final VoidCallback onViewFullLeaderboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColorToken.primary.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$totalUsers volunteers ranked',
            style: AppTextStyle.caption.copyWith(
              color: AppColorToken.primary.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onViewFullLeaderboard,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Show More',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.horizontalSpace,
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.grey[800],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardLoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : 10),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F6),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardMessageState extends StatelessWidget {
  const _LeaderboardMessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EFE9)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.grey[500]),
          10.verticalSpace,
          Text(
            title,
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.grey[900],
              fontWeight: FontWeight.w800,
            ),
          ),
          6.verticalSpace,
          Text(
            subtitle,
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onPressed != null) ...[
            12.verticalSpace,
            TextButton(
              onPressed: onPressed,
              child: Text(
                actionLabel!,
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColorToken.primary.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl, required this.name});

  final String imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    final initial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColorToken.primary.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        initial,
        style: AppTextStyle.bodyMedium.copyWith(
          color: AppColorToken.primary.color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
