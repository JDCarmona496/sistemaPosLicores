import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/shift_providers.dart';

class StartShiftDialog extends ConsumerStatefulWidget {
  const StartShiftDialog({super.key});

  @override
  ConsumerState<StartShiftDialog> createState() => _StartShiftDialogState();
}

class _StartShiftDialogState extends ConsumerState<StartShiftDialog> {
  String? _selectedRegisterId;
  final _amountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openShift() async {
    final registerId = _selectedRegisterId;
    if (registerId == null || registerId.isEmpty) {
      setState(() => _error = 'Selecciona una caja.');
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final notifier = ref.read(currentShiftProvider.notifier);
    final result = await notifier.openShift(
      cashRegisterId: registerId,
      openingAmount: amount,
      notes: _notesController.text,
    );

    if (!mounted) return;

    if (result != null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isSaving = false;
        _error = ref.read(currentShiftProvider).error ?? 'No se pudo abrir el turno';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final registersAsync = ref.watch(cashRegistersProvider);

    return AlertDialog(
      title: const Text('Abrir turno'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            registersAsync.when(
              data: (registers) {
                if (registers.isEmpty) {
                  return const Text('No hay cajas activas disponibles.');
                }
                if (_selectedRegisterId == null && registers.isNotEmpty) {
                  _selectedRegisterId = registers.first.id;
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedRegisterId,
                  decoration: const InputDecoration(
                    labelText: 'Caja',
                    border: OutlineInputBorder(),
                  ),
                  items: registers.map((register) {
                    return DropdownMenuItem<String>(
                      value: register.id,
                      child: Text(register.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedRegisterId = value);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto inicial',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
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
          onPressed: _isSaving ? null : _openShift,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: const Text('ABRIR TURNO'),
        ),
      ],
    );
  }
}
