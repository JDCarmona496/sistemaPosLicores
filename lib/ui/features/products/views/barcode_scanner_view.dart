import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código de Barras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_off),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Linterna',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Cambiar cámara',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_hasScanned) return;

              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final barcode = barcodes.first;
              final rawValue = barcode.rawValue;

              if (rawValue == null || rawValue.isEmpty) return;

              setState(() => _hasScanned = true);

              context.pop(rawValue);
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Apunta al código de barras',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
