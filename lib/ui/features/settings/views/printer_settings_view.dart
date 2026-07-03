import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/providers/printer_provider.dart';
import '../../../../data/services/printer/esc_pos_receipt_generator.dart';
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
  bool _isScanning = false;
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(printerConfigProvider);
    final devicesAsync = ref.watch(printerDevicesProvider);

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
            _buildSerialConfig(config),
          if (_connectionType != PrinterConnectionType.serial)
            _buildDeviceScanner(devicesAsync),
          const SizedBox(height: 24),
          _buildTestButton(),
          const SizedBox(height: 12),
          _buildSaveButton(config),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
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
              'Configura tu impresora de tickets. Soporta Bluetooth en móvil y USB/COM en PC.',
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
              initialValue: _connectionType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: PrinterConnectionType.values
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

  Widget _buildSerialConfig(PrinterConfig? currentConfig) {
    final comPort = currentConfig?.comPort ?? 'COM1';
    final baudRate = currentConfig?.baudRate ?? 9600;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Puerto serial (Windows)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: comPort),
              decoration: const InputDecoration(
                labelText: 'Puerto COM',
                hintText: 'COM1',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _selectedAddress = value,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: baudRate.toString()),
              decoration: const InputDecoration(
                labelText: 'Baud rate',
                hintText: '9600',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceScanner(AsyncValue<List<PrinterDevice>> devicesAsync) {
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
                  icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
                  label: Text(_isScanning ? 'Detener' : 'Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            devicesAsync.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return Text(
                    _isScanning
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
                        device.connectionType == PrinterConnectionType.bluetooth
                            ? Icons.bluetooth
                            : Icons.usb,
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

  void _toggleScanning() {
    setState(() => _isScanning = !_isScanning);
    // El stream se maneja automáticamente por printerDevicesProvider
  }

  Future<void> _testPrint() async {
    setState(() => _isTesting = true);
    try {
      final bytes = await _generateTestPage();
      final result = await ref.read(printTicketProvider)(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<Uint8List> _generateTestPage() async {
    return const EscPosReceiptGenerator(paperWidthMm: 58).generateTestPage();
  }

  Future<void> _saveConfig() async {
    if (_connectionType == PrinterConnectionType.serial) {
      // TODO: leer valores de los controllers
      final config = PrinterConfig(
        connectionType: PrinterConnectionType.serial,
        comPort: _selectedAddress ?? 'COM1',
        address: _selectedAddress ?? 'COM1',
        name: 'Puerto ${_selectedAddress ?? 'COM1'}',
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
