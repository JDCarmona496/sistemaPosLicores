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
  final _connectionStateController = StreamController<bool>.broadcast();
  var _lastConnectionState = false;

  WindowsPrinterService() {
    _connectionStateController.add(false);
  }

  void _notifyConnectionState(bool connected) {
    if (_lastConnectionState != connected) {
      _lastConnectionState = connected;
      _connectionStateController.add(connected);
      debugPrint('[WindowsPrinterService] connectionState=$connected');
    }
  }

  @override
  Stream<bool> get connectionState => _connectionStateController.stream;

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
      _notifyConnectionState(true);
      return const PrinterResult.success('Impresora seleccionada');
    } catch (e) {
      _selectedPrinter = null;
      _notifyConnectionState(false);
      return PrinterResult.error('Error al seleccionar impresora: $e');
    }
  }

  @override
  Future<PrinterResult> disconnect() async {
    _selectedPrinter = null;
    _notifyConnectionState(false);
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

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        debugPrint('[WindowsPrinterService] printPdf attempt ${attempt + 1}');
        final saved = await document.save();
        final done = await Printing.directPrintPdf(
          printer: _selectedPrinter!,
          onLayout: (format) => saved,
          format: const PdfPageFormat(
            58 * PdfPageFormat.mm,
            200 * PdfPageFormat.mm,
            marginAll: 4 * PdfPageFormat.mm,
          ),
        );
        if (done) {
          return const PrinterResult.success();
        } else {
          debugPrint('[WindowsPrinterService] Printer rejected job, retrying...');
        }
      } catch (e) {
        debugPrint('[WindowsPrinterService] printPdf attempt ${attempt + 1} error: $e');
        if (attempt == 2) {
          return PrinterResult.error('Error al imprimir PDF: $e');
        }
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    return const PrinterResult.error('La impresora no aceptó el trabajo');
  }

  @override
  bool get supportsPdf => true;

  @override
  bool get isConnected => _selectedPrinter != null;

  @override
  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
  }
}
