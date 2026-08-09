import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/currency_denominations.dart';

/// Tarjeta interactiva para contar billetes/monedas.
///
/// Muestra un icono, el valor de la denominación, botones +/- y el subtotal.
/// También permite tocar la cantidad para editarla manualmente.
class DenominationInputTile extends StatelessWidget {
  final CurrencyDenomination denomination;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  const DenominationInputTile({
    super.key,
    required this.denomination,
    required this.quantity,
    required this.onQuantityChanged,
  });

  static String _formatMoney(int value) {
    return value
        .toString()
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }

  void _update(int newQuantity) {
    final effective = newQuantity < 0 ? 0 : newQuantity;
    if (effective != quantity) {
      HapticFeedback.lightImpact();
      onQuantityChanged(effective);
    }
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _EditQuantityDialog(
        label: denomination.label,
        initialQuantity: quantity,
      ),
    );

    if (result != null) {
      _update(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBill = denomination.type == DenominationType.bill;
    final subtotal = denomination.value * quantity;
    final hasQuantity = quantity > 0;

    final baseColor = isBill
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;
    final onBaseColor = isBill
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: baseColor.withAlpha(hasQuantity ? 153 : 51),
            blurRadius: hasQuantity ? 12 : 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
              side: hasQuantity
                  ? BorderSide(color: onBaseColor.withAlpha(102), width: 2)
                  : BorderSide.none,
          ),
          color: baseColor.withAlpha(hasQuantity ? 255 : 153),
        child: InkWell(
          onTap: () => _showEditDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icono y tipo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isBill ? Icons.money : Icons.monetization_on,
                      size: 28,
                      color: onBaseColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      denomination.type.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: onBaseColor.withAlpha(204),
                      ),
                    ),
                  ],
                ),

                // Valor de denominación
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    denomination.label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: onBaseColor,
                    ),
                  ),
                ),

                // Controles +/-
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CounterButton(
                      icon: Icons.remove,
                      onPressed:
                          quantity > 0 ? () => _update(quantity - 1) : null,
                      color: onBaseColor,
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      alignment: Alignment.center,
                      child: Text(
                        quantity.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: onBaseColor,
                        ),
                      ),
                    ),
                    _CounterButton(
                      icon: Icons.add,
                      onPressed: () => _update(quantity + 1),
                      color: onBaseColor,
                    ),
                  ],
                ),

                // Subtotal
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: hasQuantity ? 15 : 13,
                    fontWeight: hasQuantity ? FontWeight.bold : FontWeight.normal,
                    color: onBaseColor,
                  ),
                  child: Text(
                    '\$${_formatMoney(subtotal)}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditQuantityDialog extends StatefulWidget {
  final String label;
  final int initialQuantity;

  const _EditQuantityDialog({
    required this.label,
    required this.initialQuantity,
  });

  @override
  State<_EditQuantityDialog> createState() => _EditQuantityDialogState();
}

class _EditQuantityDialogState extends State<_EditQuantityDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialQuantity == 0 ? '' : widget.initialQuantity.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = int.tryParse(_controller.text) ?? 0;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cantidad para ${widget.label}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          hintText: '0',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('ACEPTAR'),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _CounterButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(onPressed != null ? 51 : 13),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null ? color : color.withAlpha(76),
          ),
        ),
      ),
    );
  }
}
