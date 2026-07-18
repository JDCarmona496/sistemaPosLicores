import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'add_remove_button.dart';

/// Selector de cantidad reutilizable: `[-] [campo editable] [+]`.
///
/// Validaciones de entrada:
/// - Solo dígitos ([FilteringTextInputFormatter.digitsOnly]).
/// - Campo vacío o inválido → revierte al valor actual.
/// - Cantidad 0 → se reporta con [onChanged] (el padre decide si elimina).
/// - Mayor que [maxQuantity] → se fija en el máximo y se notifica
///   con [onLimitExceeded].
class QuantitySelector extends StatefulWidget {
  final int quantity;
  final int? maxQuantity;
  final ValueChanged<int> onChanged;
  final ValueChanged<String>? onLimitExceeded;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.maxQuantity,
    this.onLimitExceeded,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.quantity}');
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(QuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincronizar con cambios externos (p. ej. +/- del catálogo),
    // sin pisar lo que el usuario está escribiendo.
    if (!_focusNode.hasFocus &&
        int.tryParse(_controller.text) != widget.quantity) {
      _controller.text = '${widget.quantity}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commit(_controller.text);
  }

  void _increment() {
    final max = widget.maxQuantity;
    if (max != null && widget.quantity >= max) {
      widget.onLimitExceeded?.call('Stock máximo: $max');
      return;
    }
    widget.onChanged(widget.quantity + 1);
  }

  void _decrement() {
    widget.onChanged(widget.quantity - 1);
  }

  void _commit(String value) {
    final parsed = int.tryParse(value);

    if (parsed == null || parsed == widget.quantity) {
      _controller.text = '${widget.quantity}';
      return;
    }

    final max = widget.maxQuantity;
    if (max != null && parsed > max) {
      widget.onChanged(max);
      _controller.text = '$max';
      widget.onLimitExceeded?.call('Stock máximo: $max');
      return;
    }

    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final atMax =
        widget.maxQuantity != null && widget.quantity >= widget.maxQuantity!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AddRemoveButton(
          icon: Icons.remove,
          onPressed: widget.quantity > 0 ? _decrement : null,
        ),
        SizedBox(
          width: 52,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(),
            ),
            onSubmitted: _commit,
          ),
        ),
        AddRemoveButton(
          icon: Icons.add,
          onPressed: atMax ? null : _increment,
        ),
      ],
    );
  }
}
