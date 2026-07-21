import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/models/order.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/models/printer_config.dart';
import '../../providers/printer_provider.dart';

/// Genera un documento PDF para tickets de impresoras térmicas Windows.
///
/// El driver POS-58 de Windows se encarga de convertir el PDF a comandos
/// ESC/POS. Se usa con [WindowsPrinterService].
class PdfReceiptGenerator extends ReceiptGenerator {
  const PdfReceiptGenerator({super.paperWidthMm = 58});

  PdfPageFormat get _pageFormat {
    if (paperWidthMm == 58) {
      return PdfPageFormat(
        58 * PdfPageFormat.mm,
        double.infinity,
        marginAll: 4 * PdfPageFormat.mm,
      );
    }
    return PdfPageFormat.roll80;
  }

  Future<pw.Document> generateOrderReceipt({
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
    final font = await _loadFont();
    final boldFont = await _loadBoldFont();
    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);

    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.Page(
        pageFormat: _pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              pw.Center(
                child: pw.Text(
                  businessName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (businessNit != null && businessNit.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'NIT: $businessNit',
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              if (businessAddress != null && businessAddress.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    businessAddress,
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              if (businessPhone != null && businessPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'Tel: $businessPhone',
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              pw.SizedBox(height: 8),

              // Título
              pw.Center(
                child: pw.Text(
                  'ORDEN DE PEDIDO',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'No. ${order.orderNumber.toString().padLeft(6, '0')}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),

              // Fecha y vendedor
              pw.Text(
                'Fecha: ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt ?? DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Vendedor: ${sellerName ?? order.sellerId}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Estado: ${order.status.label}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 8),

              // Cliente
              pw.Text(
                'Cliente:',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                order.customerName?.isNotEmpty == true
                    ? order.customerName!
                    : 'Cliente ocasional',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (order.customerPhone?.isNotEmpty == true)
                pw.Text(
                  'Tel: ${order.customerPhone}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              if (order.customerAddress?.isNotEmpty == true)
                pw.Text(
                  'Dir: ${order.customerAddress}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              pw.SizedBox(height: 8),

              pw.Divider(height: 1),

              // Encabezados de ítems
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'CANT',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.left,
                      ),
                    ),
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        'DESCRIPCION',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'TOTAL',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              // Ítems
              ...items.map((item) => _buildItemRow(item)),

              pw.Divider(height: 1),
              pw.SizedBox(height: 4),

              // Totales
              _buildTotalRow('Subtotal:', order.subtotal),
              if (order.discountAmount > 0)
                _buildTotalRow('Descuento:', -order.discountAmount),
              if (order.deliveryFee > 0)
                _buildTotalRow('Domicilio:', order.deliveryFee),
              _buildTotalRow(
                'TOTAL:',
                order.total,
                isBold: true,
                fontSize: 11,
              ),

              pw.SizedBox(height: 8),

              // Tipo de venta y entrega
              pw.Text(
                'Venta: ${order.saleType.label}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Entrega: ${order.deliveryType.label}',
                style: const pw.TextStyle(fontSize: 9),
              ),

              if (order.notes?.isNotEmpty == true) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Notas:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  order.notes!,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],

              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  invoiceFooter ?? 'Gracias por su compra',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (legalText != null && legalText.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    legalText,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<pw.Document> generateTestPage({
    PrinterConfig? config,
    String? debugInfo,
  }) async {
    final font = await _loadFont();
    final boldFont = await _loadBoldFont();
    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);

    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.Page(
        pageFormat: _pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  'PAGINA DE PRUEBA',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 8),

              // Información compacta
              if (config != null) ...[
                pw.Text(
                  config.connectionType.label,
                  style: const pw.TextStyle(fontSize: 9),
                ),
                if (config.name?.isNotEmpty == true)
                  pw.Text(
                    config.name!,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (config.address?.isNotEmpty == true)
                  pw.Text(
                    config.address!,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (config.connectionType == PrinterConnectionType.serial)
                  pw.Text(
                    '${config.baudRate} baud',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
              ] else
                pw.Text(
                  'Sin configurar',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              pw.Text(
                '${paperWidthMm}mm | ${defaultTargetPlatform.name}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 8),

              // Estado
              pw.Center(
                child: pw.Text(
                  'IMPRESION OK',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 8),

              // Información de debug
              if (debugInfo != null && debugInfo.isNotEmpty) ...[
                pw.Divider(height: 1),
                pw.SizedBox(height: 4),
                pw.Text(
                  'DEBUG:',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                ...debugInfo.split('\n').where((l) => l.isNotEmpty).map(
                      (line) => pw.Text(
                        line,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                pw.SizedBox(height: 8),
              ],

              // Líneas de prueba
              pw.Center(
                child: pw.Text(
                  'ABC abc 123 !@#\$%',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  '12345678901234567890123456789012',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildItemRow(OrderItem item) {
    final name = item.productName ?? 'Producto';
    final qty = item.quantity.toStringAsFixed(
      item.quantity % 1 == 0 ? 0 : 1,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  qty,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Expanded(
                flex: 5,
                child: pw.Text(
                  _truncate(name, 18),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  '\$${_formatMoney(item.subtotal)}',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          if (item.quantity != 1)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 28),
              child: pw.Text(
                'x \$${_formatMoney(item.unitPrice)}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    double value, {
    bool isBold = false,
    double fontSize = 9,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '\$${_formatMoney(value)}',
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.Font> _loadFont() async {
    // Usa la fuente Helvetica incluida en el paquete pdf.
    return pw.Font.helvetica();
  }

  Future<pw.Font> _loadBoldFont() async {
    return pw.Font.helveticaBold();
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
