
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopelink_admin/features/Auth/controller/login_controller.dart';
import 'package:hopelink_admin/features/Auth/pages/login_page.dart';
import 'package:hopelink_admin/features/Admin/reports/widgets/report_card.dart';

import '../controllers/campaign_report_controller.dart';
import '../models/campaign_report_model.dart';
import '../widgets/report_atoms.dart';
import '../widgets/report_detail_widgets.dart';
import '../widgets/report_theme.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _entry.forward();
  }

  @override
  void dispose() { _entry.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CampaignReportController());

    return Scaffold(
      backgroundColor: rBg,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            // ── Main layout ─────────────────────────────────
            Column(
              children: [
                _TopBar(ctrl: ctrl),
                _StatsBar(ctrl: ctrl),
                Expanded(
                  child: Row(
                    children: [
                      // ── List panel ────────────────────────
                      Expanded(
                        child: _ReportListPanel(ctrl: ctrl),
                      ),
                      // ── Detail panel ──────────────────────
                      Obx(() {
                        final r = ctrl.selectedReport.value;
                        if (r == null) return const SizedBox.shrink();
                        return ReportDetailPanel(report: r, ctrl: ctrl);
                      }),
                    ],
                  ),
                ),
              ],
            ),

            // ── Rejection dialog overlay ─────────────────────
            Obx(() {
              if (!ctrl.showRejectDialog.value) return const SizedBox.shrink();
              return _DialogOverlay(ctrl: ctrl);
            }),
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
  final CampaignReportController ctrl;
  const _TopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: rBorder)),
      ),
      child: Row(children: [
        // ── Icon + title ──────────────────────────────────
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [rGold, Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: rR10,
              boxShadow: rGlow(rGold),
            ),
            child: const Icon(Icons.fact_check_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Campaign Reports', style: rH1()),
            Obx(() => Text(
              '${ctrl.pendingCount} pending review',
              style: rMonoSm(),
            )),
          ]),
        ]),
        const Spacer(),

        // ── Search ────────────────────────────────────────
        _SearchBar(ctrl: ctrl),
        const SizedBox(width: 12),

        // ── Refresh ───────────────────────────────────────
        Obx(() => RIconBtn(
          icon: ctrl.isLoading.value
              ? Icons.hourglass_top_rounded
              : Icons.refresh_rounded,
          tooltip: 'Refresh',
          onTap: ctrl.refresh,
        )),
        const SizedBox(width: 12),
        RIconBtn(
          icon: Icons.logout_rounded,
          tooltip: 'Logout',
          color: rRed,
          onTap: () async {
            final loginCtrl = Get.put(LoginController());
            await loginCtrl.logout();
            Get.offAll(() => const LoginPage());
          },
        ),
      ]),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final CampaignReportController ctrl;
  const _SearchBar({required this.ctrl});
  @override State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _f = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 240,
      height: 38,
      decoration: BoxDecoration(
        color: rSurf,
        borderRadius: rR10,
        border: Border.all(
          color: _f ? rGold.withOpacity(0.5) : rBorder,
          width: _f ? 1.5 : 1,
        ),
        boxShadow: _f ? rGlow(rGold) : [],
      ),
      child: Row(children: [
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Icon(Icons.search_rounded, size: 15, color: rMuted),
        ),
        Expanded(
          child: TextField(
            controller: widget.ctrl.searchCtrl,
            onTap: () => setState(() => _f = true),
            onEditingComplete: () => setState(() => _f = false),
            style: GoogleFonts.nunitoSans(fontSize: 13, color: rText),
            decoration: InputDecoration(
              hintText: 'Search reports...',
              hintStyle: GoogleFonts.nunitoSans(fontSize: 13, color: rMuted),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            ),
          ),
        ),
        Obx(() {
          if (widget.ctrl.searchQuery.value.isEmpty) {
            return const SizedBox.shrink();
          }
          return GestureDetector(
            onTap: widget.ctrl.clearSearch,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.close_rounded, size: 14, color: rMuted),
            ),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STATS BAR
// ─────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final CampaignReportController ctrl;
  const _StatsBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.reports.isEmpty) {
        return const SizedBox.shrink();
      }
      final reports = ctrl.reports;

      // Urgency analysis
      final urgentCount = reports.where((r) {
        return r.pendingDuration.inDays > 2;
      }).length;

      return Container(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
        child: Row(children: [
          _StatCard(
            label: 'Pending Reports',
            value: '${ctrl.pendingCount}',
            icon: Icons.pending_actions_rounded,
            color: rGold,
            sub: 'Awaiting review',
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Urgent (>2 days)',
            value: '$urgentCount',
            icon: Icons.timer_off_rounded,
            color: rRed,
            sub: 'Needs attention',
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Organizations',
            value: '${reports.map((r) => r.organization.id).toSet().length}',
            icon: Icons.business_rounded,
            color: rIndigo,
            sub: 'Unique submitters',
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Total Report Size',
            value: _totalSize(reports),
            icon: Icons.data_usage_rounded,
            color: rBlue,
            sub: 'All pending files',
          ),
        ]),
      );
    });
  }

  String _totalSize(List<CampaignReport> reports) {
    final bytes = reports.fold(0, (sum, r) => sum + r.reportFile.size);
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class _StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String sub;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sub,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit:  (_) => setState(() => _h = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _h ? rSurf2 : rSurf,
            borderRadius: rR14,
            border: Border.all(
                color: _h ? widget.color.withOpacity(0.3) : rBorder),
            boxShadow: _h ? rGlow(widget.color) : [],
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: rR10,
              ),
              child: Icon(widget.icon, color: widget.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.value,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: rText,
                        letterSpacing: -0.3,
                      )),
                  Text(widget.label,
                      style: GoogleFonts.nunitoSans(
                          fontSize: 11, color: rSub)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  REPORT LIST PANEL
// ─────────────────────────────────────────────────────────────
class _ReportListPanel extends StatelessWidget {
  final CampaignReportController ctrl;
  const _ReportListPanel({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // List header
        _ListHeader(ctrl: ctrl),
        // Body
        Expanded(child: _ListBody(ctrl: ctrl)),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  final CampaignReportController ctrl;
  const _ListHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: Row(children: [
        Obx(() {
          final n = ctrl.filtered.length;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: rGold.withOpacity(0.08),
              borderRadius: rR20,
              border: Border.all(color: rGold.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.pending_actions_rounded,
                  size: 12, color: rGold),
              const SizedBox(width: 5),
              Text('$n pending',
                  style: GoogleFonts.sourceCodePro(
                      fontSize: 10, color: rGold,
                      fontWeight: FontWeight.w600)),
            ]),
          );
        }),
        const Spacer(),
        Text('Sorted by submission time',
            style: rMonoSm()),
      ]),
    );
  }
}

