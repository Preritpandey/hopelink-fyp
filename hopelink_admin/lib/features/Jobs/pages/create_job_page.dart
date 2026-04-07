// ─────────────────────────────────────────────────────────────
//  PAGE  —  create_job_page.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/job_controller.dart';
import '../models/job_model.dart';
import '../widgets/job_atoms.dart';
import '../widgets/job_theme.dart';


class CreateJobPage extends StatelessWidget {
  final JobController ctrl;
  const CreateJobPage({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top ──────────────────────────────────────────────
        _Header(ctrl: ctrl),
        // ── Form body ─────────────────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                  child: Form(
                    key: ctrl.createFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Section 1: Basic Info ─────────────
                        _FormSection(
                          title: 'Basic Information',
                          icon: Icons.info_outline_rounded,
                          color: jGreen,
                          children: [
                            JField(
                              controller: ctrl.titleCtrl,
                              label: 'Job Title',
                              hint: 'e.g. Website Maintenance Volunteer',
                            ),
                            const SizedBox(height: 14),
                            JField(
                              controller: ctrl.descCtrl,
                              label: 'Description',
                              hint: 'Describe the role and responsibilities...',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 14),
                            Row(children: [
                              Expanded(
                                child: _CategoryDropdown(ctrl: ctrl),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _JobTypeSelector(ctrl: ctrl),
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Section 2: Location ───────────────
                        _FormSection(
                          title: 'Location',
                          icon: Icons.location_on_rounded,
                          color: jTeal,
                          children: [
                            JField(
                              controller: ctrl.addressCtrl,
                              label: 'Address / Venue',
                              hint: 'e.g. Bhaktapur Municipality Office',
                              prefix: const Padding(
                                padding: EdgeInsets.only(left: 12, right: 8),
                                child: Icon(Icons.place_rounded, size: 16, color: jMuted),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(children: [
                              Expanded(
                                child: JField(
                                    controller: ctrl.cityCtrl,
                                    label: 'City',
                                    hint: 'Kathmandu'),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: JField(
                                    controller: ctrl.stateCtrl,
                                    label: 'State / Province',
                                    hint: 'Bagmati'),
                              ),
                            ]),
                            const SizedBox(height: 14),
                            Row(children: [
                              Expanded(
                                child: JField(
                                  controller: ctrl.latCtrl,
                                  label: 'Latitude',
                                  hint: '27.6710',
                                  required: false,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: JField(
                                  controller: ctrl.lngCtrl,
                                  label: 'Longitude',
                                  hint: '85.4298',
                                  required: false,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                ),
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Section 3: Details ────────────────
                        _FormSection(
                          title: 'Job Details',
                          icon: Icons.tune_rounded,
                          color: jIndigo,
                          children: [
                            Row(children: [
                              Expanded(
                                child: JField(
                                  controller: ctrl.positionsCtrl,
                                  label: 'Positions Available',
                                  hint: '1',
                                  keyboardType: TextInputType.number,
                                  formatters: [FilteringTextInputFormatter.digitsOnly],
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(left: 12, right: 8),
                                    child: Icon(Icons.group_rounded, size: 16, color: jMuted),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: JField(
                                  controller: ctrl.creditHoursCtrl,
                                  label: 'Credit Hours',
                                  hint: '10',
                                  keyboardType: TextInputType.number,
                                  formatters: [FilteringTextInputFormatter.digitsOnly],
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(left: 12, right: 8),
                                    child: Icon(Icons.school_rounded, size: 16, color: jMuted),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 14),
                            JField(
                              controller: ctrl.deadlineCtrl,
                              label: 'Application Deadline',
                              hint: 'Pick a date',
                              readOnly: true,
                              onTap: () => ctrl.pickDeadline(context),
                              suffix: const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(Icons.event_rounded, size: 16, color: jMuted),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Deadline is required' : null,
                            ),
                            const SizedBox(height: 14),
                            // Certificate toggle
                            Obx(() {
                              final provided = ctrl.certificateProvided.value;
                              return _CertificateToggle(
                                ctrl: ctrl,
                                provided: provided,
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Section 4: Skills ─────────────────
                        _FormSection(
                          title: 'Required Skills',
                          icon: Icons.bolt_rounded,
                          color: jBlue,
                          children: [
                            // Skill input row
                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: ctrl.skillInputCtrl,
                                  style: GoogleFonts.inter(fontSize: 13, color: jText),
                                  onFieldSubmitted: ctrl.addSkill,
                                  decoration: InputDecoration(
                                    hintText: 'Type skill and press Enter...',
                                    hintStyle: GoogleFonts.inter(fontSize: 13, color: jMuted),
                                    filled: true,
                                    fillColor: jSurf,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: jR10,
                                      borderSide: const BorderSide(color: jBorder, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: jR10,
                                      borderSide: const BorderSide(color: jGreen, width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 13),
                                    suffixIcon: GestureDetector(
                                      onTap: () => ctrl.addSkill(ctrl.skillInputCtrl.text),
                                      child: Container(
                                        margin: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: jGreen.withOpacity(0.15),
                                          borderRadius: jR8,
                                        ),
                                        child: const Icon(Icons.add_rounded,
                                            size: 16, color: jGreen),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 10),

                            // Suggestions
                            Text('Suggestions:',
                                style: jMonoSm()),
                            const SizedBox(height: 6),
                            Obx(() => Wrap(
                              spacing: 6, runSpacing: 6,
                              children: kJobSkillSuggestions
                                  .where((s) => !ctrl.selectedSkills.contains(s))
                                  .take(8)
                                  .map((s) => _SuggestionChip(
                                    label: s,
                                    onTap: () => ctrl.addSkill(s),
                                  ))
                                  .toList(),
                            )),
                            const SizedBox(height: 10),

                            // Selected skills
                            Obx(() {
                              if (ctrl.selectedSkills.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: jSurf2,
                                    borderRadius: jR10,
                                    border: Border.all(color: jBorder),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.info_outline_rounded,
                                        size: 14, color: jMuted),
                                    const SizedBox(width: 8),
                                    Text('No skills added yet.',
                                        style: jMonoSm()),
                                  ]),
                                );
                              }
                              return Wrap(
                                spacing: 6, runSpacing: 6,
                                children: ctrl.selectedSkills.map((s) =>
                                  SkillChip(
                                    label: s,
                                    color: jBlue,
                                    onRemove: () => ctrl.removeSkill(s),
                                  ),
                                ).toList(),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Submit ────────────────────────────
                        Obx(() => JAlert(message: ctrl.createError.value)),
                        Obx(() => JAlert(
                            message: ctrl.createSuccess.value,
                            isError: false)),
                        Obx(() => SizedBox(
                          width: double.infinity,
                          child: JBtn(
                            label: 'Post Volunteer Job',
                            icon: Icons.rocket_launch_rounded,
                            loading: ctrl.isCreatingJob.value,
                            height: 48,
                            onTap: ctrl.createJob,
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Right tips panel ─────────────────────────
              _TipsPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final JobController ctrl;
  const _Header({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: jBorder))),
      child: Row(children: [
        JIconBtn(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back to Jobs',
          onTap: ctrl.backToList,
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Post a Volunteer Job', style: jH2()),
          Text('Fill in the details to recruit volunteers',
              style: jMonoSm()),
        ]),
      ]),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: jSurf,
        borderRadius: jR14,
        border: Border.all(color: jBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: jR8,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 10),
            Text(title, style: jH3()),
          ]),
          const SizedBox(height: 16),
          const Divider(color: jBorder, height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final JobController ctrl;
  const _CategoryDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Category',
              style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: jSub)),
          const Text(' *',
              style: TextStyle(color: jRose, fontSize: 11)),
        ]),
        const SizedBox(height: 6),
        Obx(() => DropdownButtonFormField<String>(
          value: ctrl.selectedCategory.value,
          dropdownColor: jSurf2,
          style: GoogleFonts.inter(fontSize: 13, color: jText),
          decoration: InputDecoration(
            filled: true,
            fillColor: jSurf,
            enabledBorder: OutlineInputBorder(
                borderRadius: jR10,
                borderSide: const BorderSide(color: jBorder, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: jR10,
                borderSide: const BorderSide(color: jGreen, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
          items: kJobCategories.map((c) =>
            DropdownMenuItem(value: c, child: Text(c)),
          ).toList(),
          onChanged: (v) { if (v != null) ctrl.selectedCategory.value = v; },
        )),
      ],
    );
  }
}

class _JobTypeSelector extends StatelessWidget {
  final JobController ctrl;
  const _JobTypeSelector({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Job Type',
            style: GoogleFonts.outfit(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: jSub)),
        const SizedBox(height: 6),
        Obx(() => Wrap(
          spacing: 6,
          children: JobType.values.map((t) {
            final selected = ctrl.selectedJobType.value == t;
            final theme    = jobTypeTheme(t);
            return GestureDetector(
              onTap: () => ctrl.selectedJobType.value = t,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? theme.color.withOpacity(0.12) : jSurf2,
                  borderRadius: jR8,
                  border: Border.all(
                    color: selected ? theme.color.withOpacity(0.4) : jBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(theme.icon, size: 12,
                      color: selected ? theme.color : jMuted),
                  const SizedBox(width: 5),
                  Text(t.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: selected ? theme.color : jSub,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      )),
                ]),
              ),
            );
          }).toList(),
        )),
      ],
    );
  }
}

class _CertificateToggle extends StatelessWidget {
  final JobController ctrl;
  final bool provided;
  const _CertificateToggle({required this.ctrl, required this.provided});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: provided ? jIndigo.withOpacity(0.07) : jSurf2,
        borderRadius: jR10,
        border: Border.all(
          color: provided ? jIndigo.withOpacity(0.3) : jBorder,
        ),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: provided ? jIndigo.withOpacity(0.15) : jSurf3,
            borderRadius: jR8,
          ),
          child: Icon(Icons.verified_rounded,
              size: 15,
              color: provided ? jIndigo : jMuted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Provide Certificate',
                style: jH3().copyWith(fontSize: 12)),
            Text('Volunteers receive a certificate upon completion.',
                style: jMonoSm()),
          ]),
        ),
        Switch(
          value: provided,
          onChanged: (v) => ctrl.certificateProvided.value = v,
          activeColor: jIndigo,
          activeTrackColor: jIndigo.withOpacity(0.3),
          inactiveTrackColor: jBorder2,
          inactiveThumbColor: jMuted,
        ),
      ]),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});
  @override State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _h ? jSurf3 : jSurf2,
            borderRadius: jR6,
            border: Border.all(color: _h ? jBorder2 : jBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, size: 10,
                color: _h ? jGreen : jMuted),
            const SizedBox(width: 3),
            Text(widget.label,
                style: GoogleFonts.firaCode(
                    fontSize: 10,
                    color: _h ? jText : jSub)),
          ]),
        ),
      ),
    );
  }
}

class _TipsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const tips = [
      ('Be specific', 'Clear job titles and descriptions attract better candidates.'),
      ('Set realistic quotas', 'Only post as many positions as you can effectively manage.'),
      ('List key skills', 'Specific skills help filter the right volunteers.'),
      ('Choose the right type', 'Remote roles expand your reach, onsite builds community.'),
      ('Offer recognition', 'Certificates and credit hours boost volunteer motivation.'),
    ];

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: jBorder)),
        color: Color(0xFF080D1C),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lightbulb_rounded, color: jAmber, size: 15),
            const SizedBox(width: 6),
            Text('Posting Tips',
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: jAmber)),
          ]),
          const SizedBox(height: 16),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(
                        color: jGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Text(t.$1,
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: jText)),
                ]),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(t.$2,
                      style: jMonoSm().copyWith(height: 1.5)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
