import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/printer_config.dart';
import '../services/printer/bluetooth_printer_service.dart';
import '../services/printer/esc_pos_receipt_generator.dart';
import '../services/printer/pdf_receipt_generator.dart';
import '../services/printer/printer_service.dart';
import '../services/printer/serial_printer_service.dart';
import '../services/printer/windows_printer_service.dart';

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
    case PrinterConnectionType.windows:
      return WindowsPrinterService();
  }
});

/// Tipo de conexión seleccionado actualmente en la UI de configuración.
///
/// Permite escanear dispositivos sin depender de la configuración guardada.
final selectedPrinterConnectionTypeProvider = StateProvider<PrinterConnectionType?>((ref) => null);

/// Indica si se está escaneando activamente en la UI de configuración.
final isPrinterScanningProvider = StateProvider<bool>((ref) => false);

/// Stream de dispositivos disponibles según el tipo de conexión seleccionado.
///
/// Solo se activa cuando [isPrinterScanningProvider] es true, evitando que
/// el escaneo comience automáticamente al abrir la pantalla.
final printerDevicesProvider = StreamProvider.autoDispose<List<PrinterDevice>>((ref) {
  final isScanning = ref.watch(isPrinterScanningProvider);
  if (!isScanning) return const Stream.empty();

  final type = ref.watch(selectedPrinterConnectionTypeProvider);

  switch (type) {
    case PrinterConnectionType.serial:
      return SerialPrinterService().discoverDevices();
    case PrinterConnectionType.windows:
      return WindowsPrinterService().discoverDevices();
    case PrinterConnectionType.bluetooth:
    case PrinterConnectionType.usb:
    case PrinterConnectionType.wifi:
    case null:
      return BluetoothPrinterService().discoverDevices();
  }
});

/// Generador de recibos adecuado para la impresora configurada.
///
/// Devuelve [PdfReceiptGenerator] cuando el servicio activo soporta PDF
/// (impresoras Windows nativas), o [EscPosReceiptGenerator] para el resto.
final receiptGeneratorProvider = Provider<ReceiptGenerator>((ref) {
  final service = ref.watch(printerServiceProvider);
  final config = ref.watch(printerConfigProvider);
  final paperWidth = config?.paperWidthMm ?? 58;

  if (service?.supportsPdf == true) {
    return PdfReceiptGenerator(paperWidthMm: paperWidth);
  }
  return EscPosReceiptGenerator(paperWidthMm: paperWidth);
});

/// Provider para imprimir un ticket genérico (bytes ESC/POS).
///
/// Útil cuando ya se tienen los bytes preparados. Para imprimir un pedido
/// completo usa [printOrderReceiptProvider].
final printTicketProvider = Provider<Future<PrinterResult> Function(Uint8List)>((ref) {
  return (bytes) async {
    debugPrint('[printTicketProvider] START bytes=${bytes.length}');
    final service = ref.read(printerServiceProvider);
    if (service == null) {
      debugPrint('[printTicketProvider] No hay impresora configurada');
      return const PrinterResult.error('No hay impresora configurada');
    }
    if (!service.isConnected) {
      final config = ref.read(printerConfigProvider);
      if (config == null) {
        debugPrint('[printTicketProvider] No hay configuración de impresora');
        return const PrinterResult.error('No hay configuración de impresora');
      }
      debugPrint('[printTicketProvider] Connecting $config');
      final connectResult = await service.connect(config);
      debugPrint('[printTicketProvider] connect result=$connectResult');
      if (!connectResult.success) return connectResult;
    }
    debugPrint('[printTicketProvider] Sending bytes...');
    final result = await service.printBytes(bytes);
    debugPrint('[printTicketProvider] result=$result');
    return result;
  };
});

