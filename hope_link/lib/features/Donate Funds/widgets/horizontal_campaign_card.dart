import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import '../models/campaign_model.dart';
import 'post_interaction_summary.dart';
import 'save_cause_button.dart';

class HorizontalCampaignCard extends StatelessWidget {
  final Campaign campaign;
  final int index;
  final AnimationController? animationController;

  const HorizontalCampaignCard({
    super.key,
    required this.campaign,
    required this.index,
    this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth >= 900
        ? 360.0
        : screenWidth >= 600
        ? 330.0
        : (screenWidth - 72).clamp(280.0, 340.0).toDouble();
    final isCompact = cardWidth <= 320;
    final cardHeight = isCompact ? 398.0 : 418.0;

    final card = GestureDetector(
      onTap: () => Get.toNamed('/campaign-details', arguments: campaign.id),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.only(left: index == 0 ? 24 : 12, right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColorToken.primary.color.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageSection(isCompact: isCompact),
            Expanded(child: contentSection(isCompact: isCompact)),
          ],
        ),
      ),
    );

    if (animationController != null) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index * 0.1) + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: card,
      );
    }

    return card;
  }

  Widget imageSection({required bool isCompact}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: campaign.images.isNotEmpty
              ? Image.network(
                  campaign.images[0],
                  height: isCompact ? 156 : 172,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage(isCompact: isCompact);
                  },
                )
              : _buildPlaceholderImage(isCompact: isCompact),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.08),
                  Colors.transparent,
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
        ),
        if (campaign.isFeatured)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        Positioned(
          top: 12,
          left: 12,
          child: SaveCauseButton(
            postType: 'campaign',
            postId: campaign.id,
            isSaved: campaign.isSavedByCurrentUser,
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: _buildTopChip(
            icon: Icons.schedule_rounded,
            label: campaign.daysRemaining > 0
                ? '${campaign.daysRemaining} days left'
                : 'Closing soon',
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage({required bool isCompact}) {
    return Container(
      height: isCompact ? 156 : 172,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorToken.primary.color.withOpacity(0.2),
            AppColorToken.primary.color.withOpacity(0.1),
          ],
        ),
      ),
      child: Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
    );
  }

  Widget contentSection({required bool isCompact}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 14 : 16,
        isCompact ? 12 : 16,
        isCompact ? 14 : 16,
        isCompact ? 14 : 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMetaPill(
                icon: Icons.auto_graph_rounded,
                label: '${campaign.progress.toStringAsFixed(0)}% funded',
                highlight: true,
                compact: isCompact,
              ),
              _buildMetaPill(
                icon: Icons.update_rounded,
                label: '${campaign.updates.length} updates',
                compact: isCompact,
              ),
              if (campaign.tags.isNotEmpty)
                _buildMetaPill(
                  icon: Icons.label_outline_rounded,
                  label: '${campaign.tags.length} tags',
                  compact: isCompact,
                ),
            ],
          ),
          (isCompact ? 10 : 14).verticalSpace,
          Text(
            campaign.title,
            style: AppTextStyle.h5.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.grey[900],
              height: 1.25,
              fontSize: isCompact ? 13 : 14,
            ),
            maxLines: isCompact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          6.verticalSpace,
          Text(
            campaign.description,
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.grey[600],
              height: 1.45,
              fontSize: isCompact ? 11 : 12,
            ),
            maxLines: isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          (isCompact ? 10 : 12).verticalSpace,
          _buildProgressSection(compact: isCompact),
          const Spacer(),
          10.verticalSpace,
          Row(
            children: [
              PostInteractionSummary(
                totalLikes: campaign.totalLikes,
                commentsCount: campaign.commentsCount,
                accentColor: AppColorToken.primary.color,
                compact: true,
              ),
              8.horizontalSpace,
              Expanded(
                child: _buildVerifiedOrganizationTag(compact: isCompact),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection({required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppColorToken.primary.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _formatCurrency(campaign.currentAmount),
                  style: AppTextStyle.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColorToken.primary.color,
                    fontSize: compact ? 12 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                campaign.hasEnded
                    ? 'Closed'
                    : '${campaign.progress.toStringAsFixed(0)}%',
                style: AppTextStyle.bodySmall.copyWith(
                  color: campaign.hasEnded ? Colors.red[400] : Colors.grey[700],
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : 12,
                ),
              ),
            ],
          ),

          (compact ? 2 : 4).verticalSpace,
          Text(
            'of ${_formatCurrency(campaign.targetAmount)} funded',
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.grey[500],
              fontSize: compact ? 10 : 11,
            ),
          ),
          (compact ? 6 : 8).verticalSpace,
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (campaign.progress / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColorToken.primary.color,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'NPR ${formatter.format(amount)}';
  }

  Widget _buildTopChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          4.horizontalSpace,
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({
    required IconData icon,
    required String label,
    bool highlight = false,
    required bool compact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? AppColorToken.primary.color.withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 12 : 14,
            color: highlight ? AppColorToken.primary.color : Colors.grey[700],
          ),
          6.horizontalSpace,
          Text(
            label,
            style: AppTextStyle.caption.copyWith(
              color: highlight ? AppColorToken.primary.color : Colors.grey[700],
              fontWeight: FontWeight.w700,
              fontSize: compact ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedOrganizationTag({required bool compact}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.toNamed(
        '/organization-profile',
        arguments: campaign.organization.id,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: AppColorToken.primary.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                size: compact ? 14 : 15,
                color: AppColorToken.primary.color,
              ),
              5.horizontalSpace,
              Flexible(
                child: Text(
                  campaign.organization.organizationName,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColorToken.primary.color,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 10 : 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
