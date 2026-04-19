import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../controllers/organization_profile_controller.dart';
import '../models/organization_profile_model.dart';

class OrganizationProfilePage extends StatefulWidget {
  const OrganizationProfilePage({super.key});

  @override
  State<OrganizationProfilePage> createState() => _OrganizationProfilePageState();
}

class _OrganizationProfilePageState extends State<OrganizationProfilePage> {
  late final String organizationId;
  late final String controllerTag;
  late final OrganizationProfileController controller;

  @override
  void initState() {
    super.initState();
    organizationId = _extractOrganizationId(Get.arguments);
    controllerTag = 'organization-profile-$organizationId';
    controller = Get.put(
      OrganizationProfileController(organizationId: organizationId),
      tag: controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<OrganizationProfileController>(tag: controllerTag)) {
      Get.delete<OrganizationProfileController>(tag: controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FBF7),
      body: SafeArea(
        child: Obx(() {
          final profile = controller.profile.value;

          if (controller.isLoading.value &&
              profile == null &&
              controller.posts.isEmpty) {
            return _buildLoadingState();
          }

          if (controller.hasError.value &&
              profile == null &&
              controller.posts.isEmpty) {
            return _buildErrorState();
          }

          return RefreshIndicator(
            onRefresh: controller.refreshProfile,
            color: AppColorToken.primary.color,
            child: CustomScrollView(
              controller: controller.scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildTopBar()),
                if (profile != null)
                  SliverToBoxAdapter(child: _buildProfileHeader(profile)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: controller.posts.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            if (index == controller.posts.length) {
                              return _buildPaginationLoader();
                            }

                            final post = controller.posts[index];
                            return _buildPostCard(post);
                          }, childCount: controller.posts.length + 1),
                        ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              'Organization Profile',
              style: AppTextStyle.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(OrganizationProfile profile) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E8E55), Color(0xFF6FCF97)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColorToken.primary.color.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(profile),
              16.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: AppTextStyle.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (profile.location.isNotEmpty) ...[
                      6.verticalSpace,
                      Text(
                        profile.location,
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (profile.description.isNotEmpty) ...[
            18.verticalSpace,
            Text(
              profile.description,
              style: AppTextStyle.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.95),
                height: 1.5,
              ),
            ),
          ],
          20.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _buildStatTile('Campaigns', profile.campaignsCount),
              ),
              10.horizontalSpace,
              Expanded(child: _buildStatTile('Events', profile.eventsCount)),
              10.horizontalSpace,
              Expanded(
                child: _buildStatTile('Volunteer', profile.volunteerJobsCount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(OrganizationProfile profile) {
    if ((profile.profileImage ?? '').isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: profile.profileImage!,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _buildAvatarFallback(profile.name),
        ),
      );
    }

    return _buildAvatarFallback(profile.name);
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'O',
          style: AppTextStyle.h1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: AppTextStyle.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          4.verticalSpace,
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(OrganizationPost post) {
    return GestureDetector(
      onTap: () => controller.openPost(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((post.image ?? '').isNotEmpty) _buildPostImage(post.image!),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTypeBadge(post.type),
                      const Spacer(),
                      Text(
                        DateFormat('MMM dd, yyyy').format(post.createdAt),
                        style: AppTextStyle.bodySmall.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  14.verticalSpace,
                  Text(
                    post.title,
                    style: AppTextStyle.h4.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[900],
                    ),
                  ),
                  if (post.description.isNotEmpty) ...[
                    10.verticalSpace,
                    Text(
                      post.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostImage(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildImageFallback(),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: AppColorToken.primary.color.withOpacity(0.08),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 54,
          color: AppColorToken.primary.color.withOpacity(0.35),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final data = switch (type) {
      'campaign' => (Colors.green.shade50, Colors.green.shade700, 'Campaign'),
      'event' => (Colors.orange.shade50, Colors.orange.shade700, 'Event'),
      _ => (Colors.blue.shade50, Colors.blue.shade700, 'Volunteer'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: data.$1,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        data.$3,
        style: AppTextStyle.bodySmall.copyWith(
          color: data.$2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: AppColorToken.primary.color),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 72, color: Colors.grey[400]),
            16.verticalSpace,
            Text(
              controller.errorMessage.value.isEmpty
                  ? 'Something went wrong'
                  : controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyLarge.copyWith(color: Colors.grey[700]),
            ),
            20.verticalSpace,
            ElevatedButton(
              onPressed: controller.loadOrganizationProfile,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 62, color: Colors.grey[350]),
          12.verticalSpace,
          Text(
            'No posts yet',
            style: AppTextStyle.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          8.verticalSpace,
          Text(
            'This organization profile is ready, but it has not published any campaigns, events, or volunteer jobs yet.',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationLoader() {
    return Obx(() {
      if (!controller.isLoadingMore.value) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: CircularProgressIndicator(color: AppColorToken.primary.color),
        ),
      );
    });
  }

  String _extractOrganizationId(dynamic args) {
    if (args is String) {
      return args;
    }

    if (args is Map && args['organizationId'] != null) {
      return args['organizationId'].toString();
    }

    return '';
  }
}
