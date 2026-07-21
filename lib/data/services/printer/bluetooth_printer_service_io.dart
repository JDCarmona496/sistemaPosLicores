import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart' as ftp;
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/models/printer_config.dart';
import 'printer_service.dart';

/// Implementación de [PrinterService] para Bluetooth/USB en Android/iOS/macOS/Windows.
///
/// - BLE: usa flutter_blue_plus directamente para descubrimiento, conexión e impresión.
/// - USB: delega el descubrimiento/impresión a flutter_thermal_printer.
///
/// El servicio mantiene una stream de estado de conexión para que la UI y los
/// providers puedan reaccionar a desconexiones inesperadas.
class BluetoothPrinterService implements PrinterService {
  final FlutterThermalPrinter _plugin = FlutterThermalPrinter.instance;

  // ---- BLE state ----
  BluetoothDevice? _connectedBleDevice;
  StreamSubscription<BluetoothConnectionState>? _bleConnectionSubscription;

  // ---- USB state ----
  ftp.Printer? _connectedUsbPrinter;

  // ---- Connection state ----
  final _connectionStateController = StreamController<bool>.broadcast();
  var _lastConnectionState = false;

  BluetoothPrinterService() {
    _connectionStateController.add(false);
  }

  void _notifyConnectionState(bool connected) {
    if (_lastConnectionState != connected) {
      _lastConnectionState = connected;
      _connectionStateController.add(connected);
      debugPrint('[BluetoothPrinterService] connectionState=$connected');
    }
  }

  void _listenToBleConnection(BluetoothDevice device) {
    _bleConnectionSubscription?.cancel();
    _bleConnectionSubscription = device.connectionState.listen(
      (state) {
        debugPrint('[BluetoothPrinterService] BLE state: $state');
        _notifyConnectionState(state == BluetoothConnectionState.connected);
      },
      onError: (e) {
        debugPrint('[BluetoothPrinterService] BLE state error: $e');
        _notifyConnectionState(false);
      },
    );
    // Cancelar automáticamente la suscripción cuando el dispositivo se desconecte
    // para evitar fugas y duplicados.
    device.cancelWhenDisconnected(_bleConnectionSubscription!, delayed: true);
  }

  @override
  Stream<bool> get connectionState => _connectionStateController.stream;

  @override
  bool get isConnected =>
      (_connectedBleDevice?.isConnected ?? false) ||
      (_connectedUsbPrinter?.isConnected ?? false);

