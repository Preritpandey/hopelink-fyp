import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../controllers/volunteer_leaderboard_controller.dart';
import '../models/volunteer_leaderboard_model.dart';

class VolunteerLeaderboardPage extends StatefulWidget {
  const VolunteerLeaderboardPage({super.key});

  @override
  State<VolunteerLeaderboardPage> createState() =>
      _VolunteerLeaderboardPageState();
}

class _VolunteerLeaderboardPageState extends State<VolunteerLeaderboardPage> {
  final String _tag = 'volunteer-leaderboard-full';
  late final VolunteerLeaderboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      VolunteerLeaderboardController(pageSize: 20),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<VolunteerLeaderboardController>(tag: _tag)) {
      Get.delete<VolunteerLeaderboardController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Volunteer Leaderboard',
          style: AppTextStyle.h4.copyWith(
            color: Colors.grey[900],
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Obx(() {
        final isInitialLoading =
            _controller.isLoading.value && !_controller.hasLoaded.value;
        final hasError = _controller.errorMessage.value.isNotEmpty &&
            _controller.entries.isEmpty;

        if (isInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (hasError) {
          return _FullPageMessage(
            icon: Icons.signal_wifi_connected_no_internet_4_rounded,
            title: 'Unable to load leaderboard',
            subtitle: _controller.errorMessage.value,
            actionLabel: 'Try Again',
            onPressed: _controller.refreshLeaderboard,
          );
        }

        if (_controller.entries.isEmpty) {
          return const _FullPageMessage(
            icon: Icons.emoji_events_outlined,
            title: 'No leaderboard entries yet',
            subtitle:
                'Once volunteers start earning credit hours, rankings will show up here.',
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.refreshLeaderboard,
          color: AppColorToken.primary.color,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _SummaryCard(controller: _controller),
              18.verticalSpace,
              ..._controller.entries.map(_FullLeaderboardTile.new),
              if (_controller.errorMessage.value.isNotEmpty &&
                  _controller.entries.isNotEmpty) ...[
                12.verticalSpace,
                Text(
                  _controller.errorMessage.value,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Colors.red[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_controller.hasMore) ...[
                16.verticalSpace,
                Center(
                  child: OutlinedButton(
                    onPressed: _controller.isLoadingMore.value
                        ? null
                        : _controller.loadMore,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColorToken.primary.color,
                      side: BorderSide(
                        color: AppColorToken.primary.color.withOpacity(0.22),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    child: _controller.isLoadingMore.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Load More',
                            style: AppTextStyle.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});

  final VolunteerLeaderboardController controller;

  @override
  Widget build(BuildContext context) {
    final pagination = controller.pagination.value;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF163A2A), Color(0xFF249B5A)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community impact leaders',
                  style: AppTextStyle.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                6.verticalSpace,
                Text(
                  'Ranked by volunteer credit hours, with points shown as a secondary score.',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.82),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          12.horizontalSpace,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Volunteers',
                  style: AppTextStyle.caption.copyWith(
                    color: Colors.white.withOpacity(0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.verticalSpace,
                Text(
                  '${pagination?.totalUsers ?? controller.entries.length}',
                  style: AppTextStyle.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

class _FullLeaderboardTile extends StatelessWidget {
  const _FullLeaderboardTile(this.entry);

  final VolunteerLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4ECE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColorToken.primary.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '#${entry.rank}',
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColorToken.primary.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          12.horizontalSpace,
          _Avatar(imageUrl: entry.profileImage, name: entry.name),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: Colors.grey[900],
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.email.isNotEmpty) ...[
                  3.verticalSpace,
                  Text(
                    entry.email,
                    style: AppTextStyle.caption.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          12.horizontalSpace,
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
              4.verticalSpace,
              Text(
                '${entry.totalPoints} pts',
                style: AppTextStyle.caption.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FullPageMessage extends StatelessWidget {
  const _FullPageMessage({
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.grey[500]),
            14.verticalSpace,
            Text(
              title,
              style: AppTextStyle.h4.copyWith(
                color: Colors.grey[900],
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            8.verticalSpace,
            Text(
              subtitle,
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.grey[600],
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onPressed != null) ...[
              14.verticalSpace,
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
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl,
          width: 46,
          height: 46,
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
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColorToken.primary.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        initial,
        style: AppTextStyle.bodyLarge.copyWith(
          color: AppColorToken.primary.color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
