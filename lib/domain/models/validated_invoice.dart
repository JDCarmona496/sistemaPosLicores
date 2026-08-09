/// Modelo normalizado de una factura/recibo ya validado.
///
/// Es la unica fuente de verdad tanto para PDF como para impresion termica.
class ValidatedInvoice {
  final InvoiceBusinessInfo business;
  final InvoiceSaleInfo sale;
  final InvoiceCustomerInfo customer;
  final String saleTypeLabel;
  final String deliveryTypeLabel;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discountAmount;
  final double deliveryFee;
  final double total;
  final List<InvoicePayment> payments;
  final double totalPaid;
  final double balance;
  final String? notes;
  final String footer;
  final String? legalText;
  final String developerFooterTitle;
  final String developerFooterName;
  final String developerFooterPhone;

  const ValidatedInvoice({
    required this.business,
    required this.sale,
    required this.customer,
    required this.saleTypeLabel,
    required this.deliveryTypeLabel,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.total,
    required this.payments,
    required this.totalPaid,
    required this.balance,
    this.notes,
    required this.footer,
    this.legalText,
    required this.developerFooterTitle,
    required this.developerFooterName,
    required this.developerFooterPhone,
  });

  bool get hasPayments => payments.isNotEmpty;
  bool get isFullyPaid => balance <= 0 && totalPaid > 0;
}

class InvoiceBusinessInfo {
  final String name;
  final String? nit;
  final String? address;
  final String? phone;
  final String? logoBase64;

  const InvoiceBusinessInfo({
    required this.name,
    this.nit,
    this.address,
    this.phone,
    this.logoBase64,
  });
}

class InvoiceSaleInfo {
  final int orderNumber;
  final String invoiceId;
  final DateTime? createdAt;
  final String sellerName;
  final String statusLabel;

  const InvoiceSaleInfo({
    required this.orderNumber,
    required this.invoiceId,
    this.createdAt,
    required this.sellerName,
    required this.statusLabel,
  });
}

class InvoiceCustomerInfo {
  final String name;
  final String? phone;
  final String? address;

  const InvoiceCustomerInfo({
    required this.name,
    this.phone,
    this.address,
  });
}

class InvoiceItem {
  final String? originalId;
  final int quantity;
  final String description;
  final String? presentation;
  final double unitPrice;
  final double lineTotal;

  const InvoiceItem({
    this.originalId,
    required this.quantity,
    required this.description,
    this.presentation,
    required this.unitPrice,
    required this.lineTotal,
  });

  String get fullDescription {
    final pres = presentation?.trim();
    if (pres != null && pres.isNotEmpty) {
      return '$description $pres';
    }
    return description;
  }
}

class InvoicePayment {
  final DateTime? createdAt;
  final String methodLabel;
  final double amount;

  const InvoicePayment({
    this.createdAt,
    required this.methodLabel,
    required this.amount,
  });
}
