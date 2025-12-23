import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/core/widgets/app_button.dart';
import 'package:hope_link/core/widgets/app_text_field.dart';
import 'package:intl/intl.dart';

import '../controllers/donation_controller.dart';
import '../models/campaign_model.dart';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage>
    with SingleTickerProviderStateMixin {
  final DonationController _controller = Get.put(DonationController());
  final _formKey = GlobalKey<FormState>();

  late Campaign campaign;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<int> quickAmounts = [500, 1000, 2500, 5000, 10000];

  @override
  void initState() {
    super.initState();
    campaign = Get.arguments as Campaign;
    _controller.setCampaign(campaign);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'NPR ${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCampaignCard(),
                            24.verticalSpace,
                            _buildDonationForm(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildDonateButton(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColorToken.primary.color,
              ),
            ),
            onPressed: () => Get.back(),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Make a Donation',
                  style: AppTextStyle.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                4.verticalSpace,
                Text(
                  'Every contribution makes a difference',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: campaign.images.isNotEmpty
                ? Image.network(
                    campaign.images[0],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_outlined, color: Colors.grey[400]),
                  ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  style: AppTextStyle.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                8.verticalSpace,
                Text(
                  campaign.organization.organizationName,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                8.verticalSpace,
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: campaign.progress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColorToken.primary.color,
                    ),
                    minHeight: 6,
                  ),
                ),
                4.verticalSpace,
                Text(
                  '${campaign.progress.toStringAsFixed(0)}% funded',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColorToken.primary.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Amount',
                  style: AppTextStyle.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                16.verticalSpace,
                // Quick amount buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: quickAmounts.map((amount) {
                    return Obx(() => _buildAmountChip(amount));
                  }).toList(),
                ),
                20.verticalSpace,
                Text(
                  'Or enter custom amount',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                12.verticalSpace,
                AppTextField(
                  controller: _controller.amountController,
                  borderRadius: 12,
                  hintText: 'Enter amount (NPR)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = int.tryParse(value);
                    if (amount == null || amount < 100) {
                      return 'Minimum donation is NPR 100';
                    }
                    return null;
                  },
                  prefix: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'NPR',
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                24.verticalSpace,
                Text(
                  'Donor Information',
                  style: AppTextStyle.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                16.verticalSpace,
                Text(
                  'Full Name',
                  style: AppTextStyle.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                8.verticalSpace,
                AppTextField(
                  controller: _controller.nameController,
                  borderRadius: 12,
                  hintText: 'John Doe',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                16.verticalSpace,
                Text(
                  'Email',
                  style: AppTextStyle.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                8.verticalSpace,
                AppTextField(
                  controller: _controller.emailController,
                  borderRadius: 12,
                  hintText: 'your.email@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                16.verticalSpace,
                Text(
                  'Phone Number (Optional)',
                  style: AppTextStyle.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                8.verticalSpace,
                AppTextField(
                  controller: _controller.phoneController,
                  borderRadius: 12,
                  hintText: '+977 9800000000',
                  keyboardType: TextInputType.phone,
                ),
                16.verticalSpace,
                Text(
                  'Message (Optional)',
                  style: AppTextStyle.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                8.verticalSpace,
                AppTextField(
                  controller: _controller.messageController,
                  borderRadius: 12,
                  hintText: 'Leave a message of support...',
                  maxLines: 4,
                ),
                20.verticalSpace,
                Obx(
                  () => CheckboxListTile(
                    value: _controller.isAnonymous.value,
                    onChanged: (value) {
                      _controller.isAnonymous.value = value ?? false;
                    },
                    title: Text(
                      'Make this donation anonymous',
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColorToken.primary.color,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
          ),
          24.verticalSpace,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColorToken.primary.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColorToken.primary.color.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColorToken.primary.color,
                  size: 24,
                ),
                12.horizontalSpace,
                Expanded(
                  child: Text(
                    'Your donation will help support ${campaign.title}',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountChip(int amount) {
    final isSelected = _controller.selectedAmount.value == amount;

    return GestureDetector(
      onTap: () {
        _controller.setAmount(amount);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColorToken.primary.color : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColorToken.primary.color
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColorToken.primary.color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          _formatCurrency(amount.toDouble()),
          style: AppTextStyle.bodyMedium.copyWith(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final amount = _controller.selectedAmount.value > 0
                  ? _controller.selectedAmount.value
                  : int.tryParse(_controller.amountController.text) ?? 0;

              if (amount > 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Donation',
                        style: AppTextStyle.bodyLarge.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatCurrency(amount.toDouble()),
                        style: AppTextStyle.h5.copyWith(
                          color: AppColorToken.primary.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            Obx(
              () => AppButton(
                title: _controller.isProcessing.value
                    ? 'Processing...'
                    : 'Complete Donation',
                backgroundColor: AppColorToken.primary.color,
                onPressed: _controller.isProcessing.value
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _controller.processDonation();
                        }
                      },
                width: double.infinity,
                radius: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
