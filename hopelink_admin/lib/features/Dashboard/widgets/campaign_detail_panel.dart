//  DETAIL PANEL   campaign_detail_panel.dart
//  Slide-in right panel showing full campaign info

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
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
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

  Future<void> _showEditDialog(BuildContext context, CampaignListItem c) async {
    final titleCtrl = TextEditingController(text: c.title);
    final descCtrl = TextEditingController(text: c.description);
    final targetCtrl = TextEditingController(
      text: c.targetAmount.toStringAsFixed(0),
    );
    final startCtrl = TextEditingController(
      text: widget.ctrl.formatDate(c.startDate),
    );
    final endCtrl = TextEditingController(
      text: widget.ctrl.formatDate(c.endDate),
    );
    final tagsCtrl = TextEditingController(text: c.tags.join(', '));
    var isFeatured = c.isFeatured;
    DateTime startDate = c.startDate;
    DateTime endDate = c.endDate;

    DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
    Future<void> _pickDate(
      TextEditingController ctrl,
      DateTime initial,
      void Function(DateTime) onPicked,
    ) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: cEmerald,
              onPrimary: Colors.black,
              surface: cSurf,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        onPicked(picked);
        ctrl.text = widget.ctrl.formatDate(picked);
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: cSurf,
            title: Text('Edit Campaign', style: headingMd()),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DialogField(label: 'Title', controller: titleCtrl),
                    const SizedBox(height: 10),
                    _DialogField(
                      label: 'Description',
                      controller: descCtrl,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 10),
                    _DialogField(
                      label: 'Target Amount',
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DialogField(
                            label: 'Start Date',
                            controller: startCtrl,
                            readOnly: true,
                            onTap: () async {
                              await _pickDate(
                                startCtrl,
                                startDate,
                                (d) => setState(() => startDate = d),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DialogField(
                            label: 'End Date',
                            controller: endCtrl,
                            readOnly: true,
                            onTap: () async {
                              await _pickDate(
                                endCtrl,
                                endDate,
                                (d) => setState(() => endDate = d),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _DialogField(
                      label: 'Tags (comma separated)',
                      controller: tagsCtrl,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Switch(
                          value: isFeatured,
                          activeColor: cEmerald,
                          onChanged: (v) => setState(() => isFeatured = v),
                        ),
                        const SizedBox(width: 8),
                        Text('Featured', style: bodySm()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel', style: bodySm()),
              ),
              Obx(() {
                final busy = widget.ctrl.actionLoading.value;
                return TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final tags = tagsCtrl.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          final req = UpdateCampaignRequest(
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            targetAmount: double.tryParse(
                              targetCtrl.text.replaceAll(',', ''),
                            ),
                            startDate: _dateOnly(
                              startDate,
                            ).toUtc().toIso8601String(),
                            endDate: _dateOnly(
                              endDate,
                            ).toUtc().toIso8601String(),
                            tags: tags,
                            isFeatured: isFeatured,
                          );
                          final ok = await widget.ctrl.updateCampaign(
                            c.id,
                            req,
                          );
                          if (ok && mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                  child: Text(
                    busy ? 'Saving...' : 'Save',
                    style: bodySm().copyWith(
                      color: busy ? cTextMute : cEmerald,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showStatusDialog(
    BuildContext context,
    CampaignListItem c,
  ) async {
    String status = c.status;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: cSurf,
            title: Text('Update Status', style: headingMd()),
            content: DropdownButton<String>(
              value: status,
              dropdownColor: cSurf,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
              ],
              onChanged: (v) => setState(() => status = v ?? status),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel', style: bodySm()),
              ),
              Obx(() {
                final busy = widget.ctrl.actionLoading.value;
                return TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final ok = await widget.ctrl.updateCampaignStatus(
                            c.id,
                            status,
                          );
                          if (ok && mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                  child: Text(
                    busy ? 'Updating...' : 'Update',
                    style: bodySm().copyWith(
                      color: busy ? cTextMute : cEmerald,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddUpdateDialog(
    BuildContext context,
    CampaignListItem c,
  ) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cSurf,
        title: Text('Add Update', style: headingMd()),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(label: 'Title', controller: titleCtrl),
              const SizedBox(height: 10),
              _DialogField(
                label: 'Description',
                controller: descCtrl,
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: bodySm()),
          ),
          Obx(() {
            final busy = widget.ctrl.actionLoading.value;
            return TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await widget.ctrl.addCampaignUpdate(
                        c.id,
                        titleCtrl.text,
                        descCtrl.text,
                      );
                      if (ok && mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
              child: Text(
                busy ? 'Posting...' : 'Post',
                style: bodySm().copyWith(
                  color: busy ? cTextMute : cEmerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showAddFaqDialog(
    BuildContext context,
    CampaignListItem c,
  ) async {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cSurf,
        title: Text('Add FAQ', style: headingMd()),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(label: 'Question', controller: qCtrl),
              const SizedBox(height: 10),
              _DialogField(label: 'Answer', controller: aCtrl, maxLines: 4),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: bodySm()),
          ),
          Obx(() {
            final busy = widget.ctrl.actionLoading.value;
            return TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await widget.ctrl.addCampaignFaq(
                        c.id,
                        qCtrl.text,
                        aCtrl.text,
                      );
                      if (ok && mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
              child: Text(
                busy ? 'Saving...' : 'Save',
                style: bodySm().copyWith(
                  color: busy ? cTextMute : cEmerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showUploadImagesDialog(
    BuildContext context,
    CampaignListItem c,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cSurf,
        title: Text('Upload Images', style: headingMd()),
        content: SizedBox(
          width: 440,
          child: Obx(() {
            final files = widget.ctrl.pickedImages;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradBtn(
                  label: 'Pick Images',
                  icon: Icons.photo_library_rounded,
                  ghost: true,
                  onTap: widget.ctrl.pickImages,
                ),
                const SizedBox(height: 10),
                if (files.isEmpty)
                  Text(
                    'No images selected.',
                    style: bodySm().copyWith(color: cTextMute),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: files
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              f.name,
                              style: bodySm().copyWith(fontSize: 11),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.ctrl.clearPickedImages();
              Navigator.of(ctx).pop();
            },
            child: Text('Close', style: bodySm()),
          ),
          Obx(() {
            final busy = widget.ctrl.isUploadingImages.value;
            return TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await widget.ctrl.uploadCampaignImages(c.id);
                      if (ok && mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
              child: Text(
                busy ? 'Uploading...' : 'Upload',
                style: bodySm().copyWith(
                  color: busy ? cTextMute : cEmerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showUploadEvidenceDialog(
    BuildContext context,
    CampaignListItem c,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cSurf,
        title: Text('Upload Evidence Photos', style: headingMd()),
        content: SizedBox(
          width: 460,
          child: Obx(() {
            final files = widget.ctrl.pickedEvidencePhotos;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'These photos become public on the campaign page right after upload.',
                  style: bodySm().copyWith(color: cTextSub),
                ),
                const SizedBox(height: 14),
                GradBtn(
                  label: 'Pick Evidence Photos',
                  icon: Icons.add_a_photo_rounded,
                  ghost: true,
                  onTap: widget.ctrl.pickEvidencePhotos,
                ),
                const SizedBox(height: 12),
                if (files.isEmpty)
                  Text(
                    'No evidence photos selected yet.',
                    style: bodySm().copyWith(color: cTextMute),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: files
                        .map(
                          (f) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cSurf2,
                              borderRadius: r10,
                              border: Border.all(color: cBorder),
                            ),
                            child: Text(
                              f.name,
                              style: monoSm().copyWith(color: cText),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.ctrl.clearPickedEvidencePhotos();
              Navigator.of(ctx).pop();
            },
            child: Text('Close', style: bodySm()),
          ),
          Obx(() {
            final busy = widget.ctrl.isUploadingEvidencePhotos.value;
            return TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await widget.ctrl.uploadCampaignEvidencePhotos(
                        c.id,
                      );
                      if (ok && mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
              child: Text(
                busy ? 'Uploading...' : 'Publish Photos',
                style: bodySm().copyWith(
                  color: busy ? cTextMute : cEmerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showUploadReportDialog(
    BuildContext context,
    CampaignListItem c,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cSurf,
        title: Text('Submit PDF Report', style: headingMd()),
        content: SizedBox(
          width: 460,
          child: Obx(() {
            final file = widget.ctrl.pickedReportFile.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Only PDF documents are accepted. Report approval still follows the admin review flow.',
                  style: bodySm().copyWith(color: cTextSub),
                ),
                const SizedBox(height: 14),
                GradBtn(
                  label: 'Choose PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  ghost: true,
                  onTap: widget.ctrl.pickReportPdf,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cSurf2,
                    borderRadius: r10,
                    border: Border.all(color: cBorder),
                  ),
                  child: Text(
                    file?.name ?? 'No PDF selected yet.',
                    style: bodySm().copyWith(
                      color: file == null ? cTextMute : cText,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.ctrl.clearPickedReportFile();
              Navigator.of(ctx).pop();
            },
            child: Text('Close', style: bodySm()),
          ),
          Obx(() {
            final busy = widget.ctrl.isUploadingReport.value;
            return TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await widget.ctrl.uploadCampaignReport(c.id);
                      if (ok && mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
              child: Text(
                busy ? 'Submitting...' : 'Submit Report',
                style: bodySm().copyWith(
                  color: busy ? cTextMute : cEmerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _reportStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return cEmerald;
      case 'rejected':
        return cRose;
      default:
        return cAmber;
    }
  }

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
              // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: cBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Campaign Details', style: headingMd()),
                    ),
                    CIconBtn(
                      icon: Icons.close_rounded,
                      tooltip: 'Close',
                      onTap: widget.ctrl.closeDetail,
                    ),
                  ],
                ),
              ),

              //  Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images carousel
                      if (c.hasImages)
                        _ImageCarousel(campaign: c)
                      else
                        _NoImageBanner(campaign: c, color: t.color),
                      const SizedBox(height: 16),

                      // Title
                      Text(c.title, style: headingLg()),
                      const SizedBox(height: 8),

                      // Org
                      if (c.organization != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.business_rounded,
                              size: 13,
                              color: cTextMute,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.organization!.organizationName,
                              style: bodySm(),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      // Status + days left
                      Row(
                        children: [
                          CampaignStatusBadge(status: c.status),
                          const SizedBox(width: 8),
                          DaysLeftPill(days: c.daysLeft, expired: c.isExpired),
                          if (c.isFeatured) ...[
                            const SizedBox(width: 8),
                            IconChip(
                              icon: Icons.star_rounded,
                              label: 'Featured',
                              color: cViolet,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Description
                      Text(
                        c.description,
                        style: bodySm().copyWith(color: cTextSub, height: 1.6),
                      ),
                      const SizedBox(height: 18),

                      //  Manage Campaign
                      _SectionLabel('Manage', Icons.settings_rounded),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          GradBtn(
                            label: 'Edit Details',
                            icon: Icons.edit_rounded,
                            ghost: true,
                            onTap: () => _showEditDialog(context, c),
                          ),
                          GradBtn(
                            label: 'Change Status',
                            icon: Icons.sync_alt_rounded,
                            ghost: true,
                            onTap: () => _showStatusDialog(context, c),
                          ),
                          GradBtn(
                            label: 'Upload Images',
                            icon: Icons.photo_library_rounded,
                            ghost: true,
                            onTap: () => _showUploadImagesDialog(context, c),
                          ),
                          GradBtn(
                            label: 'Add Update',
                            icon: Icons.update_rounded,
                            ghost: true,
                            onTap: () => _showAddUpdateDialog(context, c),
                          ),
                          GradBtn(
                            label: 'Add FAQ',
                            icon: Icons.quiz_rounded,
                            ghost: true,
                            onTap: () => _showAddFaqDialog(context, c),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      _SectionLabel(
                        'Transparency',
                        Icons.visibility_rounded,
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          GradBtn(
                            label: 'Submit PDF Report',
                            icon: Icons.picture_as_pdf_rounded,
                            ghost: true,
                            onTap: () => _showUploadReportDialog(context, c),
                          ),
                          GradBtn(
                            label: 'Upload Evidence',
                            icon: Icons.verified_rounded,
                            ghost: true,
                            onTap: () => _showUploadEvidenceDialog(context, c),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ReportStatusCard(
                        report: c.report,
                        ctrl: widget.ctrl,
                        formatBytes: _formatBytes,
                        statusColor: _reportStatusColor,
                      ),
                      const SizedBox(height: 12),
                      _EvidenceGallery(evidencePhotos: c.evidencePhotos),
                      const SizedBox(height: 16),

                      _SectionLabel(
                        'Funding Progress',
                        Icons.trending_up_rounded,
                      ),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Raised',
                                      style: monoSm().copyWith(
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.ctrl.formatCurrency(
                                        c.currentAmount,
                                      ),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: t.color,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Goal',
                                      style: monoSm().copyWith(
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.ctrl.formatCurrency(
                                        c.targetAmount,
                                      ),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: cText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CampaignProgressBar(
                              percent: c.progressPercent,
                              height: 8,
                              showLabel: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // â”€â”€ Timeline Block â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _SectionLabel('Timeline', Icons.date_range_rounded),
                      Row(
                        children: [
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
                        ],
                      ),
                      const SizedBox(height: 14),

                      // updates
                      if (c.updates.isNotEmpty) ...[
                        _SectionLabel(
                          'Updates (${c.updates.length})',
                          Icons.update_rounded,
                        ),
                        ...c.updates.map(
                          (u) => _UpdateTile(update: u, ctrl: widget.ctrl),
                        ),
                        const SizedBox(height: 4),
                      ],

                      if (c.faqs.isNotEmpty) ...[
                        _SectionLabel(
                          'FAQs (${c.faqs.length})',
                          Icons.quiz_rounded,
                        ),
                        Obx(
                          () => Column(
                            children: List.generate(
                              c.faqs.length,
                              (i) => _FaqTile(
                                faq: c.faqs[i],
                                index: i,
                                expanded:
                                    widget.ctrl.expandedFaqIndex.value == i,
                                onToggle: () => widget.ctrl.toggleFaq(i),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Donations
                      _SectionLabel(
                        'Donations',
                        Icons.volunteer_activism_rounded,
                      ),
                      Obx(() {
                        if (widget.ctrl.donationsLoading.value &&
                            widget.ctrl.donations.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(cEmerald),
                              ),
                            ),
                          );
                        }
                        if (widget.ctrl.donationsError.value.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              widget.ctrl.donationsError.value,
                              style: bodySm().copyWith(color: cRose),
                            ),
                          );
                        }
                        if (widget.ctrl.donations.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'No donations yet.',
                              style: bodySm().copyWith(color: cTextMute),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            ...widget.ctrl.donations.map(
                              (d) =>
                                  _DonationTile(donation: d, ctrl: widget.ctrl),
                            ),
                            if (widget.ctrl.donationsNextPage.value != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GradBtn(
                                  label: widget.ctrl.donationsLoading.value
                                      ? 'Loading...'
                                      : 'Load More',
                                  ghost: true,
                                  icon: Icons.expand_more_rounded,
                                  onTap: widget.ctrl.donationsLoading.value
                                      ? null
                                      : widget.ctrl.loadMoreDonations,
                                ),
                              ),
                          ],
                        );
                      }),

                      const SizedBox(height: 6),
                      _GradDivider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.tag_rounded,
                            size: 11,
                            color: cTextMute,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              c.id,
                              style: mono().copyWith(fontSize: 9),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Clipboard.setData(ClipboardData(text: c.id)),
                            child: const Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: cTextMute,
                            ),
                          ),
                        ],
                      ),
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

//  IMAGE CAROUSEL
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
    return Column(
      children: [
        ClipRRect(
          borderRadius: r12,
          child: Stack(
            children: [
              Image.network(
                imgs[_idx],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: cSurf3,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: cTextMute,
                      size: 32,
                    ),
                  ),
                ),
              ),
              if (imgs.length > 1)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: r6,
                    ),
                    child: Text(
                      '${_idx + 1}/${imgs.length}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (imgs.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imgs.length,
              (i) => GestureDetector(
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
      ],
    );
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_rounded,
              size: 28,
              color: color.withOpacity(0.4),
            ),
            const SizedBox(height: 6),
            Text(
              'No images attached',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: color.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStatusCard extends StatelessWidget {
  final CampaignReportSnapshot? report;
  final CampaignListController ctrl;
  final String Function(int bytes) formatBytes;
  final Color Function(String status) statusColor;

  const _ReportStatusCard({
    required this.report,
    required this.ctrl,
    required this.formatBytes,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cSurf2,
          borderRadius: r12,
          border: Border.all(color: cBorder),
        ),
        child: Text(
          'No campaign report submitted yet.',
          style: bodySm().copyWith(color: cTextMute),
        ),
      );
    }

    final accent = statusColor(report!.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.12), cSurf2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: r12,
        border: Border.all(color: accent.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: r20,
                ),
                child: Text(
                  report!.status.toUpperCase(),
                  style: monoSm().copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                ctrl.formatDateTime(report!.submittedAt),
                style: monoSm(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report!.reportFile?.originalName ?? 'PDF report',
            style: headingMd().copyWith(fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            report!.reportFile == null
                ? 'No report file metadata available.'
                : '${report!.reportFile!.mimeType} • ${formatBytes(report!.reportFile!.size)}',
            style: bodySm().copyWith(color: cTextSub),
          ),
          if (report!.reviewedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reviewed ${ctrl.formatDateTime(report!.reviewedAt!)}',
              style: bodySm().copyWith(color: cTextSub),
            ),
          ],
          if (report!.rejectionReason != null &&
              report!.rejectionReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cRose.withOpacity(0.08),
                borderRadius: r10,
                border: Border.all(color: cRose.withOpacity(0.2)),
              ),
              child: Text(
                report!.rejectionReason!,
                style: bodySm().copyWith(color: cText),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidenceGallery extends StatelessWidget {
  final List<String> evidencePhotos;

  const _EvidenceGallery({required this.evidencePhotos});

  @override
  Widget build(BuildContext context) {
    if (evidencePhotos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cSurf2,
          borderRadius: r12,
          border: Border.all(color: cBorder),
        ),
        child: Text(
          'No public evidence photos uploaded yet.',
          style: bodySm().copyWith(color: cTextMute),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Public evidence gallery',
          style: monoSm().copyWith(letterSpacing: 0.4),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          itemCount: evidencePhotos.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final imageUrl = evidencePhotos[index];
            return ClipRRect(
              borderRadius: r12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: cSurf3,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: cTextMute,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: r8,
                      ),
                      child: Text(
                        'Evidence ${index + 1}',
                        style: monoSm().copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

//  SECTION LABEL

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: cEmerald.withOpacity(0.1),
              borderRadius: r6,
            ),
            child: Icon(icon, size: 12, color: cEmerald),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: headingMd().copyWith(fontSize: 12, color: cTextSub),
          ),
        ],
      ),
    );
  }
}

//  INFO TILE (date/timeline)
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cSurf2,
        borderRadius: r10,
        border: Border.all(color: cBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cTextMute),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: monoSm().copyWith(letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: cText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//  DIALOG FIELD

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool readOnly;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;

  const _DialogField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.readOnly = false,
    this.keyboardType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: monoSm().copyWith(letterSpacing: 0.4)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          keyboardType: keyboardType,
          onTap: onTap,
          style: bodySm().copyWith(color: cText),
          decoration: InputDecoration(
            filled: true,
            fillColor: cSurf2,
            hintText: label,
            hintStyle: bodySm().copyWith(color: cTextMute),
            border: OutlineInputBorder(
              borderRadius: r10,
              borderSide: const BorderSide(color: cBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: r10,
              borderSide: const BorderSide(color: cBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: r10,
              borderSide: BorderSide(color: cEmerald.withOpacity(0.6)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

//  UPDATE TILE

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.update_rounded, size: 12, color: cSky),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  update.title,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cText,
                  ),
                ),
              ),
              Text(ctrl.formatDate(update.date), style: monoSm()),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            update.description,
            style: bodySm().copyWith(color: cTextSub, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
//  DONATION TILE

class _DonationTile extends StatelessWidget {
  final CampaignDonation donation;
  final CampaignListController ctrl;
  const _DonationTile({required this.donation, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final donorName = donation.isAnonymous
        ? 'Anonymous'
        : donation.donor?.name ?? 'Anonymous';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cEmerald.withOpacity(0.04),
        borderRadius: r10,
        border: Border.all(color: cEmerald.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.volunteer_activism_rounded,
                size: 12,
                color: cEmerald,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  donorName,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cText,
                  ),
                ),
              ),
              Text(ctrl.formatDateTime(donation.createdAt), style: monoSm()),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                ctrl.formatCurrency(donation.amount),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cEmerald,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                donation.paymentMethod.isEmpty
                    ? 'payment'
                    : donation.paymentMethod,
                style: bodySm().copyWith(color: cTextMute, fontSize: 11),
              ),
            ],
          ),
          if (donation.message != null && donation.message!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              donation.message!,
              style: bodySm().copyWith(color: cTextSub, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

//  FAQ TILE (accordion)

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
            color: expanded ? cAmber.withOpacity(0.2) : cBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: cAmber.withOpacity(0.1),
                      borderRadius: r6,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: cAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      faq.question,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cText,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: cTextMute,
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  faq.answer,
                  style: bodySm().copyWith(
                    color: cTextSub,
                    fontSize: 11,
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  GRADIENT DIVIDER
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
