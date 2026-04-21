import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/features/Commerce/controllers/cart_controller.dart';
import 'package:hope_link/features/Commerce/controllers/checkout_controller.dart';
import 'package:hope_link/features/Commerce/models/order_models.dart';

class CheckoutPage extends StatelessWidget {
  CheckoutPage({super.key});

  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());
  final CheckoutController checkoutController = Get.isRegistered<CheckoutController>()
      ? Get.find<CheckoutController>()
      : Get.put(CheckoutController());

  final NumberFormat currency = NumberFormat.currency(
    locale: 'en_NP',
    symbol: 'NPR ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF7),
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: Form(
        key: checkoutController.formKey,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SectionCard(
                title: 'Delivery details',
                child: Column(
                  children: [
                    _InputField(
                      controller: checkoutController.fullNameController,
                      label: 'Full name',
                    ),
                    _InputField(
                      controller: checkoutController.phoneController,
                      label: 'Phone number',
                      keyboardType: TextInputType.phone,
                    ),
                    _InputField(
                      controller: checkoutController.streetController,
                      label: 'Street address',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            controller: checkoutController.cityController,
                            label: 'City',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InputField(
                            controller: checkoutController.stateController,
                            label: 'State',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            controller: checkoutController.postalCodeController,
                            label: 'Postal code',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InputField(
                            controller: checkoutController.countryController,
                            label: 'Country',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Payment method',
                child: Column(
                  children: PurchasePaymentGateway.values
                      .map(
                        (gateway) => RadioListTile<PurchasePaymentGateway>(
                          value: gateway,
                          groupValue: checkoutController.selectedGateway.value,
                          activeColor: AppColorToken.primary.color,
                          contentPadding: EdgeInsets.zero,
                          title: Text(gateway.label),
                          subtitle: Text(
                            gateway == PurchasePaymentGateway.stripe
                                ? 'Card and wallet checkout via Stripe'
                                : 'Pay in Khalti and return to the app',
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              checkoutController.selectedGateway.value = value;
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Order summary',
                child: Column(
                  children: [
                    ...cartController.cart.value.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productNameSnapshot} x${item.quantity}',
                                style: AppTextStyle.bodyMedium,
                              ),
                            ),
                            Text(currency.format(item.lineTotal)),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: AppTextStyle.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          currency.format(cartController.subTotal),
                          style: AppTextStyle.h4.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColorToken.primary.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: checkoutController.isProcessing.value
                      ? null
                      : checkoutController.submitCheckout,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColorToken.primary.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: checkoutController.isProcessing.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.payments_outlined),
                  label: Text(
                    checkoutController.isProcessing.value
                        ? 'Processing payment...'
                        : 'Pay ${currency.format(cartController.subTotal)}',
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF7FBF8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
