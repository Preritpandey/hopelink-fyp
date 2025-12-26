import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/features/Profile/controllers/profile_controller.dart';
import 'package:hope_link/features/Profile/pages/profile_edit_page.dart';
import 'package:hope_link/features/Profile/widgets/full_screen_image.dart';

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
