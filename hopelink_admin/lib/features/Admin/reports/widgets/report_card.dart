import 'package:flutter/material.dart';
import '../controllers/campaign_report_controller.dart';
import '../models/campaign_report_model.dart';
import 'report_atoms.dart';
import 'report_theme.dart';

class ReportCard extends StatefulWidget {
  final CampaignReport report;
  final CampaignReportController ctrl;
  final bool isSelected;
  final VoidCallback onTap;

  const ReportCard({
    super.key,
    required this.report,
    required this.ctrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final r  = widget.report;
    final isActioning = widget.ctrl.actionLoading.value == r.id;

    return MouseRegion(
      onEnter:  (_) => setState(() => _hov = true),
      onExit:   (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? rGold.withOpacity(0.06)
                : _hov ? rSurf2 : rSurf,
            borderRadius: rR14,
            border: Border.all(
              color: widget.isSelected
                  ? rGold.withOpacity(0.35)
                  : _hov ? rBorder2 : rBorder,
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? rGlow(rGold)
                : _hov ? rSubtle() : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PDF icon box
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            rRed.withOpacity(0.15),
                            rRed.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: rR10,
                        border: Border.all(color: rRed.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded,
                          color: rRed, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Campaign info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.campaign.title,
                              style: rH2().copyWith(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.business_rounded,
                                size: 11, color: rMuted),
                            const SizedBox(width: 4),
                            Text(r.organization.organizationName,
                                style: rMonoSm().copyWith(color: rSub)),
                          ]),
                        ],
                      ),
                    ),

                    // Status + pending label
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ReportStatusBadge(status: r.status.value),
                        const SizedBox(height: 5),
                        Text(r.pendingLabel,
                            style: rMonoSm()),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── File info row ───────────────────────────
                Row(children: [
                  InfoChip(
                    icon: Icons.insert_drive_file_rounded,
                    label: r.reportFile.originalName,
                    color: rBlue,
                  ),
                  const SizedBox(width: 6),
                  InfoChip(
                    icon: Icons.data_usage_rounded,
                    label: r.reportFile.formattedSize,
                    color: rSub,
                  ),
                  const SizedBox(width: 6),
                  InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: r.submittedFormatted.split('·').first.trim(),
                    color: rGold,
                  ),
                  const Spacer(),
                  if (widget.isSelected)
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: rGold),
                ]),

                const SizedBox(height: 12),

                // ── Quick actions ───────────────────────────
                Row(children: [
                  Expanded(
                    child: ReportActionBtn(
                      label: 'Approve',
                      icon: Icons.check_circle_rounded,
                      color: rGreen,
                      loading: isActioning,
                      onTap: isActioning
                          ? null
                          : () => widget.ctrl.approveReport(r.id),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ReportActionBtn(
                      label: 'Reject',
                      icon: Icons.cancel_rounded,
                      color: rRed,
                      ghost: true,
                      loading: isActioning,
                      onTap: isActioning
                          ? null
                          : () => widget.ctrl.openRejectDialog(r),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RIconBtn(
                    icon: Icons.visibility_rounded,
                    tooltip: 'View PDF',
                    color: rGold,
                    onTap: () => widget.ctrl.viewReport(r),
                  ),
                  const SizedBox(width: 8),
                  RIconBtn(
                    icon: Icons.download_rounded,
                    tooltip: 'Download PDF',
                    color: rBlue,
                    onTap: () => widget.ctrl.downloadReport(r),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
