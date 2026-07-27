import 'package:flutter/material.dart';

import '../../../../../domain/models/order_item.dart';
import '../../../../../domain/models/product.dart';
import 'add_remove_button.dart';

/// Tarjeta de producto premium para el catálogo con imagen/ícono, detalles,
/// precio, stock y controles de cantidad inline.
class CatalogProductCard extends StatelessWidget {
  final Product product;
  final OrderItemPriceType priceType;
  final double price;
  final int quantity;
  final int totalQuantity;
  final bool atStockLimit;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const CatalogProductCard({
    super.key,
    required this.product,
    required this.priceType,
    required this.price,
    required this.quantity,
    required this.totalQuantity,
    required this.atStockLimit,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPrice = price > 0;
    final hasStock = product.stockCurrent > 0;
    final stockColor = !hasStock
        ? Colors.red
        : product.stockCurrent <= product.stockMin
            ? Colors.orange
            : Colors.green;

    return AnimatedScale(
      scale: quantity > 0 ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: Card(
        elevation: quantity > 0 ? 2 : 0,
        shadowColor: quantity > 0 ? colorScheme.shadow : Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: quantity > 0 ? colorScheme.primary : colorScheme.outlineVariant,
            width: quantity > 0 ? 1.5 : 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 210;
            final textScaler = isCompact
                ? TextScaler.linear(0.9)
                : TextScaler.linear(1.0);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: isCompact ? 40 : 52,
                          ),
                          child: _buildImageHeader(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isCompact) ...[
                          const SizedBox(height: 2),
                          Text(
                            product.presentation,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                '\$${price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: hasPrice
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _StockBadge(
                              stock: product.stockCurrent,
                              stockColor: stockColor,
                              atStockLimit: atStockLimit,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _QuantityControls(
                            quantity: quantity,
                            onDecrement: onDecrement,
                            onIncrement: onIncrement,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (totalQuantity > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          '$totalQuantity',
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCold = product.isCold || priceType == OrderItemPriceType.cold;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: product.imageUrl != null && product.imageUrl!.isNotEmpty
            ? Image.network(
                product.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _FallbackIcon(isCold: isCold),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              )
            : _FallbackIcon(isCold: isCold),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final bool isCold;

  const _FallbackIcon({required this.isCold});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Icon(
        isCold ? Icons.ac_unit : Icons.liquor,
        size: 28,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  final MaterialColor stockColor;
  final bool atStockLimit;

  const _StockBadge({
    required this.stock,
    required this.stockColor,
    required this.atStockLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: stockColor.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        atStockLimit ? 'Stock máx: $stock' : 'Stock: $stock',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: atStockLimit ? Colors.red.shade700 : stockColor.shade700,
        ),
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _QuantityControls({
    required this.quantity,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AddRemoveButton(
            icon: Icons.remove,
            onPressed: quantity > 0 ? onDecrement : null,
            compact: true,
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: quantity > 0 ? colorScheme.primary : null,
              ),
            ),
          ),
          AddRemoveButton(
            icon: Icons.add,
            onPressed: onIncrement,
            compact: true,
          ),
        ],
      ),
    );
  }
}
