import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pdf/widgets.dart' as pw;
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
      debugPrint('[SerialPrinterService] Solicitando lista de puertos COM...');
      final ports = SerialPort.getAvailablePorts();
      debugPrint('[SerialPrinterService] Puertos encontrados: $ports');
      yield ports
          .map(
            (name) => PrinterDevice(
              address: name,
              name: 'Puerto $name',
              connectionType: PrinterConnectionType.serial,
            ),
          )
          .toList();
    } catch (e, stack) {
      debugPrint('[SerialPrinterService] Error listando puertos: $e');
      debugPrint('[SerialPrinterService] Stack: $stack');
      yield [];
    }
  }

  @override
  Future<PrinterResult> connect(PrinterConfig config) async {
    try {
      await disconnect();

      // Verificar si el puerto existe
      final availablePorts = SerialPort.getAvailablePorts();
      debugPrint('[SerialPrinterService] Puertos disponibles: $availablePorts');
      
      if (!availablePorts.contains(config.comPort)) {
        return PrinterResult.error(
          'El puerto ${config.comPort} no está disponible. '
          'Puertos encontrados: ${availablePorts.isEmpty ? "ninguno" : availablePorts.join(", ")}',
        );
      }

      debugPrint('[SerialPrinterService] Abriendo ${config.comPort} a ${config.baudRate} baudios...');
      _port = SerialPort(
        config.comPort,
        openNow: true,
        BaudRate: config.baudRate,
        ByteSize: 8,
      );

      if (!_port!.isOpened) {
        _port = null;
        return PrinterResult.error('No se pudo abrir el puerto ${config.comPort}');
      }

      debugPrint('[SerialPrinterService] Puerto ${config.comPort} abierto correctamente');
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
  Future<PrinterResult> printPdf(pw.Document document) async {
    return const PrinterResult.error(
      'Este servicio imprime bytes ESC/POS, no PDF',
    );
  }

  @override
  bool get supportsPdf => false;

  @override
  bool get isConnected => _port != null && _port!.isOpened;
}
