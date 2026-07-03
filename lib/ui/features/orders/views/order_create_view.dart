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
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    _deliveryFeeController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(currentOrderCartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading || _currentUserId == null ? null : _saveOrder,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Guardar'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCustomerSection(cartState),
                const SizedBox(height: 16),
                _buildTypeSection(cartState),
                const SizedBox(height: 16),
                _buildProductsSection(cartState),
                const SizedBox(height: 16),
                _buildDeliverySection(cartState),
                const SizedBox(height: 16),
                _buildNotesSection(),
              ],
            ),
          ),
          _buildBottomBar(cartState),
        ],
      ),
    );
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Cliente ocasional',
                      style: TextStyle(color: Colors.grey.shade700),
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
                        if (value == DeliveryType.delivery &&
                            _addressController.text.isEmpty) {
                          // Focus on address field
                        }
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

  Widget _buildProductsSection(CurrentOrderCartState cartState) {
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
                  'Productos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addProduct(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cartState.items.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'El carrito está vacío',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...cartState.items.map((item) => _buildCartItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(OrderItem item) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Text(
          item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1),
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(item.productName ?? 'Producto'),
      subtitle: Text(
        '\$${item.unitPrice.toStringAsFixed(0)} c/u',
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '\$${item.subtotal.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => ref
                .read(currentOrderCartProvider.notifier)
                .removeItem(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(CurrentOrderCartState cartState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrega',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notas / Observaciones',
            prefixIcon: Icon(Icons.note),
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          onChanged: (value) =>
              ref.read(currentOrderCartProvider.notifier).setNotes(value),
        ),
      ),
    );
  }

  Widget _buildBottomBar(CurrentOrderCartState cartState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  'Subtotal: \$${cartState.subtotal.toStringAsFixed(0)}',
                ),
              ],
            ),
            if (cartState.discountAmount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Descuento: -\$${cartState.discountAmount.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
            if (cartState.deliveryFee > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                      'Domicilio: \$${cartState.deliveryFee.toStringAsFixed(0)}'),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${cartState.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
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
    final selected = await showDialog<Customer?>(
      context: context,
      builder: (context) => const _CustomerSelectorDialog(),
    );

    if (selected == null) {
      // Cliente ocasional
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

  Future<void> _addProduct() async {
    final selected = await showDialog<_SelectedProduct>(
      context: context,
      builder: (context) => const _ProductSelectorDialog(),
    );

    if (selected != null) {
      ref.read(currentOrderCartProvider.notifier).addItem(
            productId: selected.product.id,
            productName: selected.product.name,
            price: selected.price,
            quantity: selected.quantity,
            isWholesalePrice: selected.isWholesale,
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

class _SelectedProduct {
  final Product product;
  final double price;
  final double quantity;
  final bool isWholesale;

  _SelectedProduct({
    required this.product,
    required this.price,
    required this.quantity,
    required this.isWholesale,
  });
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);

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
            Expanded(
              child: customersState.isLoading
                  ? const Center(child: CircularProgressIndicator())
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
                            subtitle: const Text('Venta sin cliente registrado'),
                            onTap: () => Navigator.pop(context, null),
                          );
                        }
                        final customer = customersState.customers[index - 1];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(customer.fullName[0].toUpperCase()),
                          ),
                          title: Text(customer.fullName),
                          subtitle: Text(customer.phone),
                          onTap: () => Navigator.pop(context, customer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _ProductSelectorDialog extends ConsumerStatefulWidget {
  const _ProductSelectorDialog();

  @override
  ConsumerState<_ProductSelectorDialog> createState() =>
      _ProductSelectorDialogState();
}

class _ProductSelectorDialogState
    extends ConsumerState<_ProductSelectorDialog> {
  final _searchController = TextEditingController();
  Product? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  bool _isWholesale = false;

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);

    return AlertDialog(
      title: const Text('Agregar Producto'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(productsProvider.notifier).setSearch(null);
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref
                    .read(productsProvider.notifier)
                    .setSearch(value.isEmpty ? null : value);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: productsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: productsState.products.length,
                      itemBuilder: (context, index) {
                        final product = productsState.products[index];
                        final isSelected = _selectedProduct?.id == product.id;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Colors.blue.shade50,
                          leading: CircleAvatar(
                            child: Text(product.name[0].toUpperCase()),
                          ),
                          title: Text(product.name),
                          subtitle: Text(
                            'Detal: \$${product.priceRetail.toStringAsFixed(0)} | Mayorista: \$${product.priceWholesale.toStringAsFixed(0)}',
                          ),
                          trailing: Text(
                            'Stock: ${product.stockCurrent}',
                            style: TextStyle(
                              color: product.stockCurrent == 0
                                  ? Colors.red
                                  : product.stockCurrent <= product.stockMin
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ),
                          onTap: () {
                            setState(() => _selectedProduct = product);
                          },
                        );
                      },
                    ),
            ),
            if (_selectedProduct != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            const Text('Mayorista'),
                            Switch(
                              value: _isWholesale,
                              onChanged: (value) {
                                setState(() => _isWholesale = value);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Precio: \$${_getPrice().toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedProduct == null
              ? null
              : () {
                  final quantity = double.tryParse(_quantityController.text) ?? 1;
                  if (quantity <= 0) return;
                  Navigator.pop(
                    context,
                    _SelectedProduct(
                      product: _selectedProduct!,
                      price: _getPrice(),
                      quantity: quantity,
                      isWholesale: _isWholesale,
                    ),
                  );
                },
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  double _getPrice() {
    if (_selectedProduct == null) return 0;
    return _isWholesale
        ? _selectedProduct!.priceWholesale
        : _selectedProduct!.priceRetail;
  }
}
