
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/job_controller.dart';
import '../widgets/application_widgets.dart';
import '../widgets/job_atoms.dart';
import '../widgets/job_card.dart';
import '../widgets/job_theme.dart';
import 'create_job_page.dart';


// ─────────────────────────────────────────────────────────────
//  ROOT PAGE
// ─────────────────────────────────────────────────────────────
class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _fade    = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _opacity = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    _fade.forward();
  }

  @override
  void dispose() { _fade.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(JobController());

    return Scaffold(
      backgroundColor: jBg,
      body: FadeTransition(
        opacity: _opacity,
        child: Obx(() {
          switch (ctrl.panelView.value) {
            case JobPanelView.create:
              return CreateJobPage(ctrl: ctrl);
            case JobPanelView.applications:
              return _ApplicationsView(ctrl: ctrl);
            case JobPanelView.list:
              return _JobsListView(ctrl: ctrl);
          }
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  JOBS LIST VIEW
// ─────────────────────────────────────────────────────────────
class _JobsListView extends StatelessWidget {
  final JobController ctrl;
  const _JobsListView({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _JobsTopBar(ctrl: ctrl),
        _JobsStatsRow(ctrl: ctrl),
        _JobsFilterBar(ctrl: ctrl),
        Expanded(child: _JobsBody(ctrl: ctrl)),
      ],
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────
class _JobsTopBar extends StatelessWidget {
  final JobController ctrl;
  const _JobsTopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: jBorder))),
      child: Row(children: [
        // Icon + title
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [jGreen, jBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: jR10,
            boxShadow: jGlow(jGreen),
          ),
          child: const Icon(Icons.work_rounded, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Volunteer Jobs', style: jH2()),
          Obx(() => Text(
            '${ctrl.jobs.length} posted · ${ctrl.openJobsCount} open',
            style: jMonoSm(),
          )),
        ]),
        const Spacer(),

        // Search
        _JobSearchBar(ctrl: ctrl),
        const SizedBox(width: 10),

        // Refresh
        JIconBtn(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onTap: ctrl.fetchJobs,
        ),
        const SizedBox(width: 8),

        // Post new
        JBtn(
          label: 'Post Job',
          icon: Icons.add_rounded,
          onTap: ctrl.openCreate,
        ),
      ]),
    );
  }
}

class _JobSearchBar extends StatefulWidget {
  final JobController ctrl;
  const _JobSearchBar({required this.ctrl});
  @override State<_JobSearchBar> createState() => _JobSearchBarState();
}

class _JobSearchBarState extends State<_JobSearchBar> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 230,
      height: 38,
      decoration: BoxDecoration(
        color: jSurf,
        borderRadius: jR10,
        border: Border.all(
          color: _focused ? jGreen.withOpacity(0.5) : jBorder,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused ? jGlow(jGreen, radius: 12) : [],
      ),
      child: Row(children: [
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Icon(Icons.search_rounded, size: 14, color: jMuted),
        ),
        Expanded(
          child: TextField(
            controller: widget.ctrl.searchCtrl,
            onTap: () => setState(() => _focused = true),
            onEditingComplete: () => setState(() => _focused = false),
            style: GoogleFonts.inter(fontSize: 13, color: jText),
            decoration: InputDecoration(
              hintText: 'Search jobs...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: jMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────
class _JobsStatsRow extends StatelessWidget {
  final JobController ctrl;
  const _JobsStatsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingJobs.value && ctrl.jobs.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
        child: Row(children: [
          _StatTile(label: 'Total Jobs',    value: '${ctrl.jobs.length}',       icon: Icons.work_rounded,          color: jGreen),
          const SizedBox(width: 12),
          _StatTile(label: 'Open',          value: '${ctrl.openJobsCount}',     icon: Icons.check_circle_rounded,  color: jBlue),
          const SizedBox(width: 12),
          _StatTile(label: 'Total Slots',   value: '${ctrl.totalPositions}',    icon: Icons.people_rounded,        color: jTeal),
          const SizedBox(width: 12),
          _StatTile(label: 'Filled',        value: '${ctrl.filledPositions}',   icon: Icons.how_to_reg_rounded,    color: jIndigo),
        ]),
      );
    });
  }
}

class _StatTile extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});
  @override State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit:  (_) => setState(() => _h = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _h ? jSurf2 : jSurf,
            borderRadius: jR12,
            border: Border.all(
                color: _h ? widget.color.withOpacity(0.25) : jBorder),
            boxShadow: _h ? jGlow(widget.color) : [],
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: jR8,
              ),
              child: Icon(widget.icon, color: widget.color, size: 16),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.value,
                  style: GoogleFonts.firaCode(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: jText)),
              Text(widget.label,
                  style: jMonoSm()),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────
