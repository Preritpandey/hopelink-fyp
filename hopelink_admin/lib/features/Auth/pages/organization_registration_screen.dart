import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopelink_admin/features/Auth/controller/organization_controller.dart';
import 'package:hopelink_admin/features/Auth/pages/login_page.dart';

import '../models/organization_model.dart';

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Organization Registration',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const OrganizationRegistrationScreen(),
    );
  }
}

ThemeData _buildTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF080D1A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00D4AA),
      secondary: Color(0xFF7B61FF),
      surface: Color(0xFF0F1628),
      error: Color(0xFFFF4C6A),
    ),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF141D35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E2D50)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E2D50)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF4C6A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF4C6A), width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF6B7FA8)),
      hintStyle: const TextStyle(color: Color(0xFF3D4F72)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────
class OrganizationRegistrationScreen extends StatelessWidget {
  const OrganizationRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(OrganizationController());

    return Scaffold(
      body: Row(
        children: [
          // ── Left sidebar ──────────────────────────────────────
          _Sidebar(ctrl: ctrl),
          // ── Main content ──────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _TopBar(),
                Expanded(
                  child: Obx(() {
                    if (ctrl.currentStep.value >=
                        OrganizationController.totalSteps) {
                      return _SuccessScreen(ctrl: ctrl);
                    }
                    return _StepContent(ctrl: ctrl);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SIDEBAR
// ─────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final OrganizationController ctrl;
  const _Sidebar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0A1020),
        border: Border(right: BorderSide(color: Color(0xFF131E36))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF7B61FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'OrgHub',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'REGISTRATION STEPS',
              style: GoogleFonts.dmMono(
                fontSize: 10,
                color: const Color(0xFF3D4F72),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Steps
          Obx(
            () => Column(
              children: List.generate(
                OrganizationController.totalSteps,
                (i) => _SidebarStep(
                  index: i,
                  isActive: ctrl.currentStep.value == i,
                  isCompleted: ctrl.currentStep.value > i,
                  title: OrganizationController.stepTitles[i],
                  icon: OrganizationController.stepIcons[i],
                  onTap: () {
                    if (ctrl.currentStep.value > i) {
                      ctrl.currentStep.value = i;
                    }
                  },
                ),
              ),
            ),
          ),

          const Spacer(),

          // Help box
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1628),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2D50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xFF00D4AA),
                    size: 18,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Need Help?',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact support for registration assistance.',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF6B7FA8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarStep extends StatelessWidget {
  final int index;
  final bool isActive;
  final bool isCompleted;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SidebarStep({
    required this.index,
    required this.isActive,
    required this.isCompleted,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF00D4AA);
    final bgActive = accent.withOpacity(0.08);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? bgActive : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? accent.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? accent
                    : isActive
                    ? accent.withOpacity(0.15)
                    : const Color(0xFF141D35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted || isActive
                      ? accent
                      : const Color(0xFF1E2D50),
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.black,
                      size: 15,
                    )
                  : Icon(
                      icon,
                      color: isActive ? accent : const Color(0xFF3D4F72),
                      size: 14,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? Colors.white
                      : isCompleted
                      ? const Color(0xFF8FA3C8)
                      : const Color(0xFF4A5D80),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OrganizationController>();
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1020),
        border: Border(bottom: BorderSide(color: Color(0xFF131E36))),
      ),
      child: Row(
        children: [
          Obx(() {
            final step = ctrl.currentStep.value.clamp(
              0,
              OrganizationController.totalSteps - 1,
            );
            return Text(
              ctrl.currentStep.value >= OrganizationController.totalSteps
                  ? 'Registration Complete'
                  : OrganizationController.stepTitles[step],
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            );
          }),
          const Spacer(),
          Obx(() {
            final step = ctrl.currentStep.value.clamp(
              0,
              OrganizationController.totalSteps,
            );
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF141D35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E2D50)),
              ),
              child: Text(
                'Step ${step + 1} of ${OrganizationController.totalSteps}',
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  color: const Color(0xFF6B7FA8),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP CONTENT ROUTER
// ─────────────────────────────────────────────────────────────
class _StepContent extends StatelessWidget {
  final OrganizationController ctrl;
  const _StepContent({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = ctrl.currentStep.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(step),
          child: _wrapWithNav(
            context,
            step: step,
            child: _buildStep(context, step),
          ),
        ),
      );
    });
  }

  Widget _buildStep(BuildContext context, int step) {
    switch (step) {
      case 0:
        return _StepOrgInfo(ctrl: ctrl);
      case 1:
        return _StepContact(ctrl: ctrl);
      case 2:
        return _StepRepresentative(ctrl: ctrl);
      case 3:
        return _StepBank(ctrl: ctrl);
      case 4:
        return _StepDocuments(ctrl: ctrl);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _wrapWithNav(
    BuildContext context, {
    required int step,
    required Widget child,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
            child: child,
          ),
        ),
        _NavigationBar(ctrl: ctrl, step: step),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NAVIGATION BAR
// ─────────────────────────────────────────────────────────────
class _NavigationBar extends StatelessWidget {
  final OrganizationController ctrl;
  final int step;
  const _NavigationBar({required this.ctrl, required this.step});

  @override
  Widget build(BuildContext context) {
    final isLast = step == OrganizationController.totalSteps - 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF131E36))),
      ),
      child: Row(
        children: [
          // Error message
          Obx(
            () => ctrl.errorMessage.value.isNotEmpty
                ? Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFFF4C6A),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            ctrl.errorMessage.value,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: const Color(0xFFFF4C6A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Spacer(),
          ),

          if (step > 0)
            TextButton.icon(
              onPressed: ctrl.prevStep,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7FA8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Obx(
            () => ctrl.isLoading.value
                ? const SizedBox(
                    width: 120,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00D4AA),
                        ),
                      ),
                    ),
                  )
                : _GradientButton(
                    label: isLast ? 'Submit Registration' : 'Continue',
                    icon: isLast
                        ? Icons.send_rounded
                        : Icons.arrow_forward_ios_rounded,
                    onTap: isLast ? ctrl.submit : ctrl.nextStep,
                  ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [const Color(0xFF00F5C4), const Color(0xFF9B7EFF)]
                  : [const Color(0xFF00D4AA), const Color(0xFF7B61FF)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D4AA).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Icon(widget.icon, size: 14, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF6B7FA8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFB0C4E8),
            ),
          ),
          if (required) ...[
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(color: Color(0xFFFF4C6A), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _buildTextField(
  TextEditingController ctrl, {
  required String label,
  String? hint,
  bool required = true,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  int maxLines = 1,
  List<TextInputFormatter>? inputFormatters,
  Widget? suffix,
  bool readOnly = false,
  VoidCallback? onTap,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label, required: required),
      TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        validator:
            validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                      ? '$label is required'
                      : null
                : null),
      ),
    ],
  );
}

Widget _row2(Widget a, Widget b) => Row(
  children: [
    Expanded(child: a),
    const SizedBox(width: 16),
    Expanded(child: b),
  ],
);

const _gap = SizedBox(height: 16);

// ─────────────────────────────────────────────────────────────
//  STEP 0 — ORG INFO
// ─────────────────────────────────────────────────────────────
class _StepOrgInfo extends StatelessWidget {
  final OrganizationController ctrl;
  const _StepOrgInfo({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: ctrl.formKeyStep0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Organization Information',
            subtitle: 'Provide the official details of your organization.',
          ),
          _buildTextField(
            ctrl.orgNameCtrl,
            label: 'Organization Name',
            hint: 'e.g. Save the Children',
          ),
          _gap,
          _row2(
            // Org Type Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Organization Type'),
                Obx(
                  () => DropdownButtonFormField<OrganizationType>(
                    value: ctrl.selectedOrgType.value,
                    dropdownColor: const Color(0xFF141D35),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(),
                    items: OrganizationType.values
                        .map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.label)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) ctrl.selectedOrgType.value = v;
                    },
                  ),
                ),
              ],
            ),
            _buildTextField(
              ctrl.regNumberCtrl,
              label: 'Registration Number',
              hint: 'e.g. 21321324554',
            ),
          ),
          _gap,
          _row2(
            _buildTextField(
              ctrl.dateCtrl,
              label: 'Date of Registration',
              hint: 'YYYY-MM-DD',
              readOnly: true,
              onTap: () => ctrl.pickDate(context),
              suffix: const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Color(0xFF6B7FA8),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Date is required' : null,
            ),
            _buildTextField(ctrl.countryCtrl, label: 'Country', hint: 'Nepal'),
          ),
          _gap,
          _row2(
            _buildTextField(ctrl.cityCtrl, label: 'City', hint: 'Kathmandu'),
            _buildTextField(
              ctrl.addressCtrl,
              label: 'Registered Address',
              hint: 'Street / Ward / District',
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 1 — CONTACT & SOCIAL
// ─────────────────────────────────────────────────────────────
class _StepContact extends StatelessWidget {
  final OrganizationController ctrl;
  const _StepContact({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: ctrl.formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Contact & Social Media',
            subtitle: 'How can people reach your organization?',
          ),
          _row2(
            _buildTextField(
              ctrl.emailCtrl,
              label: 'Official Email',
              hint: 'org@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!GetUtils.isEmail(v.trim())) return 'Invalid email';
                return null;
              },
            ),
            _buildTextField(
              ctrl.phoneCtrl,
              label: 'Official Phone',
              hint: '+977-9800000000',
              keyboardType: TextInputType.phone,
            ),
          ),
          _gap,
          _buildTextField(
            ctrl.websiteCtrl,
            label: 'Website',
            hint: 'https://example.org',
            required: false,
            keyboardType: TextInputType.url,
          ),
          _gap,
          const _FieldLabel('Social Media', required: false),
          const SizedBox(height: 8),
          _socialField(
            ctrl.facebookCtrl,
            Icons.facebook_rounded,
            'Facebook URL',
            const Color(0xFF1877F2),
          ),
          const SizedBox(height: 10),
          _socialField(
            ctrl.instagramCtrl,
            Icons.camera_alt_rounded,
            'Instagram URL',
            const Color(0xFFE1306C),
          ),
          const SizedBox(height: 10),
          _socialField(
            ctrl.linkedinCtrl,
            Icons.work_rounded,
            'LinkedIn URL',
            const Color(0xFF0A66C2),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _socialField(
    TextEditingController c,
    IconData icon,
    String hint,
    Color iconColor,
  ) {
    return TextFormField(
      controller: c,
      style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: iconColor, size: 18),
      ),
      keyboardType: TextInputType.url,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 2 — REPRESENTATIVE
// ─────────────────────────────────────────────────────────────
class _StepRepresentative extends StatelessWidget {
  final OrganizationController ctrl;
  const _StepRepresentative({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: ctrl.formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Representative Details',
            subtitle: 'Who is the primary contact for this registration?',
          ),
          _row2(
            _buildTextField(
              ctrl.repNameCtrl,
              label: 'Representative Name',
              hint: 'Full legal name',
            ),
            _buildTextField(
              ctrl.designationCtrl,
              label: 'Designation',
              hint: 'e.g. Founder, Director',
            ),
          ),
          _gap,
          _row2(
            _buildTextField(
              ctrl.primaryCauseCtrl,
              label: 'Primary Cause',
              hint: 'e.g. Education for Underprivileged',
            ),
            _buildTextField(
              ctrl.activeMembersCtrl,
              label: 'Active Members',
              hint: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          _gap,
          _buildTextField(
            ctrl.missionCtrl,
            label: 'Mission Statement',
            hint: 'Describe your organization\'s mission in a few sentences...',
            maxLines: 3,
          ),
          _gap,
          _buildTextField(
            ctrl.campaignsCtrl,
            label: 'Recent Campaigns',
            hint: 'e.g. School Kit Distribution - 2024',
            maxLines: 2,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 3 — BANK
// ─────────────────────────────────────────────────────────────
class _StepBank extends StatelessWidget {
  final OrganizationController ctrl;
  const _StepBank({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: ctrl.formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Bank Details',
            subtitle:
                'Provide your organization\'s official bank account information.',
          ),
          _row2(
            _buildTextField(
              ctrl.bankNameCtrl,
              label: 'Bank Name',
              hint: 'e.g. NMB Bank',
            ),
            _buildTextField(
              ctrl.bankBranchCtrl,
              label: 'Branch',
              hint: 'e.g. Putalisadak',
            ),
          ),
          _gap,
          _buildTextField(
            ctrl.accountHolderCtrl,
            label: 'Account Holder Name',
            hint: 'As printed on the account',
          ),
          _gap,
          _buildTextField(
            ctrl.accountNumberCtrl,
            label: 'Account Number',
            hint: '001-0001234567000',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 4 — DOCUMENTS
// ─────────────────────────────────────────────────────────────
class _StepDocuments extends StatelessWidget {
  final OrganizationController ctrl;
  const _StepDocuments({required this.ctrl});

  static const _docs = [
    _DocMeta(
      key: 'registrationCertificate',
      title: 'Registration Certificate',
      subtitle: 'PDF format required',
      icon: Icons.badge_rounded,
      accept: 'PDF',
    ),
    _DocMeta(
      key: 'taxCertificate',
      title: 'Tax Certificate',
      subtitle: 'PDF format required',
      icon: Icons.receipt_long_rounded,
      accept: 'PDF',
    ),
    _DocMeta(
      key: 'constitutionFile',
      title: 'Constitution File',
      subtitle: 'Organization\'s official constitution — PDF',
      icon: Icons.article_rounded,
      accept: 'PDF',
    ),
    _DocMeta(
      key: 'proofOfAddress',
      title: 'Proof of Address',
      subtitle: 'JPG or PNG image',
      icon: Icons.home_rounded,
      accept: 'JPG / PNG',
    ),
    _DocMeta(
      key: 'voidCheque',
      title: 'Void Cheque',
      subtitle: 'Clear photo of the cheque — JPG or PNG',
      icon: Icons.credit_card_rounded,
      accept: 'JPG / PNG',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: ctrl.formKeyStep4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Supporting Documents',
            subtitle:
                'Upload all required files to complete your registration.',
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.4,
            children: _docs
                .map((d) => _DocUploadCard(ctrl: ctrl, meta: d))
                .toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DocMeta {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String accept;
  const _DocMeta({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accept,
  });
}

class _DocUploadCard extends StatefulWidget {
  final OrganizationController ctrl;
  final _DocMeta meta;
  const _DocUploadCard({required this.ctrl, required this.meta});

  @override
  State<_DocUploadCard> createState() => _DocUploadCardState();
}

class _DocUploadCardState extends State<_DocUploadCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final file = widget.ctrl.fileFor(widget.meta.key);
      final hasFile = file != null;
      final accent = const Color(0xFF00D4AA);

      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => widget.ctrl.pickFile(widget.meta.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasFile
                  ? accent.withOpacity(0.06)
                  : _hovered
                  ? const Color(0xFF1A2440)
                  : const Color(0xFF0F1628),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFile
                    ? accent.withOpacity(0.4)
                    : _hovered
                    ? const Color(0xFF2D3F60)
                    : const Color(0xFF1A2440),
                width: hasFile ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasFile
                        ? accent.withOpacity(0.15)
                        : const Color(0xFF141D35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasFile ? Icons.check_circle_rounded : widget.meta.icon,
                    color: hasFile ? accent : const Color(0xFF3D4F72),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.meta.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: hasFile
                              ? Colors.white
                              : const Color(0xFFB0C4E8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasFile ? file.name : widget.meta.subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: hasFile ? accent : const Color(0xFF4A5D80),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Icon(
                  hasFile
                      ? Icons.swap_horiz_rounded
                      : Icons.upload_file_rounded,
                  color: const Color(0xFF3D4F72),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  SUCCESS SCREEN
// ─────────────────────────────────────────────────────────────
class _SuccessScreen extends StatelessWidget {
  final OrganizationController ctrl;
  const _SuccessScreen({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final result = ctrl.submissionResult.value;

    return Center(
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated checkmark
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF7B61FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4AA).withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.black,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Registration Submitted!',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Go To Login!',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            _GradientButton(
              label: 'LogIn',
              icon: Icons.login_rounded,
              onTap: () => Get.to(() => const LoginPage()),
            ),

            const SizedBox(height: 8),

            Text(
              result?.message ??
                  'Your organization registration has been received.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF6B7FA8),
              ),
            ),
            if (result != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1628),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E2D50)),
                ),
                child: Column(
                  children: [
                    _resultRow('Organization', result.data.name),
                    const SizedBox(height: 12),
                    _resultRow('Reference ID', result.data.id),
                    const SizedBox(height: 12),
                    _resultRow(
                      'Status',
                      result.data.status,
                      valueColor: const Color(0xFFFFB84C),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            _GradientButton(
              label: 'Register Another',
              icon: Icons.add_rounded,
              onTap: ctrl.reset,
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF6B7FA8),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
