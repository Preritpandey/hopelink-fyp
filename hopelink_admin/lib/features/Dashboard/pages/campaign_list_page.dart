import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/campaign_list_controller.dart';
import '../models/campaign_list_model.dart';
import '../widgets/campaign_atoms.dart';
import '../widgets/campaign_cards.dart';
import '../widgets/campaign_detail_panel.dart';
import '../widgets/campaign_theme.dart';


// ─────────────────────────────────────────────────────────────
//  ROOT PAGE
// ─────────────────────────────────────────────────────────────
class CampaignListPage extends StatefulWidget {
  const CampaignListPage({super.key});

  @override
  State<CampaignListPage> createState() => _CampaignListPageState();
}

class _CampaignListPageState extends State<CampaignListPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _entry.forward();
  }

  @override
  void dispose() { _entry.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CampaignListController());

    return Scaffold(
      backgroundColor: cBg,
      body: FadeTransition(
        opacity: _fade,
        child: Obx(() => Row(
          children: [
            // ── Main area ──────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  _TopBar(ctrl: ctrl),
                  _StatsBar(ctrl: ctrl),
                  _FilterSortBar(ctrl: ctrl),
                  Expanded(child: _Body(ctrl: ctrl)),
                ],
              ),
            ),

            // ── Detail panel ───────────────────────────────
            if (ctrl.selectedCampaign.value != null)
              CampaignDetailPanel(
                campaign: ctrl.selectedCampaign.value!,
                ctrl: ctrl,
              ),
          ],
        )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final CampaignListController ctrl;
  const _TopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: cBorder))),
      child: Row(
        children: [
          // Brand mark
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [cEmerald, cSky],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: r10,
                boxShadow: glowShadow(cEmerald),
              ),
              child: const Icon(Icons.campaign_rounded,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Campaigns', style: headingLg()),
              Obx(() => Text(
                '${ctrl.allCampaigns.length} total · ${ctrl.activeCount} active',
                style: mono(),
              )),
            ]),
          ]),
          const Spacer(),

          // Search
          _SearchInput(ctrl: ctrl),
          const SizedBox(width: 10),

          // View toggle
          Obx(() => Row(children: [
            CIconBtn(
              icon: Icons.grid_view_rounded,
              tooltip: 'Grid view',
              onTap: () {
                if (ctrl.viewMode.value != CampaignViewMode.grid) ctrl.toggleView();
              },
              active: ctrl.viewMode.value == CampaignViewMode.grid,
              activeColor: cEmerald,
            ),
            const SizedBox(width: 4),
            CIconBtn(
              icon: Icons.view_list_rounded,
              tooltip: 'List view',
              onTap: () {
                if (ctrl.viewMode.value != CampaignViewMode.list) ctrl.toggleView();
              },
              active: ctrl.viewMode.value == CampaignViewMode.list,
              activeColor: cEmerald,
            ),
          ])),
          const SizedBox(width: 10),

          // Refresh
          CIconBtn(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: ctrl.refresh,
          ),
          const SizedBox(width: 10),
          Obx(() {
            final selected = ctrl.selectedCampaign.value;
            return GradBtn(
              label: 'Manage Selected',
              icon: Icons.edit_rounded,
              ghost: true,
              onTap: selected == null
                  ? null
                  : () => ctrl.openDetail(selected),
            );
          }),
        ],
      ),
    );
  }
}

