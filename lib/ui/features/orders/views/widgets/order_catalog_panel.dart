import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import '../../../../../data/providers/product_providers.dart';
import '../../../../../domain/models/order_item.dart';
import '../../../../../domain/models/product.dart';
import 'add_remove_button.dart';
import 'price_type_style.dart';

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

  void _onCategorySelected(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    ref.read(productsProvider.notifier).setCategory(categoryId);
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

    final totalInCart = _totalQuantityInCart(product);
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

  int _quantityInCart(Product product, OrderItemPriceType priceType) {
    final cart = ref.read(currentOrderCartProvider);
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

  int _totalQuantityInCart(Product product) {
    final cart = ref.read(currentOrderCartProvider);
    return cart.items
        .where((i) => i.productId == product.id)
        .fold(0, (sum, i) => sum + i.quantity);
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Catálogo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${productsState.products.length} productos',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: TextField(
                controller: _productSearchController,
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _productSearchController.clear();
                      ref.read(productsProvider.notifier).setSearch(null);
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (categories) => SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('Todas'),
                        selected: _selectedCategoryId == null,
                        onSelected: (_) => _onCategorySelected(null),
                      ),
                      const SizedBox(width: 8),
                      ...categories.map((category) {
                        final selected = _selectedCategoryId == category.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category.name),
                            selected: selected,
                            onSelected: (_) => _onCategorySelected(category.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Precio por defecto:'),
                  SegmentedButton<OrderItemPriceType>(
                    segments: [
                      ButtonSegment(
                        value: OrderItemPriceType.retail,
                        icon: Icon(OrderItemPriceType.retail.icon, size: 16),
                        label: Text(OrderItemPriceType.retail.label),
                      ),
                      ButtonSegment(
                        value: OrderItemPriceType.wholesale,
                        icon: Icon(OrderItemPriceType.wholesale.icon, size: 16),
                        label: Text(OrderItemPriceType.wholesale.label),
                      ),
                      ButtonSegment(
                        value: OrderItemPriceType.cold,
                        icon: Icon(OrderItemPriceType.cold.icon, size: 16),
                        label: Text(OrderItemPriceType.cold.label),
                      ),
                    ],
                    selected: {_defaultPriceType},
                    onSelectionChanged: (selected) {
                      if (selected.isNotEmpty) {
                        setState(() => _defaultPriceType = selected.first);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
                      Icon(Icons.search_off,
                          size: 48, color: Colors.grey.shade700),
                      const SizedBox(height: 8),
                      Text(
                        'No se encontraron productos',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildProductCard(productsState.products[index]),
                  childCount: productsState.products.length,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultPrice = _resolvePrice(product, _defaultPriceType);
    final quantityForDefault = _quantityInCart(product, _defaultPriceType);
    final totalQuantity = _totalQuantityInCart(product);
    final hasPrice = defaultPrice > 0;
    final atStockLimit = totalQuantity >= product.stockCurrent;
    final stockColor = product.stockCurrent == 0
        ? Colors.red
        : product.stockCurrent <= product.stockMin
            ? Colors.orange
            : Colors.green;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.presentation,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${defaultPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 12, color: stockColor),
                        const SizedBox(width: 2),
                        Text(
                          atStockLimit && product.stockCurrent > 0
                              ? 'Máx: ${product.stockCurrent}'
                              : 'Stock: ${product.stockCurrent}',
                          style: TextStyle(
                            fontSize: 12,
                            color: atStockLimit ? Colors.red : stockColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AddRemoveButton(
                      icon: Icons.remove,
                      onPressed: quantityForDefault > 0
                          ? () => _onProductDecrement(product)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        '$quantityForDefault',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    AddRemoveButton(
                      icon: Icons.add,
                      onPressed: hasPrice && !atStockLimit
                          ? () => _onProductIncrement(product)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (totalQuantity > 0)
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.error,
                child: Text(
                  '$totalQuantity',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
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
