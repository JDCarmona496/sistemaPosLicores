/// Denominaciones de moneda colombiana (COP) soportadas para el conteo de caja.
library;

enum DenominationType { bill, coin }

extension DenominationTypeX on DenominationType {
  String get label {
    switch (this) {
      case DenominationType.bill:
        return 'Billete';
      case DenominationType.coin:
        return 'Moneda';
    }
  }
}

/// Representa una denominación de dinero conocida.
class CurrencyDenomination {
  final int value;
  final DenominationType type;
  final String label;

  const CurrencyDenomination({
    required this.value,
    required this.type,
    required this.label,
  });
}

/// Denominaciones oficiales de pesos colombianos, ordenadas de mayor a menor.
const List<CurrencyDenomination> copDenominations = [
  CurrencyDenomination(
    value: 100000,
    type: DenominationType.bill,
    label: '\$100.000',
  ),
  CurrencyDenomination(
    value: 50000,
    type: DenominationType.bill,
    label: '\$50.000',
  ),
  CurrencyDenomination(
    value: 20000,
    type: DenominationType.bill,
    label: '\$20.000',
  ),
  CurrencyDenomination(
    value: 10000,
    type: DenominationType.bill,
    label: '\$10.000',
  ),
  CurrencyDenomination(
    value: 5000,
    type: DenominationType.bill,
    label: '\$5.000',
  ),
  CurrencyDenomination(
    value: 2000,
    type: DenominationType.bill,
    label: '\$2.000',
  ),
  CurrencyDenomination(
    value: 1000,
    type: DenominationType.bill,
    label: '\$1.000',
  ),
  CurrencyDenomination(
    value: 500,
    type: DenominationType.coin,
    label: '\$500',
  ),
  CurrencyDenomination(
    value: 200,
    type: DenominationType.coin,
    label: '\$200',
  ),
  CurrencyDenomination(
    value: 100,
    type: DenominationType.coin,
    label: '\$100',
  ),
  CurrencyDenomination(
    value: 50,
    type: DenominationType.coin,
    label: '\$50',
  ),
];
