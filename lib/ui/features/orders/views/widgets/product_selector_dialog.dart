import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/product_providers.dart';
import '../../../../../domain/models/order_item.dart';
import '../../../../../domain/models/product.dart';
import 'price_type_selector.dart';
import 'quantity_selector.dart';

/// Dialogo para seleccionar un producto, tipo de precio y cantidad,
/// y devolver un [OrderItem] listo para agregar a un pedido.
class ProductSelectorDialog extends ConsumerStatefulWidget {
  const ProductSelectorDialog({super.key});

  @override
  ConsumerState<ProductSelectorDialog> createState() =>
      _ProductSelectorDialogState();
}

class _ProductSelectorDialogState extends ConsumerState<ProductSelectorDialog> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  Product? _selectedProduct;
  OrderItemPriceType _priceType = OrderItemPriceType.retail;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).clearFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  double _resolvePrice(Product product) {
    switch (_priceType) {
      case OrderItemPriceType.wholesale:
        return product.priceWholesale;
      case OrderItemPriceType.cold:
        return product.priceCold ?? product.priceRetail;
      case OrderItemPriceType.retail:
        return product.priceRetail;
    }
  }

  int _maxQuantity(Product product) {
    return product.stockCurrent.toInt();
  }

  void _confirm() {
    final product = _selectedProduct;
    if (product == null) return;

    final price = _resolvePrice(product);
    final item = OrderItem(
      id: '',
      orderId: '',
      productId: product.id,
      productName: product.name,
      productPresentation: product.presentation,
      quantity: _quantity,
      unitPrice: price,
      discountAmount: 0,
      subtotal: price * _quantity,
      priceType: _priceType,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Agregar producto'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar producto',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(productsProvider.notifier).setSearch(null);
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            if (productsState.isLoading && productsState.products.isEmpty)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (productsState.products.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No se encontraron productos',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: productsState.products.length,
                  itemBuilder: (context, index) {
                    final product = productsState.products[index];
                    final isSelected = _selectedProduct?.id == product.id;
                    final outOfStock = product.stockCurrent <= 0;

                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor:
                          colorScheme.primaryContainer.withValues(alpha: 0.5),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.presentation} · Stock: ${product.stockCurrent}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        '\$${_formatMoney(product.priceRetail)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      enabled: !outOfStock,
                      onTap: () {
                        setState(() {
                          _selectedProduct = product;
                          _quantity = 1;
                        });
                      },
                    );
                  },
                ),
              ),
            if (_selectedProduct != null) ...[
              const Divider(),
              Text(
                _selectedProduct!.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Precio:',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PriceTypeSelector(
                      value: _priceType,
                      onChanged: (type) => setState(() => _priceType = type),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cantidad:',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  QuantitySelector(
                    quantity: _quantity,
                    maxQuantity: _maxQuantity(_selectedProduct!),
                    onChanged: (value) => setState(() => _quantity = value),
                    onLimitExceeded: (message) => _showSnack(message),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total: \$${_formatMoney(_resolvePrice(_selectedProduct!) * _quantity)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selectedProduct != null && _quantity > 0 ? _confirm : null,
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }
}
