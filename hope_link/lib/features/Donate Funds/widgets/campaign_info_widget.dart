// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:hope_link/core/extensions/num_extension.dart';
// import 'package:hope_link/core/theme/app_colors.dart';
// import 'package:hope_link/core/theme/app_text_styles.dart';

// import '../controllers/campaign_controller.dart';
// import '../models/campaign_model.dart';

// class CampaignInfoWidget extends StatelessWidget {
//   const CampaignInfoWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//   final CampaignController controller = Get.find<CampaignController>();
// Campaign campaign = controller.selectedCampaign.value;
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               if (campaign!.isFeatured)
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   margin: const EdgeInsets.only(right: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.amber.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: Colors.amber),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(
//                         Icons.star_rounded,
//                         size: 16,
//                         color: Colors.amber,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         'Featured',
//                         style: AppTextStyle.bodySmall.copyWith(
//                           color: Colors.amber[800],
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: campaign!.isActive
//                       ? Colors.green.withOpacity(0.1)
//                       : Colors.grey.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: campaign!.isActive ? Colors.green : Colors.grey,
//                   ),
//                 ),
//                 child: Text(
//                   campaign!.status.toUpperCase(),
//                   style: AppTextStyle.bodySmall.copyWith(
//                     color: campaign!.isActive
//                         ? Colors.green[700]
//                         : Colors.grey[700],
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           16.verticalSpace,
//           Text(
//             campaign!.title,
//             style: AppTextStyle.h4.copyWith(
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[900],
//             ),
//           ),
//           12.verticalSpace,
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: AppColorToken.primary.color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   Icons.business_rounded,
//                   size: 20,
//                   color: AppColorToken.primary.color,
//                 ),
//               ),
//               12.horizontalSpace,
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Organized by',
//                       style: AppTextStyle.bodySmall.copyWith(
//                         color: Colors.grey[500],
//                       ),
//                     ),
//                     2.verticalSpace,
//                     Text(
//                       campaign!.organization.organizationName,
//                       style: AppTextStyle.bodyMedium.copyWith(
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
