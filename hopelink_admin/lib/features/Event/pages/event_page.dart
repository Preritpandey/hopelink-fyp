import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Dashboard/controllers/campaign_controller.dart';
import '../controllers/event_controller.dart';
import '../models/event_model.dart';
import '../widgets/event_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  CREATE EVENT PAGE  (entry point)
// ─────────────────────────────────────────────────────────────
class CreateEventPage extends StatefulWidget {
  final CampaignController ctrl;
  const CreateEventPage({super.key, required this.ctrl});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventCtrl = Get.put(EventController());
    return Scaffold(
      backgroundColor: kEvBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          children: [
            // ── Left panel ──────────────────────────────────
            _LeftInfoPanel(),
            // ── Right wizard ────────────────────────────────
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _TopBar(ctrl: eventCtrl),
                  Expanded(
                    child: Obx(
                      () => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0.03, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: anim,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(eventCtrl.wizardStep.value),
                          child: _buildStep(eventCtrl),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(EventController eventCtrl) {
    switch (eventCtrl.wizardStep.value) {
      case 0:
        return _Step0BasicInfo(ctrl: eventCtrl);
      case 1:
        return _Step1Location(ctrl: eventCtrl);
      case 2:
        return _Step2Details(ctrl: eventCtrl);
      case 3:
        return _Step3Images(ctrl: eventCtrl);
      case 4:
        return _SuccessScreen(ctrl: eventCtrl, navCtrl: widget.ctrl);
      default:
        return _Step0BasicInfo(ctrl: eventCtrl);
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  LEFT INFO PANEL  (decorative / static)
// ─────────────────────────────────────────────────────────────
class _LeftInfoPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF09102A),
        border: Border(right: BorderSide(color: kEvBorder)),
      ),
      child: Stack(
        children: [
          // Background orbs
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kEvAccent.withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kEvAccent2.withOpacity(0.08), Colors.transparent],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kEvAccent, kEvAccent2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: kEvAccent.withOpacity(0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'OrgHub',
                      style: GoogleFonts.sora(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Title block
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kEvAccent.withOpacity(0.12),
                        kEvAccent2.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kEvAccent.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            color: kEvAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Create Event',
                            style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kEvAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Host an impactful event that connects volunteers with your cause.',
                        style: GoogleFonts.sora(
                          fontSize: 11.5,
                          color: kEvSub,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Step guide
                Text(
                  'STEPS',
                  style: GoogleFonts.sora(
                    fontSize: 9,
                    color: kEvMuted,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ..._stepGuide.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: kEvSurf3,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: kEvBorder2),
                          ),
                          child: Center(
                            child: Icon(s.$2, size: 11, color: kEvSub),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          s.$1,
                          style: GoogleFonts.sora(fontSize: 12, color: kEvSub),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Tips box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kEvSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kEvBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: kEvGold,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pro Tip',
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kEvGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Events with clear descriptions and good images attract 3× more volunteers.',
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: kEvSub,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _stepGuide = [
    ('Basic Information', Icons.info_outline_rounded),
    ('Event Location', Icons.location_on_outlined),
    ('Volunteer Details', Icons.group_outlined),
    ('Upload Images', Icons.image_outlined),
  ];
}

// ─────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final EventController ctrl;
  const _TopBar({required this.ctrl});

  static const _stepLabels = ['Basic Info', 'Location', 'Details', 'Images'];
  static const _stepIcons = [
    Icons.info_outline_rounded,
    Icons.location_on_outlined,
    Icons.group_outlined,
    Icons.image_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kEvBorder)),
      ),
      child: Obx(() {
        final step = ctrl.wizardStep.value.clamp(0, 3);
        if (ctrl.wizardStep.value >= 4) {
          return Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: kEvAccent2,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Event Created Successfully',
                style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kEvText,
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Step ${ctrl.wizardStep.value + 1} of 4',
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    color: kEvAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Linear progress chip
                Container(
                  width: 120,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kEvBorder2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (ctrl.wizardStep.value + 1) / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kEvAccent, kEvAccent2],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            EventWizardProgress(
              current: step,
              total: 4,
              labels: _stepLabels,
              icons: _stepIcons,
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOTTOM NAV BAR
// ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final EventController ctrl;
  final bool isLast;
  final VoidCallback onNext;
  const _BottomNav({
    required this.ctrl,
    this.isLast = false,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kEvBorder)),
      ),
      child: Row(
        children: [
          Obx(() => EvAlertBar(message: ctrl.errorMsg.value, isError: true)),
          const Spacer(),
          if (ctrl.wizardStep.value > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: EvPrimaryBtn(
                label: 'Back',
                icon: Icons.arrow_back_ios_new_rounded,
                secondary: true,
                onTap: ctrl.prevStep,
              ),
            ),
          Obx(
            () => EvPrimaryBtn(
              label: isLast ? 'Create Event' : 'Continue',
              icon: isLast
                  ? Icons.rocket_launch_rounded
                  : Icons.arrow_forward_rounded,
              loading: ctrl.isSubmitting.value,
              onTap: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 0 — BASIC INFO
// ─────────────────────────────────────────────────────────────
class _Step0BasicInfo extends StatelessWidget {
  final EventController ctrl;
  const _Step0BasicInfo({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Form(
              key: ctrl.formKeyStep0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EvSectionLabel(
                    text: 'Basic Information',
                    icon: Icons.info_outline_rounded,
                  ),
                  EvField(
                    controller: ctrl.titleCtrl,
                    label: 'Event Title',
                    hint: 'e.g. Human Rights Awareness Program',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        Icons.campaign_rounded,
                        size: 17,
                        color: kEvMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  EvField(
                    controller: ctrl.descCtrl,
                    label: 'Description',
                    hint:
                        'Describe the event, its purpose, and what volunteers can expect...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),

                  // Category
                  Obx(
                    () => EvChipSelector<EventCategory>(
                      label: 'Event Category',
                      options: EventCategory.values,
                      selected: ctrl.selectedCategory.value,
                      labelOf: (c) => c.label,
                      onSelect: (c) => ctrl.selectedCategory.value = c,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Event Type
                  Obx(
                    () => EvChipSelector<EventType>(
                      label: 'Event Type',
                      options: EventType.values,
                      selected: ctrl.selectedEventType.value,
                      labelOf: (t) => t.label,
                      onSelect: (t) => ctrl.selectedEventType.value = t,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        _BottomNav(ctrl: ctrl, onNext: ctrl.nextStep),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 1 — LOCATION
// ─────────────────────────────────────────────────────────────
class _Step1Location extends StatelessWidget {
  final EventController ctrl;
  const _Step1Location({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Form(
              key: ctrl.formKeyStep1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EvSectionLabel(
                    text: 'Event Location',
                    icon: Icons.location_on_rounded,
                  ),
                  EvField(
                    controller: ctrl.addressCtrl,
                    label: 'Venue / Address',
                    hint: 'e.g. Banepa Municipality Hall',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        Icons.place_rounded,
                        size: 17,
                        color: kEvMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: EvField(
                          controller: ctrl.cityCtrl,
                          label: 'City / District',
                          hint: 'e.g. Kavre',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: EvField(
                          controller: ctrl.stateCtrl,
                          label: 'Province / State',
                          hint: 'e.g. Bagmati',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Coordinates
                  Text(
                    'GPS Coordinates',
                    style: GoogleFonts.sora(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: kEvSub,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter longitude first, then latitude (optional but improves discoverability)',
                    style: GoogleFonts.sora(fontSize: 10.5, color: kEvMuted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: EvField(
                          controller: ctrl.lngCtrl,
                          label: 'Longitude',
                          hint: '-118.4912',
                          required: false,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: Icon(
                              Icons.west_rounded,
                              size: 15,
                              color: kEvMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: EvField(
                          controller: ctrl.latCtrl,
                          label: 'Latitude',
                          hint: '34.0195',
                          required: false,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: Icon(
                              Icons.north_rounded,
                              size: 15,
                              color: kEvMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Map hint card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kEvAccent2.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kEvAccent2.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.map_rounded,
                          color: kEvAccent2.withOpacity(0.7),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Coordinates help volunteers find your event on the map. Use Google Maps to find accurate coordinates.',
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: kEvSub,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        _BottomNav(ctrl: ctrl, onNext: ctrl.nextStep),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 2 — DETAILS (dates, volunteers, skills)
// ─────────────────────────────────────────────────────────────
class _Step2Details extends StatelessWidget {
  final EventController ctrl;
  const _Step2Details({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Form(
              key: ctrl.formKeyStep2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EvSectionLabel(
                    text: 'Event Details',
                    icon: Icons.tune_rounded,
                  ),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: EvField(
                          controller: ctrl.startDateCtrl,
                          label: 'Start Date',
                          hint: 'Pick a date',
                          readOnly: true,
                          onTap: () => ctrl.pickStartDate(context),
                          suffix: const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: kEvMuted,
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: EvField(
                          controller: ctrl.endDateCtrl,
                          label: 'End Date',
                          hint: 'Pick a date',
                          readOnly: true,
                          onTap: () => ctrl.pickEndDate(context),
                          suffix: const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Icon(
                              Icons.event_available_rounded,
                              size: 15,
                              color: kEvMuted,
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: EvField(
                          controller: ctrl.maxVolunteersCtrl,
                          label: 'Max Volunteers',
                          hint: '50',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: Icon(
                              Icons.group_rounded,
                              size: 17,
                              color: kEvMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _EligibilityDropdown(ctrl: ctrl)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Skills
                  Text(
                    'Required Skills',
                    style: GoogleFonts.sora(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: kEvSub,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Input row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: ctrl.skillInputCtrl,
                          style: GoogleFonts.sora(fontSize: 13, color: kEvText),
                          onFieldSubmitted: ctrl.addSkill,
                          decoration: InputDecoration(
                            hintText: 'Type a skill and press Enter...',
                            hintStyle: GoogleFonts.sora(
                              fontSize: 13,
                              color: kEvMuted,
                            ),
                            filled: true,
                            fillColor: kEvSurface,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: kEvBorder,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: kEvAccent,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _AddSkillBtn(onTap: ctrl.addSkillFromInput),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Suggestions
                  Text(
                    'Suggestions:',
                    style: GoogleFonts.sora(fontSize: 10, color: kEvMuted),
                  ),
                  const SizedBox(height: 6),
                  Obx(
                    () => Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: kSkillSuggestions
                          .where((s) => !ctrl.selectedSkills.contains(s))
                          .take(8)
                          .map(
                            (s) => SuggestionChip(
                              label: s,
                              onTap: () => ctrl.addSkill(s),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selected skills
                  Obx(() {
                    if (ctrl.selectedSkills.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kEvSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kEvBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: kEvMuted,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'No skills added yet.',
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                color: kEvMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ctrl.selectedSkills
                          .map(
                            (s) => SkillChip(
                              label: s,
                              onRemove: () => ctrl.removeSkill(s),
                            ),
                          )
                          .toList(),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        _BottomNav(ctrl: ctrl, onNext: ctrl.nextStep),
      ],
    );
  }
}

class _EligibilityDropdown extends StatelessWidget {
  final EventController ctrl;
  const _EligibilityDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Eligibility',
              style: GoogleFonts.sora(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: kEvSub,
                letterSpacing: 0.2,
              ),
            ),
            const Text(' *', style: TextStyle(color: kEvRed, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: ctrl.eligibilityCtrl.text.isNotEmpty
              ? (kEligibilityOptions.contains(ctrl.eligibilityCtrl.text)
                    ? ctrl.eligibilityCtrl.text
                    : null)
              : null,
          dropdownColor: kEvSurf2,
          style: GoogleFonts.sora(fontSize: 13, color: kEvText),
          hint: Text(
            'Select',
            style: GoogleFonts.sora(fontSize: 13, color: kEvMuted),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: kEvSurface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kEvBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kEvAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kEvRed, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
          items: kEligibilityOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) ctrl.eligibilityCtrl.text = v;
          },
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }
}

class _AddSkillBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _AddSkillBtn({required this.onTap});
  @override
  State<_AddSkillBtn> createState() => _AddSkillBtnState();
}

class _AddSkillBtnState extends State<_AddSkillBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 46,
          height: 48,
          decoration: BoxDecoration(
            gradient: _h
                ? const LinearGradient(colors: [kEvAccent, Color(0xFFAA88FF)])
                : null,
            color: _h ? null : kEvSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _h ? kEvAccent : kEvBorder, width: 1.5),
          ),
          child: Icon(
            Icons.add_rounded,
            color: _h ? Colors.white : kEvSub,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 3 — IMAGES  (shown only if user chooses to add more)
//  Note: Images are combined into the single POST request
// ─────────────────────────────────────────────────────────────
class _Step3Images extends StatelessWidget {
  final EventController ctrl;
  const _Step3Images({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EvSectionLabel(text: 'Event Images', icon: Icons.image_rounded),
                Text(
                  'Add eye-catching images to showcase your event. Multiple images are supported.',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: kEvSub,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Drop zone
                _ImageDropZone(ctrl: ctrl),
                const SizedBox(height: 16),

                // Image grid
                Obx(() {
                  if (ctrl.pickedImages.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kEvAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: kEvAccent.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              '${ctrl.pickedImages.length} image${ctrl.pickedImages.length > 1 ? 's' : ''} selected',
                              style: GoogleFonts.sora(
                                fontSize: 11,
                                color: kEvAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1,
                            ),
                        itemCount: ctrl.pickedImages.length,
                        itemBuilder: (_, i) => ImagePreviewTile(
                          name: ctrl.pickedImages[i].name,
                          onRemove: () => ctrl.removeImage(i),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _BottomNav(ctrl: ctrl, isLast: true, onNext: ctrl.submitEvent),
      ],
    );
  }
}

class _ImageDropZone extends StatefulWidget {
  final EventController ctrl;
  const _ImageDropZone({required this.ctrl});
  @override
  State<_ImageDropZone> createState() => _ImageDropZoneState();
}

class _ImageDropZoneState extends State<_ImageDropZone> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.ctrl.pickImages,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 140,
          decoration: BoxDecoration(
            color: _h ? kEvSurf3 : kEvSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _h ? kEvAccent.withOpacity(0.5) : kEvBorder,
              width: _h ? 1.5 : 1.5,
            ),
            boxShadow: _h
                ? [
                    BoxShadow(
                      color: kEvAccent.withOpacity(0.08),
                      blurRadius: 20,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _h ? kEvAccent.withOpacity(0.15) : kEvSurf2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_rounded,
                  color: _h ? kEvAccent : kEvMuted,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Click to browse images',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _h ? kEvAccent : kEvSub,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'JPG, PNG, WEBP — single or multiple',
                style: GoogleFonts.sora(fontSize: 11, color: kEvMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SUCCESS SCREEN
// ─────────────────────────────────────────────────────────────
class _SuccessScreen extends StatefulWidget {
  final EventController ctrl;
  final CampaignController navCtrl;
  const _SuccessScreen({required this.ctrl, required this.navCtrl});
  @override
  State<_SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<_SuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.ctrl.createdEvent.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            // Check icon
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kEvAccent, kEvAccent2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kEvAccent.withOpacity(0.45),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Event Created!',
              style: GoogleFonts.sora(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: kEvText,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your event is now live and visible to volunteers.',
              style: GoogleFonts.sora(fontSize: 13, color: kEvSub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            if (event != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left detail card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kEvSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kEvBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Details',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kEvAccent,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          EvInfoRow(
                            icon: Icons.campaign_rounded,
                            label: 'TITLE',
                            value: event.title,
                          ),
                          _divider(),
                          EvInfoRow(
                            icon: Icons.category_rounded,
                            label: 'CATEGORY',
                            value: EventCategory.fromValue(
                              event.category,
                            ).label,
                            valueColor: kEvAccent,
                          ),
                          _divider(),
                          EvInfoRow(
                            icon: Icons.event_repeat_rounded,
                            label: 'TYPE',
                            value: EventType.fromValue(event.eventType).label,
                          ),
                          _divider(),
                          EvInfoRow(
                            icon: Icons.fiber_manual_record_rounded,
                            label: 'STATUS',
                            value: event.status.toUpperCase(),
                            valueColor: kEvAccent2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Right detail card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kEvSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kEvBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule & Location',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kEvAccent2,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          EvInfoRow(
                            icon: Icons.play_circle_outline_rounded,
                            label: 'START DATE',
                            value: widget.ctrl.formatDate(event.startDate),
                          ),
                          _divider(),
                          EvInfoRow(
                            icon: Icons.stop_circle_outlined,
                            label: 'END DATE',
                            value: widget.ctrl.formatDate(event.endDate),
                          ),
                          _divider(),
                          EvInfoRow(
                            icon: Icons.location_on_rounded,
                            label: 'LOCATION',
                            value:
                                '${event.location.address}, ${event.location.city}',
                          ),
                          _divider(),
                          EvInfoRow(
                            icon: Icons.group_rounded,
                            label: 'MAX VOLUNTEERS',
                            value: '${event.maxVolunteers}',
                            valueColor: kEvGold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // ID chip
            if (event != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kEvSurf2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kEvBorder2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag_rounded, size: 13, color: kEvMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Event ID: ',
                      style: GoogleFonts.sora(fontSize: 11, color: kEvSub),
                    ),
                    Text(
                      event.id,
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: kEvAccent,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: event.id));
                      },
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: kEvMuted,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EvPrimaryBtn(
                  label: 'Create Another Event',
                  icon: Icons.add_rounded,
                  secondary: true,
                  onTap: widget.ctrl.reset,
                ),
                const SizedBox(width: 14),
                EvPrimaryBtn(
                  label: 'Back to Dashboard',
                  icon: Icons.dashboard_rounded,
                  onTap: () => widget.navCtrl.navigateTo(0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(color: kEvBorder, height: 16);
}
