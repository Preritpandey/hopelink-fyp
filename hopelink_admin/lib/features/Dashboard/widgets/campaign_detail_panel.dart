// ─────────────────────────────────────────────────────────────
//  DETAIL PANEL  —  campaign_detail_panel.dart
//  Slide-in right panel showing full campaign info
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/campaign_list_controller.dart';
import '../models/campaign_list_model.dart';
import 'campaign_atoms.dart';

import 'campaign_theme.dart';

class CampaignDetailPanel extends StatefulWidget {
  final CampaignListItem campaign;
  final CampaignListController ctrl;

  const CampaignDetailPanel({
    super.key,
    required this.campaign,
    required this.ctrl,
  });

  @override
  State<CampaignDetailPanel> createState() => _CampaignDetailPanelState();
}

class _CampaignDetailPanelState extends State<CampaignDetailPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  int _imgIdx = 0;

  @override
  void initState() {
    super.initState();
    _anim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    final t = campaignStatus(c.status);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          width: 400,
          decoration: const BoxDecoration(
            color: Color(0xFF090E18),
            border: Border(left: BorderSide(color: cBorder)),
          ),
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: cBorder))),
                child: Row(children: [
                  Expanded(
                    child: Text('Campaign Details',
                        style: headingMd()),
                  ),
                  CIconBtn(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    onTap: widget.ctrl.closeDetail,
                  ),
                ]),
              ),

              // ── Scrollable Body ────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images carousel
                      if (c.hasImages) _ImageCarousel(campaign: c) else _NoImageBanner(campaign: c, color: t.color),
                      const SizedBox(height: 16),

                      // Title
                      Text(c.title, style: headingLg()),
                      const SizedBox(height: 8),

                      // Org
                      if (c.organization != null)
                        Row(children: [
                          const Icon(Icons.business_rounded, size: 13, color: cTextMute),
                          const SizedBox(width: 6),
                          Text(c.organization!.organizationName,
                              style: bodySm()),
                        ]),
                      const SizedBox(height: 12),

                      // Status + days left
                      Row(children: [
                        CampaignStatusBadge(status: c.status),
                        const SizedBox(width: 8),
                        DaysLeftPill(days: c.daysLeft, expired: c.isExpired),
                        if (c.isFeatured) ...[
                          const SizedBox(width: 8),
                          IconChip(icon: Icons.star_rounded, label: 'Featured', color: cViolet),
                        ],
                      ]),
                      const SizedBox(height: 14),

                      // Description
                      Text(c.description,
                          style: bodySm().copyWith(color: cTextSub, height: 1.6)),
                      const SizedBox(height: 18),

                      // ── Progress Block ──────────────────────
                      _SectionLabel('Funding Progress', Icons.trending_up_rounded),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cSurf2,
                          borderRadius: r12,
                          border: Border.all(color: cBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Raised',
                                      style: monoSm().copyWith(letterSpacing: 0.4)),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.ctrl.formatCurrency(c.currentAmount),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: t.color,
                                    ),
                                  ),
                                ]),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('Goal', style: monoSm().copyWith(letterSpacing: 0.4)),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.ctrl.formatCurrency(c.targetAmount),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: cText,
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CampaignProgressBar(
                                percent: c.progressPercent,
                                height: 8,
                                showLabel: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Timeline Block ──────────────────────
                      _SectionLabel('Timeline', Icons.date_range_rounded),
                      Row(children: [
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.play_circle_outline_rounded,
                            label: 'START',
                            value: widget.ctrl.formatDate(c.startDate),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.stop_circle_outlined,
                            label: 'END',
                            value: widget.ctrl.formatDate(c.endDate),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      // ── Updates ──────────────────────────────
                      if (c.updates.isNotEmpty) ...[
                        _SectionLabel('Updates (${c.updates.length})', Icons.update_rounded),
                        ...c.updates.map((u) => _UpdateTile(
                              update: u,
                              ctrl: widget.ctrl,
                            )),
                        const SizedBox(height: 4),
                      ],

                      // ── FAQs ─────────────────────────────────
                      if (c.faqs.isNotEmpty) ...[
                        _SectionLabel('FAQs (${c.faqs.length})', Icons.quiz_rounded),
                        Obx(() => Column(
                          children: List.generate(c.faqs.length, (i) =>
                            _FaqTile(
                              faq: c.faqs[i],
                              index: i,
                              expanded: widget.ctrl.expandedFaqIndex.value == i,
                              onToggle: () => widget.ctrl.toggleFaq(i),
                            ),
                          ),
                        )),
                        const SizedBox(height: 4),
                      ],

                      // ── ID ────────────────────────────────────
                      const SizedBox(height: 6),
                      _GradDivider(),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.tag_rounded, size: 11, color: cTextMute),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(c.id,
                              style: mono().copyWith(fontSize: 9)),
                        ),
                        GestureDetector(
                          onTap: () => Clipboard.setData(ClipboardData(text: c.id)),
                          child: const Icon(Icons.copy_rounded, size: 12, color: cTextMute),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  IMAGE CAROUSEL
// ─────────────────────────────────────────────────────────────
class _ImageCarousel extends StatefulWidget {
  final CampaignListItem campaign;
  const _ImageCarousel({required this.campaign});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final imgs = widget.campaign.images;
    return Column(children: [
      ClipRRect(
        borderRadius: r12,
        child: Stack(children: [
          Image.network(
            imgs[_idx],
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: cSurf3,
              child: const Center(
                child: Icon(Icons.broken_image_rounded, color: cTextMute, size: 32),
              ),
            ),
          ),
          if (imgs.length > 1)
            Positioned(
              bottom: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: r6,
                ),
                child: Text('${_idx + 1}/${imgs.length}',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: Colors.white)),
              ),
            ),
        ]),
      ),
      if (imgs.length > 1) ...[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(imgs.length, (i) =>
            GestureDetector(
              onTap: () => setState(() => _idx = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _idx == i ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _idx == i ? cEmerald : cBorder2,
                  borderRadius: r20,
                ),
              ),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _NoImageBanner extends StatelessWidget {
  final CampaignListItem campaign;
  final Color color;
  const _NoImageBanner({required this.campaign, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), cSurf3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: r12,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.image_not_supported_rounded, size: 28, color: color.withOpacity(0.4)),
          const SizedBox(height: 6),
          Text('No images attached',
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: color.withOpacity(0.5))),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: cEmerald.withOpacity(0.1),
            borderRadius: r6,
          ),
          child: Icon(icon, size: 12, color: cEmerald),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: headingMd().copyWith(fontSize: 12, color: cTextSub)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  INFO TILE (date/timeline)
// ─────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cSurf2,
        borderRadius: r10,
        border: Border.all(color: cBorder),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: cTextMute),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: monoSm().copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, color: cText, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  UPDATE TILE
// ─────────────────────────────────────────────────────────────
class _UpdateTile extends StatelessWidget {
  final CampaignListUpdate update;
  final CampaignListController ctrl;
  const _UpdateTile({required this.update, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cSky.withOpacity(0.04),
        borderRadius: r10,
        border: Border.all(color: cSky.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.update_rounded, size: 12, color: cSky),
          const SizedBox(width: 6),
          Expanded(
            child: Text(update.title,
                style: GoogleFonts.manrope(
                    fontSize: 12, fontWeight: FontWeight.w700, color: cText)),
          ),
          Text(ctrl.formatDate(update.date),
              style: monoSm()),
        ]),
        const SizedBox(height: 5),
        Text(update.description,
            style: bodySm().copyWith(color: cTextSub, fontSize: 11)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FAQ TILE (accordion)
// ─────────────────────────────────────────────────────────────
class _FaqTile extends StatelessWidget {
  final CampaignListFaq faq;
  final int index;
  final bool expanded;
  final VoidCallback onToggle;

  const _FaqTile({
    required this.faq,
    required this.index,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: expanded ? cAmber.withOpacity(0.05) : cSurf2,
          borderRadius: r10,
          border: Border.all(
              color: expanded ? cAmber.withOpacity(0.2) : cBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: cAmber.withOpacity(0.1),
                  borderRadius: r6,
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, color: cAmber,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(faq.question,
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cText)),
              ),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: cTextMute,
              ),
            ]),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(faq.answer,
                  style: bodySm().copyWith(
                      color: cTextSub, fontSize: 11, height: 1.55)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  GRADIENT DIVIDER
// ─────────────────────────────────────────────────────────────
class _GradDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.transparent, cBorder, Colors.transparent],
      ),
    ),
  );
}
