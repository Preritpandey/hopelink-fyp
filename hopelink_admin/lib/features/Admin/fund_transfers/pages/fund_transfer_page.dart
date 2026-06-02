import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/fund_transfer_controller.dart';
import '../models/fund_transfer_model.dart';

const _bg = Color(0xFF070D18);
const _surface = Color(0xFF0B1220);
const _surface2 = Color(0xFF111B2D);
const _border = Color(0xFF243148);
const _text = Color(0xFFE5EEFB);
const _muted = Color(0xFF8EA1BD);
const _blue = Color(0xFF38BDF8);
const _green = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _violet = Color(0xFF8B5CF6);

class FundTransferPage extends StatefulWidget {
  const FundTransferPage({super.key});

  @override
  State<FundTransferPage> createState() => _FundTransferPageState();
}

class _FundTransferPageState extends State<FundTransferPage> {
  final ctrl = Get.put(FundTransferController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _Header(ctrl: ctrl),
            const SizedBox(height: 18),
            _Stats(ctrl: ctrl),
            const SizedBox(height: 18),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 7, child: _TransferList(ctrl: ctrl)),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _TransferDetails(ctrl: ctrl)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final FundTransferController ctrl;
  const _Header({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _green.withValues(alpha: 0.28)),
          ),
          child: const Icon(Icons.payments_rounded, color: _green),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fund Transfers', style: _title(24)),
            Obx(
              () => Text(
                '${ctrl.totalItems.value} transfer records',
                style: _body(color: _muted),
              ),
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: 260,
          height: 40,
          child: TextField(
            controller: ctrl.searchCtrl,
            style: _body(color: _text),
            decoration: _inputDecoration(
              'Search transfers...',
              Icons.search_rounded,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Obx(
          () => DropdownButtonHideUnderline(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: _box(),
              child: DropdownButton<String>(
                value: ctrl.statusFilter.value,
                dropdownColor: _surface,
                style: _body(color: _text),
                iconEnabledColor: _muted,
                onChanged: (value) {
                  if (value != null) ctrl.setStatusFilter(value);
                },
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'initiated', child: Text('Initiated')),
                  DropdownMenuItem(value: 'processing', child: Text('Processing')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _IconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onTap: ctrl.refreshAll,
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onPressed: () => _showCreateDialog(context, ctrl),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New Transfer'),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  final FundTransferController ctrl;
  const _Stats({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = ctrl.stats.value;
      return Row(
        children: [
          _StatCard(
            label: 'Transferred',
            value: ctrl.formatCurrency(stats.amountForStatus('completed')),
            icon: Icons.check_circle_rounded,
            color: _green,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Pending',
            value: ctrl.formatCurrency(
              stats.amountForStatus('initiated') +
                  stats.amountForStatus('processing'),
            ),
            icon: Icons.pending_actions_rounded,
            color: _amber,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Failed',
            value: ctrl.formatCurrency(stats.amountForStatus('failed')),
            icon: Icons.error_rounded,
            color: _red,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Total Records',
            value: '${stats.totalTransfers}',
            icon: Icons.receipt_long_rounded,
            color: _blue,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Average',
            value: ctrl.formatCurrency(stats.averageTransferAmount),
            icon: Icons.analytics_rounded,
            color: _violet,
          ),
        ],
      );
    });
  }
}

class _TransferList extends StatelessWidget {
  final FundTransferController ctrl;
  const _TransferList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _box(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text('Transfers', style: _title(16)),
                const Spacer(),
                Obx(
                  () => Text(
                    'Page ${ctrl.currentPage.value}',
                    style: _mono(color: _muted),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value && ctrl.transfers.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: _green),
                );
              }
              if (ctrl.errorMessage.value.isNotEmpty &&
                  ctrl.transfers.isEmpty) {
                return _StatePanel(
                  icon: Icons.wifi_off_rounded,
                  title: 'Could not load transfers',
                  message: ctrl.errorMessage.value,
                );
              }
              final items = ctrl.filteredTransfers;
              if (items.isEmpty) {
                return const _StatePanel(
                  icon: Icons.payments_outlined,
                  title: 'No transfers found',
                  message: 'Create a transfer or adjust your filters.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final transfer = items[index];
                  final selected =
                      ctrl.selectedTransfer.value?.id == transfer.id;
                  return _TransferTile(
                    transfer: transfer,
                    selected: selected,
                    ctrl: ctrl,
                    onTap: () => ctrl.selectTransfer(transfer),
                  );
                },
              );
            }),
          ),
          const Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Obx(
              () => Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: ctrl.prevPage.value == null
                        ? null
                        : ctrl.previous,
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Previous'),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: ctrl.nextPage.value == null ? null : ctrl.next,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Next'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  final FundTransfer transfer;
  final bool selected;
  final FundTransferController ctrl;
  final VoidCallback onTap;

  const _TransferTile({
    required this.transfer,
    required this.selected,
    required this.ctrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(transfer.status);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _blue.withValues(alpha: 0.08) : _surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _blue.withValues(alpha: 0.35) : _border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_statusIcon(transfer.status), color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transfer.organizationName, style: _body(weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '${transfer.displayId} - ${transfer.reason}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _body(color: _muted, size: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(ctrl.formatCurrency(transfer.amount), style: _mono()),
                const SizedBox(height: 5),
                _StatusPill(label: transfer.status, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferDetails extends StatelessWidget {
  final FundTransferController ctrl;
  const _TransferDetails({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final transfer = ctrl.selectedTransfer.value;
      if (transfer == null) {
        return const _StatePanel(
          icon: Icons.receipt_long_outlined,
          title: 'Select a transfer',
          message: 'Transfer details and actions appear here.',
        );
      }

      final collected = transfer.organization?.id == null
          ? 0.0
          : ctrl.collectedForOrg(transfer.organization!.id);
      return Container(
        decoration: _box(),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Expanded(child: Text(transfer.displayId, style: _title(18))),
                _StatusPill(
                  label: transfer.status,
                  color: _statusColor(transfer.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(transfer.organizationName, style: _body(color: _muted)),
            const SizedBox(height: 18),
            _DetailTile(
              label: 'Transfer Amount',
              value: ctrl.formatCurrency(transfer.amount),
              icon: Icons.payments_rounded,
            ),
            _DetailTile(
              label: 'Collected Donations',
              value: collected <= 0 ? 'Not loaded' : ctrl.formatCurrency(collected),
              icon: Icons.savings_rounded,
            ),
            _DetailTile(
              label: 'Method',
              value: transfer.transferMethod.replaceAll('_', ' '),
              icon: Icons.account_balance_rounded,
            ),
            _DetailTile(
              label: 'Reference',
              value: transfer.reference.isEmpty ? 'Not set' : transfer.reference,
              icon: Icons.tag_rounded,
            ),
            _DetailTile(
              label: 'Initiated',
              value: ctrl.formatDateTime(transfer.initiatedAt),
              icon: Icons.schedule_rounded,
            ),
            _DetailTile(
              label: 'Expected',
              value: ctrl.formatDate(transfer.expectedCompletionDate),
              icon: Icons.event_available_rounded,
            ),
            if (transfer.bankDetails != null) ...[
              const SizedBox(height: 8),
              Text('Bank Snapshot', style: _title(14)),
              const SizedBox(height: 8),
              _DetailTile(
                label: 'Bank',
                value: transfer.bankDetails!.bankName,
                icon: Icons.account_balance_rounded,
              ),
              _DetailTile(
                label: 'Account Holder',
                value: transfer.bankDetails!.accountHolderName,
                icon: Icons.person_rounded,
              ),
              _DetailTile(
                label: 'Account',
                value: transfer.bankDetails!.accountNumber,
                icon: Icons.numbers_rounded,
              ),
            ],
            if (transfer.notes.isNotEmpty || transfer.failureReason.isNotEmpty)
              _NoteBox(
                title: transfer.failureReason.isNotEmpty ? 'Failure Reason' : 'Notes',
                value: transfer.failureReason.isNotEmpty
                    ? transfer.failureReason
                    : transfer.notes,
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => _showStatusDialog(context, ctrl, transfer),
                  icon: const Icon(Icons.sync_alt_rounded, size: 18),
                  label: const Text('Update Status'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showReceiptDialog(context, ctrl, transfer),
                  icon: const Icon(Icons.receipt_rounded, size: 18),
                  label: const Text('Receipt'),
                ),
                if (transfer.canCancel)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: _red),
                    onPressed: () => _showCancelDialog(context, ctrl, transfer),
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    label: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _box(),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: _title(18)),
                  ),
                  Text(label, style: _body(color: _muted, size: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _mono(color: _muted, size: 11)),
                const SizedBox(height: 3),
                Text(value.isEmpty ? 'Not set' : value, style: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String title;
  final String value;

  const _NoteBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _amber.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _mono(color: _amber)),
          const SizedBox(height: 6),
          Text(value, style: _body(color: _text)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(label.toUpperCase(), style: _mono(color: color, size: 10)),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: _box(),
          child: Icon(icon, color: _muted, size: 18),
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _muted, size: 34),
            const SizedBox(height: 12),
            Text(title, style: _title(17), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: _body(color: _muted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

Future<void> _showCreateDialog(
  BuildContext context,
  FundTransferController ctrl,
) async {
  final formKey = GlobalKey<FormState>();
  final orgCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final reasonCtrl = TextEditingController(text: 'Manual organization payout');
  final referenceCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  var method = 'bank_transfer';

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: _surface,
        title: Text('New Fund Transfer', style: _title(18)),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ctrl.knownOrganizations.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      dropdownColor: _surface,
                      decoration: _inputDecoration('Known organization', Icons.business_rounded),
                      items: ctrl.knownOrganizations
                          .map(
                            (org) => DropdownMenuItem(
                              value: org.id,
                              child: Text(org.organizationName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => orgCtrl.text = value ?? '',
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (ctrl.donationSummaries.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      dropdownColor: _surface,
                      decoration: _inputDecoration(
                        'Organizations with collected funds',
                        Icons.savings_rounded,
                      ),
                      items: ctrl.donationSummaries
                          .map(
                            (summary) => DropdownMenuItem(
                              value: summary.organizationId,
                              child: Text(
                                '${summary.organizationId} - ${ctrl.formatCurrency(summary.totalAmount)}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => orgCtrl.text = value ?? '',
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextFormField(
                    controller: orgCtrl,
                    style: _body(color: _text),
                    decoration: _inputDecoration(
                      'Organization ID',
                      Icons.tag_rounded,
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountCtrl,
                    style: _body(color: _text),
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Amount', Icons.payments_rounded),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) return 'Invalid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: method,
                    dropdownColor: _surface,
                    decoration: _inputDecoration('Method', Icons.account_balance_rounded),
                    items: const [
                      DropdownMenuItem(value: 'bank_transfer', child: Text('Bank transfer')),
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                      DropdownMenuItem(value: 'stripe', child: Text('Stripe')),
                      DropdownMenuItem(value: 'khalti', child: Text('Khalti')),
                    ],
                    onChanged: (value) => setState(() => method = value ?? method),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: reasonCtrl,
                    style: _body(color: _text),
                    decoration: _inputDecoration('Reason', Icons.notes_rounded),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: referenceCtrl,
                    style: _body(color: _text),
                    decoration: _inputDecoration('Reference', Icons.numbers_rounded),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesCtrl,
                    style: _body(color: _text),
                    maxLines: 3,
                    decoration: _inputDecoration('Notes', Icons.sticky_note_2_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          Obx(
            () => FilledButton(
              onPressed: ctrl.actionLoading.value
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final ok = await ctrl.initiateTransfer(
                        organizationId: orgCtrl.text,
                        amount: double.parse(amountCtrl.text),
                        transferMethod: method,
                        reason: reasonCtrl.text,
                        reference: referenceCtrl.text,
                        notes: notesCtrl.text,
                      );
                      if (ok && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
              child: Text(ctrl.actionLoading.value ? 'Creating...' : 'Create'),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showStatusDialog(
  BuildContext context,
  FundTransferController ctrl,
  FundTransfer transfer,
) async {
  final txCtrl = TextEditingController(text: transfer.transactionHash);
  final notesCtrl = TextEditingController();
  final failureCtrl = TextEditingController();
  var status = transfer.status;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: _surface,
        title: Text('Update Transfer Status', style: _title(18)),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: status,
                dropdownColor: _surface,
                decoration: _inputDecoration('Status', Icons.sync_alt_rounded),
                items: const [
                  DropdownMenuItem(value: 'initiated', child: Text('Initiated')),
                  DropdownMenuItem(value: 'processing', child: Text('Processing')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) => setState(() => status = value ?? status),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: txCtrl,
                style: _body(color: _text),
                decoration: _inputDecoration('Transaction hash', Icons.confirmation_number_rounded),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                style: _body(color: _text),
                maxLines: 2,
                decoration: _inputDecoration('Notes', Icons.notes_rounded),
              ),
              if (status == 'failed') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: failureCtrl,
                  style: _body(color: _text),
                  decoration: _inputDecoration('Failure reason', Icons.error_rounded),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          Obx(
            () => FilledButton(
              onPressed: ctrl.actionLoading.value
                  ? null
                  : () async {
                      final ok = await ctrl.updateTransferStatus(
                        transfer,
                        status: status,
                        transactionHash: txCtrl.text,
                        notes: notesCtrl.text,
                        failureReason: failureCtrl.text,
                      );
                      if (ok && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
              child: Text(ctrl.actionLoading.value ? 'Updating...' : 'Update'),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showCancelDialog(
  BuildContext context,
  FundTransferController ctrl,
  FundTransfer transfer,
) async {
  final reasonCtrl = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: _surface,
      title: Text('Cancel Transfer', style: _title(18)),
      content: TextField(
        controller: reasonCtrl,
        style: _body(color: _text),
        decoration: _inputDecoration('Reason', Icons.cancel_rounded),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
        Obx(
          () => FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: ctrl.actionLoading.value
                ? null
                : () async {
                    final ok = await ctrl.cancelTransfer(transfer, reasonCtrl.text);
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
            child: Text(ctrl.actionLoading.value ? 'Cancelling...' : 'Cancel'),
          ),
        ),
      ],
    ),
  );
}

Future<void> _showReceiptDialog(
  BuildContext context,
  FundTransferController ctrl,
  FundTransfer transfer,
) async {
  final receipt = await ctrl.fetchReceipt(transfer);
  if (receipt == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: _surface,
      title: Text('Receipt ${receipt.receiptNumber}', style: _title(18)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailTile(label: 'Organization', value: receipt.organizationName, icon: Icons.business_rounded),
            _DetailTile(label: 'Amount', value: ctrl.formatCurrency(receipt.amount), icon: Icons.payments_rounded),
            _DetailTile(label: 'Method', value: receipt.method, icon: Icons.account_balance_rounded),
            _DetailTile(label: 'Status', value: receipt.status, icon: Icons.verified_rounded),
            _DetailTile(label: 'Reference', value: receipt.reference, icon: Icons.tag_rounded),
            _DetailTile(label: 'Transaction', value: receipt.transactionHash, icon: Icons.confirmation_number_rounded),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

BoxDecoration _box() {
  return BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: _border),
  );
}

InputDecoration _inputDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: _body(color: _muted),
    prefixIcon: Icon(icon, size: 18, color: _muted),
    filled: true,
    fillColor: _surface2,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _blue),
    ),
  );
}

TextStyle _title(double size) {
  return GoogleFonts.plusJakartaSans(
    color: _text,
    fontSize: size,
    fontWeight: FontWeight.w800,
  );
}

TextStyle _body({
  Color color = _text,
  double size = 13,
  FontWeight weight = FontWeight.w600,
}) {
  return GoogleFonts.dmSans(color: color, fontSize: size, fontWeight: weight);
}

TextStyle _mono({Color color = _text, double size = 12}) {
  return GoogleFonts.jetBrainsMono(
    color: color,
    fontSize: size,
    fontWeight: FontWeight.w700,
  );
}

Color _statusColor(String status) {
  switch (status) {
    case 'completed':
      return _green;
    case 'processing':
      return _blue;
    case 'failed':
      return _red;
    case 'cancelled':
      return _muted;
    default:
      return _amber;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'completed':
      return Icons.check_circle_rounded;
    case 'processing':
      return Icons.sync_rounded;
    case 'failed':
      return Icons.error_rounded;
    case 'cancelled':
      return Icons.cancel_rounded;
    default:
      return Icons.pending_actions_rounded;
  }
}
