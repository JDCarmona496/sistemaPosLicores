import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/cash_count_providers.dart';
import '../../../../../data/repositories/shift_repository.dart';

class CloseShiftDialog extends ConsumerStatefulWidget {
  const CloseShiftDialog({super.key});

  @override
  ConsumerState<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends ConsumerState<CloseShiftDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  double _expectedAmount = 0;
  bool _isLoadingExpected = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExpectedAndLastCount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExpectedAndLastCount() async {
    final shift = ref.read(currentShiftProvider).shift;
    if (shift == null) return;

    double expected = 0;
    double? lastCountTotal;

    try {
      expected = await ShiftRepository().getExpectedAmount(shift);
    } catch (e) {
      expected = shift.openingAmount;
    }

    // Intentar precargar el último conteo de caja.
    try {
      final repository = ref.read(cashCountRepositoryProvider);
      final counts = await repository.getByShift(shift.id);
      if (counts.isNotEmpty) {
        lastCountTotal = counts.first.total;
      }
    } catch (_) {
      // Ignorar: el usuario ingresará el monto manualmente.
    }

    if (mounted) {
      setState(() {
        _expectedAmount = expected;
        _isLoadingExpected = false;
        if (lastCountTotal != null) {
          _amountController.text = lastCountTotal.toStringAsFixed(0);
        }
      });
    }
  }

  double get _closingAmount {
    return double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
  }

  double get _difference {
    return _closingAmount - _expectedAmount;
  }

  Future<void> _closeShift() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final notifier = ref.read(currentShiftProvider.notifier);
    final result = await notifier.closeShift(
      closingAmount: _closingAmount,
      notes: _notesController.text,
    );

    if (!mounted) return;

    if (result != null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isSaving = false;
        _error = ref.read(currentShiftProvider).error ?? 'No se pudo cerrar el turno';
      });
    }
  }

  String _formatMoney(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diff = _difference;
    final diffColor = diff > 0
        ? Colors.green
        : diff < 0
            ? colorScheme.error
            : colorScheme.onSurface;

    return AlertDialog(
      title: const Text('Cerrar turno'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoadingExpected)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                'Monto esperado: \$${_formatMoney(_expectedAmount)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Monto final contado',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              Text(
                'Diferencia: \$${_formatMoney(diff)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: diffColor,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('CANCELAR'),
        ),
        FilledButton.icon(
          onPressed: _isSaving || _isLoadingExpected ? null : _closeShift,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.stop),
          label: const Text('CERRAR TURNO'),
        ),
      ],
    );
  }
}
