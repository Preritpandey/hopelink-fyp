import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/features/Auth/pages/login_page.dart';
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
          // return const ProfileShimmer();
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.user.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.user.value!;
        final phoneCtrl = TextEditingController(text: user.phone);
        final bioCtrl = TextEditingController(text: user.bio);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              Text(user.name, style: const TextStyle(fontSize: 18)),
              Text(user.email, style: const TextStyle(color: Colors.grey)),

              // const SectionTitle("Contact"),
              ProfileTextField(
                controller: phoneCtrl,
                label: "Phone",
                enabled: controller.isEditMode.value,
              ),

              // const SectionTitle("Bio"),
              ProfileTextField(
                controller: bioCtrl,
                label: "Bio",
                enabled: controller.isEditMode.value,
              ),

              // const SectionTitle("Interests"),
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

              const SectionTitle("Resume"),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LogoutButton(controller: controller),
              ),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user.cv.isEmpty
                            ? Colors.grey[300]
                            : AppColorToken.primary.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: const Text(
                        "View CV",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: user.cv.isEmpty ? null : () => openCV(user.cv),
                    ),
                  ),
                  if (controller.isEditMode.value) ...[
                    const SizedBox(width: 12),
                    Obx(
                      () => OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          side: BorderSide(color: Colors.blue[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: cvCtrl.uploading.value
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue[700],
                                ),
                              )
                            : const Icon(Icons.upload_file, size: 20),
                        label: Text(
                          cvCtrl.uploading.value ? "Uploading" : "Upload",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: cvCtrl.uploading.value
                            ? null
                            : () async {
                                final pdf = await Pickers.pickPDF();
                                if (pdf != null) {
                                  await cvCtrl.upload(pdf);
                                }
                              },
                      ),
                    ),
                  ],
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
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LogoutButton(controller: controller),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }
}

// Animated Logout Button with Confirmation Dialog
class _LogoutButton extends StatefulWidget {
  final ProfileController controller;
  const _LogoutButton({required this.controller});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPressed() {
    _showLogoutConfirmation();
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LogoutConfirmationDialog(onConfirm: _handleLogout),
    );
  }

  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Get.offAll(() => const LoginPage());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error logging out. Please try again.'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _animationController.forward(),
      onExit: (_) => _animationController.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) {
          _animationController.reverse();
          _onPressed();
        },
        onTapCancel: () => _animationController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[400]!, Colors.red[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red[400]!.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onPressed,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Beautiful Logout Confirmation Dialog
class _LogoutConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  const _LogoutConfirmationDialog({required this.onConfirm});

  @override
  State<_LogoutConfirmationDialog> createState() =>
      _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState extends State<_LogoutConfirmationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.pop(context);
      widget.onConfirm();
    }
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.white, const Color(0xFFF5F5F5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with animated background
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.red[100]!, Colors.orange[100]!],
                      ),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 40,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    "Logout?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    "Are you sure you want to logout?\nYou'll need to login again to access your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedButton(
                          label: "Cancel",
                          onPressed: _handleCancel,
                          isPrimary: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedButton(
                          label: "Logout",
                          onPressed: _handleConfirm,
                          isPrimary: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Animated Button Widget for Dialog Actions
class AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const AnimatedButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _animationController.forward(),
      onExit: (_) => _animationController.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) {
          _animationController.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _animationController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: widget.isPrimary
                  ? AppGradients.primaryGradient
                  : LinearGradient(
                      colors: [Colors.grey[300]!, Colors.grey[400]!],
                    ),
              boxShadow: [
                BoxShadow(
                  color:
                      (widget.isPrimary ? Colors.red[400] : Colors.grey[400])!
                          .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.isPrimary ? Colors.white : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
