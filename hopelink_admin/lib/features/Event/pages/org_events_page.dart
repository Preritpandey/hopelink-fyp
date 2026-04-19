import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Dashboard/controllers/campaign_controller.dart';
import '../controllers/org_events_controller.dart';
import '../models/org_event_model.dart';
import '../widgets/org_events_widgets.dart';
import 'event_page.dart';

class OrgEventsPage extends StatefulWidget {
  const OrgEventsPage({super.key});

  @override
  State<OrgEventsPage> createState() => _OrgEventsPageState();
}

class _OrgEventsPageState extends State<OrgEventsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    final ctrl = Get.put(OrgEventsController());

    return Scaffold(
      backgroundColor: kOeBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Obx(() {
          final hasDetail = ctrl.selectedEvent.value != null;
          return Row(
            children: [
              // ── Main content ──────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    _TopBar(ctrl: ctrl),
                    _StatsRow(ctrl: ctrl),
                    _FilterBar(ctrl: ctrl),
                    Expanded(child: _ContentArea(ctrl: ctrl)),
                  ],
                ),
              ),

              // ── Detail panel (slide in from right) ────────
              if (hasDetail)
                EventDetailPanel(event: ctrl.selectedEvent.value!, ctrl: ctrl),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final OrgEventsController ctrl;
  const _TopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kOeBorder)),
      ),
      child: Row(
        children: [
          // Title block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kOeBlue, kOeIndigo],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: kOeBlue.withOpacity(0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.event_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Organization Events',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: kOeText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Obx(
                () => Text(
                  'Showing ${ctrl.filteredEvents.length} of ${ctrl.total} events',
                  style: GoogleFonts.ibmPlexMono(fontSize: 10, color: kOeSub),
                ),
              ),
            ],
          ),
          const Spacer(),

          // Search bar
          _SearchBar(ctrl: ctrl),
          const SizedBox(width: 12),

          // View toggle
          Obx(
            () => _ViewToggle(
              isGrid: ctrl.viewMode.value == EventViewMode.grid,
              onToggle: ctrl.toggleViewMode,
            ),
          ),
          const SizedBox(width: 10),

          _PrimaryActionBtn(
            icon: Icons.add_rounded,
            label: 'Add Event',
            onTap: () {
              final navCtrl = Get.isRegistered<CampaignController>()
                  ? Get.find<CampaignController>()
                  : Get.put(CampaignController());
              Get.to(() => CreateEventPage(ctrl: navCtrl));
            },
          ),
          const SizedBox(width: 10),

          // Refresh
          _IconBtn(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: ctrl.refresh,
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PrimaryActionBtn> createState() => _PrimaryActionBtnState();
}

class _PrimaryActionBtnState extends State<_PrimaryActionBtn> {
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
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kOeBlue, kOeIndigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _h
                ? [
                    BoxShadow(
                      color: kOeBlue.withOpacity(0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: kOeBlue.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final OrgEventsController ctrl;
  const _SearchBar({required this.ctrl});
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 240,
      height: 38,
      decoration: BoxDecoration(
        color: kOeSurf,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focused ? kOeBlue.withOpacity(0.5) : kOeBorder,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: kOeBlue.withOpacity(0.1), blurRadius: 12)]
            : [],
      ),
      child: TextField(
        controller: widget.ctrl.searchCtrl,
        onTap: () => setState(() => _focused = true),
        onEditingComplete: () => setState(() => _focused = false),
        style: GoogleFonts.ibmPlexSans(fontSize: 13, color: kOeText),
        decoration: InputDecoration(
          hintText: 'Search events...',
          hintStyle: GoogleFonts.ibmPlexSans(fontSize: 13, color: kOeMuted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 16,
            color: kOeMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool isGrid;
  final VoidCallback onToggle;
  const _ViewToggle({required this.isGrid, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kOeSurf,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kOeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewBtn(
            icon: Icons.grid_view_rounded,
            active: isGrid,
            onTap: isGrid ? () {} : onToggle,
          ),
          _ViewBtn(
            icon: Icons.view_list_rounded,
            active: !isGrid,
            onTap: !isGrid ? () {} : onToggle,
          ),
        ],
      ),
    );
  }
}

class _ViewBtn extends StatefulWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ViewBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });
  @override
  State<_ViewBtn> createState() => _ViewBtnState();
}

