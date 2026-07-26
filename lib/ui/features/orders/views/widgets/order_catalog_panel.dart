import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import '../../../../../data/providers/product_providers.dart';
import '../../../../../domain/models/order_item.dart';
import '../../../../../domain/models/product.dart';
import 'catalog_product_card.dart';
import 'catalog_search_bar.dart';
import 'category_chips.dart';
import 'price_type_selector.dart';

/// Panel de catálogo de productos con búsqueda, filtros por categoría,
/// selector de tipo de precio por defecto y grilla de productos.
class OrderCatalogPanel extends ConsumerStatefulWidget {
  const OrderCatalogPanel({super.key});

  @override
  ConsumerState<OrderCatalogPanel> createState() => _OrderCatalogPanelState();
}

class _OrderCatalogPanelState extends ConsumerState<OrderCatalogPanel> {
  final _productSearchController = TextEditingController();
  Timer? _searchDebounce;
  String? _selectedCategoryId;
  OrderItemPriceType _defaultPriceType = OrderItemPriceType.retail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).clearFilters();
    });
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(productsProvider.notifier)
          .setSearch(value.isEmpty ? null : value);
    });
  }

  void _onSearchClear() {
    _productSearchController.clear();
    ref.read(productsProvider.notifier).setSearch(null);
  }

  void _onCategorySelected(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    ref.read(productsProvider.notifier).setCategory(categoryId);
  }

  void _onPriceTypeChanged(OrderItemPriceType type) {
    setState(() => _defaultPriceType = type);
  }

  void _onProductIncrement(Product product) {
    final price = _resolvePrice(product, _defaultPriceType);
    if (price <= 0) {
      _showSnack(
        'Este producto no tiene precio para ${_defaultPriceType.label.toLowerCase()}',
        isError: true,
      );
      return;
    }

    final totalInCart =
        _totalQuantityInCart(ref.read(currentOrderCartProvider), product);
    if (totalInCart >= product.stockCurrent) {
      _showSnack(
        'Stock máximo alcanzado (${product.stockCurrent} unidades)',
        isError: true,
      );
      return;
    }

    ref.read(currentOrderCartProvider.notifier).incrementItem(
          productId: product.id,
          productName: product.name,
          price: price,
          priceType: _defaultPriceType,
        );
  }

  void _onProductDecrement(Product product) {
    ref.read(currentOrderCartProvider.notifier).decrementItem(
          productId: product.id,
          priceType: _defaultPriceType,
        );
  }

  double _resolvePrice(Product product, OrderItemPriceType priceType) {
    switch (priceType) {
      case OrderItemPriceType.wholesale:
        return product.priceWholesale;
      case OrderItemPriceType.cold:
        return product.priceCold ?? product.priceRetail;
      case OrderItemPriceType.retail:
        return product.priceRetail;
    }
  }

  int _quantityInCart(
    CurrentOrderCartState cart,
    Product product,
    OrderItemPriceType priceType,
  ) {
    final item = cart.items.firstWhere(
      (i) => i.productId == product.id && i.priceType == priceType,
      orElse: () => const OrderItem(
        id: '',
        orderId: '',
        productId: '',
      ),
    );
    return item.id.isEmpty ? 0 : item.quantity;
  }

  int _totalQuantityInCart(CurrentOrderCartState cart, Product product) {
    return cart.items
        .where((i) => i.productId == product.id)
        .fold(0, (sum, i) => sum + i.quantity);
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cart = ref.watch(currentOrderCartProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: colorScheme.surfaceContainerLowest,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Catálogo',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${productsState.products.length} productos',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CatalogSearchBar(
                      controller: _productSearchController,
                      onChanged: _onSearchChanged,
                      onClear: _onSearchClear,
                    ),
                    const SizedBox(height: 12),
                    categoriesAsync.when(
                      data: (categories) => CategoryChips(
                        categories: categories,
                        selectedId: _selectedCategoryId,
                        onSelected: _onCategorySelected,
                      ),
                      loading: () => const SizedBox(
                        height: 44,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Precio:',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PriceTypeSelector(
                            value: _defaultPriceType,
                            onChanged: _onPriceTypeChanged,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (productsState.isLoading && productsState.products.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (productsState.products.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 56,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No se encontraron productos',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = productsState.products[index];
                      final quantity = _quantityInCart(
                        cart,
                        product,
                        _defaultPriceType,
                      );
                      final total = _totalQuantityInCart(cart, product);
                      final price = _resolvePrice(product, _defaultPriceType);
                      final atLimit = total >= product.stockCurrent;

                      return CatalogProductCard(
                        product: product,
                        priceType: _defaultPriceType,
                        price: price,
                        quantity: quantity,
                        totalQuantity: total,
                        atStockLimit: atLimit,
                        onIncrement:
                            price > 0 && !atLimit
                                ? () => _onProductIncrement(product)
                                : null,
                        onDecrement: quantity > 0
                            ? () => _onProductDecrement(product)
                            : null,
                      );
                    },
                    childCount: productsState.products.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}
