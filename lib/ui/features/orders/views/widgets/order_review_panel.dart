import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import 'cart_item_card.dart';
import 'delivery_section.dart';
import 'notes_section.dart';
import 'order_summary_section.dart';
import 'section_header.dart';


/// Vista de revisión/validación del pedido antes de confirmar.
class OrderReviewPanel extends ConsumerWidget {
  final TextEditingController addressController;
  final TextEditingController deliveryFeeController;
  final TextEditingController notesController;

  const OrderReviewPanel({
    super.key,
    required this.addressController,
    required this.deliveryFeeController,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(currentOrderCartProvider);
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
        child: cartState.items.isEmpty
            ? _buildEmptyState(context)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      icon: Icons.fact_check_outlined,
                      title: 'Revisá tu pedido',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Verificá los productos, dirección y totales antes de crear el pedido.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartState.items.length,
                      itemBuilder: (context, index) => CartItemCard(
                        item: cartState.items[index],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DeliverySection(
                      addressController: addressController,
                      deliveryFeeController: deliveryFeeController,
                    ),
                    NotesSection(notesController: notesController),
                    const OrderSummarySection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos para revisar',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
