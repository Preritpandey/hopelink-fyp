import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../Dashboard/widgets/dashboard_widgets.dart';
import '../controllers/org_commerce_controller.dart';
import '../models/org_commerce_models.dart';

class OrgCommercePage extends StatefulWidget {
  const OrgCommercePage({super.key});

  @override
  State<OrgCommercePage> createState() => _OrgCommercePageState();
}

class _OrgCommercePageState extends State<OrgCommercePage> {
  late final OrgCommerceController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(OrgCommerceController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Obx(() {
        if (ctrl.isBootstrapping.value) {
          return const Center(
            child: CircularProgressIndicator(color: kAccent),
          );
        }
        if (!ctrl.isAuthorized.value) {
          return Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded, color: kAmber, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Commerce access is limited to organization accounts.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            _CommerceHeader(
              ctrl: ctrl,
              onAddProduct: () => _openProductEditor(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryGrid(ctrl: ctrl),
                    const SizedBox(height: 24),
                    _TabSwitcher(ctrl: ctrl),
                    const SizedBox(height: 20),
                    if (ctrl.activeTab.value == CommerceTab.orders)
                      _OrdersSection(
                        ctrl: ctrl,
                        onConfirm: _confirmOrder,
                        onDeliver: _deliverOrder,
                        onCancel: _cancelOrder,
                      )
                    else
                      _ProductsSection(
                        ctrl: ctrl,
                        onCreate: () => _openProductEditor(context),
                        onEdit: (product) => _openProductEditor(context, product: product),
                        onArchive: _archiveProduct,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmOrder(OrgOrder order) async {
    final confirmed = await _showDecisionDialog(
      title: 'Confirm Order',
      message: 'Ready to confirm and prepare this order for shipment?',
      confirmLabel: 'Confirm Order',
    );
    if (confirmed == true) {
      await ctrl.updateOrderStatus(order, 'confirmed');
    }
  }

  Future<void> _deliverOrder(OrgOrder order) async {
    final trackingCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mark As Delivered', style: GoogleFonts.dmSans(color: Colors.white)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(controller: trackingCtrl, label: 'Tracking Number (optional)'),
              const SizedBox(height: 12),
              _DialogField(
                controller: notesCtrl,
                label: 'Delivery Notes (optional)',
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mark Delivered'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ctrl.updateOrderStatus(
        order,
        'delivered',
        trackingNumber: trackingCtrl.text,
        note: notesCtrl.text,
      );
    }
  }

  Future<void> _cancelOrder(OrgOrder order) async {
    String selectedReason = 'Customer request';
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: kSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Cancel Order', style: GoogleFonts.dmSans(color: Colors.white)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will restore inventory. Continue?',
                  style: GoogleFonts.dmSans(color: kTextSub),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  dropdownColor: kSurface2,
                  decoration: _inputDecoration('Cancellation Reason'),
                  items: const [
                    DropdownMenuItem(value: 'Customer request', child: Text('Customer request')),
                    DropdownMenuItem(value: 'Out of stock', child: Text('Out of stock')),
                    DropdownMenuItem(value: 'Shipping issue', child: Text('Shipping issue')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => selectedReason = value ?? selectedReason),
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: notesCtrl,
                  label: 'Notes (optional)',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Order'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: kRed),
              child: const Text('Cancel Order'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      final reason = notesCtrl.text.trim().isEmpty
          ? selectedReason
          : '$selectedReason: ${notesCtrl.text.trim()}';
      await ctrl.updateOrderStatus(order, 'cancelled', cancellationReason: reason);
    }
  }

  Future<void> _archiveProduct(OrgProduct product) async {
    final confirmed = await _showDecisionDialog(
      title: 'Archive Product',
      message:
          'This product will be archived instead of permanently deleted. Existing order history will remain intact.',
      confirmLabel: 'Archive',
      destructive: true,
    );
    if (confirmed == true) {
      await ctrl.archiveProduct(product);
    }
  }

  Future<void> _openProductEditor(
    BuildContext context, {
    OrgProduct? product,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: _ProductEditorDialog(ctrl: ctrl, product: product),
      ),
    );
  }

  Future<bool?> _showDecisionDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.dmSans(color: Colors.white)),
        content: Text(message, style: GoogleFonts.dmSans(color: kTextSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? kRed : kAccent,
              foregroundColor: destructive ? Colors.white : Colors.black,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _CommerceHeader extends StatelessWidget {
  const _CommerceHeader({
    required this.ctrl,
    required this.onAddProduct,
  });

  final OrgCommerceController ctrl;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Commerce', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                '${ctrl.orgName} orders, products, inventory, and sales insights',
                style: GoogleFonts.dmSans(fontSize: 13, color: kTextSub),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: ctrl.refreshAll,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onAddProduct,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Post Product'),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.ctrl});

  final OrgCommerceController ctrl;

  @override
  Widget build(BuildContext context) {
    final summary = ctrl.salesSummary.value;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.55,
      children: [
        StatCard(
          label: 'Total Revenue',
          value: _currency(summary.totalRevenue),
          icon: Icons.payments_rounded,
          accent: kAccent,
        ),
        StatCard(
          label: 'Total Orders',
          value: '${summary.totalOrders}',
          icon: Icons.receipt_long_rounded,
          accent: kAccent2,
        ),
        StatCard(
          label: 'Paid vs Pending',
          value: '${summary.paidOrders}/${summary.pendingPaymentOrders}',
          sub: 'paid/pending',
          icon: Icons.verified_rounded,
          accent: kAmber,
        ),
        StatCard(
          label: 'Cancelled Orders',
          value: '${summary.cancelledOrders}',
          icon: Icons.cancel_outlined,
          accent: kRed,
        ),
      ],
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.ctrl});

  final OrgCommerceController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          _TabChip(
            label: 'Orders',
            active: ctrl.activeTab.value == CommerceTab.orders,
            onTap: () => ctrl.setTab(CommerceTab.orders),
          ),
          const SizedBox(width: 10),
          _TabChip(
            label: 'Products',
            active: ctrl.activeTab.value == CommerceTab.products,
            onTap: () => ctrl.setTab(CommerceTab.products),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? kAccent.withOpacity(0.15) : kSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active ? kAccent : kBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: active ? kAccent : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OrdersSection extends StatelessWidget {
  const _OrdersSection({
    required this.ctrl,
    required this.onConfirm,
    required this.onDeliver,
    required this.onCancel,
  });

  final OrgCommerceController ctrl;
  final Future<void> Function(OrgOrder order) onConfirm;
  final Future<void> Function(OrgOrder order) onDeliver;
  final Future<void> Function(OrgOrder order) onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _OrdersFilters(ctrl: ctrl),
              const SizedBox(height: 16),
              _OrdersTable(
                ctrl: ctrl,
                onConfirm: onConfirm,
                onDeliver: onDeliver,
                onCancel: onCancel,
              ),
            ],
          ),
        ),
        if (ctrl.selectedOrder.value != null) ...[
          const SizedBox(width: 18),
          SizedBox(
            width: 380,
            child: _OrderDetailsPanel(
              ctrl: ctrl,
              order: ctrl.selectedOrder.value!,
              onConfirm: onConfirm,
              onDeliver: onDeliver,
              onCancel: onCancel,
            ),
          ),
        ],
      ],
    );
  }
}

class _OrdersFilters extends StatelessWidget {
  const _OrdersFilters({required this.ctrl});

  final OrgCommerceController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Obx(
        () => Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 250,
              child: TextField(
                controller: ctrl.orderSearchCtrl,
                style: GoogleFonts.dmSans(color: Colors.white),
                decoration: _inputDecoration('Search order ID or customer')
                    .copyWith(prefixIcon: const Icon(Icons.search_rounded)),
              ),
            ),
            _DropdownFilter(
              value: ctrl.orderStatusFilter.value,
              label: 'Status',
              items: const ['all', 'pending', 'confirmed', 'delivered', 'cancelled'],
              onChanged: (value) {
                ctrl.orderStatusFilter.value = value;
                ctrl.ordersPage.value = 1;
              },
            ),
            _DropdownFilter(
              value: ctrl.paymentStatusFilter.value,
              label: 'Payment',
              items: const ['all', 'paid', 'pending', 'failed'],
              onChanged: (value) {
                ctrl.paymentStatusFilter.value = value;
                ctrl.ordersPage.value = 1;
              },
            ),
            OutlinedButton.icon(
              onPressed: () => ctrl.pickDateRange(context, isFrom: true),
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label: Text(
                ctrl.orderDateFrom.value == null
                    ? 'From date'
                    : DateFormat('MMM dd, yyyy').format(ctrl.orderDateFrom.value!),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => ctrl.pickDateRange(context, isFrom: false),
              icon: const Icon(Icons.calendar_month_rounded, size: 16),
              label: Text(
                ctrl.orderDateTo.value == null
                    ? 'To date'
                    : DateFormat('MMM dd, yyyy').format(ctrl.orderDateTo.value!),
              ),
            ),
            TextButton.icon(
              onPressed: ctrl.clearOrderFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  const _OrdersTable({
    required this.ctrl,
    required this.onConfirm,
    required this.onDeliver,
    required this.onCancel,
  });

  final OrgCommerceController ctrl;
  final Future<void> Function(OrgOrder order) onConfirm;
  final Future<void> Function(OrgOrder order) onDeliver;
  final Future<void> Function(OrgOrder order) onCancel;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = ctrl.pagedOrders;
      return Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                children: [
                  Text(
                    'Organization Orders',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${ctrl.filteredOrders.length} results',
                    style: GoogleFonts.dmMono(fontSize: 11, color: kTextSub),
                  ),
                ],
              ),
            ),
            if (ctrl.isLoadingOrders.value && ctrl.orders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: kAccent),
              )
            else if (orders.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  ctrl.orderError.value.isEmpty
                      ? 'No orders match the current filters.'
                      : ctrl.orderError.value,
                  style: GoogleFonts.dmSans(color: kTextSub),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 22,
                  headingTextStyle: GoogleFonts.dmSans(
                    color: kTextSub,
                    fontWeight: FontWeight.w700,
                  ),
                  dataTextStyle: GoogleFonts.dmSans(color: Colors.white),
                  columns: const [
                    DataColumn(label: Text('Order ID')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Payment')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Created')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: orders.map((order) {
                    return DataRow(
                      cells: [
                        DataCell(Text(_shortId(order.id))),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(order.customerName),
                              Text(
                                order.customerEmail,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: kTextSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(_currency(order.totalAmount))),
                        DataCell(_StatusPill(order.paymentStatus, _paymentColor(order.paymentStatus))),
                        DataCell(_StatusPill(order.status, _orderColor(order.status))),
                        DataCell(Text(_formatDate(order.createdAt))),
                        DataCell(
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => ctrl.fetchOrderDetails(order.id),
                                child: const Text('View'),
                              ),
                              if (ctrl.canConfirm(order))
                                TextButton(
                                  onPressed: () => onConfirm(order),
                                  child: const Text('Confirm'),
                                ),
                              if (ctrl.canDeliver(order))
                                TextButton(
                                  onPressed: () => onDeliver(order),
                                  child: const Text('Deliver'),
                                ),
                              if (ctrl.canCancel(order))
                                TextButton(
                                  onPressed: () => onCancel(order),
                                  style: TextButton.styleFrom(foregroundColor: kRed),
                                  child: const Text('Cancel'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            _PaginationBar(
              page: ctrl.ordersPage.value,
              totalPages: ctrl.ordersTotalPages,
              onPrevious: ctrl.previousOrdersPage,
              onNext: ctrl.nextOrdersPage,
            ),
          ],
        ),
      );
    });
  }
}

class _OrderDetailsPanel extends StatelessWidget {
  const _OrderDetailsPanel({
    required this.ctrl,
    required this.order,
    required this.onConfirm,
    required this.onDeliver,
    required this.onCancel,
  });

  final OrgCommerceController ctrl;
  final OrgOrder order;
  final Future<void> Function(OrgOrder order) onConfirm;
  final Future<void> Function(OrgOrder order) onDeliver;
  final Future<void> Function(OrgOrder order) onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Order Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => ctrl.selectedOrder.value = null,
                icon: const Icon(Icons.close_rounded, color: kTextSub),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DetailBlock(
            title: 'Customer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customerName, style: _bodyWhite()),
                const SizedBox(height: 4),
                Text(order.customerEmail, style: _bodySub()),
              ],
            ),
          ),
          _DetailBlock(
            title: 'Shipping Address',
            child: Text(
              [
                order.shippingAddress['street'],
                order.shippingAddress['city'],
                order.shippingAddress['state'],
                order.shippingAddress['country'],
              ].whereType<String>().where((item) => item.trim().isNotEmpty).join(', '),
              style: _bodySub(),
            ),
          ),
          _DetailBlock(
            title: 'Payment',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gateway: ${order.paymentGateway}', style: _bodySub()),
                const SizedBox(height: 4),
                Text('Reference: ${order.paymentReference.isEmpty ? 'N/A' : order.paymentReference}', style: _bodySub()),
              ],
            ),
          ),
          _DetailBlock(
            title: 'Items',
            child: Column(
              children: order.items.map((item) {
                final variants = item.variantAttributes.entries
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join(', ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: _bodyWhite()),
                            if (variants.isNotEmpty)
                              Text(variants, style: _bodySub()),
                            Text('Qty ${item.quantity} • ${_currency(item.price)}', style: _bodySub()),
                          ],
                        ),
                      ),
                      Text(_currency(item.totalPrice), style: _bodyWhite()),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          _DetailBlock(
            title: 'Totals',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subtotal: ${_currency(order.subTotal)}', style: _bodySub()),
                Text('Shipping: ${_currency(order.shippingFee)}', style: _bodySub()),
                const SizedBox(height: 4),
                Text('Total: ${_currency(order.totalAmount)}', style: _bodyWhite()),
              ],
            ),
          ),
          _DetailBlock(
            title: 'Timeline',
            child: Column(
              children: order.statusHistory.isEmpty
                  ? [Text('No status history yet.', style: _bodySub())]
                  : order.statusHistory.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: _orderColor(entry.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.status} • ${entry.changedByRole}',
                                    style: _bodyWhite(),
                                  ),
                                  Text(_formatDateTime(entry.changedAt), style: _bodySub()),
                                  if (entry.note.isNotEmpty) Text(entry.note, style: _bodySub()),
                                  if (entry.reason.isNotEmpty) Text(entry.reason, style: _bodySub()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (ctrl.canConfirm(order))
                FilledButton(
                  onPressed: ctrl.isUpdatingOrder.value ? null : () => onConfirm(order),
                  child: const Text('Confirm'),
                ),
              if (ctrl.canDeliver(order))
                FilledButton(
                  onPressed: ctrl.isUpdatingOrder.value ? null : () => onDeliver(order),
                  child: const Text('Mark Delivered'),
                ),
              if (ctrl.canCancel(order))
                OutlinedButton(
                  onPressed: ctrl.isUpdatingOrder.value ? null : () => onCancel(order),
                  child: const Text('Cancel Order'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductsSection extends StatelessWidget {
  const _ProductsSection({
    required this.ctrl,
    required this.onCreate,
    required this.onEdit,
    required this.onArchive,
  });

  final OrgCommerceController ctrl;
  final VoidCallback onCreate;
  final Future<void> Function(OrgProduct product) onEdit;
  final Future<void> Function(OrgProduct product) onArchive;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _ProductsToolbar(ctrl: ctrl, onCreate: onCreate),
              const SizedBox(height: 16),
              _ProductsTable(ctrl: ctrl, onEdit: onEdit, onArchive: onArchive),
            ],
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 360,
          child: _ProductInsights(ctrl: ctrl),
        ),
      ],
    );
  }
}

