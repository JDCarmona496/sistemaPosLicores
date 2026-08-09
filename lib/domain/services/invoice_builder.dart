import 'package:flutter/foundation.dart';

import '../exceptions/invoice_validation_exception.dart';
import '../models/invoice_config.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/payment.dart';
import '../models/validated_invoice.dart';

/// Construye una [ValidatedInvoice] a partir de una venta, validando que los
/// datos sean consistentes y completos antes de imprimir o generar PDF.
///
/// Es la unica fuente de verdad para ambos formatos de salida.
class InvoiceBuilder {
  const InvoiceBuilder();

  /// Construye la factura normalizada. Lanza [InvoiceValidationException]
  /// si los datos no son validos.
  ValidatedInvoice build({
    required Order order,
    required List<OrderItem> items,
    required List<Payment> payments,
    required InvoiceConfig invoiceConfig,
    required String sellerName,
  }) {
    _validateInputs(order, items, payments);

    final business = _buildBusinessInfo(invoiceConfig);
    final sale = _buildSaleInfo(order, sellerName);
    final customer = _buildCustomerInfo(order);

    final invoiceItems = _buildItems(items);
    final subtotal = invoiceItems.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );

    final discountAmount = order.discountAmount;
    final deliveryFee = order.deliveryFee;
    final total = subtotal + deliveryFee - discountAmount;

    _validateTotals(order, subtotal, total);

    final invoicePayments = _buildPayments(payments);
    final totalPaid = invoicePayments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final balance = total - totalPaid;

    _logInvoice(order, invoiceItems, subtotal, total);

    return ValidatedInvoice(
      business: business,
      sale: sale,
      customer: customer,
      saleTypeLabel: order.saleType.label,
      deliveryTypeLabel: order.deliveryType.label,
      items: invoiceItems,
      subtotal: subtotal,
      discountAmount: discountAmount,
      deliveryFee: deliveryFee,
      total: total,
      payments: invoicePayments,
      totalPaid: totalPaid,
      balance: balance,
      notes: order.notes,
      footer: invoiceConfig.invoiceFooter.isNotEmpty
          ? invoiceConfig.invoiceFooter
          : 'Gracias por su compra',
      legalText: invoiceConfig.legalText,
      developerFooterTitle: 'Desarrollado por',
      developerFooterName: 'Juan D. Carmona',
      developerFooterPhone: '3194643984',
    );
  }

  void _validateInputs(
    Order order,
    List<OrderItem> items,
    List<Payment> payments,
  ) {
    if (items.isEmpty) {
      throw const InvoiceValidationException(
        'La venta no contiene productos. No se puede generar la factura.',
      );
    }

    for (final item in items) {
      final name = item.productName?.trim();
      if (name == null || name.isEmpty) {
        throw InvoiceValidationException(
          'Un producto no tiene nombre/descripcion. Verifique los items del pedido #${order.orderNumber}.',
        );
      }

      if (item.quantity <= 0) {
        throw InvoiceValidationException(
          'El producto "$name" tiene una cantidad invalida (${item.quantity}).',
        );
      }

      if (item.unitPrice < 0) {
        throw InvoiceValidationException(
          'El producto "$name" tiene un precio invalido.',
        );
      }
    }

    for (final payment in payments) {
      if (payment.amount <= 0) {
        throw const InvoiceValidationException(
          'Existe un abono con monto invalido.',
        );
      }
    }
  }

  void _validateTotals(Order order, double calculatedSubtotal, double calculatedTotal) {
    // Permitir una pequena diferencia por redondeo (1 unidad monetaria).
    const epsilon = 1.0;

    if ((order.subtotal - calculatedSubtotal).abs() > epsilon) {
      throw InvoiceValidationException(
        'Subtotal inconsistente: calculado \$${_formatMoney(calculatedSubtotal)} vs almacenado \$${_formatMoney(order.subtotal)}.',
      );
    }

    if ((order.total - calculatedTotal).abs() > epsilon) {
      throw InvoiceValidationException(
        'Total inconsistente: calculado \$${_formatMoney(calculatedTotal)} vs almacenado \$${_formatMoney(order.total)}.',
      );
    }
  }

  InvoiceBusinessInfo _buildBusinessInfo(InvoiceConfig config) {
    final name = config.businessName.trim();
    if (name.isEmpty) {
      throw const InvoiceValidationException(
        'No esta configurado el nombre del establecimiento.',
      );
    }

    return InvoiceBusinessInfo(
      name: name,
      nit: config.businessNit.trim(),
      address: config.businessAddress.trim(),
      phone: config.businessPhone.trim(),
      logoBase64: config.logoBase64,
    );
  }

  InvoiceSaleInfo _buildSaleInfo(Order order, String sellerName) {
    return InvoiceSaleInfo(
      orderNumber: order.orderNumber,
      invoiceId: _formatInvoiceId(order),
      createdAt: order.createdAt,
      sellerName: sellerName.trim().isNotEmpty ? sellerName.trim() : 'Vendedor',
      statusLabel: order.status.label,
    );
  }

  InvoiceCustomerInfo _buildCustomerInfo(Order order) {
    final address = order.deliveryType == DeliveryType.delivery
        ? order.deliveryAddress
        : order.customerAddress;

    return InvoiceCustomerInfo(
      name: order.customerName?.trim().isNotEmpty == true
          ? order.customerName!
          : 'Cliente ocasional',
      phone: order.customerPhone?.trim(),
      address: address?.trim(),
    );
  }

  List<InvoiceItem> _buildItems(List<OrderItem> items) {
    return items.map((item) {
      // El total de linea se muestra como cantidad x precio unitario,
      // sin restar descuentos por item. Los descuentos se agrupan en la
      // linea de descuento del recibo.
      final lineTotal = item.unitPrice * item.quantity;
      return InvoiceItem(
        originalId: item.id,
        quantity: item.quantity,
        description: item.productName?.trim() ?? 'Producto',
        presentation: item.productPresentation?.trim(),
        unitPrice: item.unitPrice,
        lineTotal: lineTotal,
      );
    }).toList();
  }

  List<InvoicePayment> _buildPayments(List<Payment> payments) {
    return payments.map((payment) {
      return InvoicePayment(
        createdAt: payment.createdAt,
        methodLabel: payment.paymentMethod.label,
        amount: payment.amount,
      );
    }).toList();
  }

  String _formatInvoiceId(Order order) {
    final suffix = order.id.replaceAll('-', '').substring(0, 4).toUpperCase();
    return 'FE-${order.orderNumber.toString().padLeft(6, '0')}-$suffix';
  }

  void _logInvoice(
    Order order,
    List<InvoiceItem> items,
    double subtotal,
    double total,
  ) {
    debugPrint('');
    debugPrint('=== INVOICE BUILDER ===');
    debugPrint('Venta: ${order.id}');
    debugPrint('Factura: ${_formatInvoiceId(order)}');
    debugPrint('Items: ${items.length}');
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      debugPrint(
        '${i + 1}. ${item.fullDescription} x${item.quantity} @ \$${_formatMoney(item.unitPrice)} = \$${_formatMoney(item.lineTotal)}',
      );
    }
    debugPrint('Subtotal calculado: \$${_formatMoney(subtotal)}');
    debugPrint('Total calculado: \$${_formatMoney(total)}');
    debugPrint('Total almacenado: \$${_formatMoney(order.total)}');
    debugPrint('=======================');
    debugPrint('');
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }
}
