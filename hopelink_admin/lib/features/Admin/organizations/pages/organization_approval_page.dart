import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopelink_admin/features/Auth/controller/login_controller.dart';
import 'package:hopelink_admin/features/Auth/pages/login_page.dart';
import 'package:hopelink_admin/features/Auth/widgets/account_switcher_button.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../controllers/organization_approval_controller.dart';
import '../models/pending_organization_model.dart';

const _bg = Color(0xFF070D18);
const _surface = Color(0xFF101827);
const _surface2 = Color(0xFF162033);
const _border = Color(0xFF243148);
const _text = Color(0xFFE5EEFB);
const _muted = Color(0xFF8EA1BD);
const _accent = Color(0xFF38BDF8);
const _green = Color(0xFF10B981);
const _red = Color(0xFFEF4444);

class OrganizationApprovalPage extends StatefulWidget {
  const OrganizationApprovalPage({super.key});

  @override
  State<OrganizationApprovalPage> createState() =>
      _OrganizationApprovalPageState();
}

class _OrganizationApprovalPageState extends State<OrganizationApprovalPage> {
  final ctrl = Get.put(OrganizationApprovalController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(ctrl: ctrl),
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value && ctrl.organizations.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }
                if (ctrl.errorMessage.value.isNotEmpty &&
                    ctrl.organizations.isEmpty) {
                  return _StatePanel(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load pending organizations',
                    message: ctrl.errorMessage.value,
                    actionLabel: 'Retry',
                    onAction: ctrl.reload,
                  );
                }
                if (ctrl.organizations.isEmpty) {
                  return _StatePanel(
                    icon: Icons.verified_user_rounded,
                    title: 'No pending organizations',
                    message: 'New organization registrations will appear here.',
                    actionLabel: 'Refresh',
                    onAction: ctrl.reload,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 980;
                    if (isWide) {
                      return Row(
                        children: [
                          SizedBox(width: 390, child: _ListPanel(ctrl: ctrl)),
                          const VerticalDivider(width: 1, color: _border),
                          Expanded(child: _DetailPanel(ctrl: ctrl)),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        SizedBox(height: 330, child: _ListPanel(ctrl: ctrl)),
                        const Divider(height: 1, color: _border),
                        Expanded(child: _DetailPanel(ctrl: ctrl)),
                      ],
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final OrganizationApprovalController ctrl;
  const _Header({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.domain_verification_rounded,
              color: _accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Organization Approvals', style: _titleStyle(22)),
                Obx(
                  () => Text(
                    '${ctrl.totalItems.value} pending review',
                    style: _bodyStyle(color: _muted, size: 13),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 280,
            height: 40,
            child: TextField(
              controller: ctrl.searchCtrl,
              style: _bodyStyle(),
              decoration: InputDecoration(
                hintText: 'Search organizations...',
                hintStyle: _bodyStyle(color: _muted),
                prefixIcon: const Icon(Icons.search_rounded, color: _muted),
                filled: true,
                fillColor: _surface,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Obx(
            () => IconButton.filledTonal(
              tooltip: 'Refresh',
              onPressed: ctrl.isLoading.value ? null : ctrl.reload,
              icon: Icon(
                ctrl.isLoading.value
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const AccountSwitcherButton(
            backgroundColor: _surface,
            hoverColor: _surface2,
            borderColor: _border,
            accentColor: _accent,
            textColor: _text,
            mutedColor: _muted,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Logout',
            color: _red,
            onPressed: () async {
              final loginCtrl = Get.put(LoginController());
              await loginCtrl.logout();
              Get.offAll(() => const LoginPage());
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }
}

class _ListPanel extends StatelessWidget {
  final OrganizationApprovalController ctrl;
  const _ListPanel({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A111F),
      child: Obx(() {
        final orgs = ctrl.filteredOrganizations;
        if (orgs.isEmpty) {
          return _StatePanel(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            message: 'Try a different organization name, email, or type.',
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orgs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final org = orgs[index];
                  final selected =
                      ctrl.selectedOrganization.value?.id == org.id;
                  return _OrganizationTile(
                    org: org,
                    selected: selected,
                    onTap: () => ctrl.selectOrganization(org),
                  );
                },
              ),
            ),
            if (ctrl.totalPages.value > 1)
              _PaginationBar(
                page: ctrl.currentPage.value,
                totalPages: ctrl.totalPages.value,
                onPrevious: ctrl.previousPage,
                onNext: ctrl.nextPage,
              ),
          ],
        );
      }),
    );
  }
}

class _OrganizationTile extends StatelessWidget {
  final PendingOrganization org;
  final bool selected;
  final VoidCallback onTap;

  const _OrganizationTile({
    required this.org,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _surface2 : _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _accent : _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(label: org.organizationName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org.organizationName,
                        style: _titleStyle(15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        org.officialEmail,
                        style: _bodyStyle(color: _muted, size: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _StatusPill(label: org.organizationType),
              ],
            ),
            const SizedBox(height: 12),
            _InlineMeta(icon: Icons.place_rounded, text: org.location),
            const SizedBox(height: 6),
            _InlineMeta(
              icon: Icons.badge_rounded,
              text: 'Reg. ${org.registrationNumber}',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final OrganizationApprovalController ctrl;
  const _DetailPanel({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final org = ctrl.selectedOrganization.value;
      if (org == null) {
        return _StatePanel(
          icon: Icons.domain_disabled_rounded,
          title: 'Select an organization',
          message: 'Choose a pending registration to review its details.',
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailHeader(ctrl: ctrl, org: org),
            const SizedBox(height: 18),
            _Section(
              title: 'Organization Details',
              children: [
                _InfoGrid(
                  items: [
                    _InfoItem('Name', org.organizationName),
                    _InfoItem('Type', org.organizationType),
                    _InfoItem('Registration Number', org.registrationNumber),
                    _InfoItem(
                      'Registered On',
                      _formatDate(org.dateOfRegistration),
                    ),
                    _InfoItem('Primary Cause', org.primaryCause),
                    _InfoItem('Active Members', '${org.activeMembers}'),
                    _InfoItem('Status', org.status),
                    _InfoItem('Verified', org.isVerified ? 'Yes' : 'No'),
                  ],
                ),
                _LongText(
                  label: 'Mission Statement',
                  value: org.missionStatement,
                ),
                _LongText(
                  label: 'Recent Campaigns',
                  value: org.recentCampaigns.isEmpty
                      ? 'Not provided'
                      : org.recentCampaigns.join(', '),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Contact & Representative',
              children: [
                _InfoGrid(
                  items: [
                    _InfoItem('Official Email', org.officialEmail),
                    _InfoItem('Official Phone', org.officialPhone),
                    _InfoItem('Website', _fallback(org.website)),
                    _InfoItem('Country', org.country),
                    _InfoItem('City', org.city),
                    _InfoItem('Address', org.registeredAddress),
                    _InfoItem('Representative', org.representativeName),
                    _InfoItem('Designation', org.designation),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Bank & Social',
              children: [
                _InfoGrid(
                  items: [
                    _InfoItem('Bank Name', org.bankDetails.bankName),
                    _InfoItem(
                      'Account Holder',
                      org.bankDetails.accountHolderName,
                    ),
                    _InfoItem('Account Number', org.bankDetails.accountNumber),
                    _InfoItem('Branch', org.bankDetails.bankBranch),
                    _InfoItem('Facebook', _fallback(org.socialMedia.facebook)),
                    _InfoItem(
                      'Instagram',
                      _fallback(org.socialMedia.instagram),
                    ),
                    _InfoItem('LinkedIn', _fallback(org.socialMedia.linkedin)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Uploaded Documents',
              children: [_DocumentGrid(documents: org.documents)],
            ),
          ],
        ),
      );
    });
  }
}

class _DetailHeader extends StatelessWidget {
  final OrganizationApprovalController ctrl;
  final PendingOrganization org;
  const _DetailHeader({required this.ctrl, required this.org});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _Avatar(label: org.organizationName, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(org.organizationName, style: _titleStyle(22)),
                const SizedBox(height: 4),
                Text(
                  '${org.organizationType} • ${org.location}',
                  style: _bodyStyle(color: _muted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(label: org.status),
                    _StatusPill(
                      label: '${org.documents.length} documents',
                      color: _accent,
                    ),
                    _StatusPill(
                      label: 'Submitted ${_formatDate(org.createdAt)}',
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Obx(() {
            final busy = ctrl.actionLoadingId.value == org.id;
            if (busy) {
              return const SizedBox(
                width: 120,
                child: Center(child: CircularProgressIndicator(color: _accent)),
              );
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => ctrl.approveOrganization(org),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _red,
                    side: const BorderSide(color: _red),
                  ),
                  onPressed: () => ctrl.rejectOrganization(org),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle(16)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 820
            ? 3
            : constraints.maxWidth > 520
            ? 2
            : 1;
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: columns == 1 ? 5.2 : 3.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) => _InfoTile(item: items[index]),
        );
      },
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}

class _InfoTile extends StatelessWidget {
  final _InfoItem item;
  const _InfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.label, style: _bodyStyle(color: _muted, size: 11)),
          const SizedBox(height: 5),
          Text(
            _fallback(item.value),
            style: _bodyStyle(size: 13, weight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LongText extends StatelessWidget {
  final String label;
  final String value;
  const _LongText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _bodyStyle(color: _muted, size: 12)),
          const SizedBox(height: 6),
          Text(_fallback(value), style: _bodyStyle(height: 1.45)),
        ],
      ),
    );
  }
}

class _DocumentGrid extends StatelessWidget {
  final List<NamedDocument> documents;
  const _DocumentGrid({required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Text('No documents uploaded.', style: _bodyStyle(color: _muted));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 560
            ? 2
            : 1;
        return GridView.builder(
          itemCount: documents.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 1.1,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            return _DocumentCard(namedDocument: documents[index]);
          },
        );
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final NamedDocument namedDocument;
  const _DocumentCard({required this.namedDocument});

  @override
  Widget build(BuildContext context) {
    final doc = namedDocument.document;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openDocument(context, namedDocument),
              child: doc.isImage
                  ? Image.network(
                      doc.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _DocumentFallback(doc: doc),
                    )
                  : _PdfPreview(doc: doc),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  doc.isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.image_rounded,
                  color: doc.isPdf ? _red : _accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namedDocument.label,
                        style: _bodyStyle(weight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${doc.originalName} • ${doc.readableSize}',
                        style: _bodyStyle(color: _muted, size: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _openDocument(context, namedDocument),
                  child: Text(doc.isPdf ? 'View PDF' : 'View'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDocument(BuildContext context, NamedDocument namedDocument) {
    showDialog<void>(
      context: context,
      builder: (_) => _DocumentDialog(namedDocument: namedDocument),
    );
  }
}

class _PdfPreview extends StatelessWidget {
  final OrganizationDocument doc;
  const _PdfPreview({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF111827),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: _red, size: 42),
          const SizedBox(height: 10),
          Text('PDF Document', style: _titleStyle(14)),
          const SizedBox(height: 4),
          Text(doc.originalName, style: _bodyStyle(color: _muted, size: 11)),
        ],
      ),
    );
  }
}

class _DocumentFallback extends StatelessWidget {
  final OrganizationDocument doc;
  const _DocumentFallback({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111827),
      child: Center(
        child: Text(
          doc.originalName.isEmpty ? 'Preview unavailable' : doc.originalName,
          textAlign: TextAlign.center,
          style: _bodyStyle(color: _muted),
        ),
      ),
    );
  }
}

class _DocumentDialog extends StatelessWidget {
  final NamedDocument namedDocument;
  const _DocumentDialog({required this.namedDocument});

  @override
  Widget build(BuildContext context) {
    final doc = namedDocument.document;
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: _surface,
      insetPadding: const EdgeInsets.all(18),
      child: SizedBox(
        width: size.width * 0.9,
        height: size.height * 0.86,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(namedDocument.label, style: _titleStyle(16)),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: _text),
                  ),
                ],
              ),
            ),
            Expanded(
              child: doc.isPdf
                  ? SfPdfViewer.network(doc.url)
                  : InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: Center(
                        child: Image.network(
                          doc.url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              _DocumentFallback(doc: doc),
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

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: page <= 1 ? null : onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('Page $page of $totalPages', style: _bodyStyle(color: _muted)),
          IconButton(
            onPressed: page >= totalPages ? null : onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String label;
  final double size;
  const _Avatar({required this.label, this.size = 38});

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Center(
        child: Text(
          initial,
          style: _titleStyle(size * 0.36).copyWith(color: _accent),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, this.color = _green});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InlineMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _fallback(text),
            style: _bodyStyle(color: _muted, size: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _muted, size: 44),
            const SizedBox(height: 12),
            Text(title, style: _titleStyle(18), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              message,
              style: _bodyStyle(color: _muted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _border),
  );
}

TextStyle _titleStyle(double size) {
  return GoogleFonts.plusJakartaSans(
    color: _text,
    fontSize: size,
    fontWeight: FontWeight.w800,
  );
}

TextStyle _bodyStyle({
  Color color = _text,
  double size = 13,
  FontWeight weight = FontWeight.w500,
  double? height,
}) {
  return GoogleFonts.dmSans(
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: height,
  );
}

String _fallback(String value) => value.trim().isEmpty ? 'Not provided' : value;

String _formatDate(DateTime? value) {
  if (value == null) return 'Not provided';
  return DateFormat('MMM d, yyyy').format(value.toLocal());
}
