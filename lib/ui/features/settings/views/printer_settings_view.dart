import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../data/providers/printer_provider.dart';
import '../../../../data/services/printer/printer_service.dart';
import '../../../../domain/models/printer_config.dart';

class PrinterSettingsView extends ConsumerStatefulWidget {
  const PrinterSettingsView({super.key});

  @override
  ConsumerState<PrinterSettingsView> createState() =>
      _PrinterSettingsViewState();
}

class _PrinterSettingsViewState extends ConsumerState<PrinterSettingsView> {
  PrinterConnectionType _connectionType = PrinterConnectionType.bluetooth;
  String? _selectedAddress;
  String? _selectedName;
  int _selectedBaudRate = 9600;
  final _manualComController = TextEditingController();
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(printerConfigProvider);
    final availableTypes = _availableConnectionTypes();

    if (config != null && availableTypes.contains(config.connectionType)) {
      _connectionType = config.connectionType;
      _selectedAddress = config.address;
      _selectedName = config.name;
      _selectedBaudRate = config.baudRate;
      _manualComController.text = config.comPort;
    } else {
      _connectionType = availableTypes.first;
    }

    // Sincronizar el tipo seleccionado con el provider de escaneo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedPrinterConnectionTypeProvider.notifier).state = _connectionType;
    });
  }

  @override
  void dispose() {
    _manualComController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(printerConfigProvider);
    final isScanning = ref.watch(isPrinterScanningProvider);
    final devicesAsync = isScanning
        ? ref.watch(printerDevicesProvider)
        : const AsyncValue<List<PrinterDevice>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Impresora'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildConnectionTypeSelector(config),
          const SizedBox(height: 16),
          if (_connectionType == PrinterConnectionType.serial)
            _buildSerialConfig(config, devicesAsync, isScanning),
          if (_connectionType != PrinterConnectionType.serial)
            _buildDeviceScanner(devicesAsync, isScanning),
          const SizedBox(height: 24),
          _buildTestButton(),
          const SizedBox(height: 12),
          _buildSaveButton(config),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final isWindows = defaultTargetPlatform == TargetPlatform.windows;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Impresora térmica ESC/POS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              isWindows
                  ? 'En Windows puedes usar una impresora POS-58 instalada en el sistema o un puerto COM.'
                  : 'Configura tu impresora de tickets. Soporta Bluetooth/USB en móvil.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Especificaciones recomendadas: 58mm, 203dpi, papel 0.06-0.08mm',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTypeSelector(PrinterConfig? currentConfig) {
    final availableTypes = _availableConnectionTypes();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de conexión',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PrinterConnectionType>(
              initialValue: availableTypes.contains(_connectionType)
                  ? _connectionType
                  : availableTypes.first,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: availableTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _connectionType = value;
                    _selectedAddress = null;
                    _selectedName = null;
                  });
                  ref.read(selectedPrinterConnectionTypeProvider.notifier).state = value;
                  // Detener el escaneo anterior si cambia el tipo de conexión
                  ref.read(isPrinterScanningProvider.notifier).state = false;
                }
              },
            ),
            if (currentConfig != null) ...[
              const SizedBox(height: 12),
              Text(
                'Configurada actualmente: ${currentConfig.connectionType.label} - ${currentConfig.name ?? currentConfig.address ?? currentConfig.comPort}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<PrinterConnectionType> _availableConnectionTypes() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return [
          PrinterConnectionType.windows,
          PrinterConnectionType.serial,
        ];
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return [
          PrinterConnectionType.bluetooth,
          PrinterConnectionType.usb,
          PrinterConnectionType.wifi,
        ];
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return [
          PrinterConnectionType.wifi,
        ];
    }
  }

  IconData _connectionTypeIcon(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.bluetooth:
        return Icons.bluetooth;
      case PrinterConnectionType.usb:
        return Icons.usb;
      case PrinterConnectionType.wifi:
        return Icons.wifi;
      case PrinterConnectionType.serial:
        return Icons.settings_ethernet;
      case PrinterConnectionType.windows:
        return Icons.print;
    }
  }

  Widget _buildSerialConfig(
    PrinterConfig? currentConfig,
    AsyncValue<List<PrinterDevice>> devicesAsync,
    bool isScanning,
  ) {
    final baudRates = [9600, 19200, 38400, 57600, 115200];
    if (!baudRates.contains(_selectedBaudRate)) {
      _selectedBaudRate = currentConfig?.baudRate ?? 9600;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Puerto COM',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _toggleScanning,
                  icon: Icon(isScanning ? Icons.stop : Icons.refresh),
                  label: Text(isScanning ? 'Detener' : 'Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            devicesAsync.when(
              data: (devices) {
                final comPorts = devices
                    .where((d) => d.connectionType == PrinterConnectionType.serial)
                    .toList();

                if (comPorts.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isScanning
                            ? 'Buscando puertos COM...'
                            : 'No se encontraron puertos COM automáticamente. Podés escribirlo manualmente abajo.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  );
                }

                // Si hay configuración previa, seleccionarla
                if (_selectedAddress == null && currentConfig != null) {
                  final existing = comPorts.firstWhere(
                    (d) => d.address == currentConfig.comPort,
                    orElse: () => comPorts.first,
                  );
                  _selectedAddress = existing.address;
                  _selectedName = existing.name;
                } else if (_selectedAddress == null) {
                  _selectedAddress = comPorts.first.address;
                  _selectedName = comPorts.first.name;
                }

                return Column(
                  children: comPorts.map((device) {
                    final isSelected = device.address == _selectedAddress;
                    return ListTile(
                      leading: const Icon(Icons.settings_ethernet),
                      title: Text(device.name ?? 'Puerto COM'),
                      subtitle: Text(device.address),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedAddress = device.address;
                          _selectedName = device.name;
                        });
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Baud rate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedBaudRate,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: baudRates
                  .map(
                    (rate) => DropdownMenuItem(
                      value: rate,
                      child: Text(rate.toString()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedBaudRate = value);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Puerto manual (opcional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Si la búsqueda no encuentra tu impresora, escribí el puerto aquí.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _manualComController,
              decoration: const InputDecoration(
                labelText: 'Ej: COM10',
                hintText: 'COM10',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                final clean = value.trim().toUpperCase();
                if (clean.isNotEmpty) {
                  setState(() {
                    _selectedAddress = clean;
                    _selectedName = 'Puerto $clean';
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceScanner(
    AsyncValue<List<PrinterDevice>> devicesAsync,
    bool isScanning,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dispositivos encontrados',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _toggleScanning,
                  icon: Icon(isScanning ? Icons.stop : Icons.refresh),
                  label: Text(isScanning ? 'Detener' : 'Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            devicesAsync.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return Text(
                    isScanning
                        ? 'Buscando dispositivos...'
                        : 'No se encontraron dispositivos. Presiona Buscar.',
                    style: TextStyle(color: Colors.grey.shade600),
                  );
                }
                return Column(
                  children: devices.map((device) {
                    final isSelected = device.address == _selectedAddress;
                    return ListTile(
                      leading: Icon(
                        _connectionTypeIcon(device.connectionType),
                      ),
                      title: Text(device.name ?? 'Desconocido'),
                      subtitle: Text(device.address),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedAddress = device.address;
                          _selectedName = device.name;
                        });
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isTesting ? null : _testPrint,
        icon: _isTesting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.print),
        label: const Text('Imprimir página de prueba'),
      ),
    );
  }

  Widget _buildSaveButton(PrinterConfig? currentConfig) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveConfig,
        icon: const Icon(Icons.save),
        label: const Text('Guardar configuración'),
      ),
    );
  }

  Future<void> _toggleScanning() async {
    final isScanning = ref.read(isPrinterScanningProvider);

    if (!isScanning) {
      // Al iniciar escaneo, pedir permisos y encender Bluetooth si es necesario
      if (_connectionType == PrinterConnectionType.bluetooth ||
          _connectionType == PrinterConnectionType.usb) {
        final hasPermission = await _requestBluetoothPermissions();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se necesitan permisos de Bluetooth para buscar dispositivos'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
    }

    ref.read(isPrinterScanningProvider.notifier).state = !isScanning;
  }

  Future<bool> _requestBluetoothPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;

    // Android 12+ (API 31+)
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();

    debugPrint('Permiso bluetoothScan: $bluetoothScan');
    debugPrint('Permiso bluetoothConnect: $bluetoothConnect');

    // En Android 12+ no debería hacer falta location si la librería no la usa.
    // La pedimos igual por compatibilidad, pero no la hacemos obligatoria.
    final location = await Permission.location.request();
    debugPrint('Permiso location: $location');

    return bluetoothScan.isGranted && bluetoothConnect.isGranted;
  }

  Future<void> _testPrint() async {
    debugPrint('[PrinterSettingsView] _testPrint pressed');
    setState(() => _isTesting = true);
    try {
      final result = await ref.read(printTestPageProvider)();
      debugPrint('[PrinterSettingsView] _testPrint result=$result');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('[PrinterSettingsView] _testPrint exception: $e');
      debugPrint(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _saveConfig() async {
    if (_connectionType == PrinterConnectionType.serial) {
      final manualPort = _manualComController.text.trim().toUpperCase();
      final comPort = _selectedAddress?.trim().toUpperCase() ??
          (manualPort.isNotEmpty ? manualPort : null);

      if (comPort == null || comPort.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selecciona o escribí un puerto COM'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      final config = PrinterConfig(
        connectionType: PrinterConnectionType.serial,
        comPort: comPort,
        address: comPort,
        name: _selectedName ?? 'Puerto $comPort',
        baudRate: _selectedBaudRate,
      );
      await ref.read(printerConfigProvider.notifier).save(config);
    } else {
      if (_selectedAddress == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selecciona un dispositivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      final config = PrinterConfig(
        connectionType: _connectionType,
        address: _selectedAddress,
        name: _selectedName,
      );
      await ref.read(printerConfigProvider.notifier).save(config);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
      context.pop();
    }
  }
}
