import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/features/Profile/controllers/saved_causes_controller.dart';

class SaveCauseButton extends StatelessWidget {
  final String postType;
  final String postId;
  final bool isSaved;
  final VoidCallback? onChangedToSaved;
  final ValueChanged<bool>? onChanged;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;

  const SaveCauseButton({
    super.key,
    required this.postType,
    required this.postId,
    required this.isSaved,
    this.onChangedToSaved,
    this.onChanged,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SavedCausesController>()
        ? Get.find<SavedCausesController>()
        : Get.put(SavedCausesController());

    return Obx(() {
      final isBusy = controller.isBusy(postId);

      return GestureDetector(
        onTap: isBusy
            ? null
            : () async {
                final nextState = await controller.toggleSaved(
                  postType: postType,
                  postId: postId,
                  currentlySaved: isSaved,
                );
                if (nextState && onChangedToSaved != null) {
                  onChangedToSaved!();
                }
                onChanged?.call(nextState);
              },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: isBusy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: activeColor ?? AppColorToken.primary.color,
                    ),
                  )
                : Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 20,
                    color: isSaved
                        ? (activeColor ?? AppColorToken.primary.color)
                        : (inactiveColor ?? Colors.grey[700]),
                  ),
          ),
        ),
      );
    });
  }
}
