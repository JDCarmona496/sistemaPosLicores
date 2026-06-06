import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/brand_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../domain/models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductsNotifier(repository);
});

class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? selectedCategoryId;
  final String? selectedBrandId;

  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.selectedCategoryId,
    this.selectedBrandId,
  });

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedCategoryId,
    String? selectedBrandId,
    bool clearSearch = false,
    bool clearCategory = false,
    bool clearBrand = false,
    bool clearError = false,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedBrandId: clearBrand ? null : (selectedBrandId ?? this.selectedBrandId),
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final ProductRepository _repository;

  ProductsNotifier(this._repository) : super(const ProductsState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final products = await _repository.getAll(
        search: state.searchQuery,
        categoryId: state.selectedCategoryId,
        brandId: state.selectedBrandId,
      );

      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar productos: ${e.toString()}',
      );
    }
  }

  void setSearch(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.isEmpty,
    );
    loadProducts();
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
    );
    loadProducts();
  }

  void setBrand(String? brandId) {
    state = state.copyWith(
      selectedBrandId: brandId,
      clearBrand: brandId == null,
    );
    loadProducts();
  }

  void clearFilters() {
    state = state.copyWith(
      clearSearch: true,
      clearCategory: true,
      clearBrand: true,
    );
    loadProducts();
  }

  Future<Product> createProduct(Product product) async {
    try {
      final created = await _repository.create(product);
      state = state.copyWith(products: [...state.products, created]);
      return created;
    } catch (e) {
      throw Exception('Error al crear producto: ${e.toString()}');
    }
  }

  Future<Product> updateProduct(Product product) async {
    try {
      final updated = await _repository.update(product);
      state = state.copyWith(
        products: state.products.map((p) => p.id == updated.id ? updated : p).toList(),
      );
      return updated;
    } catch (e) {
      throw Exception('Error al actualizar producto: ${e.toString()}');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.delete(id);
      state = state.copyWith(
        products: state.products.where((p) => p.id != id).toList(),
      );
    } catch (e) {
      throw Exception('Error al eliminar producto: ${e.toString()}');
    }
  }

  Future<Product?> getByBarcode(String barcode) async {
    return await _repository.getByBarcode(barcode);
  }

  Future<int> getNextCode() async {
    return await _repository.getNextCode();
  }
}

final brandsProvider = FutureProvider<List<Brand>>((ref) async {
  final repository = ref.watch(brandRepositoryProvider);
  return await repository.getAll();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return await repository.getAll();
});

final productByIdProvider = FutureProvider.family<Product?, String>((ref, id) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getById(id);
});
