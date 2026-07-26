import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/providers/delivery_providers.dart';
import '../../../../data/providers/order_providers.dart';
import '../../../../data/providers/printer_provider.dart';
import '../../../../data/providers/settings_providers.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/customer.dart';
import '../../../../domain/models/delivery_config.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import 'widgets/bottom_checkout_bar.dart';
import 'widgets/customer_selector_dialog.dart';
import 'widgets/order_cart_panel.dart';
import 'widgets/order_catalog_panel.dart';
import 'widgets/order_header_card.dart';
import 'widgets/order_summary_card.dart';

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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: OrderHeaderCard(
                              onCustomerTap: _selectCustomer,
                              onClearCustomer: _clearCustomer,
                              onSaleTypeChanged: _onSaleTypeChanged,
                              onDeliveryTypeChanged: _onDeliveryTypeChanged,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: OrderSummaryCard()),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 8, 16),
                              child: OrderCatalogPanel(),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                              child: OrderCartPanel(
                                addressController: _addressController,
                                deliveryFeeController: _deliveryFeeController,
                                notesController: _notesController,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    BottomCheckoutBar(
                      isLoading: _isLoading,
                      canSave: _currentUserId != null,
                      onSave: _saveOrder,
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: _buildMobileBody(cartState),
                    ),
                    BottomCheckoutBar(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: OrderHeaderCard(
              onCustomerTap: _selectCustomer,
              onClearCustomer: _clearCustomer,
              onSaleTypeChanged: _onSaleTypeChanged,
              onDeliveryTypeChanged: _onDeliveryTypeChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: const OrderSummaryCard(),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              tabs: [
                Tab(icon: Icon(Icons.search), text: 'Catálogo'),
                Tab(icon: Icon(Icons.shopping_cart), text: 'Carrito'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: OrderCatalogPanel(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: OrderCartPanel(
                    addressController: _addressController,
                    deliveryFeeController: _deliveryFeeController,
                    notesController: _notesController,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearCustomer() {
    ref.read(currentOrderCartProvider.notifier).setCustomer(
          id: null,
          name: null,
          type: null,
          address: null,
        );
    _addressController.clear();
    if (ref.read(currentOrderCartProvider).saleType == SaleType.credit) {
      ref.read(currentOrderCartProvider.notifier).setSaleType(SaleType.cash);
      _showSnack(
        'Cliente ocasional: se cambió la venta a contado',
        isError: true,
      );
    }
  }

  void _onSaleTypeChanged(SaleType value) {
    final cartState = ref.read(currentOrderCartProvider);
    if (value == SaleType.credit && cartState.isOccasionalCustomer) {
      _showSnack(
        'No se puede vender a crédito a un cliente ocasional',
        isError: true,
      );
      return;
    }
    ref.read(currentOrderCartProvider.notifier).setSaleType(value);
  }

  void _onDeliveryTypeChanged(DeliveryType value) {
    ref.read(currentOrderCartProvider.notifier).setDeliveryType(value);
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

      final createdItems = List<OrderItem>.from(cartState.items);

      ref.read(currentOrderCartProvider.notifier).clearCart();
      _showSnack('Pedido #${created.orderNumber} creado');

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
