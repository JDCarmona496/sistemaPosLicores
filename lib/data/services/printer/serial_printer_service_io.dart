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
/// El paquete maneja SerialPort como singleton por nombre de puerto, así que
/// esta implementación reutiliza instancias para no crear puertos duplicados.
class SerialPrinterService implements PrinterService {
  // serial_port_win32 trata a SerialPort como singleton por nombre de puerto,
  // por lo que mantenemos un caché local para evitar crear instancias nuevas.
  final Map<String, SerialPort> _portCache = {};
  SerialPort? _activePort;

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

  SerialPort _getOrCreatePort(String portName) {
    final name = portName.toUpperCase();
    return _portCache.putIfAbsent(name, () => SerialPort(name));
  }

  @override
  Stream<bool> get connectionState => _connectionStateController.stream;

  @override
  Stream<List<PrinterDevice>> discoverDevices() async* {
    try {
      debugPrint('[SerialPrinterService] Solicitando lista de puertos COM...');
      final ports = SerialPort.getPortsWithFullMessages();
      final names = ports.map((p) => p.portName).toList();
      debugPrint('[SerialPrinterService] Puertos encontrados: $names');
      yield ports
          .map(
            (p) => PrinterDevice(
              address: p.portName,
              name: p.friendlyName.isNotEmpty
                  ? p.friendlyName
                  : 'Puerto ${p.portName}',
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

      // serial_port_win32 usa singleton por nombre de puerto.
      final port = _getOrCreatePort(targetPort);
      _activePort = port;

      // Cerrar primero por si había una instancia previa abierta
      if (port.isOpened) {
        try {
          port.close();
        } catch (e) {
          debugPrint('[SerialPrinterService] Error cerrando puerto previo: $e');
        }
      }

      // Intentar abrir el puerto con reintentos
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          debugPrint(
            '[SerialPrinterService] Abriendo $targetPort a ${config.baudRate} baudios (intento ${attempt + 1})...',
          );
          port.BaudRate = config.baudRate;
          port.ByteSize = 8;
          port.open();

          if (port.isOpened) break;
        } catch (e) {
          debugPrint('[SerialPrinterService] Intento ${attempt + 1} fallido: $e');
          if (attempt == 2) {
            _notifyConnectionState(false);
            return PrinterResult.error(
              'No se pudo abrir $targetPort después de 3 intentos: $e',
            );
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (!port.isOpened) {
        _notifyConnectionState(false);
        return PrinterResult.error('No se pudo abrir el puerto $targetPort');
      }

      // Activar señal DTR para impresoras térmicas que la requieren
      try {
        port.setFlowControlSignal(SerialPort.SETDTR);
      } catch (e) {
        debugPrint('[SerialPrinterService] No se pudo set DTR: $e');
      }

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
      _activePort = null;
      _notifyConnectionState(false);
      return PrinterResult.error('Error al abrir ${config.comPort}: $e');
    }
  }

  @override
  Future<PrinterResult> disconnect() async {
    if (_activePort == null) return const PrinterResult.success();
    try {
      _activePort!.close();
      _activePort = null;
      _notifyConnectionState(false);
      return const PrinterResult.success('Puerto cerrado');
    } catch (e) {
      _activePort = null;
      _notifyConnectionState(false);
      return PrinterResult.error('Error al cerrar puerto: $e');
    }
  }

  @override
  Future<PrinterResult> printBytes(Uint8List bytes) async {
    final port = _activePort;
    if (port == null || !port.isOpened) {
      return const PrinterResult.error('Puerto COM no abierto');
    }

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        debugPrint(
          '[SerialPrinterService] Enviando ${bytes.length} bytes (intento ${attempt + 1})...',
        );
        await port.writeBytesFromUint8List(bytes);
        debugPrint('[SerialPrinterService] Envío exitoso');
        return const PrinterResult.success();
      } catch (e) {
        debugPrint('[SerialPrinterService] Error al enviar (intento ${attempt + 1}): $e');
        if (attempt == 2) {
          _notifyConnectionState(false);
          return PrinterResult.error('Error al enviar datos: $e');
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return const PrinterResult.error('No se pudieron enviar los datos');
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
  bool get isConnected => _activePort != null && _activePort!.isOpened;

  @override
  Future<void> dispose() async {
    await disconnect();
    for (final port in _portCache.values) {
      try {
        if (port.isOpened) port.close();
      } catch (_) {}
    }
    _portCache.clear();
    await _connectionStateController.close();
  }
}
