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
import 'settings_providers.dart';

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

/// Gestor del servicio de impresora.
///
/// Mantiene una única instancia del servicio por tipo de conexión para
/// preservar el estado de conexión entre impresiones. Cuando cambia el tipo
/// de conexión se destruye el servicio anterior; si solo cambian los datos
/// (dirección, baud rate, etc.) se reutiliza la instancia existente.
final printerServiceProvider =
    StateNotifierProvider<PrinterServiceManager, PrinterService?>((ref) {
  return PrinterServiceManager(ref);
});

class PrinterServiceManager extends StateNotifier<PrinterService?> {
  final Ref _ref;
  PrinterConfig? _lastConfig;
  StreamSubscription<bool>? _connectionSubscription;

  PrinterServiceManager(this._ref) : super(null) {
    _init();
  }

  void _init() {
    _updateService(_ref.read(printerConfigProvider));
    _ref.listen(printerConfigProvider, (previous, next) {
      _updateService(next);
    });
  }

  void _updateService(PrinterConfig? config) {
    if (config == null) {
      _disposeCurrentService();
      return;
    }

    // Mismo tipo de conexión: reutilizar instancia y solo actualizar config
    if (_lastConfig != null &&
        _lastConfig!.connectionType == config.connectionType &&
        state != null) {
      _lastConfig = config;
      return;
    }

    // Tipo diferente o sin servicio: crear nuevo
    _disposeCurrentService();
    state = _createService(config.connectionType);
    _lastConfig = config;

    // Escuchar cambios de conexión
    _connectionSubscription?.cancel();
    _connectionSubscription = state!.connectionState.listen(
      (connected) {
        _ref.read(printerConnectionStatusProvider.notifier).setStatus(
              connected
                  ? PrinterConnectionStatus.connected
                  : PrinterConnectionStatus.disconnected,
            );
      },
      onError: (_) {
        _ref
            .read(printerConnectionStatusProvider.notifier)
            .setStatus(PrinterConnectionStatus.error);
      },
    );
  }

  void _disposeCurrentService() {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    state?.dispose();
    state = null;
    _lastConfig = null;
  }

  PrinterService _createService(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.bluetooth:
      case PrinterConnectionType.usb:
      case PrinterConnectionType.wifi:
        return BluetoothPrinterService();
      case PrinterConnectionType.serial:
        return SerialPrinterService();
      case PrinterConnectionType.windows:
        return WindowsPrinterService();
    }
  }

  @override
  void dispose() {
    _disposeCurrentService();
    super.dispose();
  }
}

/// Estado de conexión de la impresora.
enum PrinterConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Provider que expone el estado de conexión actual de la impresora.
final printerConnectionStatusProvider =
    StateNotifierProvider<PrinterConnectionStatusNotifier, PrinterConnectionStatus>((ref) {
  return PrinterConnectionStatusNotifier(ref);
});

class PrinterConnectionStatusNotifier extends StateNotifier<PrinterConnectionStatus> {
  final Ref _ref;

  PrinterConnectionStatusNotifier(this._ref)
      : super(PrinterConnectionStatus.disconnected);

  void setStatus(PrinterConnectionStatus status) {
    state = status;
  }

  /// Verifica el estado de conexión actual intentando conectar si es necesario.
  Future<void> checkConnection() async {
    final service = _ref.read(printerServiceProvider);
    final config = _ref.read(printerConfigProvider);

    if (service == null || config == null) {
      state = PrinterConnectionStatus.disconnected;
      return;
    }

    if (service.isConnected) {
      state = PrinterConnectionStatus.connected;
      return;
    }

    state = PrinterConnectionStatus.connecting;
    final result = await _ensureConnected(service, config, maxAttempts: 2);
    state = result.success
        ? PrinterConnectionStatus.connected
        : PrinterConnectionStatus.error;
  }
}

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

    final statusNotifier = ref.read(printerConnectionStatusProvider.notifier);
    final config = ref.read(printerConfigProvider);
    if (config == null) {
      return const PrinterResult.error('No hay configuración de impresora');
    }

    if (!service.isConnected) {
      statusNotifier.setStatus(PrinterConnectionStatus.connecting);
      final connectResult = await _ensureConnected(service, config, maxAttempts: 2);
      if (!connectResult.success) {
        statusNotifier.setStatus(PrinterConnectionStatus.error);
        return connectResult;
      }
    }

    statusNotifier.setStatus(PrinterConnectionStatus.connected);
    debugPrint('[printTicketProvider] Sending bytes...');
    final result = await service.printBytes(bytes);
    debugPrint('[printTicketProvider] result=$result');
    _updateStatusFromResult(statusNotifier, result);
    return result;
  };
});

