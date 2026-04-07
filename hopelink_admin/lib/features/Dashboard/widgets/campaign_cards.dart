// ─────────────────────────────────────────────────────────────
//  CARDS  —  campaign_cards.dart
//  Grid card + List row for the campaign list page
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/campaign_list_controller.dart';
import '../models/campaign_list_model.dart';
import 'campaign_atoms.dart';

import 'campaign_theme.dart';

// ─────────────────────────────────────────────────────────────
//  CAMPAIGN IMAGE  (network + placeholder)
// ─────────────────────────────────────────────────────────────
class CampaignImageTile extends StatelessWidget {
  final CampaignListItem campaign;
  final double height;
  final BorderRadius? borderRadius;

  const CampaignImageTile({
    super.key,
    required this.campaign,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final t = campaignStatus(campaign.status);

    if (campaign.hasImages) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(
          campaign.primaryImage!,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _CampaignPlaceholder(campaign: campaign, height: height, color: t.color, borderRadius: borderRadius),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _CampaignPlaceholder(campaign: campaign, height: height, color: t.color, borderRadius: borderRadius),
        ),
      );
    }

    return _CampaignPlaceholder(
        campaign: campaign, height: height, color: t.color, borderRadius: borderRadius);
  }
}

class _CampaignPlaceholder extends StatelessWidget {
  final CampaignListItem campaign;
  final double height;
  final Color color;
  final BorderRadius? borderRadius;

  const _CampaignPlaceholder({
    required this.campaign,
    required this.height,
    required this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), cSurf3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(children: [
          Positioned(
            right: 10, bottom: 6,
            child: Icon(Icons.campaign_rounded,
                size: height * 0.5,
                color: color.withOpacity(0.06)),
          ),
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.campaign_rounded, size: 18, color: color),
              ),
              const SizedBox(height: 5),
              Text('No Photos',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, color: color.withOpacity(0.5))),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CAMPAIGN GRID CARD
// ─────────────────────────────────────────────────────────────
class CampaignGridCard extends StatefulWidget {
  final CampaignListItem campaign;
  final CampaignListController ctrl;
  final VoidCallback onTap;

  const CampaignGridCard({
    super.key,
    required this.campaign,
    required this.ctrl,
    required this.onTap,
  });

  @override
  State<CampaignGridCard> createState() => _CampaignGridCardState();
}

class _CampaignGridCardState extends State<CampaignGridCard> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final c   = widget.campaign;
    final t   = campaignStatus(c.status);
    final pct = c.progressPercent;

    return MouseRegion(
      onEnter:  (_) => setState(() => _hov = true),
      onExit:   (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _hov ? cSurf2 : cSurf,
            borderRadius: r16,
            border: Border.all(
                color: _hov ? t.color.withOpacity(0.3) : cBorder),
            boxShadow: _hov ? glowShadow(t.color) : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image header ───────────────────────────────
              Stack(children: [
                CampaignImageTile(
                  campaign: c,
                  height: 148,
                  borderRadius: const BorderRadius.only(
                    topLeft:  Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                // Status overlay
                Positioned(
                  top: 10, left: 10,
                  child: CampaignStatusBadge(status: c.status),
                ),
                // Featured badge
                if (c.isFeatured)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: cViolet.withOpacity(0.9),
                        borderRadius: r6,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded,
                            size: 9, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('Featured',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 9, color: Colors.white)),
                      ]),
                    ),
                  ),
                // Image count
                if (c.images.length > 1)
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: r6,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.image_rounded,
                            size: 10, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('${c.images.length}',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 9, color: Colors.white70)),
                      ]),
                    ),
                  ),
              ]),

              // ── Body ───────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(c.title,
                          style: headingMd().copyWith(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),

                      // Org name
                      if (c.organization != null)
                        Row(children: [
                          const Icon(Icons.business_rounded,
                              size: 11, color: cTextMute),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              c.organization!.organizationName,
                              style: monoSm(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),

                      const Spacer(),

                      // Progress
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(widget.ctrl.formatCurrency(c.currentAmount),
                                  style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      color: t.color,
                                      fontWeight: FontWeight.w700)),
                              Text('${pct.toStringAsFixed(1)}%',
                                  style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9, color: cTextMute)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          CampaignProgressBar(percent: pct),
                          const SizedBox(height: 4),
                          Text(
                            'of ${widget.ctrl.formatCurrency(c.targetAmount)}',
                            style: monoSm(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Footer
                      Row(children: [
                        DaysLeftPill(days: c.daysLeft, expired: c.isExpired),
                        const Spacer(),
                        if (c.updates.isNotEmpty)
                          IconChip(
                            icon: Icons.update_rounded,
                            label: '${c.updates.length}',
                            color: cSky,
                          ),
                        if (c.faqs.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          IconChip(
                            icon: Icons.quiz_rounded,
                            label: '${c.faqs.length}',
                            color: cAmber,
                          ),
                        ],
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
//  CAMPAIGN LIST ROW
// ─────────────────────────────────────────────────────────────
class CampaignListRow extends StatefulWidget {
  final CampaignListItem campaign;
  final CampaignListController ctrl;
  final VoidCallback onTap;

  const CampaignListRow({
    super.key,
    required this.campaign,
    required this.ctrl,
    required this.onTap,
  });

  @override
  State<CampaignListRow> createState() => _CampaignListRowState();
}

class _CampaignListRowState extends State<CampaignListRow> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final c   = widget.campaign;
    final t   = campaignStatus(c.status);
    final pct = c.progressPercent;

    return MouseRegion(
      onEnter:  (_) => setState(() => _hov = true),
      onExit:   (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hov ? cSurf2 : cSurf,
            borderRadius: r12,
            border: Border.all(
                color: _hov ? t.color.withOpacity(0.25) : cBorder),
          ),
          child: Row(children: [
            // Thumbnail
            ClipRRect(
              borderRadius: r10,
              child: SizedBox(
                width: 72, height: 72,
                child: CampaignImageTile(campaign: c, height: 72),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(c.title,
                          style: headingMd().copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    CampaignStatusBadge(status: c.status),
                  ]),
                  const SizedBox(height: 5),
                  CampaignProgressBar(percent: pct, height: 4),
                  const SizedBox(height: 5),
                  Row(children: [
                    Text(
                      '${widget.ctrl.formatCurrency(c.currentAmount)} of ${widget.ctrl.formatCurrency(c.targetAmount)}',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: t.color),
                    ),
                    const Spacer(),
                    DaysLeftPill(days: c.daysLeft, expired: c.isExpired),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: cTextMute),
          ]),
        ),
      ),
    );
  }
}
