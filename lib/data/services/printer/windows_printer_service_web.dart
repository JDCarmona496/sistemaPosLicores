import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/models/printer_config.dart';
import 'printer_service.dart';

/// Stub de [PrinterService] para web.
/// La impresión nativa de Windows no está disponible en navegadores.
class WindowsPrinterService implements PrinterService {
  @override
  Stream<List<PrinterDevice>> discoverDevices() async* {
    debugPrint('[WindowsPrinterService] Web: no soportado');
    yield [];
  }

  @override
  Future<PrinterResult> connect(PrinterConfig config) async {
    debugPrint('[WindowsPrinterService] Web: no soportado');
    return const PrinterResult.error(
      'La impresión Windows nativa no está disponible en web',
    );
  }

  @override
  Future<PrinterResult> disconnect() async {
    return const PrinterResult.success();
  }

  @override
  Future<PrinterResult> printBytes(Uint8List bytes) async {
    return const PrinterResult.error(
      'La impresión Windows nativa no está disponible en web',
    );
  }

  @override
  Future<PrinterResult> printPdf(pw.Document document) async {
    return const PrinterResult.error(
      'La impresión Windows nativa no está disponible en web',
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
