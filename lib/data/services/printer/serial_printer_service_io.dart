import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pdf/widgets.dart' as pw;
import 'package:serial_port_win32/serial_port_win32.dart';

import '../../../domain/models/printer_config.dart';
import 'printer_service.dart';

/// Implementación de [PrinterService] para puertos seriales COM en Windows.
///
/// Usa serial_port_win32 para enviar bytes ESC/POS directamente por COM.
class SerialPrinterService implements PrinterService {
  SerialPort? _port;
  final _connectionStateController = StreamController<bool>.broadcast();
  var _lastConnectionState = false;

  SerialPrinterService() {
    _connectionStateController.add(false);
  }

  void _notifyConnectionState(bool connected) {
    if (_lastConnectionState != connected) {
      _lastConnectionState = connected;
      _connectionStateController.add(connected);
      debugPrint('[SerialPrinterService] connectionState=$connected');
    }
  }

  @override
  Stream<bool> get connectionState => _connectionStateController.stream;

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

      final targetPort = config.comPort.trim().toUpperCase();
      if (targetPort.isEmpty) {
        return const PrinterResult.error('Puerto COM no configurado');
      }

      // Verificar si el puerto existe
      List<String> availablePorts = [];
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          availablePorts = SerialPort.getAvailablePorts();
          if (availablePorts.contains(targetPort)) break;
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          debugPrint('[SerialPrinterService] Error listando puertos (intento ${attempt + 1}): $e');
        }
      }

      debugPrint('[SerialPrinterService] Puertos disponibles: $availablePorts');

      if (!availablePorts.contains(targetPort)) {
        return PrinterResult.error(
          'El puerto $targetPort no está disponible. '
          'Puertos encontrados: ${availablePorts.isEmpty ? "ninguno" : availablePorts.join(", ")}',
        );
      }

      // Intentar abrir el puerto con reintentos
      SerialPort? port;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          debugPrint(
            '[SerialPrinterService] Abriendo $targetPort a ${config.baudRate} baudios (intento ${attempt + 1})...',
          );
          port = SerialPort(
            targetPort,
            openNow: true,
            BaudRate: config.baudRate,
            ByteSize: 8,
          );
          if (port.isOpened) break;
          port.close();
          port = null;
        } catch (e) {
          debugPrint('[SerialPrinterService] Intento ${attempt + 1} fallido: $e');
          if (attempt == 2) {
            return PrinterResult.error(
              'No se pudo abrir $targetPort después de 3 intentos: $e',
            );
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (port == null || !port.isOpened) {
        _port = null;
        _notifyConnectionState(false);
        return PrinterResult.error('No se pudo abrir el puerto $targetPort');
      }

      _port = port;
      _notifyConnectionState(true);

      // Enviar bytes de reset ESC/POS para verificar que el puerto responde
      try {
        await port.writeBytesFromUint8List(Uint8List.fromList([0x1B, 0x40]));
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('[SerialPrinterService] Advertencia: no se pudo enviar reset inicial: $e');
      }

      debugPrint('[SerialPrinterService] Puerto $targetPort abierto correctamente');
      return const PrinterResult.success('Conectado al puerto COM');
    } catch (e) {
      _port = null;
      _notifyConnectionState(false);
      return PrinterResult.error('Error al abrir ${config.comPort}: $e');
    }
  }

  @override
  Future<PrinterResult> disconnect() async {
    if (_port == null) return const PrinterResult.success();
    try {
      _port!.close();
      _port = null;
      _notifyConnectionState(false);
      return const PrinterResult.success('Puerto cerrado');
    } catch (e) {
      _port = null;
      _notifyConnectionState(false);
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
      _notifyConnectionState(false);
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

  @override
  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
  }
}
