import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopelink_admin/features/Commerce/pages/org_commerce_page.dart';
import 'package:hopelink_admin/features/Jobs/pages/jobs_page.dart';
import 'package:hopelink_admin/features/VolunteerCredits/pages/volunteer_credits_page.dart';

import '../Auth/controller/login_controller.dart';
import '../Event/pages/org_events_page.dart';
import 'controllers/campaign_controller.dart';
import 'pages/campaign_list_page.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/dashboard_top_bar.dart';
import 'widgets/dashboard_widgets.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CampaignController());
    Get.put(LoginController());
    return Scaffold(
      backgroundColor: kBg,
      body: Row(
        children: [
          DashboardSidebar(ctrl: ctrl),
          Expanded(
            child: Obx(() {
              switch (ctrl.currentNavIndex.value) {
                case 0:
                  return _DashboardPage(ctrl: ctrl);
                case 1:
                  return CampaignListPage();
                case 2:
                  return _CreateCampaignPage(ctrl: ctrl);
                case 3:
                  // return CreateEventPage(ctrl: ctrl);
                  return OrgEventsPage();
                case 4:
                  return JobsPage();
                case 5:
                  return const OrgCommercePage();
                case 6:
                  return const VolunteerCreditsPage();
                default:
                  return _DashboardPage(ctrl: ctrl);
              }
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SIDEBAR
// ─────────────────────────────────────────────────────────────
class _DashboardPage extends StatelessWidget {
  final CampaignController ctrl;
  const _DashboardPage({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashboardTopBar(
          title: 'Overview',
          sub: 'Welcome back — here\'s what\'s happening',
          actions: [
            PrimaryBtn(
              label: 'New Campaign',
              icon: Icons.add_rounded,
              onTap: () => ctrl.navigateTo(2),
            ),
          ],
        ),
        Expanded(
          child: Obx(() {
            if (ctrl.isLoadingList.value) {
              return const Center(
                child: CircularProgressIndicator(
                  color: kAccent,
                  strokeWidth: 2,
                ),
              );
            }
            final s = ctrl.stats;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stat cards row
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                    children: [
                      StatCard(
                        label: 'Total Campaigns',
                        value: '${s.totalCampaigns}',
                        icon: Icons.campaign_rounded,
                        accent: kAccent,
                      ),
                      StatCard(
                        label: 'Active Campaigns',
                        value: '${s.activeCampaigns}',
                        icon: Icons.trending_up_rounded,
                        accent: kAccent2,
                        sub: 'Live',
                      ),
                      StatCard(
                        label: 'Total Raised',
                        value: ctrl.formatCurrency(s.totalRaised),
                        icon: Icons.account_balance_wallet_rounded,
                        accent: kPurple,
                      ),
                      StatCard(
                        label: 'Funding Goal',
                        value: ctrl.formatCurrency(s.totalTarget),
                        icon: Icons.flag_rounded,
                        accent: kAmber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SectionHeader(
                    title: 'Recent Campaigns',
                    sub: '${ctrl.campaigns.length} total',
                    action: GhostBtn(
                      label: 'View All',
                      icon: Icons.arrow_forward_rounded,
                      onTap: () => ctrl.navigateTo(1),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (ctrl.campaigns.isEmpty)
                    _EmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'No campaigns yet',
                      sub: 'Create your first campaign to start raising funds.',
                      action: PrimaryBtn(
                        label: 'Create Campaign',
                        icon: Icons.add_rounded,
                        onTap: () => ctrl.navigateTo(2),
                      ),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.7,
                      children: ctrl.campaigns
                          .take(4)
                          .map(
                            (c) => CampaignCard(
                              campaign: c,
                              ctrl: ctrl,
                              onTap: () {
                                ctrl.selectedCampaign.value = c;
                                ctrl.navigateTo(1);
                              },
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CREATE CAMPAIGN WIZARD
// ─────────────────────────────────────────────────────────────
class _CreateCampaignPage extends StatelessWidget {
  final CampaignController ctrl;
  const _CreateCampaignPage({required this.ctrl});

  static const _steps = ['Campaign Info', 'Images', 'Updates', 'FAQs'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashboardTopBar(
          title: 'Create Campaign',
          sub: 'Follow the steps to launch your campaign',
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Obx(() {
                  if (ctrl.wizardStep.value >= 4) {
                    return _WizardDone(ctrl: ctrl);
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                        child: Obx(
                          () => WizardStepHeader(
                            current: ctrl.wizardStep.value,
                            steps: _steps,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Divider(color: kBorder, height: 1),
                      Expanded(
                        child: Obx(
                          () => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.02, 0),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: KeyedSubtree(
                              key: ValueKey(ctrl.wizardStep.value),
                              child: _buildStep(context, ctrl.wizardStep.value),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              _HelpPanel(ctrl: ctrl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context, int step) {
    switch (step) {
      case 0:
        return _Step0Info(ctrl: ctrl);
      case 1:
        return _Step1Images(ctrl: ctrl);
      case 2:
        return _Step2Updates(ctrl: ctrl);
      case 3:
        return _Step3Faqs(ctrl: ctrl);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Step 0 — Info ────────────────────────────────────────────
class _Step0Info extends StatelessWidget {
  final CampaignController ctrl;
  const _Step0Info({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Form(
        key: ctrl.createFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dashField(
              ctrl.titleCtrl,
              label: 'Campaign Title',
              hint: 'e.g. Health Care for Underprivileged Families',
            ),
            const SizedBox(height: 16),
            dashField(
              ctrl.descCtrl,
              label: 'Description',
              hint: 'Describe your campaign and its impact...',
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Category',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kTextSub,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(color: kRed, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          value: ctrl.selectedCategory.value.isEmpty
                              ? null
                              : ctrl.selectedCategory.value,
                          dropdownColor: kSurface2,
                          style: GoogleFonts.dmSans(fontSize: 13, color: kText),
                          hint: Text(
                            'Select category',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: kTextMuted,
                            ),
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: kSurface,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: kBorder2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: kAccent,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                          items: ctrl.categories
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat.id,
                                  child: Text(cat.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) ctrl.selectedCategory.value = v;
                          },
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: dashField(
                    ctrl.targetCtrl,
                    label: 'Target Amount (NPR)',
                    hint: '5000000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid amount';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: dashField(
                    ctrl.startDateCtrl,
                    label: 'Start Date',
                    hint: 'YYYY-MM-DD',
                    readOnly: true,
                    onTap: () => ctrl.pickStartDate(context),
                    suffix: const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: kTextSub,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: dashField(
                    ctrl.endDateCtrl,
                    label: 'End Date',
                    hint: 'YYYY-MM-DD',
                    readOnly: true,
                    onTap: () => ctrl.pickEndDate(context),
                    suffix: const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: kTextSub,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Obx(() => _ErrorBar(ctrl.errorMsg.value)),
            const SizedBox(height: 4),
            Obx(
              () => PrimaryBtn(
                label: 'Create & Continue',
                icon: Icons.arrow_forward_rounded,
                loading: ctrl.isSubmitting.value,
                onTap: ctrl.createCampaign,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 1 — Images ─────────────────────────────────────────
class _Step1Images extends StatelessWidget {
  final CampaignController ctrl;
  const _Step1Images({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campaign Images',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add compelling visuals to attract donors.',
            style: GoogleFonts.dmSans(fontSize: 12, color: kTextSub),
          ),
          const SizedBox(height: 20),
          Obx(() {
            final images = ctrl.pickedImages.toList();
            return _ImageDropZone(
              pickedImages: images,
              onAdd: ctrl.pickImages,
              onRemove: ctrl.removeImage,
            );
          }),
          const SizedBox(height: 20),
          Obx(() => _ErrorBar(ctrl.errorMsg.value)),
          const SizedBox(height: 4),
          Row(
            children: [
              GhostBtn(
                label: 'Skip',
                icon: Icons.skip_next_rounded,
                onTap: () => ctrl.wizardStep.value = 2,
              ),
              const SizedBox(width: 12),
              Obx(
                () => PrimaryBtn(
                  label: ctrl.pickedImages.isEmpty
                      ? 'Skip Images'
                      : 'Upload & Continue',
                  icon: Icons.cloud_upload_rounded,
                  loading: ctrl.isUploadingImages.value,
                  onTap: ctrl.uploadImages,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Image drop zone widget
class _ImageDropZone extends StatefulWidget {
  final List pickedImages;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  const _ImageDropZone({
    required this.pickedImages,
    required this.onAdd,
    required this.onRemove,
  });
  @override
  State<_ImageDropZone> createState() => _ImageDropZoneState();
}

class _ImageDropZoneState extends State<_ImageDropZone> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _h = true),
          onExit: (_) => setState(() => _h = false),
          child: GestureDetector(
            onTap: widget.onAdd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 120,
              decoration: BoxDecoration(
                color: _h ? kSurface2 : kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _h ? kAccent.withValues(alpha: 0.4) : kBorder2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: _h ? kAccent : kTextMuted,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click to select images',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: _h ? kAccent : kTextSub,
                    ),
                  ),
                  Text(
                    'JPG, PNG, WEBP supported',
                    style: GoogleFonts.dmSans(fontSize: 11, color: kTextMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.pickedImages.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(widget.pickedImages.length, (i) {
              final f = widget.pickedImages[i];
              return Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: kSurface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kBorder2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_rounded,
                          color: kAccent2,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            f.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: kTextSub,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => widget.onRemove(i),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: kRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ],
    );
  }
}

// ─── Step 2 — Updates ────────────────────────────────────────
class _Step2Updates extends StatelessWidget {
  final CampaignController ctrl;
  const _Step2Updates({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Form(
        key: ctrl.updateFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post a Campaign Update',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Keep your donors informed about your progress.',
              style: GoogleFonts.dmSans(fontSize: 12, color: kTextSub),
            ),
            const SizedBox(height: 20),
            dashField(
              ctrl.updateTitleCtrl,
              label: 'Update Title',
              hint: 'e.g. Midway Milestone Reached!',
            ),
            const SizedBox(height: 14),
            dashField(
              ctrl.updateDescCtrl,
              label: 'Update Description',
              hint: 'Share your progress with supporters...',
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            Obx(() => _ErrorBar(ctrl.errorMsg.value)),
            Obx(() => _SuccessBar(ctrl.successMsg.value)),
            const SizedBox(height: 4),
            Row(
              children: [
                GhostBtn(
                  label: 'Skip to FAQs',
                  icon: Icons.skip_next_rounded,
                  onTap: ctrl.skipToFaqs,
                ),
                const SizedBox(width: 12),
                Obx(
                  () => PrimaryBtn(
                    label: 'Post Update & Continue',
                    icon: Icons.send_rounded,
                    loading: ctrl.isPostingUpdate.value,
                    onTap: () async {
                      await ctrl.postUpdate();
                      if (ctrl.errorMsg.value.isEmpty) {
                        await Future.delayed(const Duration(seconds: 1));
                        ctrl.wizardStep.value = 3;
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3 — FAQs ───────────────────────────────────────────
class _Step3Faqs extends StatelessWidget {
  final CampaignController ctrl;
  const _Step3Faqs({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Form(
        key: ctrl.faqFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add FAQ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Answer common questions to build donor trust.',
              style: GoogleFonts.dmSans(fontSize: 12, color: kTextSub),
            ),
            const SizedBox(height: 20),
            dashField(
              ctrl.faqQuestionCtrl,
              label: 'Question',
              hint: 'e.g. How will the funds be used?',
            ),
            const SizedBox(height: 14),
            dashField(
              ctrl.faqAnswerCtrl,
              label: 'Answer',
              hint: 'Provide a clear, detailed answer...',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Obx(() => _ErrorBar(ctrl.errorMsg.value)),
            Obx(() => _SuccessBar(ctrl.successMsg.value)),
            const SizedBox(height: 4),
            Row(
              children: [
                GhostBtn(
                  label: 'Finish',
                  icon: Icons.check_rounded,
                  onTap: ctrl.finishWizard,
                ),
                const SizedBox(width: 12),
                Obx(
                  () => PrimaryBtn(
                    label: 'Add FAQ',
                    icon: Icons.add_rounded,
                    loading: ctrl.isPostingFaq.value,
                    onTap: ctrl.postFaq,
                  ),
                ),
                const SizedBox(width: 12),
                PrimaryBtn(
                  label: 'Done — View Campaigns',
                  icon: Icons.done_all_rounded,
                  color: kPurple,
                  onTap: ctrl.finishWizard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wizard Done ─────────────────────────────────────────────
class _WizardDone extends StatelessWidget {
  final CampaignController ctrl;
  const _WizardDone({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kAccent, kAccent2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kAccent.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.black,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Campaign Launched!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kText,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your campaign is now live and ready to receive donations.',
            style: GoogleFonts.dmSans(fontSize: 13, color: kTextSub),
          ),
          const SizedBox(height: 28),
          PrimaryBtn(
            label: 'Go to Campaigns',
            icon: Icons.arrow_forward_rounded,
            onTap: ctrl.finishWizard,
          ),
        ],
      ),
    );
  }
}

// ─── Help Panel ───────────────────────────────────────────────
class _HelpPanel extends StatelessWidget {
  final CampaignController ctrl;
  const _HelpPanel({required this.ctrl});

  static const _tips = {
    0: [
      'Use a specific, compelling title that clearly states the cause.',
      'A good description explains the problem, your solution, and the impact.',
      'Set a realistic target amount based on actual needs.',
    ],
    1: [
      'High-quality images increase donation rates by up to 3x.',
      'Show real people benefiting from the campaign when possible.',
      'You can upload multiple images to tell your story.',
    ],
    2: [
      'Regular updates build donor trust and encourage repeat giving.',
      'Even a small milestone is worth celebrating with an update.',
      'Be specific about how funds are being used.',
    ],
    3: [
      'Answer the most common donor questions upfront.',
      'Transparency in fund usage builds donor confidence.',
      'You can always add more FAQs after launch.',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: kBorder)),
        color: Color(0xFF080F1E),
      ),
      padding: const EdgeInsets.all(20),
      child: Obx(() {
        final tips = _tips[ctrl.wizardStep.value] ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: kAmber,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tips',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kAmber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: kAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: kTextSub,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Obx(() {
              if (ctrl.successMsg.value.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kAccent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: kAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ctrl.successMsg.value,
                        style: GoogleFonts.dmSans(fontSize: 11, color: kAccent),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SHARED INLINE WIDGETS
// ─────────────────────────────────────────────────────────────
class _ErrorBar extends StatelessWidget {
  final String msg;
  const _ErrorBar(this.msg);
  @override
  Widget build(BuildContext context) {
    if (msg.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kRed, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.dmSans(fontSize: 12, color: kRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBar extends StatelessWidget {
  final String msg;
  const _SuccessBar(this.msg);
  @override
  Widget build(BuildContext context) {
    if (msg.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: kAccent,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.dmSans(fontSize: 12, color: kAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final Widget? action;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.sub,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kSurface,
              shape: BoxShape.circle,
              border: Border.all(color: kBorder2),
            ),
            child: Icon(icon, color: kTextMuted, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 6),
          Text(sub, style: GoogleFonts.dmSans(fontSize: 12, color: kTextSub)),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
