/// Excepción lanzada cuando una factura no puede generarse porque los datos
/// de la venta son inválidos, inconsistentes o incompletos.
class InvoiceValidationException implements Exception {
  final String message;

  const InvoiceValidationException(this.message);

  @override
  String toString() => 'InvoiceValidationException: $message';
}