  @override
  Stream<List<PrinterDevice>> discoverDevices() async* {
    final controller = StreamController<List<PrinterDevice>>.broadcast();
    final devices = <String, PrinterDevice>{};

    StreamSubscription<List<ScanResult>>? bleSubscription;
    StreamSubscription<List<ftp.Printer>>? usbSubscription;

    void emit() => controller.add(devices.values.toList());

    // USB discovery via flutter_thermal_printer
    try {
      // ignore: unused_local_variable
      final _ = _plugin.getPrinters(
        refreshDuration: const Duration(seconds: 2),
        connectionTypes: const [ftp.ConnectionType.USB],
        androidUsesFineLocation: false,
      );
      usbSubscription = _plugin.devicesStream.listen(
        (printers) {
          for (final p in printers.where((p) => p.address != null)) {
            devices[p.address!] = PrinterDevice(
              address: p.address!,
              name: p.name,
              connectionType: PrinterConnectionType.usb,
            );
          }
          emit();
        },
        onError: (e) {
          debugPrint('[BluetoothPrinterService] USB discovery error: $e');
        },
      );
    } catch (e, stack) {
      debugPrint('[BluetoothPrinterService] Error starting USB discovery: $e');
      debugPrint(stack.toString());
    }

    // BLE discovery via FlutterBluePlus
    // onScanResults entrega resultados nuevos en tiempo real.
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState == BluetoothAdapterState.on) {
        bleSubscription = FlutterBluePlus.onScanResults.listen(
          (results) {
            if (results.isEmpty) return;
            for (final r in results) {
              final d = r.device;
              final id = d.remoteId.str.toUpperCase();
              final name = d.platformName.isNotEmpty
                  ? d.platformName
                  : (d.advName.isNotEmpty ? d.advName : null);
              devices[id] = PrinterDevice(
                address: id,
                name: name,
                connectionType: PrinterConnectionType.bluetooth,
              );
            }
            emit();
          },
          onError: (e) {
            debugPrint('[BluetoothPrinterService] BLE scan error: $e');
          },
        );
        FlutterBluePlus.cancelWhenScanComplete(bleSubscription);
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 15),
          androidUsesFineLocation: false,
        );
      } else {
        debugPrint('[BluetoothPrinterService] Bluetooth adapter is off');
      }
    } catch (e, stack) {
      debugPrint('[BluetoothPrinterService] Error starting BLE scan: $e');
      debugPrint(stack.toString());
    }

    // Initial empty emit
    emit();

    controller.onCancel = () async {
      await bleSubscription?.cancel();
      await usbSubscription?.cancel();
      await FlutterBluePlus.stopScan();
    };

    yield* controller.stream;
  }

  @override
  Future<PrinterResult> connect(PrinterConfig config) async {
    debugPrint(
      '[BluetoothPrinterService] CONNECT START type=${config.connectionType} address=${config.address} name=${config.name}',
    );

    try {
      // Verificar Bluetooth encendido (solo para BLE)
      if (config.connectionType == PrinterConnectionType.bluetooth) {
        final adapterState = await FlutterBluePlus.adapterState.first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => BluetoothAdapterState.unknown,
        );
        if (adapterState != BluetoothAdapterState.on) {
          return const PrinterResult.error(
            'Bluetooth apagado. Enciéndelo e intenta de nuevo.',
          );
        }
      }

      if (config.connectionType == PrinterConnectionType.usb) {
        return await _connectUsb(config);
      }

      if (config.connectionType == PrinterConnectionType.wifi) {
        return const PrinterResult.error(
          'La impresión WiFi aún no está implementada.',
        );
      }

      return await _connectBle(config);
    } catch (e, stack) {
      debugPrint('[BluetoothPrinterService] Error al conectar: $e');
      debugPrint(stack.toString());
      _notifyConnectionState(false);
      return PrinterResult.error('Error al conectar: $e');
    }
  }

  Future<PrinterResult> _connectUsb(PrinterConfig config) async {
    await _disconnectUsb();

    List<ftp.Printer> printers = [];
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        printers = await _plugin.devicesStream.first.timeout(
          const Duration(seconds: 8),
          onTimeout: () => [],
        );
        if (printers.isNotEmpty) break;
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        debugPrint('[BluetoothPrinterService] USB scan attempt ${attempt + 1} failed: $e');
      }
    }

    if (printers.isEmpty) {
      return const PrinterResult.error(
        'No se encontraron impresoras USB. Asegúrate de que esté encendida y conectada.',
      );
    }

    final printer = printers.firstWhere(
      (p) =>
          p.address == config.address ||
          (p.name != null && p.name == config.name),
      orElse: () => throw Exception('Impresora USB no encontrada'),
    );

    debugPrint('[BluetoothPrinterService] USB connect ${printer.name} / ${printer.address}');
    final connected = await _plugin.connect(printer);
    if (connected) {
      _connectedUsbPrinter = printer;
      _notifyConnectionState(true);
      return const PrinterResult.success('Conectado por USB');
    }
    return const PrinterResult.error('No se pudo conectar por USB');
  }

  Future<void> _disconnectUsb() async {
    if (_connectedUsbPrinter != null) {
      try {
        await _plugin.disconnect(_connectedUsbPrinter!);
      } catch (e) {
        debugPrint('[BluetoothPrinterService] USB disconnect error: $e');
      }
      _connectedUsbPrinter = null;
    }
  }

  Future<PrinterResult> _connectBle(PrinterConfig config) async {
    await _disconnectBle();

    if (config.address == null || config.address!.isEmpty) {
      return const PrinterResult.error('Dirección Bluetooth no configurada');
    }

    final address = config.address!.toUpperCase();
    final device = BluetoothDevice.fromId(address);

    debugPrint(
      '[BluetoothPrinterService] BLE device state before connect: connected=${device.isConnected} disconnected=${device.isDisconnected}',
    );

    // Si ya está conectado, solo suscribirse y salir
    if (device.isConnected) {
      _connectedBleDevice = device;
      _listenToBleConnection(device);
      _notifyConnectionState(true);
      await _logBleServices(device);
      return const PrinterResult.success('Bluetooth ya conectado');
    }

    // Intentar conectar directamente. En muchos casos el dispositivo ya está
    // emparejado y esto es suficiente, sin depender de un scan previo.
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        debugPrint('[BluetoothPrinterService] BLE connect attempt ${attempt + 1}');
        await device.connect(
          timeout: const Duration(seconds: 15),
          mtu: 512,
          autoConnect: false,
        );

        final connected = await _waitForConnection(
          device,
          timeout: const Duration(seconds: 8),
        );

        if (connected) {
          _connectedBleDevice = device;
          _listenToBleConnection(device);
          _notifyConnectionState(true);
          await _requestMtuIfNeeded(device);
          await _logBleServices(device);
          return const PrinterResult.success('Conectado por Bluetooth');
        }
      } catch (e) {
        debugPrint('[BluetoothPrinterService] BLE attempt ${attempt + 1} failed: $e');
        if (attempt == 1) {
          return PrinterResult.error(
            'No se pudo conectar después de 2 intentos. Asegúrate de que la impresora esté encendida y emparejada.',
          );
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    _notifyConnectionState(false);
    return const PrinterResult.error(
      'No se pudo conectar por Bluetooth.',
    );
  }

  Future<void> _disconnectBle() async {
    await _bleConnectionSubscription?.cancel();
    _bleConnectionSubscription = null;
    if (_connectedBleDevice != null) {
      try {
        await _connectedBleDevice!.disconnect();
      } catch (e) {
        debugPrint('[BluetoothPrinterService] BLE disconnect error: $e');
      }
      _connectedBleDevice = null;
    }
    _notifyConnectionState(false);
  }

  Future<void> _requestMtuIfNeeded(BluetoothDevice device) async {
    if (Platform.isAndroid) {
      try {
        debugPrint('[BluetoothPrinterService] Requesting MTU 512 (Android)...');
        await device.requestMtu(512);
      } catch (e) {
        debugPrint('[BluetoothPrinterService] MTU request failed: $e');
      }
    }
  }

  Future<bool> _waitForConnection(
    BluetoothDevice device, {
    required Duration timeout,
  }) async {
    if (device.isConnected) return true;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = device.connectionState.listen(
      (state) {
        debugPrint('[BluetoothPrinterService] BLE waitForConnection state: $state');
        if (state == BluetoothConnectionState.connected && !completer.isCompleted) {
          completer.complete(true);
        }
      },
      onError: (e) {
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    final result = await completer.future.timeout(
      timeout,
      onTimeout: () => device.isConnected,
    );
    await subscription.cancel();
    return result;
  }

  @override
  Future<PrinterResult> disconnect() async {
    await _disconnectUsb();
    await _disconnectBle();
    return const PrinterResult.success('Desconectado');
  }

  @override
  Future<PrinterResult> printBytes(Uint8List bytes) async {
    // USB path
    if (_connectedUsbPrinter != null) {
      try {
        debugPrint(
          '[BluetoothPrinterService] USB print ${bytes.length} bytes',
        );
        await _plugin.printData(
          _connectedUsbPrinter!,
          bytes.toList(),
          longData: false,
        );
        return const PrinterResult.success('Datos enviados por USB');
      } catch (e) {
        debugPrint('[BluetoothPrinterService] USB print error: $e');
        return PrinterResult.error('Error al imprimir por USB: $e');
      }
    }

    // BLE path
    final device = _connectedBleDevice;
    if (device == null) {
      return const PrinterResult.error('No hay dispositivo BLE conectado');
    }

    // Reconnect if needed
    if (device.isDisconnected) {
      debugPrint('[BluetoothPrinterService] BLE reconnecting before print...');
      try {
        await device.connect(
          timeout: const Duration(seconds: 10),
          mtu: 512,
          autoConnect: false,
        );
        final connected = await _waitForConnection(
          device,
          timeout: const Duration(seconds: 5),
        );
        if (!connected) {
          _notifyConnectionState(false);
          return const PrinterResult.error('No se pudo reconectar la impresora');
        }
        _notifyConnectionState(true);
        await _requestMtuIfNeeded(device);
      } catch (e) {
        _notifyConnectionState(false);
        return PrinterResult.error('Error reconectando: $e');
      }
    }

    return await _printWithFlutterBluePlus(device, bytes);
  }

  Future<PrinterResult> _printWithFlutterBluePlus(
    BluetoothDevice device,
    Uint8List bytes,
  ) async {
    debugPrint('[BluetoothPrinterService] PRINT START: ${bytes.length} bytes');

    // mtuNow refleja el valor negociado actual sin depender del stream.
    final mtu = device.mtuNow;
    debugPrint('[BluetoothPrinterService] Current MTU: $mtu');

    // Siempre redescubrir servicios tras una reconexión BLE.
    final services = await device.discoverServices();
    debugPrint('[BluetoothPrinterService] Services discovered: ${services.length}');

    final writeCandidates = <BluetoothCharacteristic>[];
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        final uuid = characteristic.uuid.str.toLowerCase();
        final isWritable = characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse;
        if (isWritable && !_ignoredCharacteristicUuids.contains(uuid)) {
          writeCandidates.add(characteristic);
        }
      }
    }

    if (writeCandidates.isEmpty) {
      return const PrinterResult.error(
        'La impresora no tiene una característica de escritura BLE usable',
      );
    }

    writeCandidates.sort((a, b) {
      final aKnown = _knownPrinterCharacteristicUuids.contains(a.uuid.str.toLowerCase());
      final bKnown = _knownPrinterCharacteristicUuids.contains(b.uuid.str.toLowerCase());
      if (aKnown && !bKnown) return -1;
      if (!aKnown && bKnown) return 1;
      return 0;
    });

    final effectiveMtu = mtu > 3 ? mtu - 3 : 20;
    final data = bytes.toList();
    debugPrint(
      '[BluetoothPrinterService] Will send ${data.length} bytes in chunks of $effectiveMtu',
    );

    for (var i = 0; i < writeCandidates.length; i++) {
      final candidate = writeCandidates[i];
      debugPrint(
        '[BluetoothPrinterService] Trying characteristic ${i + 1}/${writeCandidates.length}: ${candidate.uuid.str}',
      );

      // Preferir writeWithoutResponse cuando esté disponible: la mayoría de
      // impresoras térmicas BLE lo soportan y es más rápido.
      final firstModes = candidate.properties.writeWithoutResponse
          ? [true, false]
          : [false, true];

      for (final withoutResponse in firstModes) {
        try {
          await _writeInChunks(
            candidate,
            data,
            chunkSize: effectiveMtu,
            withoutResponse: withoutResponse,
          );
          debugPrint(
            '[BluetoothPrinterService] WRITE OK on ${candidate.uuid.str}',
          );
          return PrinterResult.success(
            'Datos enviados por BLE (${candidate.uuid.str}, MTU=$mtu, bytes=${data.length})',
          );
        } catch (e) {
          debugPrint(
            '[BluetoothPrinterService] WRITE FAILED on ${candidate.uuid.str}: $e',
          );
        }
      }
    }

    return const PrinterResult.error(
      'No se pudo escribir en ninguna característica BLE',
    );
  }

  Future<void> _writeInChunks(
    BluetoothCharacteristic characteristic,
    List<int> data, {
    required int chunkSize,
    required bool withoutResponse,
  }) async {
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = data.sublist(i, end);
      await characteristic.write(
        chunk,
        withoutResponse: withoutResponse,
        allowLongWrite: !withoutResponse,
      );
      if (i + chunkSize < data.length) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
    }
  }

  Future<void> _logBleServices(BluetoothDevice device) async {
    try {
      debugPrint('[BluetoothPrinterService] Discovering BLE services...');
      final services = await device.discoverServices();
      debugPrint('[BluetoothPrinterService] Services found: ${services.length}');
      for (final service in services) {
        debugPrint('  SERVICE ${service.uuid}');
        for (final c in service.characteristics) {
          final props = <String>[];
          if (c.properties.broadcast) props.add('broadcast');
          if (c.properties.read) props.add('read');
          if (c.properties.writeWithoutResponse) props.add('writeWithoutResponse');
          if (c.properties.write) props.add('write');
          if (c.properties.notify) props.add('notify');
          if (c.properties.indicate) props.add('indicate');
          debugPrint('    CHAR ${c.uuid} properties=[${props.join(',')}]');
        }
      }
    } catch (e) {
      debugPrint('[BluetoothPrinterService] Error discovering services: $e');
    }
  }

  // UUIDs de características conocidas de impresoras térmicas BLE.
  static const _knownPrinterCharacteristicUuids = [
    '0000ae01-0000-1000-8000-00805f9b34fb', // Xprinter / many Chinese printers
    '0000ff01-0000-1000-8000-00805f9b34fb', // Generic printer data
    '0000ff02-0000-1000-8000-00805f9b34fb',
    '0000fff1-0000-1000-8000-00805f9b34fb',
    '0000fff2-0000-1000-8000-00805f9b34fb',
    '49535343-8841-43f4-a8d4-ecbe34729bb3', // Star
    'bef8d6c9-9c21-4c9e-b632-bd58c1009f9f', // Epson
  ];

  // UUIDs de características GAP/GATT que NUNCA deben usarse para datos.
  static const _ignoredCharacteristicUuids = [
    '00002a00-0000-1000-8000-00805f9b34fb', // Device Name
    '00002a01-0000-1000-8000-00805f9b34fb', // Appearance
    '00002a04-0000-1000-8000-00805f9b34fb', // Peripheral Preferred Connection Parameters
    '00002a05-0000-1000-8000-00805f9b34fb', // Service Changed
    '00002a29-0000-1000-8000-00805f9b34fb', // Manufacturer Name String
    '00002a50-0000-1000-8000-00805f9b34fb', // PnP ID
  ];

  @override
  Future<PrinterResult> printPdf(pw.Document document) async {
    return const PrinterResult.error(
      'Este servicio imprime bytes ESC/POS, no PDF',
    );
  }

  @override
  bool get supportsPdf => false;

  @override
  Future<void> dispose() async {
    await _bleConnectionSubscription?.cancel();
    _bleConnectionSubscription = null;
    await _connectionStateController.close();
  }
}