class _ListBody extends StatelessWidget {
  final CampaignReportController ctrl;
  const _ListBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Loading skeleton
      if (ctrl.isLoading.value && ctrl.reports.isEmpty) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
          children: List.generate(3, (_) => const SkeletonReportCard()),
        );
      }

      // Error
      if (ctrl.errorMsg.value.isNotEmpty && ctrl.reports.isEmpty) {
        return Center(
          child: ReportEmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Failed to load reports',
            subtitle: ctrl.errorMsg.value,
            action: ReportActionBtn(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              color: rBlue,
              ghost: true,
              onTap: ctrl.refresh,
            ),
          ),
        );
      }

      final items = ctrl.filtered;

      // All clear
      if (items.isEmpty) {
        return Center(
          child: ReportEmptyState(
            icon: ctrl.searchQuery.value.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.task_alt_rounded,
            title: ctrl.searchQuery.value.isNotEmpty
                ? 'No matching reports'
                : 'All caught up!',
            subtitle: ctrl.searchQuery.value.isNotEmpty
                ? 'Try a different search term.'
                : 'No pending reports to review at the moment.',
            action: ctrl.searchQuery.value.isNotEmpty
                ? ReportActionBtn(
                    label: 'Clear search',
                    icon: Icons.clear_all_rounded,
                    color: rSub,
                    ghost: true,
                    onTap: ctrl.clearSearch,
                  )
                : null,
          ),
        );
      }

      // Report list
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
        itemCount: items.length,
        itemBuilder: (_, i) => _StaggerEntry(
          index: i,
          child: Obx(() => ReportCard(
            report: items[i],
            ctrl: ctrl,
            isSelected: ctrl.selectedReport.value?.id == items[i].id,
            onTap: () => ctrl.selectReport(items[i]),
          )),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  DIALOG OVERLAY  (dimmed backdrop + dialog)
// ─────────────────────────────────────────────────────────────
class _DialogOverlay extends StatelessWidget {
  final CampaignReportController ctrl;
  const _DialogOverlay({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ctrl.closeRejectDialog,
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: GestureDetector(
            // Prevent taps inside dialog from closing it
            onTap: () {},
            child: RejectReportDialog(ctrl: ctrl),
          ),
        ),
      ),
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
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

    Future.delayed(
      Duration(milliseconds: (widget.index * 60).clamp(0, 240)),
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
