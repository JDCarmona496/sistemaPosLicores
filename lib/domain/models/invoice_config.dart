import 'dart:convert';

/// Configuración de factura / datos del negocio que se imprimen en los recibos.
///
/// Se persiste localmente en SharedPreferences, igual que la configuración de
/// la impresora, por lo que sobrevive a cerrar y volver a abrir la app.
class InvoiceConfig {
  final String businessName;
  final String businessNit;
  final String businessAddress;
  final String businessPhone;
  final String sellerName;
  final String invoiceFooter;
  final String legalText;
  final String logoBase64;

  const InvoiceConfig({
    this.businessName = 'Licorería',
    this.businessNit = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.sellerName = '',
    this.invoiceFooter = 'Gracias por su compra',
    this.legalText = '',
    this.logoBase64 = '',
  });

  factory InvoiceConfig.fromJson(Map<String, dynamic> json) {
    return InvoiceConfig(
      businessName: json['businessName'] as String? ?? 'Licorería',
      businessNit: json['businessNit'] as String? ?? '',
      businessAddress: json['businessAddress'] as String? ?? '',
      businessPhone: json['businessPhone'] as String? ?? '',
      sellerName: json['sellerName'] as String? ?? '',
      invoiceFooter: json['invoiceFooter'] as String? ?? 'Gracias por su compra',
      legalText: json['legalText'] as String? ?? '',
      logoBase64: json['logoBase64'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'businessNit': businessNit,
        'businessAddress': businessAddress,
        'businessPhone': businessPhone,
        'sellerName': sellerName,
        'invoiceFooter': invoiceFooter,
        'legalText': legalText,
        'logoBase64': logoBase64,
      };

  InvoiceConfig copyWith({
    String? businessName,
    String? businessNit,
    String? businessAddress,
    String? businessPhone,
    String? sellerName,
    String? invoiceFooter,
    String? legalText,
    String? logoBase64,
  }) {
    return InvoiceConfig(
      businessName: businessName ?? this.businessName,
      businessNit: businessNit ?? this.businessNit,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      sellerName: sellerName ?? this.sellerName,
      invoiceFooter: invoiceFooter ?? this.invoiceFooter,
      legalText: legalText ?? this.legalText,
      logoBase64: logoBase64 ?? this.logoBase64,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
