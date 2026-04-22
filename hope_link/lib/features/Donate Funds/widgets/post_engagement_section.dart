import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/num_extension.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/post_interactions_controller.dart';
import '../models/post_interaction_models.dart';
import 'post_interaction_summary.dart';

class PostEngagementSection extends StatelessWidget {
  const PostEngagementSection({
    super.key,
    required this.controller,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });

  final PostInteractionsController controller;
  final Color accentColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.forum_rounded, color: accentColor),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[900],
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      subtitle,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          18.verticalSpace,
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _ActionPill(
                    label: controller.interaction.value.isLikedByCurrentUser
                        ? 'Liked'
                        : 'Like',
                    count: controller.interaction.value.totalLikes,
                    icon: controller.interaction.value.isLikedByCurrentUser
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    active: controller.interaction.value.isLikedByCurrentUser,
                    accentColor: accentColor,
                    loading: controller.isTogglingLike.value,
                    onTap: controller.toggleLike,
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: accentColor,
                        ),
                        10.horizontalSpace,
                        Expanded(
                          child: Text(
                            '${controller.interaction.value.commentsCount} comments',
                            style: AppTextStyle.bodyMedium.copyWith(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          18.verticalSpace,
          Obx(
            () => PostInteractionSummary(
              totalLikes: controller.interaction.value.totalLikes,
              commentsCount: controller.interaction.value.commentsCount,
              accentColor: accentColor,
            ),
          ),
          20.verticalSpace,
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.commentController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Write something thoughtful...',
                      hintStyle: AppTextStyle.bodyMedium.copyWith(
                        color: Colors.grey[500],
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                12.horizontalSpace,
                Obx(
                  () => GestureDetector(
                    onTap: controller.isSubmittingComment.value
                        ? null
                        : controller.submitComment,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: controller.isSubmittingComment.value
                            ? accentColor.withOpacity(0.5)
                            : accentColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: controller.isSubmittingComment.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          20.verticalSpace,
          Obx(() {
            if (controller.isLoadingComments.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.commentsError.value.isNotEmpty &&
                controller.comments.isEmpty) {
              return _EmptyCommentState(
                icon: Icons.cloud_off_rounded,
                title: 'Comments unavailable',
                subtitle: controller.commentsError.value,
              );
            }

            if (controller.comments.isEmpty) {
              return const _EmptyCommentState(
                icon: Icons.mark_chat_unread_rounded,
                title: 'Start the conversation',
                subtitle: 'Be the first person to leave a comment here.',
              );
            }

            return Column(
              children: controller.comments
                  .map(
                    (comment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CommentTile(
                        comment: comment,
                        accentColor: accentColor,
                        onDelete: comment.isOwner
                            ? () => controller.deleteOwnComment(comment)
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.count,
    required this.icon,
    required this.active,
    required this.accentColor,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool active;
  final Color accentColor;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: active ? accentColor : accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: active ? Colors.white : accentColor,
                ),
              )
            else
              Icon(icon, color: active ? Colors.white : accentColor),
            10.horizontalSpace,
            Flexible(
              child: Text(
                '$label - $count',
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: active ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.accentColor,
    this.onDelete,
  });

  final PostComment comment;
  final Color accentColor;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, h:mm a');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: accentColor.withOpacity(0.14),
            backgroundImage:
                comment.user.profileImage != null &&
                    comment.user.profileImage!.isNotEmpty &&
                    !comment.user.profileImage!.startsWith('file://')
                ? NetworkImage(comment.user.profileImage!)
                : null,
            child:
                (comment.user.profileImage == null ||
                    comment.user.profileImage!.isEmpty)
                ? Text(
                    comment.user.name.isNotEmpty
                        ? comment.user.name[0].toUpperCase()
                        : 'H',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.user.name,
                        style: AppTextStyle.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                    Text(
                      formatter.format(comment.createdAt),
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                8.verticalSpace,
                Text(
                  comment.text,
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null) ...[
            8.horizontalSpace,
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red[400],
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCommentState extends StatelessWidget {
  const _EmptyCommentState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Colors.grey[400]),
          12.verticalSpace,
          Text(
            title,
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.grey[800],
              fontWeight: FontWeight.w700,
            ),
          ),
          6.verticalSpace,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
