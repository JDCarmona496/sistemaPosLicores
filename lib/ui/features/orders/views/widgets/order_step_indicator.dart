import 'package:flutter/material.dart';

/// Indicador visual de pasos para el flujo de creación de pedido.
class OrderStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const OrderStepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = (index ~/ 2);
            final isActive = stepBefore < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCurrent = stepIndex == currentStep;
          final isCompleted = stepIndex < currentStep;

          return _StepCircle(
            label: steps[stepIndex],
            step: stepIndex + 1,
            isCurrent: isCurrent,
            isCompleted: isCompleted,
          );
        }),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final String label;
  final int step;
  final bool isCurrent;
  final bool isCompleted;

  const _StepCircle({
    required this.label,
    required this.step,
    required this.isCurrent,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isCurrent || isCompleted
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;
    final background = isCompleted
        ? colorScheme.primary
        : isCurrent
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, size: 18, color: foreground)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
            color: isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
