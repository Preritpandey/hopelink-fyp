import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/features/Auth/pages/login_page.dart';
import 'package:hope_link/features/Profile/controllers/profile_controller.dart';
import 'package:hope_link/features/Profile/pages/profile_edit_page.dart';
import 'package:hope_link/features/Profile/pages/profile_page.dart';
import 'package:hope_link/features/Profile/widgets/full_screen_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileViewPage extends StatelessWidget {
  final String token;

  const ProfileViewPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController(token));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColorToken.primary.color,
            ),
          );
        }

        if (controller.user.value == null) {
          return const Center(child: Text('Unable to load profile'));
        }

        final user = controller.user.value!;

        return CustomScrollView(
          slivers: [
            _buildAppBar(context, user),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  10.verticalSpace,
                  _buildProfileHeader(user),
                  16.verticalSpace,

                  _buildInfoSection(user),
                  16.verticalSpace,

                  _buildInterestsSection(user),
                  16.verticalSpace,

                  _buildDocumentsSection(user),
                  16.verticalSpace,
                  _buildLogoutButton(controller),

                  // 30.verticalSpace,
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // -------------------- APP BAR --------------------

  // In _buildAppBar method:
  Widget _buildAppBar(BuildContext context, user) {
    return SliverAppBar(
      expandedHeight: 200, // Increased height
      pinned: true,
      backgroundColor: AppColorToken.primary.color,
      flexibleSpace: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColorToken.primary.color,
                  AppColorToken.primary.color.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          // Centered profile avatar
          Center(
            child: Transform.translate(
              offset: const Offset(0, 20), // Adjust vertical position
              child: _buildProfileAvatar(
                user,
              ), // This will be our larger avatar
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white),
            ),
            onPressed: () {
              Get.to(
                () => ProfileEditPage(token: token),
                transition: Transition.rightToLeft,
              );
            },
          ),
        ),
      ],
    );
  }

  // Update _buildProfileAvatar method:
  Widget _buildProfileAvatar(user) {
    return Hero(
      tag: 'profile_image',
      child: GestureDetector(
        onTap: user.profileImage.isEmpty
            ? null
            : () {
                Get.to(
                  () => FullScreenImageView(imageUrl: user.profileImage),
                  transition: Transition.fadeIn,
                );
              },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 70, // Increased size
            backgroundColor: Colors.grey[200],
            backgroundImage: user.profileImage.isNotEmpty
                ? NetworkImage(user.profileImage)
                : null,
            child: user.profileImage.isEmpty
                ? Icon(Icons.person, size: 70, color: Colors.grey[400])
                : null,
          ),
        ),
      ),
    );
  }

  // -------------------- HEADER -----------------
  Widget _buildProfileHeader(user) {
    return Column(
      children: [
        Text(
          user.name,
          style: AppTextStyle.h2.bold.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(user.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.status.toUpperCase(),
            style: AppTextStyle.bodySmall.copyWith(
              color: _getStatusColor(user.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------- INFO SECTION --------------------

  Widget _buildInfoSection(user) {
    return _cardWrapper(
      title: 'Personal Information',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _infoRow(Icons.phone, 'Phone', user.phone),
          const Divider(),
          _infoRow(Icons.wc, 'Gender', user.gender),
          const Divider(),
          _infoRow(
            Icons.location_on,
            'Location',
            '${user.location.city}, ${user.location.country}',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyle.bodySmall.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(value, style: AppTextStyle.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------- INTERESTS --------------------

  Widget _buildInterestsSection(user) {
    if (user.interest.isEmpty) return const SizedBox();

    return _cardWrapper(
      title: 'Interests',
      icon: Icons.favorite,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: user.interest.map<Widget>((e) {
          return Chip(
            label: Text(e),
            backgroundColor: AppColorToken.primary.color.withValues(alpha: 0.1),
          );
        }).toList(),
      ),
    );
  }

  // -------------------- DOCUMENTS --------------------

  Widget _buildDocumentsSection(user) {
    return _cardWrapper(
      title: 'Documents',
      icon: Icons.folder,
      child: ListTile(
        leading: Icon(Icons.description, color: AppColorToken.primary.color),
        title: const Text('CV / Resume'),
        subtitle: Text(user.cv.isNotEmpty ? 'Uploaded' : 'Not uploaded'),
        trailing: user.cv.isNotEmpty
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
    );
  }

  // ---- logout button ----

  Widget _buildLogoutButton(controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _LogoutButton(controller: controller),
    );
  }

  // -------------------- CARD WRAPPER --------------------

  Widget _cardWrapper({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColorToken.primary.color),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyle.h4.bold),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // -------------------- STATUS COLOR --------------------

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

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
                gradient: AppGradients.primaryGradient,
                //  LinearGradient(
                //   colors: [Colors.red[400]!, Colors.red[600]!],
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomRight,
                // ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColorToken.primary.color.withValues(alpha: 0.4),
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
