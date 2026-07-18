import 'package:flutter/material.dart';

/// Botón circular con icono +/- usado en las tarjetas del catálogo
/// para incrementar o decrementar la cantidad de un producto.
class AddRemoveButton extends StatelessWidget {
  const AddRemoveButton({super.key, required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.shade200
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: disabled
              ? Colors.grey
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
