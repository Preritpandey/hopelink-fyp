import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../controllers/campaign_controller.dart';

// // ignore: must_be_immutable
// class SearchFilterChip extends StatelessWidget {
//   CampaignController campaignController;
//   String label;
//   String value;
//   SearchFilterChip({
//     super.key,
//     required this.campaignController,
//     required this.label,
//     required this.value,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final isSelected = campaignController.selectedFilter.value == value;

//       return GestureDetector(
//         onTap: () => campaignController.setFilter(value),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           decoration: BoxDecoration(
//             color: isSelected ? AppColorToken.primary.color : Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: isSelected
//                   ? AppColorToken.primary.color
//                   : Colors.grey.withOpacity(0.3),
//             ),
//             boxShadow: isSelected
//                 ? [
//                     BoxShadow(
//                       color: AppColorToken.primary.color.withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ]
//                 : [],
//           ),
//           child: Text(
//             label,
//             style: AppTextStyle.bodySmall.copyWith(
//               color: isSelected ? Colors.white : Colors.grey[700],
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//             ),
//           ),
//         ),
//       );
//     });
//   }
// }
class SearchFilterChip extends StatelessWidget {
  // final CampaignController campaignController;
  final String label;
  final String value;

  const SearchFilterChip({
    super.key,
    // required this.campaignController,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
        final campaignController = Get.find<CampaignController>();

    return Obx(() {
      final isSelected = campaignController.selectedFilter.value == value;

      return GestureDetector(
        onTap: () => campaignController.setFilter(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColorToken.primary.color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColorToken.primary.color
                  : Colors.grey.withOpacity(0.3),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColorToken.primary.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
    });
  }
}