class _JobsFilterBar extends StatelessWidget {
  final JobController ctrl;
  const _JobsFilterBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: Obx(() => Row(children: [
        ...[
          ('all',    'All',     jSub),
          ('open',   'Open',    jGreen),
          ('closed', 'Closed',  jMuted),
          ('paused', 'Paused',  jAmber),
        ].map((f) {
          final isActive = ctrl.jobFilter.value == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _FilterChip(
              label: f.$2,
              active: isActive,
              color: f.$3 as Color,
              onTap: () => ctrl.jobFilter.value = f.$1,
            ),
          );
        }),
        const Spacer(),
        Obx(() {
          final n = ctrl.filteredJobs.length;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: jSurf2, borderRadius: jR20,
              border: Border.all(color: jBorder2),
            ),
            child: Text('$n job${n != 1 ? 's' : ''}',
                style: jMonoSm()),
          );
        }),
      ])),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.color, required this.onTap});
  @override State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.active ? widget.color.withOpacity(0.1) : (_h ? jSurf2 : Colors.transparent),
            borderRadius: jR8,
            border: Border.all(
              color: widget.active ? widget.color.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Text(widget.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: widget.active ? jText : (_h ? jText : jSub),
                fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
              )),
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────
class _JobsBody extends StatelessWidget {
  final JobController ctrl;
  const _JobsBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingJobs.value && ctrl.jobs.isEmpty) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
          children: List.generate(3, (_) => const SkeletonJobCard()),
        );
      }
      if (ctrl.jobsError.value.isNotEmpty && ctrl.jobs.isEmpty) {
        return _EmptyOrError(
          icon: Icons.wifi_off_rounded,
          title: 'Failed to load jobs',
          subtitle: ctrl.jobsError.value,
          action: JBtn(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            ghost: true,
            onTap: ctrl.fetchJobs,
          ),
        );
      }
      final items = ctrl.filteredJobs;
      if (items.isEmpty) {
        return _EmptyOrError(
          icon: Icons.work_off_rounded,
          title: 'No jobs found',
          subtitle: ctrl.jobSearchQuery.value.isNotEmpty
              ? 'Try a different search term.'
              : 'Post your first volunteer job.',
          action: JBtn(
            label: 'Post a Job',
            icon: Icons.add_rounded,
            onTap: ctrl.openCreate,
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
        itemCount: items.length,
        itemBuilder: (_, i) => _StaggerEntry(
          index: i,
          child: JobCard(
            job: items[i],
            ctrl: ctrl,
            onViewApplications: () => ctrl.openJobApplications(items[i]),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  APPLICATIONS VIEW
// ─────────────────────────────────────────────────────────────
class _ApplicationsView extends StatelessWidget {
  final JobController ctrl;
  const _ApplicationsView({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _ApplicationsTopBar(ctrl: ctrl),
      Expanded(
        child: Row(children: [
          // ── Applications list ─────────────────────────────
          SizedBox(
            width: 360,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: jBorder)),
              ),
              child: Column(children: [
                // Header
                _AppListHeader(ctrl: ctrl),
                // List
                Expanded(child: _AppList(ctrl: ctrl)),
              ]),
            ),
          ),

          // ── Detail or empty state ─────────────────────────
          Expanded(
            child: Obx(() {
              final selected = ctrl.selectedApplication.value;
              if (selected == null) {
                return _AppEmptyDetail();
              }
              return ApplicationDetailPanel(
                application: selected,
                ctrl: ctrl,
              );
            }),
          ),
        ]),
      ),
    ]);
  }
}

