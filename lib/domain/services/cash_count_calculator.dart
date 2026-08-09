import '../../core/constants/currency_denominations.dart';
import '../models/cash_count.dart';

/// Resultado del cálculo de un conteo de efectivo.
class CashCountCalculation {
  final double total;
  final double totalBills;
  final double totalCoins;
  final List<CashCountDenomination> denominations;

  const CashCountCalculation({
    required this.total,
    required this.totalBills,
    required this.totalCoins,
    required this.denominations,
  });
}

/// Calcula totales y detalle de un conteo de efectivo a partir de las
/// cantidades ingresadas por denominación.
class CashCountCalculator {
  const CashCountCalculator();

  /// [quantities] mapea el valor de la denominación a la cantidad física.
  CashCountCalculation calculate(Map<int, int> quantities) {
    double totalBills = 0;
    double totalCoins = 0;
    final denominations = <CashCountDenomination>[];

    for (final denom in copDenominations) {
      final quantity = quantities[denom.value] ?? 0;
      if (quantity < 0) {
        throw ArgumentError(
          'La cantidad para ${denom.label} no puede ser negativa',
        );
      }
      final subtotal = denom.value * quantity;
      denominations.add(
        CashCountDenomination(
          value: denom.value,
          type: denom.type,
          quantity: quantity,
          subtotal: subtotal.toDouble(),
        ),
      );
      if (denom.type == DenominationType.bill) {
        totalBills += subtotal;
      } else {
        totalCoins += subtotal;
      }
    }

    return CashCountCalculation(
      total: totalBills + totalCoins,
      totalBills: totalBills,
      totalCoins: totalCoins,
      denominations: denominations,
    );
  }

  /// Valida que haya al menos una denominación con cantidad mayor a cero.
  bool hasAnyQuantity(Map<int, int> quantities) {
    return quantities.values.any((q) => q > 0);
  }
}
