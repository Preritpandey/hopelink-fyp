import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RegistrationHeader extends StatelessWidget {
  const RegistrationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColorToken.primary.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.volunteer_activism_rounded,
            size: 50,
            color: AppColorToken.primary.color,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Create Account',
          style: AppTextStyle.h3.bold.copyWith(
            fontSize: 32,
            color: AppColorToken.primary.color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Join our community of volunteers',
          style: AppTextStyle.bodySmall.copyWith(
            color: Colors.grey[600],
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}