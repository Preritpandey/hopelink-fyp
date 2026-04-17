import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopelink_admin/features/Jobs/widgets/job_atoms.dart';
import 'package:hopelink_admin/features/Jobs/widgets/job_theme.dart';
import 'package:hopelink_admin/features/VolunteerCredits/controllers/volunteer_credits_controller.dart';
import 'package:hopelink_admin/features/VolunteerCredits/models/volunteer_credit_model.dart';
import 'package:hopelink_admin/features/VolunteerCredits/widgets/volunteer_credits_widgets.dart';

class VolunteerCreditsPage extends StatefulWidget {
  const VolunteerCreditsPage({super.key});

  @override
  State<VolunteerCreditsPage> createState() => _VolunteerCreditsPageState();
}

class _VolunteerCreditsPageState extends State<VolunteerCreditsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final VolunteerCreditsController ctrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(VolunteerCreditsController());
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: jBg,
      body: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            _TopBar(ctrl: ctrl, searchCtrl: _searchCtrl),
            Expanded(
              child: Obx(() {
                if (ctrl.isBootstrapping.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: jGreen,
                      strokeWidth: 2,
                    ),
                  );
                }

                return Column(
                  children: [
                    _StatsRow(ctrl: ctrl),
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(width: 390, child: _LeftPanel(ctrl: ctrl)),
                          Expanded(child: _RightPanel(ctrl: ctrl)),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VolunteerCreditsController ctrl;
  final TextEditingController searchCtrl;

  const _TopBar({required this.ctrl, required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: jBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [jGreen, jBlue]),
              borderRadius: jR10,
              boxShadow: jGlow(jGreen),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Volunteer Credits', style: jH2()),
              Text(
                'Review approved volunteers and grant credit hours',
                style: jMonoSm(),
              ),
            ],
          ),
          const Spacer(),
          Obx(
            () => CreditSourceToggle(
              value: ctrl.sourceType.value,
              onChanged: (next) {
                searchCtrl.clear();
                ctrl.switchSourceType(next);
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 260,
            child: TextField(
              controller: searchCtrl,
              onChanged: (value) => ctrl.searchQuery.value = value,
              style: GoogleFonts.inter(fontSize: 13, color: jText),
              decoration: InputDecoration(
                hintText: 'Search volunteers...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: jMuted),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: jMuted,
                ),
                filled: true,
                fillColor: jSurf,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: jBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: jGreen.withOpacity(0.5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          JIconBtn(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: () {
              if (ctrl.selectedSource.value == null) {
                ctrl.fetchSources();
              } else {
                ctrl.fetchEntries();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final VolunteerCreditsController ctrl;
  const _StatsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entries = ctrl.entries;
      final granted = entries.where((e) => e.creditsGranted).length;
      final pending = entries.where((e) => !e.creditsGranted).length;
      final totalHours = entries.fold<int>(
        0,
        (sum, e) => sum + e.creditHoursGranted,
      );

      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
        child: Row(
          children: [
            CreditStatCard(
              label: 'Approved Volunteers',
              value: '${entries.length}',
              icon: Icons.groups_2_rounded,
              color: jBlue,
            ),
            const SizedBox(width: 12),
            CreditStatCard(
              label: 'Credits Granted',
              value: '$granted',
              icon: Icons.verified_rounded,
              color: jGreen,
            ),
            const SizedBox(width: 12),
            CreditStatCard(
              label: 'Pending Grant',
              value: '$pending',
              icon: Icons.schedule_rounded,
              color: jAmber,
            ),
            const SizedBox(width: 12),
            CreditStatCard(
              label: 'Total Hours Granted',
              value: '${totalHours}h',
              icon: Icons.workspace_premium_rounded,
              color: jTeal,
            ),
          ],
        ),
      );
    });
  }
}

class _LeftPanel extends StatelessWidget {
  final VolunteerCreditsController ctrl;
  const _LeftPanel({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: jBorder)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: jBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Source', style: jH3()),
                const SizedBox(height: 8),
                Obx(
                  () => CreditSourceDropdown(
                    options: ctrl.sourceOptions,
                    selected: ctrl.selectedSource.value,
                    onChanged: ctrl.selectSource,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoadingSources.value && ctrl.sourceOptions.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: jGreen,
                    strokeWidth: 2,
                  ),
                );
              }

              if (ctrl.sourceError.value.isNotEmpty &&
                  ctrl.sourceOptions.isEmpty) {
                return CreditEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to load sources',
                  subtitle: ctrl.sourceError.value,
                  action: JBtn(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    ghost: true,
                    onTap: ctrl.fetchSources,
                  ),
                );
              }

              if (ctrl.selectedSource.value == null) {
                return CreditEmptyState(
                  icon: Icons.filter_alt_off_rounded,
                  title: 'No source available',
                  subtitle: ctrl.sourceType.value == VolunteerCreditSource.job
                      ? 'Post a volunteer job first to manage credit approvals.'
                      : 'Create an event first to review approved participants.',
                );
              }

              if (ctrl.isLoadingEntries.value && ctrl.entries.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: List.generate(4, (_) => const SkeletonJobCard()),
                );
              }

              if (ctrl.entriesError.value.isNotEmpty && ctrl.entries.isEmpty) {
                return CreditEmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Failed to load volunteers',
                  subtitle: ctrl.entriesError.value,
                  action: JBtn(
                    label: 'Try Again',
                    icon: Icons.refresh_rounded,
                    ghost: true,
                    onTap: ctrl.fetchEntries,
                  ),
                );
              }

              final items = ctrl.filteredEntries;
              if (items.isEmpty) {
                return CreditEmptyState(
                  icon: Icons.group_off_rounded,
                  title: 'No matching volunteers',
                  subtitle: ctrl.searchQuery.value.isNotEmpty
                      ? 'Try a different search term.'
                      : 'Approved volunteers will appear here.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final entry = items[index];
                  return VolunteerEntryCard(
                    entry: entry,
                    ctrl: ctrl,
                    selected: ctrl.selectedEntry.value?.id == entry.id,
                    onTap: () => ctrl.selectEntry(entry),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  final VolunteerCreditsController ctrl;
  const _RightPanel({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entry = ctrl.selectedEntry.value;
      if (entry == null) {
        return const CreditEmptyState(
          icon: Icons.touch_app_rounded,
          title: 'Select a volunteer',
          subtitle:
              'Pick an approved volunteer from the left panel to review their profile and credit status.',
        );
      }

      return VolunteerCreditDetailPanel(
        entry: entry,
        source: ctrl.selectedSource.value,
        ctrl: ctrl,
      );
    });
  }
}
