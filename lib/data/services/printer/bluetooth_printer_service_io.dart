import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart' as ftp;
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/models/printer_config.dart';
import 'printer_service.dart';

/// Implementación de [PrinterService] usando flutter_thermal_printer.
/// Soporta Bluetooth/BLE y USB en Android, iOS, macOS y Windows.
class BluetoothPrinterService implements PrinterService {
  final FlutterThermalPrinter _plugin = FlutterThermalPrinter.instance;
  ftp.Printer? _connectedPrinter;
  BluetoothDevice? _connectedBtDevice;

  @override
  Stream<List<PrinterDevice>> discoverDevices() async* {
    final controller = StreamController<List<PrinterDevice>>.broadcast();

    try {
      final isOn = await _plugin.isBleTurnedOn();
      debugPrint('[BluetoothPrinterService] Bluetooth encendido: $isOn');
      if (!isOn) {
        debugPrint(
          '[BluetoothPrinterService] ADVERTENCIA: Bluetooth apagado. '
          'Enciéndelo manualmente para usar la impresora.',
        );
      }

      debugPrint('[BluetoothPrinterService] Iniciando escaneo BLE/USB...');
      // ignore: unused_local_variable
      final _ = _plugin.getPrinters(
        refreshDuration: const Duration(seconds: 2),
        connectionTypes: const [
          ftp.ConnectionType.BLE,
          ftp.ConnectionType.USB,
        ],
        androidUsesFineLocation: false,
      );

      _plugin.devicesStream.listen((printers) {
        debugPrint(
          '[BluetoothPrinterService] Dispositivos encontrados: ${printers.length}',
        );
        for (final p in printers) {
          debugPrint(
            '  - ${p.name} / ${p.address} / ${p.connectionType} / connected=${p.isConnected}',
          );
        }
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
    } catch (e, stack) {
      debugPrint('[BluetoothPrinterService] Error en discoverDevices: $e');
      debugPrint(stack.toString());
      controller.addError(e);
    }

    yield* controller.stream;
  }

  @override
  Future<PrinterResult> connect(PrinterConfig config) async {
    try {
      debugPrint(
        '[BluetoothPrinterService] CONNECT START name=${config.name} address=${config.address} type=${config.connectionType}',
      );

      // Verificar si Bluetooth está encendido
      final isOn = await _plugin.isBleTurnedOn();
      if (!isOn) {
        debugPrint('[BluetoothPrinterService] Bluetooth está apagado');
        return const PrinterResult.error(
          'Bluetooth apagado. Enciende el Bluetooth e intenta de nuevo.',
        );
      }

      // Intentar obtener dispositivos con retry
      List<ftp.Printer> printers = [];
      for (int attempt = 0; attempt < 3; attempt++) {
        debugPrint('[BluetoothPrinterService] Intento ${attempt + 1}/3 de obtener dispositivos...');
        try {
          printers = await _plugin.devicesStream.first.timeout(
            const Duration(seconds: 8),
            onTimeout: () => [],
          );
          if (printers.isNotEmpty) break;
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          debugPrint('[BluetoothPrinterService] Error en intento ${attempt + 1}: $e');
          if (attempt == 2) {
            return PrinterResult.error(
              'No se pudieron obtener dispositivos después de 3 intentos: $e',
            );
          }
        }
      }

      debugPrint(
        '[BluetoothPrinterService] Printers in stream: ${printers.length}',
      );
      for (final p in printers) {
        debugPrint(
          '  candidate: name=${p.name} address=${p.address} type=${p.connectionType} connected=${p.isConnected}',
        );
      }

      if (printers.isEmpty) {
        return const PrinterResult.error(
          'No se encontraron impresoras. Asegúrate de que la impresora esté encendida y en rango.',
        );
      }

      final printer = printers.firstWhere(
        (p) =>
            p.address == config.address ||
            (p.name != null && p.name == config.name),
        orElse: () => throw Exception('Impresora no encontrada en el escaneo'),
      );
      debugPrint(
        '[BluetoothPrinterService] MATCHED printer: ${printer.name} / ${printer.address} / ${printer.connectionType}',
      );

      if (printer.connectionType == ftp.ConnectionType.USB) {
        debugPrint(
          '[BluetoothPrinterService] Conectando a impresora USB ${printer.name}...',
        );
        final connected = await _plugin.connect(printer);
        if (connected) {
          _connectedPrinter = printer;
          _connectedBtDevice = null;
          debugPrint('[BluetoothPrinterService] USB CONNECT OK');
          return const PrinterResult.success('Conectado por USB');
        }
        debugPrint('[BluetoothPrinterService] USB CONNECT FAILED');
        return const PrinterResult.error('No se pudo conectar por USB');
      }

      final btDevice = BluetoothDevice.fromId(printer.address!);
      debugPrint(
        '[BluetoothPrinterService] BLE device state before connect: isConnected=${btDevice.isConnected} isDisconnected=${btDevice.isDisconnected}',
      );

      if (btDevice.isConnected) {
        debugPrint('[BluetoothPrinterService] Desconectando primero...');
        try {
          await btDevice.disconnect();
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          debugPrint('[BluetoothPrinterService] Error al desconectar: $e');
        }
      }

      debugPrint(
        '[BluetoothPrinterService] BLE connect() call name=${printer.name} address=${printer.address}',
      );
      
      // Intentar conectar con retry
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          await btDevice.connect(
            timeout: const Duration(seconds: 15),
            mtu: 512,
            autoConnect: false,
          );

          final isConnected = await _waitForConnection(
            btDevice,
            timeout: const Duration(seconds: 8),
          );
          debugPrint(
            '[BluetoothPrinterService] BLE connection confirmed=$isConnected device.isConnected=${btDevice.isConnected}',
          );

          if (isConnected) {
            _connectedPrinter = printer;
            _connectedBtDevice = btDevice;
            debugPrint('[BluetoothPrinterService] BLE CONNECT OK');
            await _logBleServices(btDevice);
            return const PrinterResult.success('Conectado por Bluetooth');
          }
        } catch (e) {
          debugPrint('[BluetoothPrinterService] Intento ${attempt + 1} falló: $e');
          if (attempt == 1) {
            return PrinterResult.error(
              'No se pudo conectar después de 2 intentos. Asegúrate de que la impresora esté encendida y emparejada.',
            );
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      return const PrinterResult.error(
        'No se pudo conectar. Asegúrate de que la impresora esté encendida y emparejada.',
      );
    } catch (e, stack) {
      debugPrint('[BluetoothPrinterService] Error al conectar: $e');
      debugPrint(stack.toString());
      return PrinterResult.error('Error al conectar: $e');
    }
  }

  Future<bool> _waitForConnection(
    BluetoothDevice device, {
    required Duration timeout,
  }) async {
    if (device.isConnected) return true;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = device.connectionState.listen((state) {
      debugPrint('[BluetoothPrinterService] BLE state: $state');
      if (state == BluetoothConnectionState.connected) {
        if (!completer.isCompleted) completer.complete(true);
      }
    }, onError: (e) {
      if (!completer.isCompleted) completer.complete(false);
    });

    final result = await completer.future.timeout(
      timeout,
      onTimeout: () => device.isConnected,
    );
    await subscription.cancel();
    return result;
  }

  @override
  Future<PrinterResult> disconnect() async {
    if (_connectedPrinter == null) {
      return const PrinterResult.success('No había conexión activa');
    }
    try {
      debugPrint(
        '[BluetoothPrinterService] Desconectando de ${_connectedPrinter!.name}...',
      );
      await _plugin.disconnect(_connectedPrinter!);
      _connectedPrinter = null;
      _connectedBtDevice = null;
      return const PrinterResult.success('Desconectado');
    } catch (e) {
      debugPrint('[BluetoothPrinterService] Error al desconectar: $e');
      return PrinterResult.error('Error al desconectar: $e');
    }
  }

  @override
  Future<PrinterResult> printBytes(Uint8List bytes) async {
    if (_connectedPrinter == null) {
      return const PrinterResult.error('No hay impresora conectada');
    }

    try {
      if (_connectedPrinter!.connectionType == ftp.ConnectionType.USB) {
        debugPrint(
          '[BluetoothPrinterService] Enviando ${bytes.length} bytes por USB...',
        );
        await _plugin.printData(
          _connectedPrinter!,
          bytes.toList(),
          longData: false,
        );
        return const PrinterResult.success('Datos enviados por USB');
      }

      return await _printWithFlutterBluePlus(bytes);
    } catch (e) {
      debugPrint('[BluetoothPrinterService] Error al imprimir: $e');
      return PrinterResult.error('Error al imprimir: $e');
    }
  }

  Future<void> _logBleServices(BluetoothDevice device) async {
    try {
      debugPrint('[BluetoothPrinterService] Discovering BLE services...');
      final services = await device.discoverServices();
      debugPrint(
        '[BluetoothPrinterService] Services found: ${services.length}',
      );
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
          debugPrint(
            '    CHAR ${c.uuid} properties=[${props.join(',')}]',
          );
        }
      }
    } catch (e) {
      debugPrint('[BluetoothPrinterService] Error discovering services: $e');
    }
  }

  // UUIDs de características conocidas de impresoras térmicas BLE.
  // Se usan para priorizar el canal de datos correcto.
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

  Future<PrinterResult> _printWithFlutterBluePlus(Uint8List bytes) async {
    final device = _connectedBtDevice;
    if (device == null) {
      return const PrinterResult.error('No hay dispositivo BLE conectado');
    }

    if (device.isDisconnected) {
      debugPrint('[BluetoothPrinterService] Reconectando BLE...');
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
        return const PrinterResult.error('No se pudo reconectar la impresora');
      }
    }

    debugPrint(
      '[BluetoothPrinterService] PRINT START: ${bytes.length} bytes',
    );

    int? mtu;
    try {
      mtu = await device.mtu.first;
      debugPrint('[BluetoothPrinterService] Current MTU: $mtu');
    } catch (e) {
      debugPrint('[BluetoothPrinterService] Could not read MTU: $e');
    }

    debugPrint(
      '[BluetoothPrinterService] Descubriendo servicios BLE para imprimir...',
    );
    final services = await device.discoverServices();
    debugPrint(
      '[BluetoothPrinterService] Services discovered: ${services.length}',
    );

    final writeCandidates = <BluetoothCharacteristic>[];
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        final uuid = characteristic.uuid.str.toLowerCase();
        final isWritable = characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse;
        debugPrint(
          '  CHAR $uuid write=${characteristic.properties.write} '
          'writeWithoutResponse=${characteristic.properties.writeWithoutResponse}',
        );
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

    // Ordenar: primero UUIDs conocidos de impresora, luego el resto.
    writeCandidates.sort((a, b) {
      final aKnown = _knownPrinterCharacteristicUuids.contains(a.uuid.str.toLowerCase());
      final bKnown = _knownPrinterCharacteristicUuids.contains(b.uuid.str.toLowerCase());
      if (aKnown && !bKnown) return -1;
      if (!aKnown && bKnown) return 1;
      return 0;
    });

    debugPrint(
      '[BluetoothPrinterService] ${writeCandidates.length} writable characteristic(s) found',
    );
    for (var i = 0; i < writeCandidates.length; i++) {
      debugPrint(
        '  candidate ${i + 1}: ${writeCandidates[i].uuid.str}',
      );
    }

    // Intentamos escribir en cada característica candidata hasta que una tenga éxito.
    for (var i = 0; i < writeCandidates.length; i++) {
      final candidate = writeCandidates[i];
      debugPrint(
        '[BluetoothPrinterService] Trying characteristic ${i + 1}/${writeCandidates.length}: ${candidate.uuid.str}',
      );

      final effectiveMtu = (mtu != null && mtu > 3) ? mtu - 3 : 512;
      final data = bytes.toList();
      debugPrint(
        '[BluetoothPrinterService] Will send ${data.length} bytes in chunks of $effectiveMtu',
      );

      final firstModes = candidate.properties.writeWithoutResponse
          ? [true, false]
          : [false, true];

      for (final withoutResponse in firstModes) {
        try {
          debugPrint(
            '[BluetoothPrinterService] Writing withoutResponse=$withoutResponse',
          );
          await _writeInChunks(
            candidate,
            data,
            chunkSize: effectiveMtu,
            withoutResponse: withoutResponse,
          );
          debugPrint(
            '[BluetoothPrinterService] WRITE OK on ${candidate.uuid.str} withoutResponse=$withoutResponse',
          );
          return PrinterResult.success(
            'Datos enviados por BLE (${candidate.uuid.str}, sinRespuesta=$withoutResponse, MTU=${mtu ?? '?'}, bytes=${data.length})',
          );
        } catch (e) {
          debugPrint(
            '[BluetoothPrinterService] WRITE FAILED on ${candidate.uuid.str} withoutResponse=$withoutResponse: $e',
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
      debugPrint(
        '[BluetoothPrinterService] Sending chunk ${i ~/ chunkSize + 1}: ${chunk.length} bytes',
      );
      await characteristic.write(
        chunk,
        withoutResponse: withoutResponse,
        allowLongWrite: !withoutResponse,
      );
      // Pequeña pausa para no saturar la impresora BLE.
      if (i + chunkSize < data.length) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
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
