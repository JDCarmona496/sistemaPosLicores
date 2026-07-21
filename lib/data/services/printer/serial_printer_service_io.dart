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
/// Incluye diagnósticos detallados y manejo defensivo para puertos virtuales
/// (p. ej. Nuvoton Virtual COM Port) que pueden necesitar inicialización especial.
class SerialPrinterService implements PrinterService {
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
    debugPrint(
      '[SerialPrinterService] CONNECT START comPort=${config.comPort} baudRate=${config.baudRate}',
    );

    try {
      await disconnect();

      final targetPort = config.comPort.trim().toUpperCase();
      if (targetPort.isEmpty) {
        return const PrinterResult.error('Puerto COM no configurado');
      }

      // Verificar si el puerto existe en el sistema
      List<String> availablePorts = [];
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          availablePorts = SerialPort.getAvailablePorts();
          debugPrint('[SerialPrinterService] Intento ${attempt + 1}: puertos=$availablePorts');
          if (availablePorts.contains(targetPort)) break;
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint('[SerialPrinterService] Error listando puertos (intento ${attempt + 1}): $e');
        }
      }

      if (!availablePorts.contains(targetPort)) {
        return PrinterResult.error(
          'El puerto $targetPort no está disponible. '
          'Puertos encontrados: ${availablePorts.isEmpty ? "ninguno" : availablePorts.join(", ")}',
        );
      }

      // Intentar abrir de varias formas porque los puertos virtuales (Nuvoton, etc.)
      // a veces fallan con una combinación de parámetros pero aceptan otra.
      final strategies = <String, Future<SerialPort> Function()>{
        'openNow con baudRate': () async => _tryOpenWithConstructor(targetPort, config.baudRate),
        'open() luego de setear baudRate': () async => _tryOpenWithSetters(targetPort, config.baudRate),
        'openWithSettings': () async => _tryOpenWithSettings(targetPort, config.baudRate),
      };

      SerialPort? port;
      String? lastError;
      for (final entry in strategies.entries) {
        try {
          debugPrint('[SerialPrinterService] Probando estrategia: ${entry.key}');
          port = await entry.value();
          if (port.isOpened) {
            debugPrint('[SerialPrinterService] Estrategia exitosa: ${entry.key}');
            break;
          }
        } catch (e) {
          lastError = 'Estrategia ${entry.key} falló: $e';
          debugPrint('[SerialPrinterService] $lastError');
          port = null;
        }
      }

      if (port == null || !port.isOpened) {
        _notifyConnectionState(false);
        return PrinterResult.error(
          'No se pudo abrir $targetPort. '
          '${lastError ?? "Verifica que ninguna otra aplicación esté usando el puerto."}',
        );
      }

      _activePort = port;

      // Pausa para que el puerto virtual (USB-UART) termine de inicializarse.
      await Future.delayed(const Duration(milliseconds: 200));

      // Activar líneas de control. Algunos adaptadores virtuales requieren DTR o RTS.
      await _setControlLines(port);

      _notifyConnectionState(true);

      // Enviar reset ESC/POS y heartbeat para verificar que el puerto responde
      try {
        await port.writeBytesFromUint8List(Uint8List.fromList([0x1B, 0x40]));
        await Future.delayed(const Duration(milliseconds: 150));
      } catch (e) {
        debugPrint('[SerialPrinterService] Advertencia: reset inicial falló: $e');
      }

      debugPrint('[SerialPrinterService] Puerto $targetPort abierto correctamente');
      return const PrinterResult.success('Conectado al puerto COM');
    } catch (e, stack) {
      debugPrint('[SerialPrinterService] Error al conectar: $e');
      debugPrint('[SerialPrinterService] Stack: $stack');
      _activePort = null;
      _notifyConnectionState(false);
      return PrinterResult.error('Error al abrir ${config.comPort}: $e');
    }
  }

  Future<SerialPort> _tryOpenWithConstructor(String portName, int baudRate) async {
    final port = SerialPort(
      portName,
      openNow: true,
      BaudRate: baudRate,
      ByteSize: 8,
    );
    // Algunos drivers virtuales reportan isOpened con delay.
    await Future.delayed(const Duration(milliseconds: 100));
    return port;
  }

  Future<SerialPort> _tryOpenWithSetters(String portName, int baudRate) async {
    final port = SerialPort(portName, openNow: false);
    port.BaudRate = baudRate;
    port.ByteSize = 8;
    port.open();
    await Future.delayed(const Duration(milliseconds: 100));
    return port;
  }

  Future<SerialPort> _tryOpenWithSettings(String portName, int baudRate) async {
    final port = SerialPort(portName, openNow: false);
    port.openWithSettings(BaudRate: baudRate);
    await Future.delayed(const Duration(milliseconds: 100));
    return port;
  }

  Future<void> _setControlLines(SerialPort port) async {
    final signals = [
      (SerialPort.SETDTR, 'DTR'),
      (SerialPort.SETRTS, 'RTS'),
    ];
    for (final (signal, name) in signals) {
      try {
        port.setFlowControlSignal(signal);
        debugPrint('[SerialPrinterService] Señal $name activada');
      } catch (e) {
        debugPrint('[SerialPrinterService] No se pudo activar $name: $e');
      }
    }
  }

  @override
  Future<PrinterResult> disconnect() async {
    if (_activePort == null) return const PrinterResult.success();
    try {
      final name = _activePort.toString();
      _activePort!.close();
      _activePort = null;
      _notifyConnectionState(false);
      debugPrint('[SerialPrinterService] Puerto $name cerrado');
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
        await port.writeBytesFromUint8List(bytes).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Timeout escribiendo en puerto COM'),
        );
        debugPrint('[SerialPrinterService] Envío exitoso');
        return const PrinterResult.success();
      } catch (e) {
        debugPrint('[SerialPrinterService] Error al enviar (intento ${attempt + 1}): $e');
        if (attempt == 2) {
          _notifyConnectionState(false);
          return PrinterResult.error('Error al enviar datos: $e');
        }
        await Future.delayed(const Duration(milliseconds: 200));
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
    await _connectionStateController.close();
  }
}
