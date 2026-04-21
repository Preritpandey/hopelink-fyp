import 'package:get/get.dart';
import 'package:hope_link/features/Commerce/models/order_models.dart';
import 'package:hope_link/features/Commerce/services/commerce_service.dart';
import 'package:hope_link/utils/helpers/snackbar_helper.dart';

class OrdersController extends GetxController {
  OrdersController({CommerceService? service})
      : _service = service ?? CommerceService();

  final CommerceService _service;

  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;
      error.value = '';
      orders.assignAll(await _service.getOrders());
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<OrderModel?> fetchOrder(String orderId) async {
    try {
      return await _service.getOrderDetails(orderId);
    } catch (e) {
      SnackbarHelper.showErrorSnackBar(
        'Order not available',
        e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final updated = await _service.cancelOrder(orderId);
      final index = orders.indexWhere((order) => order.id == orderId);
      if (index >= 0) {
        orders[index] = updated;
        orders.refresh();
      }
      SnackbarHelper.showSuccessSnackBar(
        'Order cancelled',
        'Inventory and payment status will be updated by the server.',
      );
    } catch (e) {
      SnackbarHelper.showErrorSnackBar(
        'Cancellation failed',
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
