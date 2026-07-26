import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive.dart';
import '../../../../data/providers/delivery_providers.dart';
import '../../../../data/providers/order_providers.dart';
import '../../../../data/providers/printer_provider.dart';
import '../../../../data/providers/settings_providers.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/customer.dart';
import '../../../../domain/models/delivery_config.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import 'widgets/customer_selector_dialog.dart';
import 'widgets/order_cart_panel.dart';
import 'widgets/order_catalog_panel.dart';
import 'widgets/order_create_bottom_bar.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentOrderCartProvider.notifier).clearCart();
      _notesController.clear();
      _addressController.clear();
      _deliveryFeeController.text = '0';
    });
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
                          const Expanded(
                            flex: 3,
                            child: OrderCatalogPanel(),
                          ),
                          Expanded(
                            flex: 2,
                            child: OrderCartPanel(
                              addressController: _addressController,
                              deliveryFeeController: _deliveryFeeController,
                              notesController: _notesController,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OrderCreateBottomBar(
                      isLoading: _isLoading,
                      canSave: _currentUserId != null,
                      onSave: _saveOrder,
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _buildMobileBody(cartState)),
                    OrderCreateBottomBar(
                      isLoading: _isLoading,
                      canSave: _currentUserId != null,
                      onSave: _saveOrder,
                    ),
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
          _buildMobileHeader(cartState),
          _buildMobileSummary(cartState),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search), text: 'Catálogo'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Carrito'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const OrderCatalogPanel(),
                OrderCartPanel(
                  addressController: _addressController,
                  deliveryFeeController: _deliveryFeeController,
                  notesController: _notesController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(CurrentOrderCartState cartState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pedido',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildMobileCustomerChip(cartState),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMobileSaleTypeDropdown(cartState),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMobileDeliveryTypeDropdown(cartState),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCustomerChip(CurrentOrderCartState cartState) {
    final isOccasional = cartState.isOccasionalCustomer;
    return InkWell(
      onTap: _selectCustomer,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              isOccasional ? Icons.person_outline : Icons.person,
              size: 18,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cliente',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  Text(
                    isOccasional ? 'Ocasional' : (cartState.customerName ?? 'Cliente'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isOccasional)
              GestureDetector(
                onTap: () {
                  ref.read(currentOrderCartProvider.notifier).setCustomer(
                        id: null,
                        name: null,
                        type: null,
                        address: null,
                      );
                  _addressController.clear();
                  if (cartState.saleType == SaleType.credit) {
                    ref.read(currentOrderCartProvider.notifier).setSaleType(SaleType.cash);
                  }
                },
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSaleTypeDropdown(CurrentOrderCartState cartState) {
    return DropdownButtonFormField<SaleType>(
      initialValue: cartState.saleType,
      isDense: true,
      decoration: InputDecoration(
        labelText: 'Venta',
        labelStyle: const TextStyle(fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: SaleType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              enabled: !cartState.isOccasionalCustomer || type == SaleType.cash,
              child: Text(
                type.label,
                style: TextStyle(
                  fontSize: 12,
                  color: cartState.isOccasionalCustomer && type == SaleType.credit
                      ? Colors.grey
                      : null,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        if (value == SaleType.credit && cartState.isOccasionalCustomer) {
          _showSnack(
            'No se puede vender a crédito a un cliente ocasional',
            isError: true,
          );
          return;
        }
        ref.read(currentOrderCartProvider.notifier).setSaleType(value);
      },
    );
  }

  Widget _buildMobileDeliveryTypeDropdown(CurrentOrderCartState cartState) {
    return DropdownButtonFormField<DeliveryType>(
      initialValue: cartState.deliveryType,
      isDense: true,
      decoration: InputDecoration(
        labelText: 'Entrega',
        labelStyle: const TextStyle(fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: DeliveryType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(type.label, style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          ref.read(currentOrderCartProvider.notifier).setDeliveryType(value);
        }
      },
    );
  }

  Widget _buildMobileSummary(CurrentOrderCartState cartState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryChip(
              icon: Icons.shopping_bag_outlined,
              label: 'Items',
              value: '${cartState.itemCount}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryChip(
              icon: Icons.attach_money,
              label: 'Subtotal',
              value: '\$${cartState.subtotal.toStringAsFixed(0)}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryChip(
              icon: Icons.account_balance_wallet,
              label: 'Total',
              value: '\$${cartState.total.toStringAsFixed(0)}',
              isHighlighted: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted ? Colors.blue.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isHighlighted ? Colors.blue.shade700 : Colors.grey.shade700),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? Colors.blue.shade800 : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(CurrentOrderCartState cartState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ResponsiveBuilder(
        mobile: (context) => Column(
          children: [
            _buildCustomerSection(cartState),
            const SizedBox(height: 12),
            _buildTypeSection(cartState),
          ],
        ),
        desktop: (context) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCustomerSection(cartState)),
            const SizedBox(width: 16),
            Expanded(child: _buildTypeSection(cartState)),
          ],
        ),
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
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.grey.shade700),
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

  Future<void> _offerPrintReceipt(
    Order order,
    List<OrderItem> items,
  ) async {
    final config = ref.read(printerConfigProvider);
    if (config == null) return;

    final shouldPrint = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pedido creado'),
        content: Text('¿Querés imprimir el recibo del pedido #${order.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.print),
            label: const Text('IMPRIMIR'),
          ),
        ],
      ),
    );

    if (shouldPrint != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final result = await ref.read(printOrderReceiptProvider)(order, items);
      if (mounted) {
        _showSnack(
          result.success
              ? 'Recibo impreso'
              : 'Error al imprimir: ${result.message}',
          isError: !result.success,
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Error al imprimir: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCustomer() async {
    final result = await showDialog<CustomerSelectionResult>(
      context: context,
      builder: (context) => const CustomerSelectorDialog(),
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
          latitude: selected.latitude,
          longitude: selected.longitude,
        );

    if (selected.address != null && selected.address!.isNotEmpty) {
      _addressController.text = selected.address!;
      ref
          .read(currentOrderCartProvider.notifier)
          .setDeliveryAddress(selected.address!, clearCoordinates: false);
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
      String? autoDeliveryPersonId;
      final deliveryConfig = ref.read(deliveryConfigProvider);
      if (cartState.deliveryType == DeliveryType.delivery &&
          deliveryConfig.assignmentMode == DeliveryAssignmentMode.automatic) {
        final user = await ref.read(leastBusyDeliveryUserProvider.future);
        autoDeliveryPersonId = user?.id;
        if (user != null) {
          _showSnack('Domiciliario asignado: ${user.fullName}');
        } else {
          _showSnack(
            'No hay domiciliarios disponibles para asignación automática',
            isError: true,
          );
        }
      }

      final created = await ref.read(ordersProvider.notifier).createOrder(
            sellerId: _currentUserId!,
            customerId: cartState.customerId,
            saleType: cartState.saleType,
            deliveryType: cartState.deliveryType,
            items: cartState.items,
            notes: cartState.notes,
            deliveryAddress: cartState.deliveryAddress,
            deliveryLatitude: cartState.deliveryLatitude,
            deliveryLongitude: cartState.deliveryLongitude,
            deliveryFee: cartState.deliveryFee,
            deliveryPersonId: autoDeliveryPersonId,
          );

      // Guardar items antes de limpiar el carrito para la impresión del recibo
      final createdItems = List<OrderItem>.from(cartState.items);

      ref.read(currentOrderCartProvider.notifier).clearCart();
      _showSnack('Pedido #${created.orderNumber} creado');

      // Ofrecer impresión del recibo si hay impresora configurada
      if (mounted) {
        await _offerPrintReceipt(created, createdItems);
      }

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
