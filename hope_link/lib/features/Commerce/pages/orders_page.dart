import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/features/Commerce/controllers/orders_controller.dart';
import 'package:hope_link/features/Commerce/models/order_models.dart';

class OrdersPage extends StatelessWidget {
  OrdersPage({super.key});

  final OrdersController controller = Get.isRegistered<OrdersController>()
      ? Get.find<OrdersController>()
      : Get.put(OrdersController());

  final NumberFormat currency = NumberFormat.currency(
    locale: 'en_NP',
    symbol: 'NPR ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: const Text('My orders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                controller.error.value.isNotEmpty
                    ? controller.error.value
                    : 'No orders yet. When you complete checkout, your purchases will show up here.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchOrders,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemBuilder: (context, index) {
              final order = controller.orders[index];
              return _OrderCard(
                order: order,
                currency: currency,
                onTap: () => Get.toNamed('/orders/details', arguments: order.id),
                onCancel: order.status == 'pending'
                    ? () => controller.cancelOrder(order.id)
                    : null,
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemCount: controller.orders.length,
          ),
        );
      }),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _OrderCard({
    required this.order,
    required this.currency,
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusPill(label: order.status),
                const Spacer(),
                _StatusPill(
                  label: order.paymentStatus,
                  color: order.paymentStatus == 'paid'
                      ? const Color(0xFF27AE60)
                      : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              order.items.map((item) => item.productName).join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              order.organizationName.isNotEmpty
                  ? order.organizationName
                  : 'HopeLink marketplace',
              style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    currency.format(order.totalAmount),
                    style: AppTextStyle.h4.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColorToken.primary.color,
                    ),
                  ),
                ),
                if (onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color? color;

  const _StatusPill({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final tone = color ?? _statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: tone,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF27AE60);
      case 'confirmed':
      case 'shipped':
        return const Color(0xFF2D9CDB);
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }
}
