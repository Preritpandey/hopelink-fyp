import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

enum ProductStatus { initial, loading, success, error }

class ProductController extends GetxController {
  // ── Observables ──────────────────────────────────────────────────────────
  final _products = <ProductModel>[].obs;
  final _selectedProduct = Rxn<ProductModel>();
  final _selectedVariant = Rxn<ProductVariant>();
  final _status = ProductStatus.initial.obs;
  final _errorMessage = ''.obs;
  final _currentImageIndex = 0.obs;
  final _total = 0.obs;
  final _totalPages = 1.obs;
  final _currentPage = 1.obs;
  final _searchQuery = ''.obs;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<ProductModel> get products => _products;
  ProductModel? get selectedProduct => _selectedProduct.value;
  ProductVariant? get selectedVariant => _selectedVariant.value;
  ProductStatus get status => _status.value;
  String get errorMessage => _errorMessage.value;
  int get currentImageIndex => _currentImageIndex.value;
  int get total => _total.value;
  int get totalPages => _totalPages.value;
  int get currentPage => _currentPage.value;
  bool get isLoading => _status.value == ProductStatus.loading;
  bool get hasError => _status.value == ProductStatus.error;
  bool get hasProducts => _products.isNotEmpty;
  String get searchQuery => _searchQuery.value;

  // ── Config ────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> fetchProducts({int page = 1, String? search}) async {
    try {
      _status.value = ProductStatus.loading;
      _errorMessage.value = '';

      final queryParams = <String, String>{'page': page.toString()};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        ApiEndpoints.products,
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final parsed = ProductsResponse.fromJson(json);

        if (page == 1) {
          _products.value = parsed.products;
        } else {
          _products.addAll(parsed.products);
        }

        _total.value = parsed.total;
        _totalPages.value = parsed.totalPages;
        _currentPage.value = page;
        _status.value = ProductStatus.success;
      } else {
        _handleHttpError(response.statusCode);
      }
    } catch (e) {
      _status.value = ProductStatus.error;
      _errorMessage.value = 'Failed to load products. Please try again.';
      debugPrint('ProductController.fetchProducts error: $e');
    }
  }

  Future<void> refreshProducts() => fetchProducts(page: 1);

  Future<void> searchProducts(String query) {
    _searchQuery.value = query;
    return fetchProducts(page: 1, search: query);
  }

  Future<void> loadMoreProducts() async {
    if (_currentPage.value < _totalPages.value && !isLoading) {
      await fetchProducts(page: _currentPage.value + 1);
    }
  }

  // ── Detail / Variant Selection ────────────────────────────────────────────

  void selectProduct(ProductModel product) {
    _selectedProduct.value = product;
    _currentImageIndex.value = 0;
    _selectedVariant.value = product.defaultVariant;
  }

  void selectVariant(ProductVariant variant) {
    _selectedVariant.value = variant;
  }

  void setImageIndex(int index) {
    _currentImageIndex.value = index;
  }

  void nextImage() {
    final images = _selectedProduct.value?.images ?? [];
    if (images.isNotEmpty) {
      _currentImageIndex.value = (_currentImageIndex.value + 1) % images.length;
    }
  }

  void prevImage() {
    final images = _selectedProduct.value?.images ?? [];
    if (images.isNotEmpty) {
      _currentImageIndex.value =
          (_currentImageIndex.value - 1 + images.length) % images.length;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, String> _buildHeaders() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // 'Authorization': 'Bearer $token', // ← add auth token here
  };

  void _handleHttpError(int statusCode) {
    _status.value = ProductStatus.error;
    switch (statusCode) {
      case 401:
        _errorMessage.value = 'Unauthorized. Please log in again.';
      case 403:
        _errorMessage.value = 'You do not have permission to view products.';
      case 404:
        _errorMessage.value = 'Products endpoint not found.';
      case 500:
        _errorMessage.value = 'Server error. Please try again later.';
      default:
        _errorMessage.value = 'Something went wrong (code $statusCode).';
    }
  }

  List<ProductVariant> activeVariantsFor(ProductModel product) =>
      product.displayVariants;
}
