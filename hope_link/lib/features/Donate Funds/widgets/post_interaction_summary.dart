import 'package:flutter/material.dart';

import '../../../core/extensions/num_extension.dart';
import '../../../core/theme/app_text_styles.dart';

class PostInteractionSummary extends StatelessWidget {
  const PostInteractionSummary({
    super.key,
    required this.totalLikes,
    required this.commentsCount,
    required this.accentColor,
    this.compact = false,
  });

  final int totalLikes;
  final int commentsCount;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 14.0 : 16.0;
    final spacing = compact ? 6.0 : 8.0;
    final textStyle = compact
        ? AppTextStyle.bodySmall.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 11,
          )
        : AppTextStyle.bodySmall.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          );

    return Row(
      children: [
        Icon(Icons.favorite_rounded, size: iconSize, color: accentColor),
        spacing.horizontalSpace,
        Text(
          '$totalLikes',
          style: textStyle,
        ),
        (compact ? 10.0 : 14.0).horizontalSpace,
        Icon(Icons.chat_bubble_rounded, size: iconSize, color: accentColor),
        spacing.horizontalSpace,
        Text(
          '$commentsCount',
          style: textStyle,
        ),
      ],
    );
  }
}
