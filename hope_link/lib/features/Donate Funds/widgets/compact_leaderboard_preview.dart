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
          color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.08),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Obx(() {
          final items = controller.entries.take(2).toList();
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
                          'Community Heroes',
                          style: AppTextStyle.h4.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        4.verticalSpace,
                        Text(
                          'Top volunteers of the week',
                          style: AppTextStyle.bodySmall.copyWith(
                            color: AppColors.grey700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              16.verticalSpace,
              if (isInitialLoading) const _LeaderboardLoadingState(),
              if (!isInitialLoading && hasError)
                _LeaderboardMessageState(
                  icon: Icons.signal_wifi_connected_no_internet_4_rounded,
                  title: 'Leaderboard unavailable',
                  subtitle: controller.errorMessage.value,
                  actionLabel: 'Retry',
                  onPressed: controller.refreshLeaderboard,
                ),
              if (!isInitialLoading && !hasError && items.isEmpty)
                const _LeaderboardMessageState(
                  icon: Icons.emoji_events_outlined,
                  title: 'No leaders yet',
                  subtitle:
                      'Volunteer rankings will appear once credits start rolling in.',
                ),
              if (!isInitialLoading && !hasError && items.isNotEmpty) ...[
                ...items.map(_LeaderboardTile.new),
                14.verticalSpace,

                _FooterButton(onViewFullLeaderboard: onViewFullLeaderboard),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.black12,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _rankBackground(entry.rank),
                shape: BoxShape.circle,
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
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.name,
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: AppColors.grey900,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  2.verticalSpace,
                  Text(
                    'Community volunteer',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            10.horizontalSpace,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${entry.totalCreditHours} hrs',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                2.verticalSpace,
                Text(
                  '${entry.totalPoints} points',
                  style: AppTextStyle.caption.copyWith(
                    color: AppColors.grey600,
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
        return AppColors.warningLight;
      case 2:
        return AppColors.inputFill;
      case 3:
        return AppColors.amberLight;
      default:
        return AppColors.primarySoft;
    }
  }

  Color _rankForeground(int rank) {
    switch (rank) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.grey600;
      case 3:
        return AppColors.orangeDark;
      default:
        return AppColors.primaryDark;
    }
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.onViewFullLeaderboard});

  final VoidCallback onViewFullLeaderboard;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onViewFullLeaderboard,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Show More',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              8.horizontalSpace,
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardLoadingState extends StatelessWidget {
  const _LeaderboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 1 ? 0 : 12),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.white,
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.grey500),
          10.verticalSpace,
          Text(
            title,
            style: AppTextStyle.bodyMedium.copyWith(
              color: AppColors.grey900,
              fontWeight: FontWeight.w800,
            ),
          ),
          6.verticalSpace,
          Text(
            subtitle,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.grey600,
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
    final fallback = _fallback();
    if (imageUrl.isEmpty) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Image.network(
        imageUrl,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  Widget _fallback() {
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTextStyle.bodyMedium.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
