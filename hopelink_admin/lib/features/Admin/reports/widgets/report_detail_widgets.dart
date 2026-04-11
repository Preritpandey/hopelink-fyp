// ─────────────────────────────────────────────────────────────
//  WIDGETS  —  report_detail_widgets.dart
//  Detail panel + Rejection dialog
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/campaign_report_controller.dart';
import '../models/campaign_report_model.dart';
import 'report_atoms.dart';
import 'report_theme.dart';

// ─────────────────────────────────────────────────────────────
//  DETAIL PANEL
// ─────────────────────────────────────────────────────────────
class ReportDetailPanel extends StatefulWidget {
  final CampaignReport report;
  final CampaignReportController ctrl;

  const ReportDetailPanel({
    super.key,
    required this.report,
    required this.ctrl,
  });

  @override
  State<ReportDetailPanel> createState() => _ReportDetailPanelState();
}

class _ReportDetailPanelState extends State<ReportDetailPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
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
    final r = widget.report;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          width: 420,
          decoration: const BoxDecoration(
            color: Color(0xFF070C18),
            border: Border(left: BorderSide(color: rBorder)),
          ),
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────
              _PanelHeader(report: r, ctrl: widget.ctrl),

              // ── Body ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report PDF card
                      _PdfPreviewCard(report: r, ctrl: widget.ctrl),
                      const SizedBox(height: 18),

                      // Campaign info
                      _DetailSection(
                        title: 'Campaign',
                        icon: Icons.campaign_rounded,
                        color: rBlue,
                        children: [
                          _DetailRow(
                            icon: Icons.title_rounded,
                            label: 'Title',
                            value: r.campaign.title,
                          ),
                          _DetailRow(
                            icon: Icons.tag_rounded,
                            label: 'Campaign ID',
                            value: r.campaign.id,
                            mono: true,
                          ),
                          _DetailRow(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Active',
                            value: r.campaign.isActive ? 'Yes' : 'No',
                            valueColor: r.campaign.isActive ? rGreen : rSub,
                          ),
                          if (r.campaign.progress != null)
                            _DetailRow(
                              icon: Icons.trending_up_rounded,
                              label: 'Progress',
                              value:
                                  '${r.campaign.progress!.toStringAsFixed(1)}%',
                              valueColor: rGold,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Organization info
                      _DetailSection(
                        title: 'Organization',
                        icon: Icons.business_rounded,
                        color: rIndigo,
                        children: [
                          _DetailRow(
                            icon: Icons.corporate_fare_rounded,
                            label: 'Name',
                            value: r.organization.organizationName,
                          ),
                          _DetailRow(
                            icon: Icons.tag_rounded,
                            label: 'Org ID',
                            value: r.organization.id,
                            mono: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Submission info
                      _DetailSection(
                        title: 'Submission Details',
                        icon: Icons.send_rounded,
                        color: rGold,
                        children: [
                          _DetailRow(
                            icon: Icons.schedule_rounded,
                            label: 'Submitted',
                            value: r.submittedFormatted,
                          ),
                          _DetailRow(
                            icon: Icons.timer_rounded,
                            label: 'Pending for',
                            value: r.pendingLabel,
                            valueColor: _pendingColor(r.pendingDuration),
                          ),
                          _DetailRow(
                            icon: Icons.how_to_reg_rounded,
                            label: 'Reviewed By',
                            value: r.reviewedBy ?? 'Not yet reviewed',
                            valueColor: r.reviewedBy != null ? rText : rSub,
                          ),
                          if (r.reviewedAt != null)
                            _DetailRow(
                              icon: Icons.event_available_rounded,
                              label: 'Reviewed At',
                              value: r.reviewedFormatted,
                            ),
                          if (r.rejectionReason != null)
                            _DetailRow(
                              icon: Icons.comment_rounded,
                              label: 'Rejection Reason',
                              value: r.rejectionReason!,
                              valueColor: rRed,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // File details
                      _DetailSection(
                        title: 'Report File',
                        icon: Icons.attach_file_rounded,
                        color: rRed,
                        children: [
                          _DetailRow(
                            icon: Icons.description_rounded,
                            label: 'File Name',
                            value: r.reportFile.originalName,
                          ),
                          _DetailRow(
                            icon: Icons.data_usage_rounded,
                            label: 'File Size',
                            value: r.reportFile.formattedSize,
                          ),
                          _DetailRow(
                            icon: Icons.category_rounded,
                            label: 'Type',
                            value: r.reportFile.mimeType,
                            mono: true,
                          ),
                          _DetailRow(
                            icon: Icons.cloud_upload_rounded,
                            label: 'Uploaded',
                            value: _fmtDate(r.reportFile.uploadedAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Action buttons ──────────────────────
                      Obx(() {
                        final loading = widget.ctrl.actionLoading.value == r.id;
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ReportActionBtn(
                                label: 'Approve Report',
                                icon: Icons.verified_rounded,
                                color: rGreen,
                                loading: loading,
                                onTap: loading
                                    ? null
                                    : () => widget.ctrl.approveReport(r.id),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ReportActionBtn(
                                label: 'Reject with Reason',
                                icon: Icons.block_rounded,
                                color: rRed,
                                ghost: true,
                                loading: loading,
                                onTap: loading
                                    ? null
                                    : () => widget.ctrl.openRejectDialog(r),
                              ),
                            ),
                          ],
                        );
                      }),
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

  Color _pendingColor(Duration d) {
    if (d.inDays > 3) return rRed;
    if (d.inDays > 1) return rGold;
    return rGreen;
  }

  String _fmtDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────
//  PANEL HEADER
// ─────────────────────────────────────────────────────────────
class _PanelHeader extends StatelessWidget {
  final CampaignReport report;
  final CampaignReportController ctrl;
  const _PanelHeader({required this.report, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: rBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: rGold.withOpacity(0.12),
              borderRadius: rR8,
            ),
            child: const Icon(Icons.article_rounded, color: rGold, size: 15),
          ),
          const SizedBox(width: 10),
          Text('Report Review', style: rH2()),
          const Spacer(),
          RIconBtn(
            icon: Icons.close_rounded,
            tooltip: 'Close',
            onTap: ctrl.closeDetail,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PDF PREVIEW CARD
// ─────────────────────────────────────────────────────────────
class _PdfPreviewCard extends StatefulWidget {
  final CampaignReport report;
  final CampaignReportController ctrl;
  const _PdfPreviewCard({required this.report, required this.ctrl});

  @override
  State<_PdfPreviewCard> createState() => _PdfPreviewCardState();
}

class _PdfPreviewCardState extends State<_PdfPreviewCard> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [rRed.withOpacity(_hov ? 0.1 : 0.06), rSurf2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: rR14,
          border: Border.all(
            color: _hov ? rRed.withOpacity(0.35) : rRed.withOpacity(0.2),
          ),
          boxShadow: _hov ? rGlow(rRed) : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: rRed.withOpacity(0.12),
                borderRadius: rR12,
                border: Border.all(color: rRed.withOpacity(0.25)),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: rRed,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.reportFile.originalName,
                    style: rH2().copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(r.reportFile.formattedSize, style: rMonoSm()),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GestureDetector(
                  onTap: () => widget.ctrl.viewReport(r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: rGold.withOpacity(0.1),
                      borderRadius: rR8,
                      border: Border.all(color: rGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_rounded, size: 14, color: rGold),
                        const SizedBox(width: 5),
                        Text(
                          'View',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 11,
                            color: rGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.ctrl.downloadReport(r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: rBlue.withOpacity(0.1),
                      borderRadius: rR8,
                      border: Border.all(color: rBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.download_rounded, size: 14, color: rBlue),
                        const SizedBox(width: 5),
                        Text(
                          'Download',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 11,
                            color: rBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DETAIL SECTION
// ─────────────────────────────────────────────────────────────
class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: rSurf,
        borderRadius: rR12,
        border: Border.all(color: rBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: rR6,
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 8),
              Text(title, style: rH3().copyWith(color: rSub, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: rBorder, height: 1),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: rMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label, style: rMonoSm().copyWith(color: rSub)),
          ),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? rMono().copyWith(color: valueColor ?? rSub, fontSize: 10)
                  : rBodySm().copyWith(
                      color: valueColor ?? rText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  REJECTION DIALOG
// ─────────────────────────────────────────────────────────────
class RejectReportDialog extends StatefulWidget {
  final CampaignReportController ctrl;
  const RejectReportDialog({super.key, required this.ctrl});

  @override
  State<RejectReportDialog> createState() => _RejectReportDialogState();
}

class _RejectReportDialogState extends State<RejectReportDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.ctrl.selectedReport.value;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 480,
            decoration: BoxDecoration(
              color: rSurf2,
              borderRadius: rR16,
              border: Border.all(color: rRed.withOpacity(0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: rRed.withOpacity(0.12),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Dialog header ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [rRed.withOpacity(0.08), Colors.transparent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(color: rRed.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: rRed.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: rRed.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.block_rounded,
                          color: rRed,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reject Report', style: rH1()),
                          if (report != null)
                            Text(
                              report.campaign.title,
                              style: rMonoSm().copyWith(color: rSub),
                            ),
                        ],
                      ),
                      const Spacer(),
                      RIconBtn(
                        icon: Icons.close_rounded,
                        tooltip: 'Cancel',
                        onTap: widget.ctrl.closeRejectDialog,
                      ),
                    ],
                  ),
                ),

                // ── Body ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Warning card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: rGold.withOpacity(0.05),
                          borderRadius: rR10,
                          border: Border.all(color: rGold.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: rGold,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'The organization will be notified with this reason. '
                                'Be specific and constructive.',
                                style: rBodySm().copyWith(
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reason input
                      Text(
                        'Rejection Reason',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: rSub,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: widget.ctrl.rejectReasonCtrl,
                              maxLines: 4,
                              style: GoogleFonts.nunitoSans(
                                fontSize: 13,
                                color: rText,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'e.g. Not enough evidence of expenses. Please resubmit with detailed receipts...',
                                hintStyle: GoogleFonts.nunitoSans(
                                  fontSize: 12,
                                  color: rMuted,
                                ),
                                filled: true,
                                fillColor: rSurf,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: rR10,
                                  borderSide: BorderSide(
                                    color:
                                        widget
                                            .ctrl
                                            .rejectReasonError
                                            .value
                                            .isNotEmpty
                                        ? rRed
                                        : rBorder,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: rR10,
                                  borderSide: const BorderSide(
                                    color: rRed,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(14),
                              ),
                              onChanged: (_) {
                                if (widget
                                    .ctrl
                                    .rejectReasonError
                                    .value
                                    .isNotEmpty) {
                                  widget.ctrl.rejectReasonError.value = '';
                                }
                              },
                            ),
                            if (widget.ctrl.rejectReasonError.value.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 12,
                                      color: rRed,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      widget.ctrl.rejectReasonError.value,
                                      style: GoogleFonts.sourceCodePro(
                                        fontSize: 11,
                                        color: rRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ReportActionBtn(
                              label: 'Cancel',
                              icon: Icons.close_rounded,
                              color: rSub,
                              ghost: true,
                              onTap: widget.ctrl.closeRejectDialog,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ReportActionBtn(
                              label: 'Confirm Rejection',
                              icon: Icons.block_rounded,
                              color: rRed,
                              onTap: widget.ctrl.rejectReport,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