class _SearchInput extends StatefulWidget {
  final CampaignListController ctrl;
  const _SearchInput({required this.ctrl});
  @override State<_SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<_SearchInput> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 240,
      height: 38,
      decoration: BoxDecoration(
        color: cSurf,
        borderRadius: r10,
        border: Border.all(
          color: _focused ? cEmerald.withOpacity(0.5) : cBorder,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused ? glowShadow(cEmerald) : [],
      ),
      child: Row(children: [
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Icon(Icons.search_rounded, size: 15, color: cTextMute),
        ),
        Expanded(
          child: TextField(
            controller: widget.ctrl.searchCtrl,
            onTap: () => setState(() => _focused = true),
            onEditingComplete: () => setState(() => _focused = false),
            style: GoogleFonts.inter(fontSize: 13, color: cText),
            decoration: InputDecoration(
              hintText: 'Search campaigns...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: cTextMute),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            ),
          ),
        ),
        Obx(() {
          if (widget.ctrl.searchQuery.value.isEmpty) return const SizedBox.shrink();
          return GestureDetector(
            onTap: widget.ctrl.clearSearch,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.close_rounded, size: 14, color: cTextMute),
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
  final CampaignListController ctrl;
  const _StatsBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.allCampaigns.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
        child: Row(children: [
          _StatTile(
            label: 'Total Campaigns',
            value: '${ctrl.allCampaigns.length}',
            icon: Icons.campaign_rounded,
            color: cEmerald,
          ),
          const SizedBox(width: 12),
          _StatTile(
            label: 'Active Now',
            value: '${ctrl.activeCount}',
            icon: Icons.bolt_rounded,
            color: cSky,
          ),
          const SizedBox(width: 12),
          _StatTile(
            label: 'Total Raised',
            value: ctrl.formatCurrency(ctrl.totalRaised),
            icon: Icons.savings_rounded,
            color: cViolet,
          ),
          const SizedBox(width: 12),
          _StatTile(
            label: 'Overall Progress',
            value: '${ctrl.overallProgress.toStringAsFixed(1)}%',
            icon: Icons.pie_chart_rounded,
            color: cAmber,
          ),
          const SizedBox(width: 12),
          _StatTile(
            label: 'With Photos',
            value: '${ctrl.withImagesCount}',
            icon: Icons.image_rounded,
            color: cEmerald,
          ),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _h ? cSurf2 : cSurf,
            borderRadius: r12,
            border: Border.all(
                color: _h ? widget.color.withOpacity(0.25) : cBorder),
            boxShadow: _h ? glowShadow(widget.color) : [],
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: r8,
              ),
              child: Icon(widget.icon, color: widget.color, size: 17),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cText,
                    letterSpacing: -0.3,
                  )),
              Text(widget.label,
                  style: GoogleFonts.inter(fontSize: 10, color: cTextSub)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FILTER + SORT BAR
// ─────────────────────────────────────────────────────────────
class _FilterSortBar extends StatelessWidget {
  final CampaignListController ctrl;
  const _FilterSortBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: Row(
        children: [
          // Filter tabs
          Obx(() => Wrap(
            spacing: 4,
            children: CampaignStatusFilter.values.map((f) {
              final count = f == CampaignStatusFilter.all
                  ? ctrl.allCampaigns.length
                  : ctrl.allCampaigns
                      .where((c) => c.status == f.value)
                      .length;
              final isActive = ctrl.activeFilter.value == f;
              final color = f == CampaignStatusFilter.active
                  ? cEmerald
                  : f == CampaignStatusFilter.completed
                      ? cSky
                      : f == CampaignStatusFilter.paused
                          ? cOrange
                          : f == CampaignStatusFilter.cancelled
                              ? cRose
                              : cTextSub;

              return _FilterChip(
                label: f.label,
                count: count,
                active: isActive,
                color: color,
                onTap: () => ctrl.setFilter(f),
              );
            }).toList(),
          )),
          const Spacer(),

          // Sort dropdown
          _SortDropdown(ctrl: ctrl),

          const SizedBox(width: 10),

          // Result count
          Obx(() {
            final n = ctrl.filtered.length;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cSurf2,
                borderRadius: r20,
                border: Border.all(color: cBorder2),
              ),
              child: Text('$n result${n != 1 ? 's' : ''}',
                  style: mono()),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.count,
      required this.active, required this.color, required this.onTap});
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
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.active
                ? widget.color.withOpacity(0.12)
                : _h ? cSurf2 : Colors.transparent,
            borderRadius: r8,
            border: Border.all(
              color: widget.active
                  ? widget.color.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: widget.active
                      ? cText
                      : _h ? cText : cTextSub,
                  fontWeight: widget.active
                      ? FontWeight.w600
                      : FontWeight.w400,
                )),
            if (widget.count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: widget.active
                      ? widget.color.withOpacity(0.2)
                      : cSurf3,
                  borderRadius: r10,
                ),
                child: Text('${widget.count}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: widget.active ? widget.color : cTextMute,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatefulWidget {
  final CampaignListController ctrl;
  const _SortDropdown({required this.ctrl});
  @override State<_SortDropdown> createState() => _SortDropdownState();
}

class _SortDropdownState extends State<_SortDropdown> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _h ? cSurf2 : cSurf,
          borderRadius: r8,
          border: Border.all(color: _h ? cBorder2 : cBorder),
        ),
        child: Obx(
          () => DropdownButtonHideUnderline(
            child: DropdownButton<CampaignSortOption>(
              value: widget.ctrl.sortOption.value,
              dropdownColor: const Color(0xFF0D1520),
              style: GoogleFonts.inter(fontSize: 12, color: cTextSub),
              icon: const Icon(Icons.unfold_more_rounded,
                  size: 14, color: cTextMute),
              onChanged: (v) { if (v != null) widget.ctrl.setSort(v); },
              items: CampaignSortOption.values.map((s) =>
                DropdownMenuItem(
                  value: s,
                  child: Text(s.label,
                      style: GoogleFonts.inter(fontSize: 12, color: cTextSub)),
                ),
              ).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BODY (grid / list / skeleton / empty / error)
// ─────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final CampaignListController ctrl;
  const _Body({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ── Loading skeleton ──────────────────────────────────
      if (ctrl.isLoading.value && ctrl.allCampaigns.isEmpty) {
        return _SkeletonGrid();
      }

      // ── Error ─────────────────────────────────────────────
      if (ctrl.errorMsg.value.isNotEmpty && ctrl.allCampaigns.isEmpty) {
        return Center(
          child: _EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Could not load campaigns',
            subtitle: ctrl.errorMsg.value,
            action: GradBtn(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onTap: ctrl.refresh,
              accentColor: cEmerald,
            ),
          ),
        );
      }

      final items = ctrl.filtered;

      // ── Empty ─────────────────────────────────────────────
      if (items.isEmpty) {
        final hasFilter = ctrl.activeFilter.value != CampaignStatusFilter.all ||
            ctrl.searchQuery.value.isNotEmpty;
        return Center(
          child: _EmptyState(
            icon: Icons.campaign_outlined,
            title: hasFilter ? 'No campaigns match' : 'No campaigns yet',
            subtitle: hasFilter
                ? 'Try adjusting your filter or search.'
                : 'Create your first campaign to get started.',
            action: hasFilter
                ? GradBtn(
                    label: 'Clear filters',
                    icon: Icons.clear_all_rounded,
                    ghost: true,
                    onTap: () {
                      ctrl.setFilter(CampaignStatusFilter.all);
                      ctrl.clearSearch();
                    },
                  )
                : null,
          ),
        );
      }

      // ── Grid ──────────────────────────────────────────────
      if (ctrl.viewMode.value == CampaignViewMode.grid) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _StaggerEntry(
            index: i,
            child: CampaignGridCard(
              campaign: items[i],
              ctrl: ctrl,
              onTap: () => ctrl.openDetail(items[i]),
            ),
          ),
        );
      }

      // ── List ──────────────────────────────────────────────
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
        itemCount: items.length,
        itemBuilder: (_, i) => _StaggerEntry(
          index: i,
          child: CampaignListRow(
            campaign: items[i],
            ctrl: ctrl,
            onTap: () => ctrl.openDetail(items[i]),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  STAGGER ENTRY ANIMATION
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
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

    final delay = Duration(milliseconds: (widget.index * 35).clamp(0, 210));
    Future.delayed(delay, () { if (mounted) _c.forward(); });
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
      childAspectRatio: 0.7,
      children: List.generate(6, (_) => const SkeletonCampaignCard()),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: cSurf2,
          shape: BoxShape.circle,
          border: Border.all(color: cBorder2),
        ),
        child: Icon(icon, color: cTextMute, size: 30),
      ),
      const SizedBox(height: 18),
      Text(title, style: headingLg()),
      const SizedBox(height: 6),
      Text(subtitle,
          style: bodySm(),
          textAlign: TextAlign.center),
      if (action != null) ...[const SizedBox(height: 22), action!],
    ]);
  }
}
