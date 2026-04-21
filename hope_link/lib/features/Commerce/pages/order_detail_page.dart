import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/features/Commerce/controllers/orders_controller.dart';
import 'package:hope_link/features/Commerce/models/order_models.dart';

class OrderDetailPage extends StatelessWidget {
  OrderDetailPage({super.key});

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
    final orderId = Get.arguments?.toString() ?? '';
    return FutureBuilder<OrderModel?>(
      future: controller.fetchOrder(orderId),
      builder: (context, snapshot) {
        final order = snapshot.data;
        return Scaffold(
          backgroundColor: const Color(0xFFF6FBF7),
          appBar: AppBar(
            title: const Text('Order details'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : order == null
                  ? const Center(child: Text('Unable to load order.'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        _TimelineCard(order: order),
                        const SizedBox(height: 16),
                        _InfoCard(
                          title: 'Items',
                          child: Column(
                            children: order.items
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.productName} x${item.quantity}',
                                          ),
                                        ),
                                        Text(currency.format(item.totalPrice)),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InfoCard(
                          title: 'Shipping',
                          child: Text(
                            [
                              order.shippingAddress?.fullName,
                              order.shippingAddress?.phone,
                              order.shippingAddress?.street,
                              order.shippingAddress?.city,
                              order.shippingAddress?.state,
                              order.shippingAddress?.postalCode,
                              order.shippingAddress?.country,
                            ].whereType<String>().where((e) => e.isNotEmpty).join('\n'),
                            style: AppTextStyle.bodyMedium.copyWith(height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InfoCard(
                          title: 'Summary',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv('Transaction', order.transactionId),
                              _kv('Tracking number', order.trackingNumber ?? 'Not assigned'),
                              _kv('Payment', order.paymentStatus),
                              _kv('Status', order.status),
                              _kv('Total', currency.format(order.totalAmount)),
                            ],
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final OrderModel order;

  const _TimelineCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = ['pending', 'paid', 'confirmed', 'shipped', 'delivered'];
    final activeIndex = _resolveActiveIndex(order);

    return Container(
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
          Text(
            'Order tracking',
            style: AppTextStyle.h4.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final active = index <= activeIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColorToken.primary.color
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      active ? Icons.check : Icons.circle,
                      size: active ? 16 : 10,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    step.toUpperCase(),
                    style: AppTextStyle.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  int _resolveActiveIndex(OrderModel order) {
    if (order.status == 'delivered') return 4;
    if (order.status == 'shipped') return 3;
    if (order.status == 'confirmed') return 2;
    if (order.paymentStatus == 'paid') return 1;
    return 0;
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            title,
            style: AppTextStyle.h4.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
