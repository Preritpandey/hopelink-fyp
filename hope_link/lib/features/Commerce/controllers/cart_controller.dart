import 'package:get/get.dart';
import 'package:hope_link/features/Commerce/models/cart_models.dart';
import 'package:hope_link/features/Commerce/services/commerce_service.dart';
import 'package:hope_link/utils/helpers/snackbar_helper.dart';

class CartController extends GetxController {
  CartController({CommerceService? service})
      : _service = service ?? CommerceService();

  final CommerceService _service;

  final Rx<CartModel> cart = CartModel.empty().obs;
  final RxBool isLoading = false.obs;
  final RxBool isMutating = false.obs;
  final RxString error = ''.obs;

  bool get hasItems => cart.value.items.isNotEmpty;
  int get itemCount => cart.value.itemCount;
  double get subTotal => cart.value.subTotal;

  @override
  void onInit() {
    super.onInit();
    fetchCart();
  }

  Future<void> fetchCart() async {
    try {
      isLoading.value = true;
      error.value = '';
      cart.value = await _service.getCart();
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToCart({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    try {
      isMutating.value = true;
      cart.value = await _service.addToCart(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );
      SnackbarHelper.showSuccessSnackBar(
        'Added to cart',
        'Your item is ready for checkout.',
      );
    } catch (e) {
      SnackbarHelper.showErrorSnackBar(
        'Could not add item',
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    try {
      isMutating.value = true;
      cart.value = await _service.updateCartItem(
        itemId: itemId,
        quantity: quantity,
      );
    } catch (e) {
      SnackbarHelper.showErrorSnackBar(
        'Update failed',
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      isMutating.value = true;
      cart.value = await _service.removeCartItem(itemId);
      SnackbarHelper.showSuccessSnackBar(
        'Item removed',
        'Your cart has been updated.',
      );
    } catch (e) {
      SnackbarHelper.showErrorSnackBar(
        'Remove failed',
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> clearCart() async {
    try {
      isMutating.value = true;
      cart.value = await _service.clearCart();
      SnackbarHelper.showSuccessSnackBar(
        'Cart cleared',
        'All items have been removed.',
      );
    } catch (e) {
      SnackbarHelper.showErrorSnackBar(
        'Clear cart failed',
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isMutating.value = false;
    }
  }
}