class _ViewBtnState extends State<_ViewBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: widget.active
                ? kOeBlue.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: widget.active
                ? kOeBlue
                : _h
                ? kOeText
                : kOeSub,
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _h ? kOeSurf3 : kOeSurf,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _h ? kOeBorder2 : kOeBorder),
            ),
            child: Icon(widget.icon, size: 16, color: _h ? kOeText : kOeSub),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STATS ROW
// ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final OrgEventsController ctrl;
  const _StatsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.allEvents.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
        child: Row(
          children: [
            Expanded(
              child: OeStatCard(
                value: '${ctrl.total}',
                label: 'Total Events',
                icon: Icons.event_rounded,
                accent: kOeBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OeStatCard(
                value: '${ctrl.publishedCount}',
                label: 'Published',
                icon: Icons.public_rounded,
                accent: kOeBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OeStatCard(
                value: '${ctrl.ongoingCount}',
                label: 'Ongoing',
                icon: Icons.play_circle_rounded,
                accent: kOeGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OeStatCard(
                value: '${ctrl.totalVolunteers}',
                label: 'Total Volunteers',
                icon: Icons.group_rounded,
                accent: kOeIndigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OeStatCard(
                value: '${ctrl.withImagesCount}',
                label: 'With Images',
                icon: Icons.image_rounded,
                accent: kOeAmber,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  FILTER BAR
// ─────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final OrgEventsController ctrl;
  const _FilterBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
      child: Row(
        children: [
          Obx(() {
            final events = ctrl.allEvents;
            return Row(
              children: [
                FilterTab(
                  label: 'All',
                  count: events.length,
                  active: ctrl.activeFilter.value == OrgEventFilter.all,
                  accent: kOeBlue,
                  onTap: () => ctrl.setFilter(OrgEventFilter.all),
                ),
                FilterTab(
                  label: 'Published',
                  count: events.where((e) => e.status == 'published').length,
                  active: ctrl.activeFilter.value == OrgEventFilter.published,
                  accent: kOeBlue,
                  onTap: () => ctrl.setFilter(OrgEventFilter.published),
                ),
                FilterTab(
                  label: 'Ongoing',
                  count: events.where((e) => e.status == 'ongoing').length,
                  active: ctrl.activeFilter.value == OrgEventFilter.ongoing,
                  accent: kOeGreen,
                  onTap: () => ctrl.setFilter(OrgEventFilter.ongoing),
                ),
                FilterTab(
                  label: 'Completed',
                  count: events.where((e) => e.status == 'completed').length,
                  active: ctrl.activeFilter.value == OrgEventFilter.completed,
                  accent: kOeAmber,
                  onTap: () => ctrl.setFilter(OrgEventFilter.completed),
                ),
                FilterTab(
                  label: 'Cancelled',
                  count: events.where((e) => e.status == 'cancelled').length,
                  active: ctrl.activeFilter.value == OrgEventFilter.cancelled,
                  accent: kOeRed,
                  onTap: () => ctrl.setFilter(OrgEventFilter.cancelled),
                ),
              ],
            );
          }),
          const Spacer(),
          // Result count pill
          Obx(() {
            final n = ctrl.filteredEvents.length;
            if (ctrl.isLoading.value) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kOeSurf3,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kOeBorder2),
              ),
              child: Text(
                '$n result${n != 1 ? 's' : ''}',
                style: GoogleFonts.ibmPlexMono(fontSize: 10, color: kOeSub),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CONTENT AREA
// ─────────────────────────────────────────────────────────────
class _ContentArea extends StatelessWidget {
  final OrgEventsController ctrl;
  const _ContentArea({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ── Loading skeleton ──────────────────────────────────
      if (ctrl.isLoading.value && ctrl.allEvents.isEmpty) {
        return _SkeletonGrid();
      }

      // ── Error ─────────────────────────────────────────────
      if (ctrl.errorMsg.value.isNotEmpty && ctrl.allEvents.isEmpty) {
        return OeEmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Failed to load events',
          subtitle: ctrl.errorMsg.value,
          action: _RefreshBtn(onTap: ctrl.refresh),
        );
      }

      final events = ctrl.filteredEvents;

      // ── Empty ─────────────────────────────────────────────
      if (events.isEmpty) {
        final hasFilter =
            ctrl.activeFilter.value != OrgEventFilter.all ||
            ctrl.searchQuery.value.isNotEmpty;
        return OeEmptyState(
          icon: Icons.event_busy_rounded,
          title: hasFilter ? 'No matching events' : 'No events yet',
          subtitle: hasFilter
              ? 'Try adjusting your search or filter.'
              : 'Create your first event to get started.',
          action: hasFilter ? _ClearFilterBtn(ctrl: ctrl) : null,
        );
      }

      // ── Grid view ─────────────────────────────────────────
      if (ctrl.viewMode.value == EventViewMode.grid) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.92,
          ),
          itemCount: events.length,
          itemBuilder: (_, i) => _AnimatedCard(
            index: i,
            child: EventGridCard(
              event: events[i],
              ctrl: ctrl,
              onTap: () => ctrl.openDetail(events[i]),
            ),
          ),
        );
      }

      // ── List view ─────────────────────────────────────────
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
        itemCount: events.length,
        itemBuilder: (_, i) => _AnimatedCard(
          index: i,
          child: EventListRow(
            event: events[i],
            ctrl: ctrl,
            onTap: () => ctrl.openDetail(events[i]),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  ANIMATED CARD WRAPPER  (staggered entry)
// ─────────────────────────────────────────────────────────────
class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedCard({required this.index, required this.child});
  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Stagger based on index (max 200ms)
    final delay = Duration(milliseconds: (widget.index * 40).clamp(0, 200));
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SKELETON GRID
// ─────────────────────────────────────────────────────────────
class _SkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.72,
      children: List.generate(6, (_) => const SkeletonCard()),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SMALL ACTION BUTTONS
// ─────────────────────────────────────────────────────────────
class _RefreshBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _RefreshBtn({required this.onTap});
  @override
  State<_RefreshBtn> createState() => _RefreshBtnState();
}

class _RefreshBtnState extends State<_RefreshBtn> {
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: _h
                ? const LinearGradient(colors: [kOeBlue, kOeIndigo])
                : null,
            color: _h ? null : kOeSurf3,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _h ? kOeBlue : kOeBorder2),
            boxShadow: _h
                ? [
                    BoxShadow(
                      color: kOeBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 15,
                color: _h ? Colors.white : kOeSub,
              ),
              const SizedBox(width: 7),
              Text(
                'Retry',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: _h ? Colors.white : kOeSub,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClearFilterBtn extends StatefulWidget {
  final OrgEventsController ctrl;
  const _ClearFilterBtn({required this.ctrl});
  @override
  State<_ClearFilterBtn> createState() => _ClearFilterBtnState();
}

class _ClearFilterBtnState extends State<_ClearFilterBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: () {
          widget.ctrl.setFilter(OrgEventFilter.all);
          widget.ctrl.searchCtrl.clear();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _h ? kOeSurf3 : kOeSurf,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _h ? kOeBorder2 : kOeBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.clear_all_rounded,
                size: 15,
                color: _h ? kOeText : kOeSub,
              ),
              const SizedBox(width: 7),
              Text(
                'Clear filters',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: _h ? kOeText : kOeSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