/// Provider para imprimir el recibo de un pedido completo.
///
/// Selecciona automáticamente el formato (PDF para Windows nativo,
/// ESC/POS para Bluetooth/USB/Serial).
final printOrderReceiptProvider = Provider<Future<PrinterResult> Function(Order, List<OrderItem>)>((ref) {
  return (order, items) async {
    debugPrint('[printOrderReceiptProvider] START order=${order.id} items=${items.length}');
    final service = ref.read(printerServiceProvider);
    if (service == null) {
      debugPrint('[printOrderReceiptProvider] No hay impresora configurada');
      return const PrinterResult.error('No hay impresora configurada');
    }

    if (!service.isConnected) {
      final config = ref.read(printerConfigProvider);
      if (config == null) {
        debugPrint('[printOrderReceiptProvider] No hay configuración de impresora');
        return const PrinterResult.error('No hay configuración de impresora');
      }
      debugPrint('[printOrderReceiptProvider] Connecting $config');
      final connectResult = await service.connect(config);
      debugPrint('[printOrderReceiptProvider] connect result=$connectResult');
      if (!connectResult.success) return connectResult;
    }

    final config = ref.read(printerConfigProvider);
    final businessName = 'Licorería';

    if (service.supportsPdf) {
      debugPrint('[printOrderReceiptProvider] Generating PDF...');
      final generator = PdfReceiptGenerator(
        paperWidthMm: config?.paperWidthMm ?? 58,
      );
      final document = await generator.generateOrderReceipt(
        order: order,
        items: items,
        businessName: businessName,
      );
      debugPrint('[printOrderReceiptProvider] Printing PDF...');
      final result = await service.printPdf(document);
      debugPrint('[printOrderReceiptProvider] result=$result');
      return result;
    } else {
      debugPrint('[printOrderReceiptProvider] Generating ESC/POS bytes...');
      final generator = EscPosReceiptGenerator(
        paperWidthMm: config?.paperWidthMm ?? 58,
      );
      final bytes = await generator.generateOrderReceipt(
        order: order,
        items: items,
        businessName: businessName,
      );
      debugPrint('[printOrderReceiptProvider] Printing ${bytes.length} bytes...');
      final result = await service.printBytes(bytes);
      debugPrint('[printOrderReceiptProvider] result=$result');
      return result;
    }
  };
});

/// Provider para imprimir una página de prueba.
///
/// Selecciona automáticamente el formato según la impresora configurada.
final printTestPageProvider = Provider<Future<PrinterResult> Function()>((ref) {
  return () async {
    debugPrint('[printTestPageProvider] START');
    final service = ref.read(printerServiceProvider);
    if (service == null) {
      debugPrint('[printTestPageProvider] No hay impresora configurada');
      return const PrinterResult.error('No hay impresora configurada');
    }

    final config = ref.read(printerConfigProvider);
    if (config == null) {
      debugPrint('[printTestPageProvider] No hay configuración de impresora');
      return const PrinterResult.error('No hay configuración de impresora');
    }
    debugPrint('[printTestPageProvider] Config: $config');

    debugPrint('[printTestPageProvider] Disconnecting any previous connection...');
    await service.disconnect();
    debugPrint('[printTestPageProvider] Connecting...');
    final connectResult = await service.connect(config);
    debugPrint('[printTestPageProvider] connect result=$connectResult');
    if (!connectResult.success) return connectResult;

    if (service.supportsPdf) {
      debugPrint('[printTestPageProvider] Generating PDF test page...');
      final generator = PdfReceiptGenerator(
        paperWidthMm: config.paperWidthMm,
      );
      final debugInfo = _buildStaticDebugInfo(config);
      final document = await generator.generateTestPage(
        config: config,
        debugInfo: debugInfo,
      );
      debugPrint('[printTestPageProvider] Printing PDF test page...');
      final result = await service.printPdf(document);
      debugPrint('[printTestPageProvider] result=$result');
      return result;
    } else {
      debugPrint('[printTestPageProvider] Generating ESC/POS test bytes...');
      final generator = EscPosReceiptGenerator(
        paperWidthMm: config.paperWidthMm,
      );
      // Generamos una primera vez para medir el payload exacto.
      final preBytes = await generator.generateTestPage(config: config);
      final debugInfo = '${_buildStaticDebugInfo(config)}\nBytes: ${preBytes.length}';
      final bytes = await generator.generateTestPage(
        config: config,
        debugInfo: debugInfo,
      );
      debugPrint('[printTestPageProvider] Printing ${bytes.length} bytes...');
      final result = await service.printBytes(bytes);
      debugPrint('[printTestPageProvider] result=$result');
      return result;
    }
  };
});

String _buildStaticDebugInfo(PrinterConfig config) {
  final lines = <String>[
    'Tipo: ${config.connectionType.label}',
    if (config.name?.isNotEmpty == true) 'Nombre: ${config.name}',
    if (config.address?.isNotEmpty == true) 'Dir: ${config.address}',
    if (config.connectionType == PrinterConnectionType.serial)
      'Baud: ${config.baudRate}',
    'Papel: ${config.paperWidthMm}mm',
    'Plataforma: ${defaultTargetPlatform.name}',
  ];
  return lines.join('\n');
}

/// Abstracción común para los generadores de recibo.
///
/// Permite que la UI no distinga entre PDF y ESC/POS cuando solo necesita
/// conocer el ancho de papel.
abstract class ReceiptGenerator {
  final int paperWidthMm;

  const ReceiptGenerator({required this.paperWidthMm});
}
