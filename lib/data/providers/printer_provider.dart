import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/printer_config.dart';
import '../services/printer/bluetooth_printer_service.dart';
import '../services/printer/printer_service.dart';
import '../services/printer/serial_printer_service.dart';

final printerConfigProvider = StateNotifierProvider<PrinterConfigNotifier, PrinterConfig?>((ref) {
  return PrinterConfigNotifier();
});

class PrinterConfigNotifier extends StateNotifier<PrinterConfig?> {
  PrinterConfigNotifier() : super(null) {
    _load();
  }

  static const _key = 'printer_config';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json != null) {
        state = PrinterConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(json)),
        );
      }
    } catch (e) {
      debugPrint('[PrinterConfigNotifier] Error cargando config: $e');
    }
  }

  Future<void> save(PrinterConfig config) async {
    state = config;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(config.toJson()));
    } catch (e) {
      debugPrint('[PrinterConfigNotifier] Error guardando config: $e');
    }
  }

  Future<void> clear() async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('[PrinterConfigNotifier] Error limpiando config: $e');
    }
  }
}

final printerServiceProvider = Provider<PrinterService?>((ref) {
  final config = ref.watch(printerConfigProvider);
  if (config == null) return null;

  switch (config.connectionType) {
    case PrinterConnectionType.bluetooth:
    case PrinterConnectionType.usb:
    case PrinterConnectionType.wifi:
      return BluetoothPrinterService();
    case PrinterConnectionType.serial:
      return SerialPrinterService();
  }
});

final printerDevicesProvider = StreamProvider.autoDispose<List<PrinterDevice>>((ref) {
  final service = ref.watch(printerServiceProvider);
  if (service == null) return const Stream.empty();
  return service.discoverDevices();
});

/// Provider para imprimir un ticket genérico.
final printTicketProvider = Provider<Future<PrinterResult> Function(Uint8List)>((ref) {
  return (bytes) async {
    final service = ref.read(printerServiceProvider);
    if (service == null) {
      return const PrinterResult.error('No hay impresora configurada');
    }
    if (!service.isConnected) {
      final config = ref.read(printerConfigProvider);
      if (config == null) {
        return const PrinterResult.error('No hay configuración de impresora');
      }
      final connectResult = await service.connect(config);
      if (!connectResult.success) return connectResult;
    }
    return service.printBytes(bytes);
  };
});
