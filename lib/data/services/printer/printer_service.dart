import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../../domain/models/printer_config.dart';

/// Resultado de una operación de impresión.
class PrinterResult {
  final bool success;
  final String message;

  const PrinterResult.success([this.message = 'Impreso correctamente'])
      : success = true;

  const PrinterResult.error(this.message) : success = false;
}

/// Información básica de una impresora descubierta.
class PrinterDevice {
  final String address;
  final String? name;
  final PrinterConnectionType connectionType;

  const PrinterDevice({
    required this.address,
    this.name,
    required this.connectionType,
  });
}

/// Contrato para cualquier servicio de impresión térmica.
abstract class PrinterService {
  /// Descubre impresoras disponibles según el tipo de conexión.
  Stream<List<PrinterDevice>> discoverDevices();

  /// Conecta a la impresora configurada.
  Future<PrinterResult> connect(PrinterConfig config);

  /// Desconecta la impresora.
  Future<PrinterResult> disconnect();

  /// Envía bytes ESC/POS a la impresora.
  Future<PrinterResult> printBytes(Uint8List bytes);

  /// Envía un documento PDF a la impresora (solo servicios nativos Windows).
  Future<PrinterResult> printPdf(pw.Document document) async {
    return const PrinterResult.error('PDF no soportado por este servicio');
  }

  /// Indica si el servicio puede imprimir documentos PDF.
  bool get supportsPdf => false;

  /// Indica si está conectado.
  bool get isConnected;

  /// Stream que notifica cambios de estado de conexión.
  Stream<bool> get connectionState;

  /// Libera recursos del servicio.
  Future<void> dispose();
}
