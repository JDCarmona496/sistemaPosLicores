import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/models/printer_config.dart';
import 'printer_service.dart';

/// Stub de [PrinterService] para web.
/// La impresión por puerto COM no está disponible en navegadores.
class SerialPrinterService implements PrinterService {
  @override
  Stream<List<PrinterDevice>> discoverDevices() async* {
    debugPrint('[SerialPrinterService] Web: descubrimiento no soportado');
    yield [];
  }

  @override
  Future<PrinterResult> connect(PrinterConfig config) async {
    debugPrint('[SerialPrinterService] Web: conexión no soportada');
    return const PrinterResult.error(
      'La impresión por puerto COM no está disponible en web',
    );
  }

  @override
  Future<PrinterResult> disconnect() async {
    return const PrinterResult.success();
  }

  @override
  Future<PrinterResult> printBytes(Uint8List bytes) async {
    debugPrint('[SerialPrinterService] Web: impresión no soportada');
    return const PrinterResult.error(
      'La impresión por puerto COM no está disponible en web',
    );
  }

  @override
  Future<PrinterResult> printPdf(pw.Document document) async {
    return const PrinterResult.error(
      'La impresión por puerto COM no está disponible en web',
    );
  }

  @override
  bool get supportsPdf => false;

  @override
  bool get isConnected => false;

  @override
  Stream<bool> get connectionState => Stream.value(false);

  @override
  Future<void> dispose() async {}
}
