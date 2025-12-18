import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/widgets/app_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';

import '../../../utils/pickers.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_image_controller.dart';
import '../controllers/profile_cv_controller.dart';

import '../widgets/profile_text_field.dart';
import '../widgets/section_title.dart';
import '../widgets/interest_chips.dart';
import '../widgets/location_bottom_sheet.dart';
import '../widgets/profile_shimmer.dart';

class ProfilePage extends StatefulWidget {
  final String token;
  const ProfilePage({super.key, required this.token});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileController controller;
  late final ProfileImageController imageCtrl;
  late final ProfileCVController cvCtrl;

  void openCV(String url) {
    OpenFilex.open(url);
  }

  @override
  void initState() {
    super.initState();
    controller = Get.put(ProfileController(widget.token));
    imageCtrl = Get.put(ProfileImageController(widget.token));
    cvCtrl = Get.put(ProfileCVController(widget.token));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.isEditMode.value ? Icons.close : Icons.edit,
              ),
              onPressed: controller.isLoading.value
                  ? null
                  : controller.toggleEdit,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ProfileShimmer();
        }

        final user = controller.user.value!;
        final phoneCtrl = TextEditingController(text: user.phone);
        final bioCtrl = TextEditingController(text: user.bio);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// PROFILE IMAGE
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        "${user.profileImage}?t=${DateTime.now().millisecondsSinceEpoch}",
                      ),
                    ),
                    if (controller.isEditMode.value)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Obx(
                          () => imageCtrl.uploading.value
                              ? Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: AppColorToken.error.color,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.camera_alt),
                                  onPressed: () async {
                                    final img = await Pickers.pickImage();
                                    if (img != null) {
                                      await imageCtrl.upload(img);
                                    }
                                  },
                                ),
                        ),
                      ),
                  ],
                ),
              ),

              const SectionTitle("Basic Info"),
              Text(user.name, style: const TextStyle(fontSize: 18)),
              Text(user.email, style: const TextStyle(color: Colors.grey)),

              const SectionTitle("Contact"),
              ProfileTextField(
                controller: phoneCtrl,
                label: "Phone",
                enabled: controller.isEditMode.value,
              ),

              const SectionTitle("Bio"),
              ProfileTextField(
                controller: bioCtrl,
                label: "Bio",
                enabled: controller.isEditMode.value,
              ),

              const SectionTitle("Interests"),
              InterestChips(
                allInterests: const [
                  "Education",
                  "Environment",
                  "Healthcare",
                  "Technology",
                  "Social Work",
                ],
                selected: user.interest,
                editable: controller.isEditMode.value,
                onChanged: controller.updateInterests,
              ),

              const SectionTitle("Location"),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("${user.location.city}, ${user.location.country}"),
                subtitle: Text(user.location.address),
                trailing: controller.isEditMode.value
                    ? const Icon(Icons.edit)
                    : null,
                onTap: controller.isEditMode.value
                    ? () async {
                        final updated = await showLocationEditor(
                          context,
                          user.location,
                        );
                        if (updated != null) {
                          controller.updateProfile({
                            "location": updated.toJson(),
                          });
                        }
                      }
                    : null,
              ),

              const SectionTitle("Curriculum Vitae"),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("View CV"),
                    onPressed: user.cv.isEmpty ? null : () => openCV(user.cv),
                  ),
                  const SizedBox(width: 12),
                  if (controller.isEditMode.value)
                    TextButton(
                      onPressed: () async {
                        final pdf = await Pickers.pickPDF();
                        if (pdf != null) {
                          await cvCtrl.upload(pdf);
                        }
                      },
                      child: const Text("Upload New"),
                    ),
                ],
              ),

              if (controller.isEditMode.value)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.updateProfile({
                          "phone": phoneCtrl.text,
                          "bio": bioCtrl.text,
                          "interest": user.interest,
                        });
                      },
                      child: const Text("Save Changes"),
                    ),
                  ),
                ),
              30.verticalSpace,
              AppButton(
                title: "Logout",
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Get.offAllNamed('/login');
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
