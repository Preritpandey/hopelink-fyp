import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'package:hope_link/config/payment_config.dart';
import 'package:hope_link/core/services/payment_service.dart';
import 'package:hope_link/features/Commerce/controllers/cart_controller.dart';
import 'package:hope_link/features/Commerce/controllers/orders_controller.dart';
import 'package:hope_link/features/Commerce/models/order_models.dart';
import 'package:hope_link/features/Commerce/services/commerce_service.dart';
import 'package:hope_link/utils/helpers/snackbar_helper.dart';

class CheckoutController extends GetxController {
  CheckoutController({
    CommerceService? commerceService,
    PaymentService? paymentService,
  })  : _commerceService = commerceService ?? CommerceService(),
        _paymentService = paymentService ?? PaymentService();

  final CommerceService _commerceService;
  final PaymentService _paymentService;

  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final countryController = TextEditingController(text: 'Nepal');

  final Rx<PurchasePaymentGateway> selectedGateway =
      PurchasePaymentGateway.stripe.obs;
  final RxBool isProcessing = false.obs;

  CartController get _cartController =>
      Get.isRegistered<CartController>()
          ? Get.find<CartController>()
          : Get.put(CartController());

  OrdersController get _ordersController =>
      Get.isRegistered<OrdersController>()
          ? Get.find<OrdersController>()
          : Get.put(OrdersController());

  ShippingAddress buildAddress() {
    return ShippingAddress(
      fullName: fullNameController.text.trim(),
      phone: phoneController.text.trim(),
      street: streetController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      postalCode: postalCodeController.text.trim(),
      country: countryController.text.trim(),
    );
  }

  Future<void> submitCheckout() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!_cartController.hasItems) {
      SnackbarHelper.showErrorSnackBar(
        'Cart is empty',
        'Add a few products before checking out.',
      );
      return;
    }

    final context = Get.context;
    if (context == null) return;

    try {
      isProcessing.value = true;

      final checkoutResult = await _commerceService.checkout(
        shippingAddress: buildAddress(),
        paymentGateway: selectedGateway.value,
      );

      final amountInPaisa = (checkoutResult.totalAmount * 100).round();

      if (selectedGateway.value == PurchasePaymentGateway.stripe) {
        await _paymentService.processStripePayment(
          initializePayment: () => _commerceService.initializeStripeOrderPayment(
            amountInPaisa: amountInPaisa,
          ),
          verifyPayment: (paymentIntentId) {
            return _commerceService.verifyOrderPayment(
              gateway: PurchasePaymentGateway.stripe,
              transactionId: checkoutResult.transactionId,
              paymentIntentId: paymentIntentId,
            );
          },
        );
      } else {
        if (PaymentConfig.khaltiPublicKey == null ||
            PaymentConfig.khaltiPublicKey!.isEmpty) {
          await PaymentConfig.fetch();
        }
        final publicKey = PaymentConfig.khaltiPublicKey;
        if (publicKey == null || publicKey.isEmpty) {
          throw Exception('Khalti is not configured. Please contact support.');
        }

        await _paymentService.processKhaltiPayment(
          context: context,
          publicKey: publicKey,
          environment: _resolveKhaltiEnvironment(),
          initializePayment: () => _commerceService.initializeKhaltiOrderPayment(
            amountInPaisa: amountInPaisa,
            purchaseOrderId: checkoutResult.transactionId,
            purchaseOrderName:
                checkoutResult.orders.isNotEmpty &&
                        checkoutResult.orders.first.items.isNotEmpty
                    ? checkoutResult.orders.first.items.first.productName
                    : 'HopeLink order',
          ),
          onPaymentSuccess: (pidx) async {
            final verified = await _commerceService.verifyOrderPayment(
              gateway: PurchasePaymentGateway.khalti,
              transactionId: checkoutResult.transactionId,
              pidx: pidx,
            );
            if (!verified) {
              throw Exception('Khalti payment could not be verified.');
            }
          },
          confirmationTitle: 'Finalizing your order',
          confirmationMessage:
              'Your Khalti payment was received. We are updating the order and clearing your cart.',
        );
      }

      await _cartController.fetchCart();
      await _ordersController.fetchOrders();
      _showSuccessSheet(checkoutResult.totalAmount);
    } catch (e) {
      SnackbarHelper.showErrorSnackBar(
        'Checkout failed',
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isProcessing.value = false;
    }
  }

  Environment _resolveKhaltiEnvironment() {
    final env = PaymentConfig.khaltiEnvironment.toLowerCase();
    if (env == 'prod' || env == 'production' || env == 'live') {
      return Environment.prod;
    }
    return Environment.test;
  }

  void _showSuccessSheet(double totalAmount) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF27AE60),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order confirmed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Payment received for NPR ${totalAmount.toStringAsFixed(0)}. You can track status updates from your orders page.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Get.back();
                  Get.offNamed('/orders');
                },
                child: const Text('Track order'),
              ),
            ),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    countryController.dispose();
    super.onClose();
  }
}
