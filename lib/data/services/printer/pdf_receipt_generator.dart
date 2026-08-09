import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/models/cash_count.dart';
import '../../../domain/models/cash_count_receipt_data.dart';
import '../../../domain/models/printer_config.dart';
import '../../../domain/models/validated_invoice.dart';
import '../../providers/printer_provider.dart';

/// Genera un documento PDF para tickets de impresoras termicas Windows.
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

  @override
  Future<pw.Document> generateOrderReceipt(ValidatedInvoice invoice) async {
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
              // Logo
              if (invoice.business.logoBase64?.isNotEmpty == true)
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(base64Decode(invoice.business.logoBase64!)),
                    height: 60,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              if (invoice.business.logoBase64?.isNotEmpty == true)
                pw.SizedBox(height: 8),

              // Encabezado del negocio: centrado, negrita y ancho completo.
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  invoice.business.name,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (invoice.business.nit?.isNotEmpty == true)
                pw.Container(
                  width: double.infinity,
                  child: pw.Text(
                    'NIT: ${invoice.business.nit}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              if (invoice.business.address?.isNotEmpty == true)
                pw.Container(
                  width: double.infinity,
                  child: pw.Text(
                    invoice.business.address!,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              if (invoice.business.phone?.isNotEmpty == true)
                pw.Container(
                  width: double.infinity,
                  child: pw.Text(
                    'Tel: ${invoice.business.phone}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              pw.SizedBox(height: 8),

              // Titulo y factura electronica
              pw.Center(
                child: pw.Text(
                  'FACTURA ELECTRONICA',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  invoice.sale.invoiceId,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),

              // Fecha y vendedor
              pw.Text(
                'Fecha: ${DateFormat('yyyy-MM-dd HH:mm').format((invoice.sale.createdAt ?? DateTime.now()).toLocal())}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Vendedor: ${invoice.sale.sellerName}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Estado: ${invoice.sale.statusLabel}',
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
                invoice.customer.name,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (invoice.customer.phone?.isNotEmpty == true)
                pw.Text(
                  'Tel: ${invoice.customer.phone}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              if (invoice.customer.address?.isNotEmpty == true)
                pw.Text(
                  'Dir: ${invoice.customer.address}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Forma de pago: ${invoice.saleTypeLabel}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              pw.Divider(height: 1),

              // Encabezados de items
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

              // Items
              ...invoice.items.map((item) => _buildItemRow(item)),

              pw.Divider(height: 1),
              pw.SizedBox(height: 4),

              // Totales
              _buildTotalRow('Subtotal:', invoice.subtotal),
              if (invoice.discountAmount > 0)
                _buildTotalRow('Descuento:', -invoice.discountAmount),
              if (invoice.deliveryFee > 0)
                _buildTotalRow('Domicilio:', invoice.deliveryFee),
              _buildTotalRow(
                'TOTAL:',
                invoice.total,
                isBold: true,
                fontSize: 11,
              ),

              pw.SizedBox(height: 8),

              // Pagos / Abonos
              pw.Center(
                child: pw.Text(
                  'PAGOS / ABONOS',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),

              if (invoice.payments.isEmpty)
                pw.Center(
                  child: pw.Text(
                    'No hay abonos registrados',
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                )
              else ...[
                ...invoice.payments.map((payment) {
                  final date = payment.createdAt != null
                      ? DateFormat('yyyy-MM-dd').format(
                          payment.createdAt!.toLocal(),
                        )
                      : 'N/A';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            date,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            payment.methodLabel,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            '\$${_formatMoney(payment.amount)}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                pw.Divider(height: 1),
                pw.SizedBox(height: 4),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total abonado:',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '\$${_formatMoney(invoice.totalPaid)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    if (invoice.balance > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Saldo pendiente:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '\$${_formatMoney(invoice.balance)}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Estado:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'PAGADO',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],

              pw.SizedBox(height: 8),

              // Entrega
              pw.Text(
                'Entrega: ${invoice.deliveryTypeLabel}',
                style: const pw.TextStyle(fontSize: 9),
              ),

              if (invoice.notes?.isNotEmpty == true) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Notas:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  invoice.notes!,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],

              // Pie: centrado y negrita
              pw.SizedBox(height: 16),
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  invoice.footer,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (invoice.legalText?.isNotEmpty == true) ...[
                pw.SizedBox(height: 4),
                pw.Container(
                  width: double.infinity,
                  child: pw.Text(
                    invoice.legalText!,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],

              // Pie de pagina fijo con creditos del desarrollador.
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  invoice.developerFooterTitle,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  invoice.developerFooterName,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  invoice.developerFooterPhone,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
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

  @override
  Future<pw.Document> generateCashCountReceipt(CashCountReceiptData data) async {
    final font = await _loadFont();
    final boldFont = await _loadBoldFont();
    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);

    final cashCount = data.cashCount;
    final config = data.invoiceConfig;

    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.Page(
        pageFormat: _pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Logo
              if (config.logoBase64.isNotEmpty)
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(base64Decode(config.logoBase64)),
                    height: 60,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              if (config.logoBase64.isNotEmpty)
                pw.SizedBox(height: 8),

              // Encabezado del negocio
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  config.businessName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (config.businessNit.trim().isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  child: pw.Text(
                    'NIT: ${config.businessNit}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              if (config.businessAddress.trim().isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  child: pw.Text(
                    config.businessAddress,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              if (config.businessPhone.trim().isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  child: pw.Text(
                    'Tel: ${config.businessPhone}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              pw.SizedBox(height: 8),

              // Titulo
              pw.Center(
                child: pw.Text(
                  'CONTEO DE CAJA',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),

              // Fecha y responsable
              pw.Text(
                'Fecha: ${DateFormat('yyyy-MM-dd HH:mm').format((cashCount.createdAt ?? DateTime.now()).toLocal())}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Responsable: ${data.responsibleName}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 8),

              pw.Divider(height: 1),

              // Encabezados
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        'DENOM',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'CANT',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
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

              // Filas
              ...cashCount.denominations
                  .where((d) => d.quantity > 0)
                  .map((d) => _buildCashCountDenominationRow(d)),

              pw.Divider(height: 1),
              pw.SizedBox(height: 4),

              // Totales
              _buildTotalRow('Total billetes:', cashCount.totalBills),
              _buildTotalRow('Total monedas:', cashCount.totalCoins),
              _buildTotalRow(
                'TOTAL EFECTIVO:',
                cashCount.total,
                isBold: true,
                fontSize: 11,
              ),

              if (cashCount.notes?.trim().isNotEmpty == true) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Notas:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  cashCount.notes!,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],

              // Pie
              pw.SizedBox(height: 16),
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  config.invoiceFooter.trim().isNotEmpty
                      ? config.invoiceFooter
                      : 'Conserve este recibo',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (config.legalText.trim().isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Container(
                  width: double.infinity,
                  child: pw.Text(
                    config.legalText,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  'Desarrollado por',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  'Juan D. Carmona',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  '3194643984',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
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

              // Informacion compacta
              if (config != null) ...[
                pw.Text(
                  config.connectionType.label,
                  style: const pw.TextStyle(fontSize: 9),
                ),
                if (config.name?.isNotEmpty == true)
                  pw.Text(config.name!, style: const pw.TextStyle(fontSize: 9)),
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
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toLocal()),
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

              // Informacion de debug
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
                ...debugInfo
                    .split('\n')
                    .where((l) => l.isNotEmpty)
                    .map(
                      (line) =>
                          pw.Text(line, style: const pw.TextStyle(fontSize: 9)),
                    ),
                pw.SizedBox(height: 8),
              ],

              // Lineas de prueba
              pw.Center(
                child: pw.Text(
                  'ABC abc 123 !@#\$%',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  '12345678901234567890123456789012',
                  style: const pw.TextStyle(fontSize: 9),
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

  pw.Widget _buildCashCountDenominationRow(CashCountDenomination denom) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              '\$${_formatMoney(denom.value.toDouble())}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              denom.quantity.toString(),
              style: const pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              '\$${_formatMoney(denom.subtotal)}',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemRow(InvoiceItem item) {
    final qty = item.quantity.toString();

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(qty, style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              item.fullDescription,
              style: const pw.TextStyle(fontSize: 9),
              softWrap: true,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              '\$${_formatMoney(item.lineTotal)}',
              style: const pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.right,
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
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

}
