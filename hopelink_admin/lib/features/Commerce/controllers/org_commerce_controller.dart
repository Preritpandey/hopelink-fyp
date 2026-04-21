import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_endpoints.dart';
import '../models/org_commerce_models.dart';

enum CommerceTab { orders, products }

class OrgCommerceController extends GetxController {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';
  static const _orgIdKey = 'org_id';
  static const _orgNameKey = 'org_name';

  final activeTab = CommerceTab.orders.obs;

  final isAuthorized = false.obs;
  final isBootstrapping = true.obs;

  final isLoadingOrders = false.obs;
  final isLoadingOrderDetails = false.obs;
  final isUpdatingOrder = false.obs;
  final isLoadingProducts = false.obs;
  final isSavingProduct = false.obs;
  final isLoadingAnalytics = false.obs;

  final orders = <OrgOrder>[].obs;
  final products = <OrgProduct>[].obs;
  final categories = <OrgCategory>[].obs;
  final productSales = <OrgProductSalesSummary>[].obs;
  final salesSummary = OrgSalesSummary.empty().obs;

  final selectedOrder = Rxn<OrgOrder>();
  final selectedProduct = Rxn<OrgProduct>();

  final orderError = ''.obs;
  final productError = ''.obs;
  final analyticsError = ''.obs;

  final orderSearchCtrl = TextEditingController();
  final productSearchCtrl = TextEditingController();

  final orderStatusFilter = 'all'.obs;
  final paymentStatusFilter = 'all'.obs;
  final productStatusFilter = 'all'.obs;

  final ordersPage = 1.obs;
  final productsPage = 1.obs;

  final orderDateFrom = Rxn<DateTime>();
  final orderDateTo = Rxn<DateTime>();

  String _token = '';
  String _role = '';
  String _orgId = '';
  String _orgName = 'Organization';
  Timer? _pollTimer;

  Set<String> _knownOrderIds = <String>{};
  Set<String> _knownPaidOrderIds = <String>{};
  Set<String> _knownLowStockIds = <String>{};
  bool _notificationsPrimed = false;

  static const int ordersPerPage = 10;
  static const int productsPerPage = 8;

  String get orgName => _orgName;

  bool get canManageCommerce => _role == 'organization' || _role == 'admin';