/// Provider para imprimir el recibo de un pedido completo.
///
/// Selecciona automáticamente el formato (PDF para Windows nativo,
/// ESC/POS para Bluetooth/USB/Serial).
final printOrderReceiptProvider =
    Provider<Future<PrinterResult> Function(Order, List<OrderItem>)>((ref) {
  return (order, items) async {
    debugPrint('[printOrderReceiptProvider] START order=${order.id} items=${items.length}');
    final service = ref.read(printerServiceProvider);
    if (service == null) {
      debugPrint('[printOrderReceiptProvider] No hay impresora configurada');
      return const PrinterResult.error('No hay impresora configurada');
    }

    final statusNotifier = ref.read(printerConnectionStatusProvider.notifier);
    final config = ref.read(printerConfigProvider);
    if (config == null) {
      return const PrinterResult.error('No hay configuración de impresora');
    }

    if (!service.isConnected) {
      statusNotifier.setStatus(PrinterConnectionStatus.connecting);
      final connectResult = await _ensureConnected(service, config, maxAttempts: 2);
      if (!connectResult.success) {
        statusNotifier.setStatus(PrinterConnectionStatus.error);
        return connectResult;
      }
    }

    statusNotifier.setStatus(PrinterConnectionStatus.connected);

    final invoiceConfig = ref.read(invoiceConfigProvider);
    final receiptParams = (
      businessName: invoiceConfig.businessName,
      businessNit: invoiceConfig.businessNit,
      businessAddress: invoiceConfig.businessAddress,
      businessPhone: invoiceConfig.businessPhone,
      sellerName: invoiceConfig.sellerName,
      invoiceFooter: invoiceConfig.invoiceFooter,
      legalText: invoiceConfig.legalText,
      logoBase64: invoiceConfig.logoBase64,
    );

    if (service.supportsPdf) {
      debugPrint('[printOrderReceiptProvider] Generating PDF...');
      final generator = PdfReceiptGenerator(
        paperWidthMm: config.paperWidthMm,
      );
      final document = await generator.generateOrderReceipt(
        order: order,
        items: items,
        businessName: receiptParams.businessName,
        businessNit: receiptParams.businessNit,
        businessAddress: receiptParams.businessAddress,
        businessPhone: receiptParams.businessPhone,
        sellerName: receiptParams.sellerName,
        invoiceFooter: receiptParams.invoiceFooter,
        legalText: receiptParams.legalText,
        logoBase64: receiptParams.logoBase64,
      );
      debugPrint('[printOrderReceiptProvider] Printing PDF...');
      final result = await service.printPdf(document);
      debugPrint('[printOrderReceiptProvider] result=$result');
      _updateStatusFromResult(statusNotifier, result);
      return result;
    } else {
      debugPrint('[printOrderReceiptProvider] Generating ESC/POS bytes...');
      final generator = EscPosReceiptGenerator(
        paperWidthMm: config.paperWidthMm,
      );
      final bytes = await generator.generateOrderReceipt(
        order: order,
        items: items,
        businessName: receiptParams.businessName,
        businessNit: receiptParams.businessNit,
        businessAddress: receiptParams.businessAddress,
        businessPhone: receiptParams.businessPhone,
        sellerName: receiptParams.sellerName,
        invoiceFooter: receiptParams.invoiceFooter,
        legalText: receiptParams.legalText,
        logoBase64: receiptParams.logoBase64,
      );
      debugPrint('[printOrderReceiptProvider] Printing ${bytes.length} bytes...');
      final result = await service.printBytes(bytes);
      debugPrint('[printOrderReceiptProvider] result=$result');
      _updateStatusFromResult(statusNotifier, result);
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

    final statusNotifier = ref.read(printerConnectionStatusProvider.notifier);

    debugPrint('[printTestPageProvider] Disconnecting any previous connection...');
    await service.disconnect();
    debugPrint('[printTestPageProvider] Connecting...');
    statusNotifier.setStatus(PrinterConnectionStatus.connecting);
    final connectResult = await _ensureConnected(service, config, maxAttempts: 2);
    debugPrint('[printTestPageProvider] connect result=$connectResult');
    if (!connectResult.success) {
      statusNotifier.setStatus(PrinterConnectionStatus.error);
      return connectResult;
    }
    statusNotifier.setStatus(PrinterConnectionStatus.connected);

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
      _updateStatusFromResult(statusNotifier, result);
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
      _updateStatusFromResult(statusNotifier, result);
      return result;
    }
  };
});

/// Intenta conectar [service] con [config] hasta [maxAttempts] veces.
Future<PrinterResult> _ensureConnected(
  PrinterService service,
  PrinterConfig config, {
  required int maxAttempts,
}) async {
  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    debugPrint('[PrinterProvider] connect attempt ${attempt + 1}/$maxAttempts');
    try {
      final result = await service.connect(config);
      if (result.success) return result;
      if (attempt == maxAttempts - 1) return result;
      debugPrint('[PrinterProvider] retrying after 1s...');
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('[PrinterProvider] connect exception: $e');
      if (attempt == maxAttempts - 1) {
        return PrinterResult.error('Error de conexión: $e');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }
  return const PrinterResult.error('No se pudo conectar');
}

void _updateStatusFromResult(
  PrinterConnectionStatusNotifier notifier,
  PrinterResult result,
) {
  if (!result.success) {
    notifier.setStatus(PrinterConnectionStatus.error);
  }
}

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
