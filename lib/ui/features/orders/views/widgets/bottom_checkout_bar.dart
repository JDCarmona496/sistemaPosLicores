import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';

/// Barra inferior de navegación entre pasos y confirmación del pedido.
class BottomCheckoutBar extends ConsumerWidget {
  final int currentStep;
  final bool isLoading;
  final bool canSave;
  final bool canContinue;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onConfirm;

  const BottomCheckoutBar({
    super.key,
    required this.currentStep,
    required this.isLoading,
    required this.canSave,
    required this.canContinue,
    required this.onBack,
    required this.onNext,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(currentOrderCartProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isLastStep = currentStep == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (currentStep > 0)
              OutlinedButton.icon(
                onPressed: isLoading ? null : onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('ATRÁS'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
            const SizedBox(width: 12),
            Expanded(
              child: isLastStep
                  ? FilledButton.icon(
                      onPressed: isLoading || !canSave ? null : onConfirm,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        !canSave
                            ? 'CARGANDO USUARIO...'
                            : 'CREAR PEDIDO \u00b7 \$${cartState.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: isLoading || !canContinue ? null : onNext,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        currentStep == 0 ? 'CONTINUAR' : 'REVISAR PEDIDO',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
