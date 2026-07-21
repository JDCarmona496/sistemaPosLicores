import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/order.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/models/printer_config.dart';
import '../../providers/printer_provider.dart';

/// Genera comandos ESC/POS para tickets de 58mm.
///
/// Especificaciones soportadas:
/// - Ancho de papel: 58mm
/// - Resolución: 203dpi
/// - Espesor de papel: 0.06-0.08mm
/// - Ancho útil de impresión: ~48mm (384 puntos)
/// - Caracteres por línea (fuente A 12x24): 32
class EscPosReceiptGenerator extends ReceiptGenerator {
  const EscPosReceiptGenerator({super.paperWidthMm = 58});

  Future<Uint8List> generateOrderReceipt({
    required Order order,
    required List<OrderItem> items,
    required String businessName,
    String? businessNit,
    String? businessAddress,
    String? businessPhone,
    String? sellerName,
    String? invoiceFooter,
    String? legalText,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperWidthMm == 58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );

    var bytes = <int>[];

    // Encabezado
    bytes += generator.setStyles(
      const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(businessName);
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    if (businessNit != null && businessNit.isNotEmpty) {
      bytes += generator.text('NIT: $businessNit');
    }
    if (businessAddress != null && businessAddress.isNotEmpty) {
      bytes += generator.text(businessAddress);
    }
    if (businessPhone != null && businessPhone.isNotEmpty) {
      bytes += generator.text('Tel: $businessPhone');
    }
    bytes += generator.feed(1);

    // Título
    bytes += generator.setStyles(
      const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text('ORDEN DE PEDIDO');
    bytes += generator.text(
      'No. ${order.orderNumber.toString().padLeft(6, '0')}',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.setStyles(const PosStyles());
    bytes += generator.feed(1);

    // Fecha y vendedor
    bytes += generator.text(
      'Fecha: ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt ?? DateTime.now())}',
    );
    bytes += generator.text('Vendedor: ${sellerName ?? order.sellerId}');
    bytes += generator.text('Estado: ${order.status.label}');
    bytes += generator.feed(1);

    // Cliente
    bytes += generator.text('Cliente:');
    bytes += generator.text(
      order.customerName?.isNotEmpty == true
          ? order.customerName!
          : 'Cliente ocasional',
      styles: const PosStyles(bold: true),
    );
    if (order.customerPhone?.isNotEmpty == true) {
      bytes += generator.text('Tel: ${order.customerPhone}');
    }
    if (order.customerAddress?.isNotEmpty == true) {
      bytes += generator.text('Dir: ${order.customerAddress}');
    }
    bytes += generator.feed(1);

    // Línea separadora
    bytes += generator.hr();

    // Encabezados de ítems
    bytes += generator.row([
      PosColumn(text: 'CANT', width: 2, styles: const PosStyles(bold: true)),
      PosColumn(text: 'DESCRIPCION', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: 'TOTAL',
        width: 4,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    // Ítems
    for (final item in items) {
      final name = item.productName ?? 'Producto';
      final qty = item.quantity.toStringAsFixed(
        item.quantity % 1 == 0 ? 0 : 1,
      );
      final total = '\$${_formatMoney(item.subtotal)}';

      // Primera línea: cantidad + nombre truncado
      bytes += generator.row([
        PosColumn(text: qty, width: 2),
        PosColumn(
          text: _truncate(name, 16),
          width: 6,
        ),
        PosColumn(
          text: total,
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      // Si el precio unitario es distinto al total, mostrar precio unitario
      if (item.quantity != 1) {
        bytes += generator.row([
          PosColumn(text: '', width: 2),
          PosColumn(
            text: 'x \$${_formatMoney(item.unitPrice)}',
            width: 8,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(text: '', width: 2),
        ]);
      }
    }

    bytes += generator.hr();

    // Totales
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 6),
      PosColumn(
        text: '\$${_formatMoney(order.subtotal)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (order.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Descuento:', width: 6),
        PosColumn(
          text: '-\$${_formatMoney(order.discountAmount)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    if (order.deliveryFee > 0) {
      bytes += generator.row([
        PosColumn(text: 'Domicilio:', width: 6),
        PosColumn(
          text: '\$${_formatMoney(order.deliveryFee)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.row([
      PosColumn(
        text: 'TOTAL:',
        width: 4,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: '\$${_formatMoney(order.total)}',
        width: 8,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    ]);

    bytes += generator.feed(1);

    // Tipo de venta y entrega
    bytes += generator.text('Venta: ${order.saleType.label}');
    bytes += generator.text('Entrega: ${order.deliveryType.label}');

    if (order.notes?.isNotEmpty == true) {
      bytes += generator.feed(1);
      bytes += generator.text('Notas:');
      bytes += generator.text(order.notes!);
    }

    // Pie
    bytes += generator.feed(2);
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));

    final footer = invoiceFooter ?? 'Gracias por su compra';
    bytes += generator.text(footer);

    if (legalText != null && legalText.isNotEmpty) {
      bytes += generator.feed(1);
      bytes += generator.setStyles(
        const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(legalText);
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  /// Genera una página de prueba compacta con información básica de la
  /// impresora y del dispositivo. Se mantiene corta para evitar problemas
  /// con impresoras BLE que no aceptan trabajos largos.
  Future<Uint8List> generateTestPage({
    PrinterConfig? config,
    String? debugInfo,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperWidthMm == 58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );

    var bytes = <int>[];

    // Título
    bytes += generator.setStyles(
      const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text('PAGINA DE PRUEBA');
    bytes += generator.feed(1);

    // Información compacta en una sola sección
    bytes += generator.setStyles(const PosStyles());
    if (config != null) {
      bytes += generator.text(config.connectionType.label);
      if (config.name?.isNotEmpty == true) {
        bytes += generator.text(config.name!);
      }
      if (config.address?.isNotEmpty == true) {
        bytes += generator.text(config.address!);
      }
      if (config.connectionType == PrinterConnectionType.serial) {
        bytes += generator.text('${config.baudRate} baud');
      }
    } else {
      bytes += generator.text('Sin configurar');
    }
    bytes += generator.text('${paperWidthMm}mm | ${defaultTargetPlatform.name}');
    bytes += generator.text(
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );
    bytes += generator.feed(1);

    // Estado
    bytes += generator.setStyles(
      const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text('IMPRESION OK');
    bytes += generator.setStyles(const PosStyles());
    bytes += generator.feed(1);

    // Información de debug
    if (debugInfo != null && debugInfo.isNotEmpty) {
      bytes += generator.hr();
      bytes += generator.text('DEBUG:', styles: const PosStyles(bold: true));
      for (final line in debugInfo.split('\n')) {
        if (line.isNotEmpty) {
          bytes += generator.text(line);
        }
      }
      bytes += generator.feed(1);
    }

    // Línea de prueba
    bytes += generator.text('12345678901234567890123456789012');
    bytes += generator.feed(2);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 1)}~';
  }
}