class _ApplicationsTopBar extends StatelessWidget {
  final JobController ctrl;
  const _ApplicationsTopBar({required this.ctrl});

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
        Obx(() {
          final job = ctrl.selectedJob.value;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job?.title ?? 'Applications', style: jH2()),
            Text('Review and manage applicants', style: jMonoSm()),
          ]);
        }),
        const Spacer(),
        // Stats chips
        Obx(() => Row(children: [
          _AppStatChip(
              icon: Icons.schedule_rounded,
              label: '${ctrl.pendingCount} pending',
              color: jAmber),
          const SizedBox(width: 8),
          _AppStatChip(
              icon: Icons.check_circle_rounded,
              label: '${ctrl.approvedCount} approved',
              color: jGreen),
          const SizedBox(width: 8),
          _AppStatChip(
              icon: Icons.people_rounded,
              label: '${ctrl.applications.length} total',
              color: jBlue),
        ])),
      ]),
    );
  }
}

class _AppStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _AppStatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: jR20,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.firaCode(fontSize: 10, color: color)),
      ]),
    );
  }
}

class _AppListHeader extends StatelessWidget {
  final JobController ctrl;
  const _AppListHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: jBorder))),
      child: Row(children: [
        Text('Applicants', style: jH3()),
        const Spacer(),
        Obx(() => Text(
          '${ctrl.applications.length} total',
          style: jMonoSm(),
        )),
      ]),
    );
  }
}

class _AppList extends StatelessWidget {
  final JobController ctrl;
  const _AppList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingApplications.value) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: List.generate(3, (_) => const SkeletonJobCard()),
        );
      }
      if (ctrl.appsError.value.isNotEmpty) {
        return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline_rounded, color: jMuted, size: 32),
            const SizedBox(height: 10),
            Text(ctrl.appsError.value,
                style: jMonoSm(), textAlign: TextAlign.center),
          ]),
        );
      }
      if (ctrl.applications.isEmpty) {
        return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.inbox_rounded, color: jMuted, size: 40),
            const SizedBox(height: 12),
            Text('No applications yet',
                style: jH3().copyWith(color: jSub)),
            const SizedBox(height: 4),
            Text('Share the job to attract volunteers.',
                style: jMonoSm()),
          ]),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: ctrl.applications.length,
        itemBuilder: (_, i) => _StaggerEntry(
          index: i,
          child: Obx(() => ApplicationCard(
            application: ctrl.applications[i],
            ctrl: ctrl,
            isSelected: ctrl.selectedApplication.value?.id ==
                ctrl.applications[i].id,
            onTap: () =>
                ctrl.selectedApplication.value = ctrl.applications[i],
          )),
        ),
      );
    });
  }
}

class _AppEmptyDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: jGreen.withOpacity(0.07),
            shape: BoxShape.circle,
            border: Border.all(color: jGreen.withOpacity(0.2)),
          ),
          child: const Icon(Icons.person_search_rounded,
              color: jGreen, size: 30),
        ),
        const SizedBox(height: 16),
        Text('Select an applicant',
            style: jH2().copyWith(color: jSub)),
        const SizedBox(height: 6),
        Text('Click on an application to view details\nand approve or reject.',
            style: jMonoSm().copyWith(height: 1.6),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STAGGER ANIMATION WRAPPER
// ─────────────────────────────────────────────────────────────
class _StaggerEntry extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggerEntry({required this.index, required this.child});
  @override State<_StaggerEntry> createState() => _StaggerEntryState();
}

class _StaggerEntryState extends State<_StaggerEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    Future.delayed(
      Duration(milliseconds: (widget.index * 40).clamp(0, 200)),
      () { if (mounted) _c.forward(); },
    );
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY / ERROR STATE
// ─────────────────────────────────────────────────────────────
class _EmptyOrError extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  const _EmptyOrError({required this.icon, required this.title,
      required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            color: jSurf2, shape: BoxShape.circle,
            border: Border.all(color: jBorder2),
          ),
          child: Icon(icon, color: jMuted, size: 28),
        ),
        const SizedBox(height: 16),
        Text(title, style: jH2()),
        const SizedBox(height: 6),
        Text(subtitle, style: jMonoSm(), textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 22), action!],
      ]),
    );
  }
}
