import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import '../../../../../data/providers/settings_providers.dart';

/// Boton que geocodifica la direccion de entrega actual y guarda
/// las coordenadas en el carrito. Muestra el estado de la captura.
class GeocodeAddressButton extends ConsumerStatefulWidget {
  final TextEditingController addressController;

  const GeocodeAddressButton({super.key, required this.addressController});

  @override
  ConsumerState<GeocodeAddressButton> createState() =>
      _GeocodeAddressButtonState();
}

class _GeocodeAddressButtonState extends ConsumerState<GeocodeAddressButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(currentOrderCartProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (cartState.hasDeliveryCoordinates) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.gps_fixed, size: 16, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ubicación capturada '
                '(${cartState.deliveryLatitude!.toStringAsFixed(4)}, '
                '${cartState.deliveryLongitude!.toStringAsFixed(4)})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isLoading ? null : _geocode,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: _isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh,
                        size: 16, color: Colors.green.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _geocode,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      label: Text(_isLoading ? 'Buscando...' : 'Obtener ubicación'),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
      ),
    );
  }

  Future<void> _geocode() async {
    final address = widget.addressController.text.trim();
    if (address.isEmpty) {
      _showSnack('Escribe primero la dirección de entrega', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final service = ref.read(geocodingServiceProvider);
    final locationContext = ref.read(geocodingContextProvider);
    final result =
        await service.geocode(address, locationContext: locationContext);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) {
      _showSnack(
        'No se encontró la dirección. Revisa que esté bien escrita '
        'o ajusta la zona de operación en Configuración.',
        isError: true,
      );
      return;
    }

    ref
        .read(currentOrderCartProvider.notifier)
        .setDeliveryCoordinates(result.latitude, result.longitude);

    _showSnack('Ubicación: ${result.displayName}');
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}
