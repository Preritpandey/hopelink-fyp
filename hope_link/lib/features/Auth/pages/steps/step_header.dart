
import 'package:flutter/material.dart';
import 'package:hope_link/core/theme/app_colors.dart';

class StepHeader extends StatelessWidget {
  final int currentStep;
  final Function(int) onStepSelected;

  const StepHeader({
    super.key,
    required this.currentStep,
    required this.onStepSelected,
  });

  final steps = const [
    "General",
    "Socials",
    "Representative",
    "Bank",
    "Documents",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: AppColors.black12),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(steps.length, (index) {
          final active = index == currentStep;

          return GestureDetector(
            onTap: () => onStepSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: active ? AppColors.blue : AppColors.grey200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                steps[index],
                style: TextStyle(
                  color: active ? AppColors.white : AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}



