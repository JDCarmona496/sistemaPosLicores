import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../domain/models/printer_config.dart';
import 'printer_service.dart';

/// Implementación de [PrinterService] para impresoras Windows nativas.
///
/// Usa el paquete `printing` para descubrir impresoras del sistema y enviar
/// documentos PDF. Está pensada para impresoras térmicas POS-58/80 conectadas
/// por USB que se presentan como impresoras Windows (no como puerto COM).
class WindowsPrinterService implements PrinterService {
  Printer? _selectedPrinter;

  @override
  Stream<List<PrinterDevice>> discoverDevices() async* {
    try {
      final printers = await Printing.listPrinters();
      yield printers
          .map(
            (p) => PrinterDevice(
              address: p.url,
              name: p.name,
              connectionType: PrinterConnectionType.windows,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[WindowsPrinterService] Error listando impresoras: $e');
      yield [];
    }
  }

  @override
  Future<PrinterResult> connect(PrinterConfig config) async {
    try {
      final printers = await Printing.listPrinters();
      final printer = printers.firstWhere(
        (p) =>
            p.url == config.address ||
            (config.name != null && p.name == config.name),
        orElse: () => throw Exception('Impresora no encontrada'),
      );
      _selectedPrinter = printer;
      return const PrinterResult.success('Impresora seleccionada');
    } catch (e) {
      _selectedPrinter = null;
      return PrinterResult.error('Error al seleccionar impresora: $e');
    }
  }

  @override
  Future<PrinterResult> disconnect() async {
    _selectedPrinter = null;
    return const PrinterResult.success('Impresora deseleccionada');
  }

  @override
  Future<PrinterResult> printBytes(Uint8List bytes) async {
    return const PrinterResult.error(
      'Este servicio imprime PDF, no bytes ESC/POS',
    );
  }

  @override
  Future<PrinterResult> printPdf(pw.Document document) async {
    if (_selectedPrinter == null) {
      return const PrinterResult.error('No hay impresora seleccionada');
    }
    try {
      final saved = await document.save();
      final done = await Printing.directPrintPdf(
        printer: _selectedPrinter!,
        onLayout: (format) => saved,
        format: const PdfPageFormat(
          58 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
      );
      if (done) {
        return const PrinterResult.success();
      } else {
        return const PrinterResult.error('La impresora no aceptó el trabajo');
      }
    } catch (e) {
      return PrinterResult.error('Error al imprimir PDF: $e');
    }
  }

  @override
  bool get supportsPdf => true;

  @override
  bool get isConnected => _selectedPrinter != null;
}
