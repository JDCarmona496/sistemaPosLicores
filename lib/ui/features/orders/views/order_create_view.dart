import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/providers/customer_providers.dart';
import '../../../../data/providers/order_providers.dart';
import '../../../../data/providers/product_providers.dart';

import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/customer.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import '../../../../domain/models/product.dart';

class OrderCreateView extends ConsumerStatefulWidget {
  const OrderCreateView({super.key});

  @override
  ConsumerState<OrderCreateView> createState() => _OrderCreateViewState();
}

class _OrderCreateViewState extends ConsumerState<OrderCreateView> {
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  final _deliveryFeeController = TextEditingController(text: '0');
  final _productSearchController = TextEditingController();
  bool _isLoading = false;
  String? _currentUserId;
  OrderItemPriceType _defaultPriceType = OrderItemPriceType.retail;
  String? _selectedCategoryId;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentOrderCartProvider.notifier).clearCart();
      _notesController.clear();
      _addressController.clear();
      _deliveryFeeController.text = '0';
      _productSearchController.clear();
      _selectedCategoryId = null;
      _defaultPriceType = OrderItemPriceType.retail;
      ref.read(productsProvider.notifier).clearFilters();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    _deliveryFeeController.dispose();
    _productSearchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (mounted) {
        setState(() => _currentUserId = user.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentUserId = null);
      }
    }
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
      _showSnack('Este producto no tiene precio para ${orderItemPriceTypeLabel(_defaultPriceType).toLowerCase()}', isError: true);
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
    final cartState = ref.watch(currentOrderCartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return isWide
              ? Column(
                  children: [
                    _buildHeader(cartState),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildCatalogPanel(cartState),
                          ),
                          Expanded(
                            flex: 2,
                            child: _buildCartPanel(cartState),
                          ),
                        ],
                      ),
                    ),
                    _buildBottomBar(cartState),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _buildMobileBody(cartState)),
                    _buildBottomBar(cartState),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildMobileBody(CurrentOrderCartState cartState) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildHeader(cartState),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search), text: 'Catálogo'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Carrito'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCatalogPanel(cartState),
                _buildCartPanel(cartState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(CurrentOrderCartState cartState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          _buildCustomerSection(cartState),
          const SizedBox(height: 12),
          _buildTypeSection(cartState),
        ],
      ),
    );
  }

  Widget _buildCatalogPanel(CurrentOrderCartState cartState) {
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
                        label: Text(OrderItemPriceType.retail.label),
                      ),
                      ButtonSegment(
                        value: OrderItemPriceType.wholesale,
                        label: Text(OrderItemPriceType.wholesale.label),
                      ),
                      ButtonSegment(
                        value: OrderItemPriceType.cold,
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
                          size: 48,
                          color: Colors.grey.shade700),
                      const SizedBox(height: 8),
                      Text(
                        'No se encontraron productos',
                        style: TextStyle(
                            color: Colors.grey.shade700),
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
                    Text(
                      'Stock: ${product.stockCurrent}',
                      style: TextStyle(
                        fontSize: 12,
                        color: stockColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _IconButton(
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
                    _IconButton(
                      icon: Icons.add,
                      onPressed: hasPrice
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

  Widget _buildCartPanel(CurrentOrderCartState cartState) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Carrito',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (cartState.items.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => ref
                          .read(currentOrderCartProvider.notifier)
                          .clearCart(),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Vaciar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (cartState.items.isEmpty)
                SizedBox(
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 48,
                            color: Colors.grey.shade700),
                        const SizedBox(height: 8),
                        Text(
                          'El carrito está vacío',
                          style: TextStyle(
                              color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartState.items.length,
                  itemBuilder: (context, index) =>
                      _buildCartItem(cartState.items[index]),
                ),
              const Divider(),
              _buildDeliverySection(cartState),
              const SizedBox(height: 12),
              _buildNotesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(OrderItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          '${item.quantity}',
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        item.productName ?? 'Producto',
        style: TextStyle(color: colorScheme.onSurface),
      ),
      subtitle: Wrap(
        spacing: 8,
        children: [
          Text(
            '\$${item.unitPrice.toStringAsFixed(0)} c/u',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          _buildItemPriceTypeChip(item),
        ],
      ),
      trailing: SizedBox(
        width: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '\$${item.subtotal.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => ref
                      .read(currentOrderCartProvider.notifier)
                      .updateItemQuantity(item.id, item.quantity + 1),
                  child: const Icon(Icons.add, size: 18),
                ),
                InkWell(
                  onTap: () => ref
                      .read(currentOrderCartProvider.notifier)
                      .updateItemQuantity(item.id, item.quantity - 1),
                  child: const Icon(Icons.remove, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemPriceTypeChip(OrderItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _showItemPriceTypeSelector(item),
      child: Chip(
        label: Text(
          item.priceType.label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: colorScheme.primaryContainer,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Future<void> _showItemPriceTypeSelector(OrderItem item) async {
    final selected = await showDialog<OrderItemPriceType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar tipo de precio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderItemPriceType.values.map((type) {
            final selected = type == item.priceType;
            return ListTile(
              title: Text(type.label),
              leading: Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              onTap: () => Navigator.pop(context, type),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null && selected != item.priceType) {
      ref
          .read(currentOrderCartProvider.notifier)
          .updateItemPriceType(item.id, selected);
    }
  }

  Widget _buildCustomerSection(CurrentOrderCartState cartState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cliente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _selectCustomer(),
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cartState.customerId == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Cliente ocasional',
                      style: TextStyle(
                          color: Colors.grey.shade700),
                    ),
                  ],
                ),
              )
            else
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.person, color: Colors.blue.shade700),
                ),
                title: Text(cartState.customerName ?? 'Cliente'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(currentOrderCartProvider.notifier).setCustomer(
                          id: null,
                          name: null,
                          type: null,
                          address: null,
                        );
                    _addressController.clear();
                    if (cartState.saleType == SaleType.credit) {
                      ref
                          .read(currentOrderCartProvider.notifier)
                          .setSaleType(SaleType.cash);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSection(CurrentOrderCartState cartState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de Pedido',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<SaleType>(
                    initialValue: cartState.saleType,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Venta',
                      border: const OutlineInputBorder(),
                      helperText: cartState.isOccasionalCustomer
                          ? 'Solo contado para cliente ocasional'
                          : null,
                    ),
                    items: SaleType.values
                        .map((type) => DropdownMenuItem(
                              value: type,
                              enabled: !cartState.isOccasionalCustomer ||
                                  type == SaleType.cash,
                              child: Text(
                                type.label,
                                style: TextStyle(
                                  color: cartState.isOccasionalCustomer &&
                                          type == SaleType.credit
                                      ? Colors.grey
                                      : null,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      if (value == SaleType.credit &&
                          cartState.isOccasionalCustomer) {
                        _showSnack(
                          'No se puede vender a crédito a un cliente ocasional',
                          isError: true,
                        );
                        return;
                      }

                      ref
                          .read(currentOrderCartProvider.notifier)
                          .setSaleType(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<DeliveryType>(
                    initialValue: cartState.deliveryType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Entrega',
                      border: OutlineInputBorder(),
                    ),
                    items: DeliveryType.values
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(currentOrderCartProvider.notifier)
                            .setDeliveryType(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection(CurrentOrderCartState cartState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Entrega',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Dirección de entrega',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (value) => ref
              .read(currentOrderCartProvider.notifier)
              .setDeliveryAddress(value),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _deliveryFeeController,
          decoration: const InputDecoration(
            labelText: 'Costo de domicilio',
            prefixIcon: Icon(Icons.delivery_dining),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final fee = double.tryParse(value) ?? 0;
            ref
                .read(currentOrderCartProvider.notifier)
                .setDeliveryFee(fee);
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return TextField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notas / Observaciones',
        prefixIcon: Icon(Icons.note),
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 2,
      onChanged: (value) =>
          ref.read(currentOrderCartProvider.notifier).setNotes(value),
    );
  }

  Widget _buildBottomBar(CurrentOrderCartState cartState) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${cartState.items.length} productos',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  'Subtotal: \$${cartState.subtotal.toStringAsFixed(0)}',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ],
            ),
            if (cartState.discountAmount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Descuento: -\$${cartState.discountAmount.toStringAsFixed(0)}',
                    style: TextStyle(color: colorScheme.tertiary),
                  ),
                ],
              ),
            if (cartState.deliveryFee > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Domicilio: \$${cartState.deliveryFee.toStringAsFixed(0)}',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ],
              ),
            Divider(color: colorScheme.outlineVariant),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '\$${cartState.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading || _currentUserId == null
                    ? null
                    : _saveOrder,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: _currentUserId == null
                    ? const Text('CARGANDO USUARIO...')
                    : const Text('CREAR PEDIDO'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCustomer() async {
    final result = await showDialog<_CustomerSelectionResult>(
      context: context,
      builder: (context) => const _CustomerSelectorDialog(),
    );

    if (result == null || result.cancelled) return;

    if (result.isOccasional) {
      ref.read(currentOrderCartProvider.notifier).setCustomer(
            id: null,
            name: null,
            type: null,
            address: null,
          );
      _addressController.clear();
      ref.read(currentOrderCartProvider.notifier).setDeliveryAddress('');

      if (ref.read(currentOrderCartProvider).saleType == SaleType.credit) {
        ref.read(currentOrderCartProvider.notifier).setSaleType(SaleType.cash);
        _showSnack(
          'Cliente ocasional: se cambió la venta a contado',
          isError: true,
        );
      }
      return;
    }

    final selected = result.customer;
    if (selected == null) return;

    ref.read(currentOrderCartProvider.notifier).setCustomer(
          id: selected.id,
          name: selected.fullName,
          type: selected.type,
          address: selected.address,
        );

    if (selected.address != null && selected.address!.isNotEmpty) {
      _addressController.text = selected.address!;
      ref
          .read(currentOrderCartProvider.notifier)
          .setDeliveryAddress(selected.address!);
    }

    if (selected.type == CustomerType.occasional &&
        ref.read(currentOrderCartProvider).saleType == SaleType.credit) {
      ref.read(currentOrderCartProvider.notifier).setSaleType(SaleType.cash);
      _showSnack(
        'Cliente ocasional: se cambió la venta a contado',
        isError: true,
      );
    }
  }

  Future<void> _saveOrder() async {
    final cartState = ref.read(currentOrderCartProvider);

    if (cartState.items.isEmpty) {
      _showSnack('Agrega al menos un producto', isError: true);
      return;
    }

    if (_currentUserId == null) {
      _showSnack('No se pudo identificar el vendedor', isError: true);
      return;
    }

    if (cartState.saleType == SaleType.credit &&
        cartState.isOccasionalCustomer) {
      _showSnack(
        'No se puede vender a crédito a un cliente ocasional. Selecciona un cliente registrado o cambia a contado.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final created = await ref.read(ordersProvider.notifier).createOrder(
            sellerId: _currentUserId!,
            customerId: cartState.customerId,
            saleType: cartState.saleType,
            deliveryType: cartState.deliveryType,
            items: cartState.items,
            notes: cartState.notes,
            deliveryAddress: cartState.deliveryAddress,
            deliveryFee: cartState.deliveryFee,
          );

      ref.read(currentOrderCartProvider.notifier).clearCart();
      _showSnack('Pedido #${created.orderNumber} creado');
      if (mounted) {
        context.pop();
        context.push('/orders/${created.id}');
      }
    } catch (e) {
      _showSnack('Error al crear pedido: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _IconButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onPressed == null
              ? Colors.grey.shade200
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onPressed == null
              ? Colors.grey
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _CustomerSelectionResult {
  final bool cancelled;
  final bool isOccasional;
  final Customer? customer;

  const _CustomerSelectionResult._({
    this.cancelled = false,
    this.isOccasional = false,
    this.customer,
  });

  factory _CustomerSelectionResult.cancelled() =>
      const _CustomerSelectionResult._(cancelled: true);

  factory _CustomerSelectionResult.occasional() =>
      const _CustomerSelectionResult._(isOccasional: true);

  factory _CustomerSelectionResult.customer(Customer customer) =>
      _CustomerSelectionResult._(customer: customer);
}

class _CustomerSelectorDialog extends ConsumerStatefulWidget {
  const _CustomerSelectorDialog();

  @override
  ConsumerState<_CustomerSelectorDialog> createState() =>
      _CustomerSelectorDialogState();
}

class _CustomerSelectorDialogState
    extends ConsumerState<_CustomerSelectorDialog> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.clear();
      ref.read(customersProvider.notifier).clearFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Seleccionar Cliente'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(customersProvider.notifier).setSearch(null);
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref
                    .read(customersProvider.notifier)
                    .setSearch(value.isEmpty ? null : value);
              },
            ),
            const SizedBox(height: 8),
            if (customersState.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customersState.error!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () =>
                          ref.read(customersProvider.notifier).loadCustomers(),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: customersState.isLoading && customersState.customers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : customersState.customers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 48,
                                  color: Colors.grey.shade700),
                              const SizedBox(height: 8),
                              Text(
                                customersState.error != null
                                    ? 'No se pudieron cargar los clientes'
                                    : 'No hay clientes registrados',
                                style: TextStyle(
                                    color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: customersState.customers.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey.shade200,
                                  child: Icon(Icons.person_outline,
                                      color: Colors.grey.shade700),
                                ),
                                title: const Text('Cliente ocasional'),
                                subtitle: const Text(
                                    'Venta sin cliente registrado'),
                                onTap: () => Navigator.pop(
                                  context,
                                  _CustomerSelectionResult.occasional(),
                                ),
                              );
                            }
                            final customer =
                                customersState.customers[index - 1];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                    customer.fullName[0].toUpperCase()),
                              ),
                              title: Text(customer.fullName),
                              subtitle: Text(customer.phone),
                              onTap: () => Navigator.pop(
                                context,
                                _CustomerSelectionResult.customer(customer),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _CustomerSelectionResult.cancelled(),
          ),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

String orderItemPriceTypeLabel(OrderItemPriceType type) {
  return type.label;
}
