import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:applicoresestacion/data/providers/product_providers.dart';
import 'package:applicoresestacion/domain/models/product.dart' as models;

/// Modal escáner de código de barras que muestra el producto escaneado
/// de forma minimalista con iconos y gráficos.
class ProductBarcodeScannerModal extends ConsumerStatefulWidget {
  /// Si se proporciona, al escanear un código válido se invoca este callback
  /// y se cierra el modal inmediatamente sin buscar el producto.
  final ValueChanged<String>? onBarcode;

  const ProductBarcodeScannerModal({super.key, this.onBarcode});

  @override
  ConsumerState<ProductBarcodeScannerModal> createState() =>
      _ProductBarcodeScannerModalState();
}

class _ProductBarcodeScannerModalState
    extends ConsumerState<ProductBarcodeScannerModal> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _hasScanned = false;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  models.Product? _scannedProduct;
  String? _errorMessage;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  void _setError(String? message) {
    if (!_isDisposed && mounted) {
      setState(() => _errorMessage = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxHeight = size.height * 0.92;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                  _buildOverlay(),
                  _buildCameraControls(),
                ],
              ),
            ),
            if (_scannedProduct != null)
              _buildProductResult(_scannedProduct!)
            else if (_errorMessage != null)
              _buildErrorPanel(_errorMessage!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escanear precio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Apunta el código de barras',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Container(
        width: 260,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(
            color: _scannedProduct != null ? Colors.green : Colors.white,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          const SizedBox(width: 24),
          _buildControlButton(
            icon: Icons.cameraswitch,
            onPressed: () => _controller.switchCamera(),
          ),
          if (_scannedProduct != null) ...[
            const SizedBox(width: 24),
            _buildControlButton(
              icon: Icons.refresh,
              onPressed: _reset,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorPanel(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Escanear otro'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductResult(models.Product product) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory,
                    size: 32,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${product.presentation} · #${product.code}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildPriceTile(
                  label: 'Detal',
                  value: product.priceRetail,
                  color: Colors.green,
                  icon: Icons.person,
                ),
                const SizedBox(width: 12),
                _buildPriceTile(
                  label: 'Mayorista',
                  value: product.priceWholesale,
                  color: Colors.indigo,
                  icon: Icons.groups,
                ),
                if (product.priceCold != null) ...[
                  const SizedBox(width: 12),
                  _buildPriceTile(
                    label: 'Frío',
                    value: product.priceCold!,
                    color: Colors.lightBlue,
                    icon: Icons.ac_unit,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            _buildStockIndicator(product),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/products/${product.id}');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTile({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '\$${value.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockIndicator(models.Product product) {
    final ratio = product.stockMax > 0
        ? (product.stockCurrent / product.stockMax).clamp(0.0, 1.0)
        : 0.0;
    final color = product.stockCurrent <= product.stockMin
        ? Colors.orange
        : product.stockCurrent == 0
            ? Colors.red
            : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              'Stock: ${product.stockCurrent} / ${product.stockMax}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _hasScanned = true);
    await _controller.stop();

    if (widget.onBarcode != null) {
      debugPrint('[BarcodeScanner] Callback mode - barcode: $rawValue');
      widget.onBarcode!(rawValue);
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    debugPrint('[BarcodeScanner] Search mode - barcode: $rawValue');
    try {
      final product = await ref
          .read(productsProvider.notifier)
          .getByBarcode(rawValue);

      if (mounted) {
        setState(() {
          if (product != null) {
            _scannedProduct = product;
            _setError(null);
          } else {
            _setError('No se encontró producto con código $rawValue');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _setError('Error: $e');
      }
    }
  }

  void _reset() {
    setState(() {
      _hasScanned = false;
      _scannedProduct = null;
      _setError(null);
    });
    _controller.start();
  }
}