class _ProductsToolbar extends StatelessWidget {
  const _ProductsToolbar({required this.ctrl, required this.onCreate});

  final OrgCommerceController ctrl;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Obx(
        () => Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: ctrl.productSearchCtrl,
                style: GoogleFonts.dmSans(color: Colors.white),
                decoration: _inputDecoration('Search products')
                    .copyWith(prefixIcon: const Icon(Icons.search_rounded)),
              ),
            ),
            _DropdownFilter(
              value: ctrl.productStatusFilter.value,
              label: 'Product Status',
              items: const ['all', 'active', 'inactive', 'low-stock'],
              onChanged: (value) {
                ctrl.productStatusFilter.value = value;
                ctrl.productsPage.value = 1;
              },
            ),
            TextButton.icon(
              onPressed: ctrl.clearProductFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Clear'),
            ),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Product'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({
    required this.ctrl,
    required this.onEdit,
    required this.onArchive,
  });

  final OrgCommerceController ctrl;
  final Future<void> Function(OrgProduct product) onEdit;
  final Future<void> Function(OrgProduct product) onArchive;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final products = ctrl.pagedProducts;
      return Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                children: [
                  Text(
                    'Products & Inventory',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${ctrl.filteredProducts.length} products',
                    style: GoogleFonts.dmMono(fontSize: 11, color: kTextSub),
                  ),
                ],
              ),
            ),
            if (ctrl.isLoadingProducts.value && ctrl.products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: kAccent),
              )
            else if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  ctrl.productError.value.isEmpty
                      ? 'No products match the current filters.'
                      : ctrl.productError.value,
                  style: GoogleFonts.dmSans(color: kTextSub),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 18,
                  headingTextStyle: GoogleFonts.dmSans(
                    color: kTextSub,
                    fontWeight: FontWeight.w700,
                  ),
                  dataTextStyle: GoogleFonts.dmSans(color: Colors.white),
                  columns: const [
                    DataColumn(label: Text('Image')),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: products.map((product) {
                    return DataRow(cells: [
                      DataCell(_ProductThumb(url: product.images.isEmpty ? '' : product.images.first)),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(product.name),
                            if (product.sku.isNotEmpty)
                              Text(product.sku, style: GoogleFonts.dmMono(fontSize: 11, color: kTextSub)),
                          ],
                        ),
                      ),
                      DataCell(Text(product.categoryName)),
                      DataCell(Text(_currency(product.price))),
                      DataCell(
                        _StatusPill(
                          '${product.stock}',
                          product.isOutOfStock
                              ? kRed
                              : product.isLowStock
                                  ? kAmber
                                  : kAccent,
                        ),
                      ),
                      DataCell(
                        _StatusPill(product.isActive ? 'active' : 'inactive', product.isActive ? kAccent2 : kTextSub),
                      ),
                      DataCell(
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () {
                                ctrl.selectedProduct.value = product;
                                _showProductDetails(context, product);
                              },
                              child: const Text('View'),
                            ),
                            TextButton(
                              onPressed: () => onEdit(product),
                              child: const Text('Edit'),
                            ),
                            TextButton(
                              onPressed: () => onArchive(product),
                              style: TextButton.styleFrom(foregroundColor: kRed),
                              child: const Text('Archive'),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            _PaginationBar(
              page: ctrl.productsPage.value,
              totalPages: ctrl.productsTotalPages,
              onPrevious: ctrl.previousProductsPage,
              onNext: ctrl.nextProductsPage,
            ),
          ],
        ),
      );
    });
  }

  Future<void> _showProductDetails(BuildContext context, OrgProduct product) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(product.name, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.images.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.images.first,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(180),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(product.description, style: GoogleFonts.dmSans(color: kTextSub, height: 1.5)),
                const SizedBox(height: 16),
                Text('Stock history', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (product.stockHistory.isEmpty)
                  Text('No stock history recorded.', style: GoogleFonts.dmSans(color: kTextSub))
                else
                  ...product.stockHistory.take(8).map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${_formatDateTime(entry.changedAt)} • ${entry.previousStock} -> ${entry.newStock} • ${entry.note.isEmpty ? entry.source : entry.note}',
                            style: GoogleFonts.dmSans(color: kTextSub, fontSize: 12),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ProductInsights extends StatelessWidget {
  const _ProductInsights({required this.ctrl});

  final OrgCommerceController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top Selling Products', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 14),
              Obx(
                () => Column(
                  children: ctrl.topSellingProducts.isEmpty
                      ? [
                          Text('Sales data will appear here once orders are paid.', style: GoogleFonts.dmSans(color: kTextSub))
                        ]
                      : ctrl.topSellingProducts.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                _ProductThumb(url: item.image),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
                                      Text('${item.unitsSold} sold • ${_currency(item.revenue)}', style: GoogleFonts.dmSans(color: kTextSub, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Low Stock Alerts', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 14),
              Obx(
                () => Column(
                  children: ctrl.lowStockProducts.isEmpty
                      ? [
                          Text('Inventory looks healthy right now.', style: GoogleFonts.dmSans(color: kTextSub))
                        ]
                      : ctrl.lowStockProducts.take(6).map((product) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.name, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
                                      Text('Current stock: ${product.stock}', style: GoogleFonts.dmSans(color: kTextSub, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                _StatusPill(
                                  product.isOutOfStock ? 'out' : 'low',
                                  product.isOutOfStock ? kRed : kAmber,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductEditorDialog extends StatefulWidget {
  const _ProductEditorDialog({
    required this.ctrl,
    this.product,
  });

  final OrgCommerceController ctrl;
  final OrgProduct? product;

  @override
  State<_ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<_ProductEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _stockNoteCtrl;
  String _categoryId = '';
  bool _isActive = true;
  bool _slugEdited = false;
  bool _syncingSlug = false;
  final List<PlatformFile> _newImages = [];
  final List<String> _retainedImages = [];
  late List<ProductVariantDraft> _variants;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameCtrl = TextEditingController(text: product?.name ?? '');
    _slugCtrl = TextEditingController(text: product?.slug ?? '');
    _descriptionCtrl = TextEditingController(text: product?.description ?? '');
    _priceCtrl = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(2),
    );
    _stockCtrl = TextEditingController(text: product?.stock.toString() ?? '');
    _skuCtrl = TextEditingController(text: product?.sku ?? '');
    _stockNoteCtrl = TextEditingController();
    _categoryId = product?.categoryId ?? (widget.ctrl.categories.isNotEmpty ? widget.ctrl.categories.first.id : '');
    _isActive = product?.isActive ?? true;
    _retainedImages.addAll(product?.images ?? const []);
    _variants = product?.variants
            .map(
              (variant) => ProductVariantDraft(
                id: variant.id,
                attributeName: variant.attributes.entries.isEmpty ? '' : variant.attributes.entries.first.key,
                optionValue: variant.attributes.entries.isEmpty ? '' : variant.attributes.entries.first.value,
                priceAdjustment: variant.price - (product?.price ?? 0),
                stock: variant.stock,
                sku: variant.sku,
                isActive: variant.isActive,
                isDeleted: variant.isDeleted,
              ),
            )
            .toList() ??
        [];

    _nameCtrl.addListener(() {
      if (!_slugEdited) {
        _syncingSlug = true;
        _slugCtrl.text = widget.ctrl.generateSlug(_nameCtrl.text);
        _syncingSlug = false;
      }
    });
    _slugCtrl.addListener(() {
      if (!_syncingSlug) {
        _slugEdited = true;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _skuCtrl.dispose();
    _stockNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 980,
      constraints: const BoxConstraints(maxHeight: 760),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Product' : 'Post New Product',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage listing details, inventory, images, and variants.',
                      style: GoogleFonts.dmSans(color: kTextSub),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.ctrl.isSavingProduct.value
                    ? null
                    : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: kTextSub),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _DialogField(
                                      controller: _nameCtrl,
                                      label: 'Product Name',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _DialogField(
                                      controller: _slugCtrl,
                                      label: 'Slug',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _DialogField(
                                controller: _descriptionCtrl,
                                label: 'Description',
                                maxLines: 5,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: widget.ctrl.categories.any((item) => item.id == _categoryId)
                                          ? _categoryId
                                          : null,
                                      dropdownColor: kSurface2,
                                      decoration: _inputDecoration('Category'),
                                      items: widget.ctrl.categories
                                          .map(
                                            (category) => DropdownMenuItem(
                                              value: category.id,
                                              child: Text(category.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) => setState(() => _categoryId = value ?? ''),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _DialogField(
                                      controller: _skuCtrl,
                                      label: 'SKU (optional)',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _DialogField(
                                      controller: _priceCtrl,
                                      label: 'Base Price',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _DialogField(
                                      controller: _stockCtrl,
                                      label: 'Stock Quantity',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _DialogField(
                                controller: _stockNoteCtrl,
                                label: 'Stock Note (optional)',
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                value: _isActive,
                                activeColor: kAccent,
                                contentPadding: EdgeInsets.zero,
                                title: Text('Product is active', style: GoogleFonts.dmSans(color: Colors.white)),
                                subtitle: Text('Inactive products remain visible in the admin panel only.', style: GoogleFonts.dmSans(color: kTextSub, fontSize: 12)),
                                onChanged: (value) => setState(() => _isActive = value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 2,
                          child: _ImagePickerCard(
                            retainedImages: _retainedImages,
                            newImages: _newImages,
                            onRemoveRetained: (index) => setState(() => _retainedImages.removeAt(index)),
                            onRemoveNew: (index) => setState(() => _newImages.removeAt(index)),
                            onAddImages: _pickImages,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _VariantEditor(
                      basePrice: double.tryParse(_priceCtrl.text) ?? 0,
                      variants: _variants,
                      onChanged: (variants) => setState(() => _variants = variants),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Row(
              children: [
                Text(
                  widget.ctrl.isSavingProduct.value ? 'Saving...' : '',
                  style: GoogleFonts.dmSans(color: kTextSub),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.ctrl.isSavingProduct.value
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: widget.ctrl.isSavingProduct.value ? null : _submit,
                  child: Text(_isEditing ? 'Update Product' : 'Create Product'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final remaining = 5 - (_retainedImages.length + _newImages.length);
    if (remaining <= 0) {
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result != null) {
      final files = result.files.take(remaining);
      setState(() => _newImages.addAll(files));
    }
  }

  Future<void> _submit() async {
    final validation = widget.ctrl.validateProductInput(
      name: _nameCtrl.text,
      slug: _slugCtrl.text,
      description: _descriptionCtrl.text,
      categoryId: _categoryId,
      price: _priceCtrl.text,
      stock: _stockCtrl.text,
      retainedImages: _retainedImages,
      newImages: _newImages,
      sku: _skuCtrl.text,
      variants: _variants,
      existing: widget.product,
    );
    if (validation.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation), backgroundColor: kRed),
      );
      return;
    }

    final ok = await widget.ctrl.saveProduct(
      existing: widget.product,
      name: _nameCtrl.text,
      slug: _slugCtrl.text,
      description: _descriptionCtrl.text,
      categoryId: _categoryId,
      price: double.parse(_priceCtrl.text),
      stock: int.parse(_stockCtrl.text),
      isActive: _isActive,
      sku: _skuCtrl.text,
      retainedImages: _retainedImages,
      newImages: _newImages,
      variants: _variants,
      stockNote: _stockNoteCtrl.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.retainedImages,
    required this.newImages,
    required this.onRemoveRetained,
    required this.onRemoveNew,
    required this.onAddImages,
  });

  final List<String> retainedImages;
  final List<PlatformFile> newImages;
  final void Function(int index) onRemoveRetained;
  final void Function(int index) onRemoveNew;
  final VoidCallback onAddImages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Images', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Upload between 1 and 5 images.', style: GoogleFonts.dmSans(color: kTextSub, fontSize: 12)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAddImages,
            icon: const Icon(Icons.file_upload_outlined, size: 18),
            label: const Text('Select Images'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < retainedImages.length; i++)
                _ImageChip(url: retainedImages[i], onRemove: () => onRemoveRetained(i)),
              for (var i = 0; i < newImages.length; i++)
                _ImageChip(
                  label: newImages[i].name,
                  onRemove: () => onRemoveNew(i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageChip extends StatelessWidget {
  const _ImageChip({this.url = '', this.label = '', required this.onRemove});

  final String url;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: url.isNotEmpty
                ? Image.network(
                    url,
                    height: 70,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(70),
                  )
                : _imagePlaceholder(70),
          ),
          const SizedBox(height: 8),
          Text(
            label.isEmpty ? 'Uploaded image' : label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(color: kTextSub, fontSize: 11),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _VariantEditor extends StatelessWidget {
  const _VariantEditor({
    required this.basePrice,
    required this.variants,
    required this.onChanged,
  });

  final double basePrice;
  final List<ProductVariantDraft> variants;
  final ValueChanged<List<ProductVariantDraft>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Variants', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => onChanged([...variants, ProductVariantDraft()]),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Variant'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (variants.isEmpty)
            Text('Add size, color, or similar options if this product needs variants.', style: GoogleFonts.dmSans(color: kTextSub))
          else
            ...List.generate(variants.length, (index) {
              final variant = variants[index];
              final attrCtrl = TextEditingController(text: variant.attributeName);
              final optionCtrl = TextEditingController(text: variant.optionValue);
              final adjustmentCtrl =
                  TextEditingController(text: variant.priceAdjustment.toString());
              final stockCtrl = TextEditingController(text: variant.stock.toString());
              final skuCtrl = TextEditingController(text: variant.sku);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _DialogField(controller: attrCtrl, label: 'Variant Name')),
                          const SizedBox(width: 10),
                          Expanded(child: _DialogField(controller: optionCtrl, label: 'Option Value')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _DialogField(controller: adjustmentCtrl, label: 'Price Adjustment', keyboardType: TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(child: _DialogField(controller: stockCtrl, label: 'Variant Stock', keyboardType: TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(child: _DialogField(controller: skuCtrl, label: 'Variant SKU')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Final price: ${_currency(basePrice + (double.tryParse(adjustmentCtrl.text) ?? 0))}',
                            style: GoogleFonts.dmSans(color: kTextSub, fontSize: 12),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              final next = [...variants]..removeAt(index);
                              onChanged(next);
                            },
                            style: TextButton.styleFrom(foregroundColor: kRed),
                            child: const Text('Remove'),
                          ),
                          FilledButton(
                            onPressed: () {
                              final next = [...variants];
                              next[index] = variant.copyWith(
                                attributeName: attrCtrl.text,
                                optionValue: optionCtrl.text,
                                priceAdjustment: double.tryParse(adjustmentCtrl.text) ?? 0,
                                stock: int.tryParse(stockCtrl.text) ?? 0,
                                sku: skuCtrl.text,
                              );
                              onChanged(next);
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  const _DropdownFilter({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final String label;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: kSurface2,
        decoration: _inputDecoration(label),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: (selected) => onChanged(selected ?? value),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: Row(
        children: [
          Text('Page $page of $totalPages', style: GoogleFonts.dmSans(color: kTextSub)),
          const Spacer(),
          OutlinedButton(onPressed: page <= 1 ? null : onPrevious, child: const Text('Previous')),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: page >= totalPages ? null : onNext, child: const Text('Next')),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmMono(fontSize: 11, color: color),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url.isEmpty
          ? _imagePlaceholder(44, width: 44)
          : Image.network(
              url,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(44, width: 44),
            ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.dmSans(color: kTextSub),
    filled: true,
    fillColor: kSurface2,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kAccent),
    ),
  );
}

TextStyle _bodyWhite() => GoogleFonts.dmSans(color: Colors.white, fontSize: 13);
TextStyle _bodySub() => GoogleFonts.dmSans(color: kTextSub, fontSize: 12);

Color _paymentColor(String value) {
  switch (value) {
    case 'paid':
      return kAccent;
    case 'pending':
      return kAmber;
    case 'failed':
      return kRed;
    default:
      return kTextSub;
  }
}

Color _orderColor(String value) {
  switch (value) {
    case 'pending':
      return kAmber;
    case 'confirmed':
      return kAccent2;
    case 'delivered':
      return kAccent;
    case 'cancelled':
      return kRed;
    default:
      return kTextSub;
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return 'N/A';
  return DateFormat('MMM dd, yyyy').format(value);
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'N/A';
  return DateFormat('MMM dd, yyyy • hh:mm a').format(value);
}

String _shortId(String value) => value.length <= 8 ? value : value.substring(0, 8);

String _currency(double amount) => 'NPR ${amount.toStringAsFixed(2)}';

Widget _imagePlaceholder(double height, {double width = double.infinity}) {
  return Container(
    width: width,
    height: height,
    color: kSurface2,
    alignment: Alignment.center,
    child: const Icon(Icons.image_outlined, color: kTextSub),
  );
}
