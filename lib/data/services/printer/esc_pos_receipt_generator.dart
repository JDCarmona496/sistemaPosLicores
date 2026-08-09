import 'dart:convert';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../../../domain/models/cash_count_receipt_data.dart';
import '../../../domain/models/printer_config.dart';
import '../../../domain/models/validated_invoice.dart';
import '../../providers/printer_provider.dart';

/// Genera comandos ESC/POS para tickets de 58mm.
///
/// Especificaciones soportadas:
/// - Ancho de papel: 58mm
/// - Resolucion: 203dpi
/// - Espesor de papel: 0.06-0.08mm
/// - Ancho util de impresion: ~48mm (384 puntos)
/// - Caracteres por linea (fuente A 12x24): 32
class EscPosReceiptGenerator extends ReceiptGenerator {
  const EscPosReceiptGenerator({super.paperWidthMm = 58});

  @override
  Future<Uint8List> generateOrderReceipt(ValidatedInvoice invoice) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperWidthMm == 58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );

    var bytes = <int>[];

    // Logo
    final logoBase64 = invoice.business.logoBase64;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      try {
        final decoded = base64Decode(logoBase64);
        final image = img.decodeImage(decoded);
        if (image != null) {
          bytes += generator.imageRaster(image, align: PosAlign.center);
          bytes += generator.feed(1);
        }
      } catch (e) {
        debugPrint('[EscPosReceiptGenerator] Error imprimiendo logo: $e');
      }
    }

    // Encabezado del negocio: centrado y negrita.
    bytes += generator.text(
      invoice.business.name,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    if (invoice.business.nit?.isNotEmpty == true) {
      bytes += generator.text(
        'NIT: ${invoice.business.nit}',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    if (invoice.business.address?.isNotEmpty == true) {
      bytes += generator.text(
        invoice.business.address!,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    if (invoice.business.phone?.isNotEmpty == true) {
      bytes += generator.text(
        'Tel: ${invoice.business.phone}',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    bytes += generator.feed(1);

    // Titulo y factura electronica
    bytes += generator.text(
      'FACTURA ELECTRONICA',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      invoice.sale.invoiceId,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);

    // Fecha y vendedor
    bytes += generator.text(
      'Fecha: ${DateFormat('yyyy-MM-dd HH:mm').format((invoice.sale.createdAt ?? DateTime.now()).toLocal())}',
    );
    bytes += generator.text('Vendedor: ${invoice.sale.sellerName}');
    bytes += generator.text('Estado: ${invoice.sale.statusLabel}');
    bytes += generator.feed(1);

    // Cliente
    bytes += generator.text('Cliente:');
    bytes += generator.text(
      invoice.customer.name,
      styles: const PosStyles(bold: true),
    );
    if (invoice.customer.phone?.isNotEmpty == true) {
      bytes += generator.text('Tel: ${invoice.customer.phone}');
    }
    if (invoice.customer.address?.isNotEmpty == true) {
      bytes += generator.text('Dir: ${invoice.customer.address}');
    }
    bytes += generator.feed(1);
    bytes += generator.text(
      'Forma de pago: ${invoice.saleTypeLabel}',
      styles: const PosStyles(bold: true),
    );
    bytes += generator.feed(1);

    // Linea separadora
    bytes += generator.hr();

    // Items con soporte multilinea para descripciones largas.
    bytes += _buildItemHeader(generator);

    for (final item in invoice.items) {
      bytes += _buildItemRows(generator, item);
    }

    bytes += generator.hr();

    // Totales
    bytes += _buildTotalRow(generator, 'Subtotal:', invoice.subtotal);

    if (invoice.discountAmount > 0) {
      bytes += _buildTotalRow(generator, 'Descuento:', -invoice.discountAmount);
    }

    if (invoice.deliveryFee > 0) {
      bytes += _buildTotalRow(generator, 'Domicilio:', invoice.deliveryFee);
    }

    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(
        text: '\$${_formatMoney(invoice.total)}',
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

    // Pagos / Abonos
    bytes += generator.setStyles(
      const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text('PAGOS / ABONOS');
    bytes += generator.setStyles(const PosStyles());

    if (invoice.payments.isEmpty) {
      bytes += generator.text('No hay abonos registrados');
    } else {
      for (final payment in invoice.payments) {
        final date = payment.createdAt != null
            ? DateFormat('yyyy-MM-dd').format(payment.createdAt!.toLocal())
            : 'N/A';
        bytes += generator.row([
          PosColumn(
            text: date,
            width: 5,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: payment.methodLabel,
            width: 4,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: '\$${_formatMoney(payment.amount)}',
            width: 3,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]);
      }

      bytes += generator.hr();

      bytes += _buildTotalRow(generator, 'Total abonado:', invoice.totalPaid);

      if (invoice.balance > 0) {
        bytes += _buildTotalRow(generator, 'Saldo pendiente:', invoice.balance);
      } else {
        bytes += _buildTotalRow(generator, 'Estado:', 0, customValue: 'PAGADO');
      }
    }

    bytes += generator.feed(1);

    // Entrega
    bytes += generator.text('Entrega: ${invoice.deliveryTypeLabel}');

    if (invoice.notes?.isNotEmpty == true) {
      bytes += generator.feed(1);
      bytes += generator.text('Notas:');
      bytes += generator.text(invoice.notes!);
    }

    // Pie: centrado y negrita
    bytes += generator.feed(2);

    const footerStyles = PosStyles(
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size1,
      width: PosTextSize.size1,
    );

    bytes += generator.text(invoice.footer, styles: footerStyles);

    if (invoice.legalText?.isNotEmpty == true) {
      bytes += generator.feed(1);
      bytes += generator.text(invoice.legalText!, styles: footerStyles);
    }

    // Pie de pagina fijo con creditos del desarrollador.
    bytes += generator.feed(2);
    bytes += generator.text(invoice.developerFooterTitle, styles: footerStyles);
    bytes += generator.text(invoice.developerFooterName, styles: footerStyles);
    bytes += generator.text(invoice.developerFooterPhone, styles: footerStyles);

    bytes += generator.feed(2);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List> generateCashCountReceipt(CashCountReceiptData data) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperWidthMm == 58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );

    final cashCount = data.cashCount;
    final config = data.invoiceConfig;

    var bytes = <int>[];

    // Logo
    final logoBase64 = config.logoBase64;
    if (logoBase64.isNotEmpty) {
      try {
        final decoded = base64Decode(logoBase64);
        final image = img.decodeImage(decoded);
        if (image != null) {
          bytes += generator.imageRaster(image, align: PosAlign.center);
          bytes += generator.feed(1);
        }
      } catch (e) {
        debugPrint('[EscPosReceiptGenerator] Error imprimiendo logo: $e');
      }
    }

    // Encabezado del negocio
    bytes += generator.text(
      config.businessName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    if (config.businessNit.trim().isNotEmpty) {
      bytes += generator.text(
        'NIT: ${config.businessNit}',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    if (config.businessAddress.trim().isNotEmpty) {
      bytes += generator.text(
        config.businessAddress,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    if (config.businessPhone.trim().isNotEmpty) {
      bytes += generator.text(
        'Tel: ${config.businessPhone}',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    bytes += generator.feed(1);

    // Titulo
    bytes += generator.text(
      'CONTEO DE CAJA',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(1);

    // Fecha y responsable
    bytes += generator.text(
      'Fecha: ${DateFormat('yyyy-MM-dd HH:mm').format((cashCount.createdAt ?? DateTime.now()).toLocal())}',
    );
    bytes += generator.text('Responsable: ${data.responsibleName}');
    bytes += generator.feed(1);

    bytes += generator.hr();

    // Encabezados de tabla
    final denomWidth = paperWidthMm == 58 ? 4 : 5;
    final qtyWidth = 2;
    final totalWidth = 12 - denomWidth - qtyWidth;

    bytes += generator.row([
      PosColumn(
        text: 'DENOM',
        width: denomWidth,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: 'CANT',
        width: qtyWidth,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        text: 'TOTAL',
        width: totalWidth,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    // Filas
    for (final denom in cashCount.denominations.where((d) => d.quantity > 0)) {
      bytes += generator.row([
        PosColumn(
          text: '\$${_formatMoney(denom.value.toDouble())}',
          width: denomWidth,
        ),
        PosColumn(
          text: denom.quantity.toString(),
          width: qtyWidth,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: '\$${_formatMoney(denom.subtotal)}',
          width: totalWidth,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    }

    bytes += generator.hr();

    // Totales
    bytes += _buildTotalRow(generator, 'Total billetes:', cashCount.totalBills);
    bytes += _buildTotalRow(generator, 'Total monedas:', cashCount.totalCoins);
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: '\$${_formatMoney(cashCount.total)}',
        width: 6,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    ]);

    if (cashCount.notes?.trim().isNotEmpty == true) {
      bytes += generator.feed(1);
      bytes += generator.text('Notas:');
      bytes += generator.text(cashCount.notes!);
    }

    // Pie
    bytes += generator.feed(2);
    const footerStyles = PosStyles(
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size1,
      width: PosTextSize.size1,
    );

    final footer = config.invoiceFooter.trim().isNotEmpty
        ? config.invoiceFooter
        : 'Conserve este recibo';
    bytes += generator.text(footer, styles: footerStyles);

    if (config.legalText.trim().isNotEmpty) {
      bytes += generator.feed(1);
      bytes += generator.text(config.legalText, styles: footerStyles);
    }

    bytes += generator.feed(2);
    bytes += generator.text('Desarrollado por', styles: footerStyles);
    bytes += generator.text('Juan D. Carmona', styles: footerStyles);
    bytes += generator.text('3194643984', styles: footerStyles);

    bytes += generator.feed(2);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  // --------------------------------------------------------------------------
  // Helpers de formato de items con soporte multilinea
  // --------------------------------------------------------------------------

  int get _lineWidth => paperWidthMm == 58 ? 32 : 48;
  int get _qtyWidth => 4;
  int get _totalWidth => 11;
  int get _descWidth => _lineWidth - _qtyWidth - _totalWidth - 2;

  List<int> _buildItemHeader(Generator generator) {
    final qty = 'CANT'.padLeft(_qtyWidth);
    final desc = 'DESCRIPCION'.padRight(_descWidth);
    final total = 'TOTAL'.padLeft(_totalWidth);
    return generator.text(
      '$qty $desc $total',
      styles: const PosStyles(bold: true),
    );
  }

  List<int> _buildItemRows(Generator generator, InvoiceItem item) {
    var bytes = <int>[];
    final description = item.fullDescription;
    final qty = item.quantity.toString().padLeft(_qtyWidth);
    final total = '\$${_formatMoney(item.lineTotal)}'.padLeft(_totalWidth);
    final descChunks = _wrapText(description, _descWidth);

    for (var i = 0; i < descChunks.length; i++) {
      final chunk = descChunks[i];
      if (i == 0) {
        final line = '$qty ${chunk.padRight(_descWidth)} $total';
        bytes += generator.text(line);
      } else {
        final indent = ''.padLeft(_qtyWidth + 1);
        final line =
            '$indent${chunk.padRight(_descWidth)} ${''.padLeft(_totalWidth)}';
        bytes += generator.text(line);
      }
    }

    return bytes;
  }

  List<int> _buildTotalRow(
    Generator generator,
    String label,
    double value, {
    String? customValue,
  }) {
    return generator.row([
      PosColumn(text: label, width: 6),
      PosColumn(
        text: customValue ?? '\$${_formatMoney(value)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
  }

  /// Divide un texto en lineas de ancho maximo respetando palabras cuando
  /// sea posible.
  List<String> _wrapText(String text, int maxWidth) {
    if (text.length <= maxWidth) return [text];

    final lines = <String>[];
    final words = text.split(' ');
    var current = '';

    for (final word in words) {
      if (word.length > maxWidth) {
        if (current.isNotEmpty) {
          lines.add(current.trim());
          current = '';
        }
        for (var i = 0; i < word.length; i += maxWidth) {
          lines.add(word.substring(i, (i + maxWidth).clamp(0, word.length)));
        }
        continue;
      }

      final candidate = current.isEmpty ? word : '$current $word';
      if (candidate.length > maxWidth) {
        lines.add(current.trim());
        current = word;
      } else {
        current = candidate;
      }
    }

    if (current.isNotEmpty) {
      lines.add(current.trim());
    }

    return lines;
  }

  /// Genera una pagina de prueba compacta con informacion basica de la
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

    // Titulo
    bytes += generator.setStyles(
      const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text('PAGINA DE PRUEBA');
    bytes += generator.feed(1);

    // Informacion compacta en una sola seccion
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
    bytes += generator.text(
      '${paperWidthMm}mm | ${defaultTargetPlatform.name}',
    );
    bytes += generator.text(
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toLocal()),
    );
    bytes += generator.feed(1);

    // Estado
    bytes += generator.setStyles(
      const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text('IMPRESION OK');
    bytes += generator.setStyles(const PosStyles());
    bytes += generator.feed(1);

    // Informacion de debug
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

    // Linea de prueba
    bytes += generator.text('12345678901234567890123456789012');
    bytes += generator.feed(2);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  String _formatMoney(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }
}
