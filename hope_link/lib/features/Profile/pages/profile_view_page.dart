import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/features/Auth/pages/login_page.dart';
import 'package:hope_link/features/Profile/controllers/profile_controller.dart';
import 'package:hope_link/features/Profile/controllers/volunteer_credit_controller.dart';
import 'package:hope_link/features/Profile/models/user_model.dart';
import 'package:hope_link/features/Profile/models/volunteer_credit_model.dart';
import 'package:hope_link/features/Profile/pages/profile_edit_page.dart';
import 'package:hope_link/features/Profile/widgets/full_screen_image.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileViewPage extends StatelessWidget {
  final String token;

  const ProfileViewPage({super.key, required this.token});

  Future<void> _openCv(String cvPath) async {
    if (cvPath.isEmpty) return;

    final uri = Uri.tryParse(cvPath);
    final isWebUrl =
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    try {
      if (isWebUrl) {
        final didLaunch = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!didLaunch) {
          Get.snackbar('Open failed', 'Could not open the uploaded CV.');
        }
        return;
      }

      final result = await OpenFilex.open(cvPath);
      if (result.type != ResultType.done) {
        Get.snackbar('Open failed', result.message);
      }
    } catch (_) {
      Get.snackbar('Open failed', 'Could not open the uploaded CV.');
    }
  }

  void _showComingSoon(String featureName) {
    Get.snackbar(
      'Coming soon',
      '$featureName will be connected next.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController(token));
    final creditController = Get.isRegistered<VolunteerCreditController>()
        ? Get.find<VolunteerCreditController>()
        : Get.put(VolunteerCreditController(token));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
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

        return RefreshIndicator(
          onRefresh: controller.fetchProfile,
          color: AppColorToken.primary.color,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, user),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    16.verticalSpace,
                    _buildProfileHero(context, user),
                    18.verticalSpace,
                    _buildQuickActionsSection(context, user),
                    18.verticalSpace,
                    _buildAboutSection(user),
                    18.verticalSpace,
                    _buildVolunteerCreditsSection(creditController),
                    18.verticalSpace,
                    _buildInfoSection(user),
                    18.verticalSpace,
                    _buildResourcesSection(user),
                    18.verticalSpace,
                    _buildInterestsSection(user),
                    18.verticalSpace,
                    _buildPlanningSection(),
                    18.verticalSpace,
                    _buildLogoutButton(controller),
                    32.verticalSpace,
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAppBar(BuildContext context, UserModel user) {
    return SliverAppBar(
      expandedHeight: 108,
      pinned: true,
      backgroundColor: AppColorToken.primary.color,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorToken.primary.color,
              const Color(0xFF238255),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
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

  Widget _buildProfileHero(BuildContext context, UserModel user) {
    final completion = _profileCompleteness(user);
    final completionLabel = _completionLabel(completion);
    final tags = <String>[
      if (user.location.city.isNotEmpty) user.location.city,
      if (user.gender.isNotEmpty) user.gender,
      if (user.status.isNotEmpty) user.status.toUpperCase(),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileAvatar(user),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: AppTextStyle.h2.bold.copyWith(
              fontSize: 28,
              color: const Color(0xFF18211E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: tags
                  .map((tag) => _buildMetaChip(tag, _chipColorForTag(tag)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Profile completion',
                      style: AppTextStyle.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B2320),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(completion * 100).round()}%',
                      style: AppTextStyle.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColorToken.primary.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: completion,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      AppColorToken.primary.color,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  completionLabel,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(UserModel user) {
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
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFE9EFEC),
            backgroundImage: user.profileImage.isNotEmpty
                ? NetworkImage(user.profileImage)
                : null,
            child: user.profileImage.isEmpty
                ? Icon(Icons.person, size: 52, color: Colors.grey[400])
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, UserModel user) {
    return _sectionCard(
      title: 'Quick Actions',
      subtitle: 'Fast access to the things people usually reach for first.',
      icon: Icons.flash_on_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = constraints.maxWidth > 520
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: tileWidth,
                child: _quickActionTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal details and public presence.',
                  accent: AppColorToken.primary.color,
                  onTap: () => Get.to(
                    () => ProfileEditPage(token: token),
                    transition: Transition.rightToLeft,
                  ),
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _quickActionTile(
                  icon: Icons.local_shipping_outlined,
                  title: 'My Pledges',
                  subtitle: 'Review active essential donation commitments.',
                  accent: const Color(0xFF0E9F6E),
                  onTap: () => Get.toNamed('/essential-commitments'),
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _quickActionTile(
                  icon: Icons.description_outlined,
                  title: user.cv.isNotEmpty ? 'Open Resume' : 'Add Resume',
                  subtitle: user.cv.isNotEmpty
                      ? 'Check the CV currently attached to your profile.'
                      : 'A dedicated resume workflow will land here next.',
                  accent: const Color(0xFF2563EB),
                  onTap: () => user.cv.isNotEmpty
                      ? _openCv(user.cv)
                      : _showComingSoon('Resume management'),
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _quickActionTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Certificates',
                  subtitle: 'A cleaner place for badges and proof of impact.',
                  accent: const Color(0xFFF59E0B),
                  onTap: () => _showComingSoon('Certificates'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAboutSection(UserModel user) {
    final aboutText = [
      if (user.bio.trim().isNotEmpty) user.bio.trim(),
      if (user.description.trim().isNotEmpty) user.description.trim(),
    ].join('\n\n');

    return _sectionCard(
      title: 'About',
      subtitle: 'How your profile introduces you to organizers and teams.',
      icon: Icons.auto_awesome_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            aboutText.isNotEmpty
                ? aboutText
                : 'Add a short bio and description to make your profile feel more complete and more trustworthy to organizations.',
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.grey[800],
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerCreditsSection(
    VolunteerCreditController creditController,
  ) {
    return Obx(() {
      final credits = creditController.credits.value;
      final isLoading = creditController.isLoading.value && credits == null;
      final hasError =
          creditController.errorMessage.value.isNotEmpty && credits == null;

      return _sectionCard(
        title: 'Volunteer Impact',
        subtitle: 'A readable snapshot of the contribution you have built.',
        icon: Icons.workspace_premium_rounded,
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColorToken.primary.color,
                ),
              )
            : hasError
            ? Text(
                creditController.errorMessage.value,
                style: AppTextStyle.bodyMedium.copyWith(color: Colors.red[400]),
              )
            : credits == null
            ? Text(
                'Impact data will appear here once credits are available.',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _metricPanel(
                          label: 'Total Points',
                          value: '${credits.totalPoints}',
                          icon: Icons.stars_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricPanel(
                          label: 'Credit Hours',
                          value: '${credits.totalCreditHours}h',
                          icon: Icons.schedule_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailTile(
                    Icons.bolt_rounded,
                    'Points Per Hour',
                    '${credits.pointsPerHour}',
                  ),
                  const Divider(height: 24),
                  _detailTile(
                    Icons.person_outline_rounded,
                    'Credits Owner',
                    credits.userName.isNotEmpty
                        ? credits.userName
                        : credits.userEmail,
                  ),
                  if (credits.creditBreakdown.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent Breakdown',
                        style: AppTextStyle.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...credits.creditBreakdown.map(_buildBreakdownCard),
                  ],
                ],
              ),
      );
    });
  }

  Widget _buildInfoSection(UserModel user) {
    return _sectionCard(
      title: 'Profile Details',
      subtitle: 'The core information organizations use when reviewing you.',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _infoRow(Icons.phone_outlined, 'Phone', _safeValue(user.phone)),
          const Divider(height: 24),
          _infoRow(Icons.wc_outlined, 'Gender', _safeValue(user.gender)),
          const Divider(height: 24),
          _infoRow(
            Icons.location_on_outlined,
            'Location',
            _formatLocation(user),
          ),
          const Divider(height: 24),
          _infoRow(Icons.mail_outline_rounded, 'Email', _safeValue(user.email)),
        ],
      ),
    );
  }

  Widget _buildResourcesSection(UserModel user) {
    return _sectionCard(
      title: 'Resources',
      subtitle: 'Profile assets and utility areas that deserve faster access.',
      icon: Icons.dashboard_customize_outlined,
      child: Column(
        children: [
          _actionRow(
            icon: Icons.picture_as_pdf_rounded,
            title: 'CV / Resume',
            subtitle: user.cv.isNotEmpty
                ? 'Open the resume attached to your profile.'
                : 'No resume uploaded yet.',
            onTap: user.cv.isNotEmpty
                ? () => _openCv(user.cv)
                : () => _showComingSoon('Resume upload'),
          ),
          const SizedBox(height: 10),
          _actionRow(
            icon: Icons.bookmark_border_rounded,
            title: 'Saved Causes',
            subtitle: 'A future home for campaigns, roles, and organizations you want to revisit.',
            onTap: () => _showComingSoon('Saved causes'),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(UserModel user) {
    return _sectionCard(
      title: 'Interests',
      subtitle: 'Your causes, topics, and volunteer preferences at a glance.',
      icon: Icons.favorite_border_rounded,
      child: user.interest.isEmpty
          ? Text(
              'No interests added yet. This area can become a strong discovery signal once you start curating it.',
              style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.interest.map<Widget>((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorToken.primary.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColorToken.primary.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPlanningSection() {
    return _sectionCard(
      title: 'Ready To Add',
      subtitle: 'UI concepts that can become useful product features next.',
      icon: Icons.lightbulb_outline_rounded,
      child: Column(
        children: [
          _suggestionItem(
            icon: Icons.history_rounded,
            title: 'Volunteer Timeline',
            subtitle: 'A scrolling history of jobs, applications, approvals, and earned milestones.',
          ),
          const SizedBox(height: 10),
          _suggestionItem(
            icon: Icons.notifications_active_outlined,
            title: 'Profile Alerts',
            subtitle: 'Deadlines, pledge reminders, document expiry, and new role matches.',
          ),
          const SizedBox(height: 10),
          _suggestionItem(
            icon: Icons.bar_chart_outlined,
            title: 'Impact Analytics',
            subtitle: 'Trends for hours, points, categories served, and organizer engagement.',
          ),
        ],
      ),
    );
  }

  Widget _metricPanel({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAF8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColorToken.primary.color),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyle.h3.bold.copyWith(
              color: AppColorToken.primary.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyle.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(VolunteerCreditBreakdown item) {
    final appliedAt = item.appliedAt ?? item.createdAt;
    final formattedDate = appliedAt == null
        ? 'No date'
        : DateFormat('MMM d, yyyy').format(appliedAt.toLocal());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.description.isNotEmpty ? item.description : item.source,
                  style: AppTextStyle.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A2320),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColorToken.primary.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.creditHours}h',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColorToken.primary.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Source: ${item.sourceModel}',
            style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Applied: ${item.isApplied ? 'Yes' : 'No'} | $formattedDate',
            style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF6FAF8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColorToken.primary.color),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 3),
              Text(
                value,
                style: AppTextStyle.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: accent.withValues(alpha: 0.08),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2320),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColorToken.primary.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColorToken.primary.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestionItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColorToken.primary.color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyle.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyle.bodySmall.copyWith(
                  color: Colors.grey[600],
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyle.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColorToken.primary.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColorToken.primary.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.h4.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _LogoutButton(controller: controller),
    );
  }

  double _profileCompleteness(UserModel user) {
    var completed = 0;
    const total = 8;

    if (user.profileImage.isNotEmpty) completed++;
    if (user.phone.trim().isNotEmpty) completed++;
    if (user.gender.trim().isNotEmpty) completed++;
    if (user.bio.trim().isNotEmpty) completed++;
    if (user.description.trim().isNotEmpty) completed++;
    if (user.location.city.trim().isNotEmpty || user.location.country.trim().isNotEmpty) {
      completed++;
    }
    if (user.interest.isNotEmpty) completed++;
    if (user.cv.trim().isNotEmpty) completed++;

    return completed / total;
  }

  String _completionLabel(double value) {
    if (value >= 0.9) {
      return 'Your profile looks polished and ready for outreach.';
    }
    if (value >= 0.65) {
      return 'A few more details would make this profile feel much stronger.';
    }
    return 'Adding bio, interests, resume, and contact details will improve trust fast.';
  }

  String _formatLocation(UserModel user) {
    final city = user.location.city.trim();
    final country = user.location.country.trim();
    if (city.isEmpty && country.isEmpty) {
      return 'Not added yet';
    }
    if (city.isEmpty) return country;
    if (country.isEmpty) return city;
    return '$city, $country';
  }

  String _safeValue(String value) {
    return value.trim().isEmpty ? 'Not added yet' : value.trim();
  }

  Color _chipColorForTag(String label) {
    final normalized = label.toLowerCase();
    if (normalized == 'active') return const Color(0xFF0E9F6E);
    if (normalized == 'inactive') return const Color(0xFFF59E0B);
    if (normalized == 'blocked') return const Color(0xFFDC2626);
    return AppColorToken.primary.color;
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
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColorToken.primary.color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onPressed,
                  borderRadius: BorderRadius.circular(18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
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
                  const Text(
                    'Logout?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedButton(
                          label: 'Cancel',
                          onPressed: _handleCancel,
                          isPrimary: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedButton(
                          label: 'Logout',
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

class AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const AnimatedButton({
    super.key,
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
