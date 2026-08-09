import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/currency_denominations.dart';
import '../../../../data/providers/cash_count_providers.dart';
import '../../../../data/providers/printer_provider.dart';
import 'widgets/denomination_input_tile.dart';

class CashCountView extends ConsumerStatefulWidget {
  const CashCountView({super.key});

  @override
  ConsumerState<CashCountView> createState() => _CashCountViewState();
}

class _CashCountViewState extends ConsumerState<CashCountView> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatMoney(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }

  Future<void> _saveAndOfferPrint() async {
    final notifier = ref.read(cashCountFormProvider.notifier);
    final saved = await notifier.save();

    if (saved == null || !mounted) return;

    final shouldPrint = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conteo guardado'),
        content: Text(
          'Total efectivo: \$${_formatMoney(saved.total)}\n'
          'Base apertura: \$${_formatMoney(saved.total - saved.netTotal)}\n'
          'Efectivo neto: \$${_formatMoney(saved.netTotal)}\n\n'
          '¿Querés imprimir el recibo?',
        ),
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

    final result = await ref.read(printCashCountReceiptProvider)(saved);
    _showSnack(
      result.success ? 'Recibo impreso' : 'Error al imprimir: ${result.message}',
      isError: !result.success,
    );

    if (result.success && mounted) {
      notifier.reset();
      _notesController.clear();
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

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar conteo'),
        content: const Text('¿Estás seguro de que querés reiniciar todas las cantidades?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('BORRAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(cashCountFormProvider.notifier).reset();
      _notesController.clear();
      _showSnack('Conteo reiniciado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashCountFormProvider);
    final hasAnyQuantity = state.quantities.values.any((q) => q > 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteo de caja'),
        actions: [
          if (hasAnyQuantity)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Borrar conteo',
              onPressed: _confirmClear,
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => context.push('/cash-counts'),
          ),
        ],
      ),
      body: state.isLoadingShift
          ? const Center(child: CircularProgressIndicator())
          : state.shift == null
              ? _buildNoShift()
              : _buildBody(state),
      bottomNavigationBar: state.shift == null || state.isLoadingShift
          ? null
          : _buildBottomBar(state),
    );
  }

  Widget _buildNoShift() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 64, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            Text(
              'No hay turno abierto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Para hacer un conteo de caja debe existir un turno abierto.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('VOLVER'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CashCountFormState state) {
    final notifier = ref.read(cashCountFormProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ingresá las cantidades',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Usá los botones + / – o tocá el número para editar.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            final crossAxisCount = width >= 900
                ? 4
                : width >= 600
                    ? 3
                    : 2;

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final denom = copDenominations[index];
                    final quantity = state.quantities[denom.value] ?? 0;
                    return DenominationInputTile(
                      denomination: denom,
                      quantity: quantity,
                      onQuantityChanged: (value) =>
                          notifier.setQuantity(denom.value, value),
                    );
                  },
                  childCount: copDenominations.length,
                ),
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _notesController,
                  onChanged: notifier.setNotes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    hintText: 'Observaciones opcionales',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.error!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(CashCountFormState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(cashCountFormProvider.notifier);

    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(color: colorScheme.outlineVariant),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total animado
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              child: Text(
                '\$${_formatMoney(state.total)}',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Base apertura: \$${_formatMoney(state.openingAmount)}',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Efectivo neto: \$${_formatMoney(state.netTotal)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: state.netTotal >= 0 ? Colors.green : colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Descontar base',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Switch(
                  value: state.deductOpening,
                  onChanged: (value) => notifier.setDeductOpening(value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Chips billetes / monedas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSummaryChip(
                  icon: Icons.money,
                  label: 'Billetes',
                  value: state.totalBills,
                  color: colorScheme.primaryContainer,
                  textColor: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                _buildSummaryChip(
                  icon: Icons.monetization_on,
                  label: 'Monedas',
                  value: state.totalCoins,
                  color: colorScheme.secondaryContainer,
                  textColor: colorScheme.onSecondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.isSaving ? null : _saveAndOfferPrint,
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text(
                      'GUARDAR CONTEO',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            if (state.savedCashCount != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  notifier.reset();
                  _notesController.clear();
                },
                icon: const Icon(Icons.add),
                label: const Text('NUEVO CONTEO'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    required Color textColor,
  }) {
    return Chip(
      avatar: Icon(icon, size: 18, color: textColor),
      label: Text(
        '$label: \$${_formatMoney(value)}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      backgroundColor: color,
      side: BorderSide.none,
    );
  }
}
