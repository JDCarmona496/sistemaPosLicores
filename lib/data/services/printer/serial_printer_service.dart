import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:serial_port_win32/serial_port_win32.dart';

import '../../../domain/models/printer_config.dart';
import 'printer_service.dart';

/// Implementación de [PrinterService] para puertos seriales COM en Windows.
/// Usa serial_port_win32 para enviar bytes ESC/POS directamente por COM.
class SerialPrinterService implements PrinterService {
  SerialPort? _port;

  @override
  Stream<List<PrinterDevice>> discoverDevices() async* {
    try {
      final ports = SerialPort.getAvailablePorts();
      yield ports
          .map(
            (name) => PrinterDevice(
              address: name,
              name: 'Puerto $name',
              connectionType: PrinterConnectionType.serial,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[SerialPrinterService] Error listando puertos: $e');
      yield [];
    }
  }

  @override
  Future<PrinterResult> connect(PrinterConfig config) async {
    try {
      await disconnect();

      _port = SerialPort(
        config.comPort,
        openNow: true,
        BaudRate: config.baudRate,
        ByteSize: 8,
      );

      return const PrinterResult.success('Conectado al puerto COM');
    } catch (e) {
      _port = null;
      return PrinterResult.error('Error al abrir ${config.comPort}: $e');
    }
  }

  @override
  Future<PrinterResult> disconnect() async {
    if (_port == null) return const PrinterResult.success();
    try {
      _port!.close();
      _port = null;
      return const PrinterResult.success('Puerto cerrado');
    } catch (e) {
      return PrinterResult.error('Error al cerrar puerto: $e');
    }
  }

  @override
  Future<PrinterResult> printBytes(Uint8List bytes) async {
    if (_port == null || !_port!.isOpened) {
      return const PrinterResult.error('Puerto COM no abierto');
    }
    try {
      await _port!.writeBytesFromUint8List(bytes);
      return const PrinterResult.success();
    } catch (e) {
      return PrinterResult.error('Error al enviar datos: $e');
    }
  }

  @override
  bool get isConnected => _port != null && _port!.isOpened;
}