  @override
  void onInit() {
    super.onInit();
    orderSearchCtrl.addListener(() => ordersPage.value = 1);
    productSearchCtrl.addListener(() => productsPage.value = 1);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    isBootstrapping.value = true;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey) ?? '';
    _role = (prefs.getString(_roleKey) ?? '').toLowerCase();
    _orgId = prefs.getString(_orgIdKey) ?? '';
    _orgName = prefs.getString(_orgNameKey) ?? 'Organization';
    isAuthorized.value = _token.isNotEmpty && canManageCommerce && _orgId.isNotEmpty;
    if (isAuthorized.value) {
      await Future.wait([
        fetchOrders(showLoader: true),
        fetchProducts(showLoader: true),
        fetchCategories(),
        fetchAnalytics(showLoader: true),
      ]);
      _startPolling();
    }
    isBootstrapping.value = false;
  }

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  Map<String, String> get _authOnlyHeaders => {
        'Authorization': 'Bearer $_token',
      };

  void setTab(CommerceTab tab) => activeTab.value = tab;

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() request,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await request().timeout(const Duration(seconds: 20));
        if (response.statusCode >= 500 && attempt < 2) {
          await Future.delayed(Duration(milliseconds: 350 * (attempt + 1)));
          continue;
        }
        return response;
      } catch (error) {
        lastError = error;
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 350 * (attempt + 1)));
          continue;
        }
      }
    }
    throw lastError ?? Exception('Request failed');
  }

  Future<Map<String, dynamic>> _sendMultipartWithRetry(
    http.MultipartRequest request,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final streamed = await request.send().timeout(const Duration(seconds: 40));
        final response = await http.Response.fromStream(streamed);
        final body = _decodeJson(response.body);
        body['_statusCode'] = response.statusCode;
        return body;
      } catch (error) {
        lastError = error;
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 350 * (attempt + 1)));
          continue;
        }
      }
    }
    throw lastError ?? Exception('Upload failed');
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchOrders(showLoader: false),
      fetchProducts(showLoader: false),
      fetchAnalytics(showLoader: false),
    ]);
  }

  Future<void> fetchOrders({bool showLoader = false}) async {
    if (!isAuthorized.value) return;
    if (showLoader) {
      isLoadingOrders.value = true;
    }
    orderError.value = '';
    try {
      final response = await _sendWithRetry(
        () => http.get(
          Uri.parse('${ApiEndpoints.baseUrl}/orders/org-orders'),
          headers: _authHeaders,
        ),
      );
      final json = _decodeJson(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        final list = ((json['data'] as List?) ?? const [])
            .map((item) => OrgOrder.fromJson((item as Map).cast<String, dynamic>()))
            .toList();
        orders.assignAll(list);
        _handleOrderNotifications(list);

        if (selectedOrder.value != null) {
          final currentId = selectedOrder.value!.id;
          OrgOrder? match;
          for (final item in list) {
            if (item.id == currentId) {
              match = item;
              break;
            }
          }
          if (match != null) {
            selectedOrder.value = match;
          }
        }
      } else {
        orderError.value = _readMessage(json, fallback: 'Failed to load orders.');
      }
    } catch (error) {
      orderError.value = 'Failed to load orders.';
    } finally {
      if (showLoader) {
        isLoadingOrders.value = false;
      }
    }
  }

  Future<void> fetchOrderDetails(String orderId) async {
    if (!isAuthorized.value) return;
    isLoadingOrderDetails.value = true;
    try {
      final response = await _sendWithRetry(
        () => http.get(
          Uri.parse('${ApiEndpoints.baseUrl}/orders/$orderId'),
          headers: _authHeaders,
        ),
      );
      final json = _decodeJson(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        selectedOrder.value =
            OrgOrder.fromJson((json['data'] as Map).cast<String, dynamic>());
      } else {
        _toast(_readMessage(json, fallback: 'Unable to load order details.'), isError: true);
      }
    } catch (_) {
      _toast('Unable to load order details.', isError: true);
    } finally {
      isLoadingOrderDetails.value = false;
    }
  }

  Future<void> fetchProducts({bool showLoader = false}) async {
    if (!isAuthorized.value) return;
    if (showLoader) {
      isLoadingProducts.value = true;
    }
    productError.value = '';
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl}/products?orgId=$_orgId&includeInactive=true&limit=100',
      );
      final response = await _sendWithRetry(() => http.get(uri, headers: _authHeaders));
      final json = _decodeJson(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        final list = ((json['products'] as List?) ?? const [])
            .map((item) => OrgProduct.fromJson((item as Map).cast<String, dynamic>()))
            .toList();
        products.assignAll(list);
        _handleStockNotifications(list);

        if (selectedProduct.value != null) {
          final currentId = selectedProduct.value!.id;
          OrgProduct? match;
          for (final item in list) {
            if (item.id == currentId) {
              match = item;
              break;
            }
          }
          if (match != null) {
            selectedProduct.value = match;
          }
        }
      } else {
        productError.value = _readMessage(json, fallback: 'Failed to load products.');
      }
    } catch (_) {
      productError.value = 'Failed to load products.';
    } finally {
      if (showLoader) {
        isLoadingProducts.value = false;
      }
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await _sendWithRetry(
        () => http.get(
          Uri.parse('${ApiEndpoints.baseUrl}/categories?limit=100'),
          headers: _authHeaders,
        ),
      );
      final json = _decodeJson(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        categories.assignAll(
          ((json['data'] as List?) ?? const [])
              .map((item) => OrgCategory.fromJson((item as Map).cast<String, dynamic>()))
              .toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> fetchAnalytics({bool showLoader = false}) async {
    if (!isAuthorized.value) return;
    if (showLoader) {
      isLoadingAnalytics.value = true;
    }
    analyticsError.value = '';
    try {
      final responses = await Future.wait([
        _sendWithRetry(
          () => http.get(
            Uri.parse('${ApiEndpoints.baseUrl}/orders/org-sales/summary'),
            headers: _authHeaders,
          ),
        ),
        _sendWithRetry(
          () => http.get(
            Uri.parse('${ApiEndpoints.baseUrl}/orders/org-sales/products'),
            headers: _authHeaders,
          ),
        ),
      ]);

      final summaryJson = _decodeJson(responses[0].body);
      final productsJson = _decodeJson(responses[1].body);

      if (responses[0].statusCode == 200 && summaryJson['success'] == true) {
        salesSummary.value =
            OrgSalesSummary.fromJson((summaryJson['data'] as Map).cast<String, dynamic>());
      }
      if (responses[1].statusCode == 200 && productsJson['success'] == true) {
        productSales.assignAll(
          ((productsJson['data'] as List?) ?? const [])
              .map((item) => OrgProductSalesSummary.fromJson(
                    (item as Map).cast<String, dynamic>(),
                  ))
              .toList(),
        );
      }
    } catch (_) {
      analyticsError.value = 'Unable to refresh analytics.';
    } finally {
      if (showLoader) {
        isLoadingAnalytics.value = false;
      }
    }
  }

  Future<void> updateOrderStatus(
    OrgOrder order,
    String status, {
    String trackingNumber = '',
    String note = '',
    String cancellationReason = '',
  }) async {
    isUpdatingOrder.value = true;
    try {
      final response = await _sendWithRetry(
        () => http.patch(
          Uri.parse('${ApiEndpoints.baseUrl}/orders/${order.id}/status'),
          headers: _authHeaders,
          body: jsonEncode({
            'status': status,
            if (trackingNumber.trim().isNotEmpty) 'trackingNumber': trackingNumber.trim(),
            if (note.trim().isNotEmpty) 'note': note.trim(),
            if (cancellationReason.trim().isNotEmpty)
              'cancellationReason': cancellationReason.trim(),
          }),
        ),
      );
      final json = _decodeJson(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        final updated =
            OrgOrder.fromJson((json['data'] as Map).cast<String, dynamic>());
        _replaceOrder(updated);
        selectedOrder.value = updated;
        await Future.wait([
          fetchProducts(showLoader: false),
          fetchAnalytics(showLoader: false),
        ]);
        _toast('Order status updated to $status', isError: false);
      } else {
        _toast(_readMessage(json, fallback: 'Failed to update order status.'), isError: true);
      }
    } catch (_) {
      _toast('Failed to update order status.', isError: true);
    } finally {
      isUpdatingOrder.value = false;
    }
  }

  Future<bool> saveProduct({
    OrgProduct? existing,
    required String name,
    required String slug,
    required String description,
    required String categoryId,
    required double price,
    required int stock,
    required bool isActive,
    String sku = '',
    List<String> retainedImages = const [],
    List<PlatformFile> newImages = const [],
    List<ProductVariantDraft> variants = const [],
    String stockNote = '',
  }) async {
    isSavingProduct.value = true;
    try {
      final uri = Uri.parse(
        existing == null
            ? '${ApiEndpoints.baseUrl}/products'
            : '${ApiEndpoints.baseUrl}/products/${existing.id}',
      );
      final request = http.MultipartRequest(existing == null ? 'POST' : 'PUT', uri)
        ..headers.addAll(_authOnlyHeaders)
        ..fields['name'] = name.trim()
        ..fields['slug'] = slug.trim()
        ..fields['description'] = description.trim()
        ..fields['beneficiaryDescription'] = description.trim()
        ..fields['category'] = categoryId
        ..fields['price'] = price.toString()
        ..fields['stock'] = stock.toString()
        ..fields['isActive'] = isActive.toString()
        ..fields['stockNote'] = stockNote.trim().isEmpty ? 'Manual stock update' : stockNote.trim()
        ..fields['variants'] = jsonEncode(
          variants
              .where((variant) =>
                  variant.attributeName.trim().isNotEmpty &&
                  variant.optionValue.trim().isNotEmpty)
              .map(
                (variant) => {
                  if (variant.id.isNotEmpty) '_id': variant.id,
                  'attributes': {
                    variant.attributeName.trim(): variant.optionValue.trim(),
                  },
                  'price': (price + variant.priceAdjustment).clamp(0, double.infinity),
                  'sku': variant.sku.trim(),
                  'stock': variant.stock,
                  'isActive': variant.isActive,
                  'isDeleted': variant.isDeleted,
                },
              )
              .toList(),
        );

      if (sku.trim().isNotEmpty) {
        request.fields['sku'] = sku.trim();
      }

      if (existing != null) {
        request.fields['images'] = jsonEncode(
          retainedImages.map((url) => {'url': url}).toList(),
        );
      }

      for (final file in newImages) {
        final bytes = file.bytes;
        if (bytes == null) {
          continue;
        }
        final mime = lookupMimeType(file.name, headerBytes: bytes) ?? 'image/jpeg';
        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: file.name,
            contentType: MediaType.parse(mime),
          ),
        );
      }

      final json = await _sendMultipartWithRetry(request);
      final statusCode = json['_statusCode'] as int? ?? 500;
      if ((statusCode == 200 || statusCode == 201) && json['success'] == true) {
        await Future.wait([
          fetchProducts(showLoader: false),
          fetchAnalytics(showLoader: false),
        ]);
        _toast(
          existing == null ? 'Product posted successfully' : 'Product updated successfully',
          isError: false,
        );
        return true;
      }

      _toast(_readMessage(json, fallback: 'Unable to save product.'), isError: true);
      return false;
    } catch (_) {
      _toast('Unable to save product.', isError: true);
      return false;
    } finally {
      isSavingProduct.value = false;
    }
  }

  Future<void> archiveProduct(OrgProduct product) async {
    try {
      final response = await _sendWithRetry(
        () => http.delete(
          Uri.parse('${ApiEndpoints.baseUrl}/products/${product.id}'),
          headers: _authHeaders,
        ),
      );
      final json = _decodeJson(response.body);
      if (response.statusCode == 200) {
        products.removeWhere((item) => item.id == product.id);
        productSales.removeWhere((item) => item.productId == product.id);
        if (selectedProduct.value?.id == product.id) {
          selectedProduct.value = null;
        }
        _toast('Product archived successfully', isError: false);
      } else {
        _toast(_readMessage(json, fallback: 'Unable to archive product.'), isError: true);
      }
    } catch (_) {
      _toast('Unable to archive product.', isError: true);
    }
  }

  Future<void> pickDateRange(BuildContext context, {required bool isFrom}) async {
    final initialDate = isFrom
        ? (orderDateFrom.value ?? DateTime.now().subtract(const Duration(days: 30)))
        : (orderDateTo.value ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00C896),
            onPrimary: Colors.black,
            surface: Color(0xFF101A30),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (isFrom) {
        orderDateFrom.value = picked;
      } else {
        orderDateTo.value = picked;
      }
      ordersPage.value = 1;
    }
  }

  void clearOrderFilters() {
    orderSearchCtrl.clear();
    orderStatusFilter.value = 'all';
    paymentStatusFilter.value = 'all';
    orderDateFrom.value = null;
    orderDateTo.value = null;
    ordersPage.value = 1;
  }

  void clearProductFilters() {
    productSearchCtrl.clear();
    productStatusFilter.value = 'all';
    productsPage.value = 1;
  }

  List<OrgOrder> get filteredOrders {
    var list = orders.toList();
    final query = orderSearchCtrl.text.trim().toLowerCase();

    if (orderStatusFilter.value != 'all') {
      list = list.where((item) => item.status == orderStatusFilter.value).toList();
    }
    if (paymentStatusFilter.value != 'all') {
      list = list
          .where((item) => item.paymentStatus == paymentStatusFilter.value)
          .toList();
    }
    if (query.isNotEmpty) {
      list = list.where((item) {
        return item.id.toLowerCase().contains(query) ||
            item.customerName.toLowerCase().contains(query);
      }).toList();
    }
    if (orderDateFrom.value != null) {
      list = list.where((item) {
        final created = item.createdAt;
        return created != null &&
            !DateUtils.dateOnly(created)
                .isBefore(DateUtils.dateOnly(orderDateFrom.value!));
      }).toList();
    }
    if (orderDateTo.value != null) {
      list = list.where((item) {
        final created = item.createdAt;
        return created != null &&
            !DateUtils.dateOnly(created)
                .isAfter(DateUtils.dateOnly(orderDateTo.value!));
      }).toList();
    }
    return list;
  }

  List<OrgProduct> get filteredProducts {
    var list = products.toList();
    final query = productSearchCtrl.text.trim().toLowerCase();
    if (productStatusFilter.value == 'active') {
      list = list.where((item) => item.isActive).toList();
    } else if (productStatusFilter.value == 'inactive') {
      list = list.where((item) => !item.isActive).toList();
    } else if (productStatusFilter.value == 'low-stock') {
      list = list.where((item) => item.isLowStock || item.isOutOfStock).toList();
    }
    if (query.isNotEmpty) {
      list = list.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.slug.toLowerCase().contains(query) ||
            item.sku.toLowerCase().contains(query);
      }).toList();
    }
    return list;
  }

  int get ordersTotalPages =>
      filteredOrders.isEmpty ? 1 : (filteredOrders.length / ordersPerPage).ceil();

  int get productsTotalPages =>
      filteredProducts.isEmpty ? 1 : (filteredProducts.length / productsPerPage).ceil();

  List<OrgOrder> get pagedOrders {
    final start = (ordersPage.value - 1) * ordersPerPage;
    return filteredOrders.skip(start).take(ordersPerPage).toList();
  }

  List<OrgProduct> get pagedProducts {
    final start = (productsPage.value - 1) * productsPerPage;
    return filteredProducts.skip(start).take(productsPerPage).toList();
  }

  List<OrgProductSalesSummary> get topSellingProducts {
    final items = productSales.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return items.take(5).toList();
  }

  List<OrgProduct> get lowStockProducts {
    final items = products
        .where((item) => item.isLowStock || item.isOutOfStock)
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
    return items;
  }

  bool canConfirm(OrgOrder order) =>
      order.status == 'pending' && order.paymentStatus == 'paid';

  bool canDeliver(OrgOrder order) =>
      order.status == 'confirmed' && order.paymentStatus == 'paid';

  bool canCancel(OrgOrder order) =>
      order.status == 'pending' || order.status == 'confirmed';

  void nextOrdersPage() {
    if (ordersPage.value < ordersTotalPages) {
      ordersPage.value++;
    }
  }

  void previousOrdersPage() {
    if (ordersPage.value > 1) {
      ordersPage.value--;
    }
  }

  void nextProductsPage() {
    if (productsPage.value < productsTotalPages) {
      productsPage.value++;
    }
  }

  void previousProductsPage() {
    if (productsPage.value > 1) {
      productsPage.value--;
    }
  }

  String validateProductInput({
    required String name,
    required String slug,
    required String description,
    required String categoryId,
    required String price,
    required String stock,
    required List<String> retainedImages,
    required List<PlatformFile> newImages,
    required String sku,
    required List<ProductVariantDraft> variants,
    OrgProduct? existing,
  }) {
    if (name.trim().isEmpty) return 'Product name is required';
    if (name.trim().length > 200) return 'Product name must be 200 characters or less';
    if (slug.trim().isEmpty) return 'Slug is required';
    if (description.trim().isEmpty) return 'Description is required';
    if (categoryId.trim().isEmpty) return 'Category is required';
    if (double.tryParse(price) == null) return 'Base price must be a valid number';
    if (int.tryParse(stock) == null) return 'Stock quantity must be a whole number';

    final totalImages = retainedImages.length + newImages.length;
    if (existing == null && totalImages < 1) return 'At least one image is required';
    if (totalImages > 5) return 'You can upload up to 5 images';

    final normalizedSlug = slug.trim().toLowerCase();
    final slugInUse = products.any(
      (item) => item.slug.toLowerCase() == normalizedSlug && item.id != existing?.id,
    );
    if (slugInUse) return 'Slug is already in use';

    if (sku.trim().isNotEmpty) {
      final normalizedSku = sku.trim().toUpperCase();
      final skuInUse = products.any(
        (item) => item.sku.toUpperCase() == normalizedSku && item.id != existing?.id,
      );
      if (skuInUse) return 'SKU is already in use';
    }

    for (final image in newImages) {
      final bytes = image.bytes;
      if (bytes == null) return 'Unable to read selected image ${image.name}';
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        return '${image.name} is larger than 5 MB';
      }
      final mime = lookupMimeType(image.name, headerBytes: bytes) ?? '';
      if (!mime.startsWith('image/')) {
        return '${image.name} is not a supported image file';
      }
    }

    final variantSkus = <String>{};
    for (final variant in variants) {
      final attr = variant.attributeName.trim();
      final option = variant.optionValue.trim();
      if (attr.isEmpty && option.isEmpty) {
        continue;
      }
      if (attr.isEmpty || option.isEmpty) {
        return 'Each variant needs both a variant name and option value';
      }
      if (variant.sku.trim().isNotEmpty) {
        final key = variant.sku.trim().toUpperCase();
        if (!variantSkus.add(key)) {
          return 'Variant SKUs must be unique';
        }
      }
    }

    return '';
  }

  String generateSlug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  void _replaceOrder(OrgOrder updated) {
    final index = orders.indexWhere((item) => item.id == updated.id);
    if (index >= 0) {
      orders[index] = updated;
      orders.refresh();
    }
  }

  void _handleOrderNotifications(List<OrgOrder> latestOrders) {
    final latestIds = latestOrders.map((item) => item.id).toSet();
    final latestPaidIds = latestOrders
        .where((item) => item.paymentStatus == 'paid')
        .map((item) => item.id)
        .toSet();

    if (_notificationsPrimed) {
      for (final order in latestOrders) {
        if (!_knownOrderIds.contains(order.id)) {
          _toast('New order received from ${order.customerName}', isError: false);
        }
        if (order.paymentStatus == 'paid' && !_knownPaidOrderIds.contains(order.id)) {
          final label = order.id.length <= 8 ? order.id : order.id.substring(0, 8);
          _toast('Payment received for order $label', isError: false);
        }
      }
    }

    _knownOrderIds = latestIds;
    _knownPaidOrderIds = latestPaidIds;
    _notificationsPrimed = true;
  }

  void _handleStockNotifications(List<OrgProduct> latestProducts) {
    final latestLowStock = latestProducts
        .where((item) => item.isLowStock || item.isOutOfStock)
        .map((item) => item.id)
        .toSet();

    if (_notificationsPrimed) {
      for (final product in latestProducts) {
        if ((product.isLowStock || product.isOutOfStock) &&
            !_knownLowStockIds.contains(product.id)) {
          _toast('Low stock for ${product.name}', isError: false);
        }
      }
    }

    _knownLowStockIds = latestLowStock;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await refreshAll();
    });
  }

  void _toast(String message, {required bool isError}) {
    if (Get.context == null) return;
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Map<String, dynamic> _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  String _readMessage(Map<String, dynamic> json, {required String fallback}) {
    return (json['message'] ?? json['error'] ?? fallback).toString();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    orderSearchCtrl.dispose();
    productSearchCtrl.dispose();
    super.onClose();
  }
}
