import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/core/widgets/app_button.dart';
import 'package:intl/intl.dart';

import '../controllers/campaign_controller.dart';
import '../models/campaign_model.dart';

class CampaignDetailsPage extends StatefulWidget {
  const CampaignDetailsPage({super.key});

  @override
  State<CampaignDetailsPage> createState() => _CampaignDetailsPageState();
}

class _CampaignDetailsPageState extends State<CampaignDetailsPage>
    with SingleTickerProviderStateMixin {
  final CampaignController _controller = Get.find<CampaignController>();
  final RxInt _selectedImageIndex = 0.obs;
  final RxInt _selectedTab = 0.obs; // 0: About, 1: Updates, 2: FAQs

  late AnimationController _animationController;
  late String campaignId;
  Campaign? campaign;

  void _initFromArgs(dynamic args) {
    // Accept String, Campaign, or Map payloads and normalize to id + campaign.
    if (args is Campaign) {
      campaign = args;
      campaignId = args.id;
      return;
    }

    if (args is String) {
      campaignId = args;
      return;
    }

    if (args is Map) {
      final map = Map<String, dynamic>.from(args);

      final embeddedCampaign = map['campaign'];
      if (embeddedCampaign is Campaign) {
        campaign = embeddedCampaign;
        campaignId = embeddedCampaign.id;
        return;
      }

      final idValue = map['id'] ?? map['campaignId'] ?? map['_id'];
      if (idValue != null) {
        campaignId = idValue.toString();
        return;
      }

      try {
        campaign = Campaign.fromJson(map);
        campaignId = campaign!.id;
        return;
      } catch (_) {
        // Fall through to empty id below.
      }
    }

    campaignId = '';
  }

  @override
  void initState() {
    super.initState();
    _initFromArgs(Get.arguments);
    if (campaign == null && campaignId.isNotEmpty) {
      _loadCampaignDetails();
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  Future<void> _loadCampaignDetails() async {
    final loadedCampaign = await _controller.getCampaignById(campaignId);
    setState(() {
      campaign = loadedCampaign;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'NPR ${formatter.format(amount)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (campaign == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColorToken.primary.color.withOpacity(0.05),
                Colors.white,
                AppColorToken.primary.color.withOpacity(0.03),
              ],
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColorToken.primary.color,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorToken.primary.color.withOpacity(0.05),
              Colors.white,
              AppColorToken.primary.color.withOpacity(0.03),
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildImageCarousel(),
                  _buildMainInfo(),
                  // CampaignInfoWidget(),
                  _buildProgressSection(),
                  _buildTabBar(),
                  _buildTabContent(),
                  32.verticalSpace,
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildDonateButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: AppColorToken.primary.color,
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share_rounded, color: AppColorToken.primary.color),
          onPressed: () {
            // Share functionality
            Get.snackbar(
              'Share',
              'Share functionality coming soon',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColorToken.primary.color.withOpacity(0.9),
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
          },
        ),
        16.horizontalSpace,
      ],
    );
  }

  Widget _buildImageCarousel() {
    if (campaign!.images.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: Icon(Icons.image_outlined, size: 80, color: Colors.grey[400]),
      );
    }

    return Column(
      children: [
        SizedBox(
          child: SizedBox(
            height: 300,
            child: PageView.builder(
              itemCount: campaign!.images.length,
              onPageChanged: (index) {
                _selectedImageIndex.value = index;
              },
              itemBuilder: (context, index) {
                return Image.network(
                  campaign!.images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (campaign!.images.length > 1) ...[
          12.verticalSpace,
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                campaign!.images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _selectedImageIndex.value == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _selectedImageIndex.value == index
                        ? AppColorToken.primary.color
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainInfo() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (campaign!.isFeatured)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Featured',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: campaign!.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: campaign!.isActive ? Colors.green : Colors.grey,
                  ),
                ),
                child: Text(
                  campaign!.status.toUpperCase(),
                  style: AppTextStyle.bodySmall.copyWith(
                    color: campaign!.isActive
                        ? Colors.green[700]
                        : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Text(
            campaign!.title,
            style: AppTextStyle.h4.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          12.verticalSpace,
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorToken.primary.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.business_rounded,
                  size: 20,
                  color: AppColorToken.primary.color,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organized by',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    2.verticalSpace,
                    Text(
                      campaign!.organization.organizationName,
                      style: AppTextStyle.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final daysLeft = campaign!.endDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorToken.primary.color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatCurrency(campaign!.currentAmount),
                    style: AppTextStyle.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColorToken.primary.color,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    'raised of ${_formatCurrency(campaign!.targetAmount)}',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColorToken.primary.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${campaign!.progress.toStringAsFixed(0)}%',
                      style: AppTextStyle.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColorToken.primary.color,
                      ),
                    ),
                    2.verticalSpace,
                    Text(
                      'funded',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          16.verticalSpace,
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: campaign!.progress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColorToken.primary.color,
              ),
              minHeight: 12,
            ),
          ),
          16.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                Icons.calendar_today_rounded,
                '$daysLeft days',
                'left',
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              _buildStatItem(
                Icons.date_range_rounded,
                _formatDate(campaign!.endDate),
                'end date',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColorToken.primary.color),
        8.horizontalSpace,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyle.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            2.verticalSpace,
            Text(
              label,
              style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Obx(
        () => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColorToken.primary.color.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildTabItem('About', 0),
              _buildTabItem('Updates', 1),
              _buildTabItem('FAQs', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _selectedTab.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectedTab.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColorToken.primary.color
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyMedium.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Obx(() {
        switch (_selectedTab.value) {
          case 0:
            return _buildAboutTab();
          case 1:
            return _buildUpdatesTab();
          case 2:
            return _buildFAQsTab();
          default:
            return const SizedBox.shrink();
        }
      }),
    );
  }

  Widget _buildAboutTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorToken.primary.color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this campaign',
            style: AppTextStyle.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          16.verticalSpace,
          Text(
            campaign!.description,
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          if (campaign!.tags.isNotEmpty) ...[
            24.verticalSpace,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: campaign!.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorToken.primary.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColorToken.primary.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpdatesTab() {
    if (campaign!.updates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            16.verticalSpace,
            Text(
              'No updates yet',
              style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: campaign!.updates.asMap().entries.map((entry) {
        final update = entry.value;
        return Container(
          margin: EdgeInsets.only(
            bottom: entry.key < campaign!.updates.length - 1 ? 16 : 0,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColorToken.primary.color.withOpacity(0.05),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColorToken.primary.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      size: 20,
                      color: AppColorToken.primary.color,
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update.title,
                          style: AppTextStyle.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        4.verticalSpace,
                        Text(
                          _formatDate(update.date),
                          style: AppTextStyle.bodySmall.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              16.verticalSpace,
              Text(
                update.description,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFAQsTab() {
    if (campaign!.faqs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.help_outline_rounded, size: 64, color: Colors.grey[300]),
            16.verticalSpace,
            Text(
              'No FAQs yet',
              style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: campaign!.faqs.asMap().entries.map((entry) {
        final faq = entry.value;
        final isExpanded = RxBool(false);

        return Obx(
          () => Container(
            margin: EdgeInsets.only(
              bottom: entry.key < campaign!.faqs.length - 1 ? 12 : 0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColorToken.primary.color.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                title: Text(
                  faq.question,
                  style: AppTextStyle.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                trailing: Icon(
                  isExpanded.value
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColorToken.primary.color,
                ),
                onExpansionChanged: (expanded) {
                  isExpanded.value = expanded;
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text(
                      faq.answer,
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDonateButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: AppButton(
          title: 'Donate Now',
          backgroundColor: AppColorToken.primary.color,
          onPressed: campaign!.isActive
              ? () {
                  Get.toNamed('/donate', arguments: campaign);
                }
              : null,
          width: double.infinity,
          radius: 16,
        ),
      ),
    );
  }
}
