import 'cash_count.dart';
import 'invoice_config.dart';

/// Datos necesarios para imprimir el recibo de un conteo de efectivo.
class CashCountReceiptData {
  final CashCount cashCount;
  final InvoiceConfig invoiceConfig;
  final String responsibleName;

  const CashCountReceiptData({
    required this.cashCount,
    required this.invoiceConfig,
    required this.responsibleName,
  });
}
