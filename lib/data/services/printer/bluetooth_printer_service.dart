import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart' as ftp;

import '../../../domain/models/printer_config.dart';
import 'printer_service.dart';

/// Implementación de [PrinterService] usando flutter_thermal_printer.
/// Soporta Bluetooth/BLE y USB en Android, iOS, macOS y Windows.
class BluetoothPrinterService implements PrinterService {
  final FlutterThermalPrinter _plugin = FlutterThermalPrinter.instance;
  ftp.Printer? _connectedPrinter;

  @override
  Stream<List<PrinterDevice>> discoverDevices() async* {
    final controller = StreamController<List<PrinterDevice>>.broadcast();

    // Iniciar escaneo
    // ignore: unused_local_variable
    final _ = _plugin.getPrinters(
      refreshDuration: const Duration(seconds: 2),
      connectionTypes: const [
        ftp.ConnectionType.BLE,
        ftp.ConnectionType.USB,
      ],
    );

    _plugin.devicesStream.listen((printers) {
      final devices = printers
          .where((p) => p.address != null)
          .map(
            (p) => PrinterDevice(
              address: p.address!,
              name: p.name,
              connectionType: _mapConnectionType(p.connectionType),
            ),
          )
          .toList();
      controller.add(devices);
    }, onError: (e) {
      debugPrint('[BluetoothPrinterService] Error descubriendo: $e');
      controller.addError(e);
    });

    yield* controller.stream;
  }

  @override
  Future<PrinterResult> connect(PrinterConfig config) async {
    try {
      final printers = await _plugin.devicesStream.first;
      final printer = printers.firstWhere(
        (p) =>
            p.address == config.address ||
            (p.name != null && p.name == config.name),
        orElse: () => throw Exception('Impresora no encontrada'),
      );

      final connected = await _plugin.connect(printer);
      if (connected) {
        _connectedPrinter = printer;
        return const PrinterResult.success('Conectado');
      } else {
        return const PrinterResult.error('No se pudo conectar');
      }
    } catch (e) {
      return PrinterResult.error('Error al conectar: $e');
    }
  }

  @override
  Future<PrinterResult> disconnect() async {
    if (_connectedPrinter == null) {
      return const PrinterResult.success('No había conexión activa');
    }
    try {
      await _plugin.disconnect(_connectedPrinter!);
      _connectedPrinter = null;
      return const PrinterResult.success('Desconectado');
    } catch (e) {
      return PrinterResult.error('Error al desconectar: $e');
    }
  }

  @override
  Future<PrinterResult> printBytes(Uint8List bytes) async {
    if (_connectedPrinter == null) {
      return const PrinterResult.error('No hay impresora conectada');
    }
    try {
      await _plugin.printData(
        _connectedPrinter!,
        bytes.toList(),
      );
      return const PrinterResult.success();
    } catch (e) {
      return PrinterResult.error('Error al imprimir: $e');
    }
  }

  @override
  bool get isConnected => _connectedPrinter != null;

  PrinterConnectionType _mapConnectionType(ftp.ConnectionType? type) {
    switch (type) {
      case ftp.ConnectionType.USB:
        return PrinterConnectionType.usb;
      case ftp.ConnectionType.BLE:
      default:
        return PrinterConnectionType.bluetooth;
    }
  }
}
