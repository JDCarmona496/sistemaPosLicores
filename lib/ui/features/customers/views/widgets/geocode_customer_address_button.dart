import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/settings_providers.dart';

/// Botón para geocodificar la dirección de un cliente desde el formulario.
///
/// Usa Nominatim + el contexto de zona configurado. Si encuentra una
/// coordenada, llena los campos de latitud y longitud del formulario.
class GeocodeCustomerAddressButton extends ConsumerStatefulWidget {
  final TextEditingController addressController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;

  const GeocodeCustomerAddressButton({
    super.key,
    required this.addressController,
    required this.latitudeController,
    required this.longitudeController,
  });

  @override
  ConsumerState<GeocodeCustomerAddressButton> createState() =>
      _GeocodeCustomerAddressButtonState();
}

class _GeocodeCustomerAddressButtonState
    extends ConsumerState<GeocodeCustomerAddressButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _geocode,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.location_searching),
      label: Text(_isLoading ? 'Buscando...' : 'Buscar coordenadas por dirección'),
    );
  }

  Future<void> _geocode() async {
    final address = widget.addressController.text.trim();
    if (address.isEmpty) {
      _showSnack('Escribe una dirección primero', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(geocodingServiceProvider);
      final context = ref.read(geocodingContextProvider);
      final result = await service.geocode(address, locationContext: context);

      if (!mounted) return;

      if (result == null) {
        _showSnack('No se encontró la ubicación. Revisa la dirección.',
            isError: true);
        return;
      }

      widget.latitudeController.text = result.latitude.toStringAsFixed(8);
      widget.longitudeController.text = result.longitude.toStringAsFixed(8);
      _showSnack('Coordenada encontrada: ${result.displayName ?? ''}');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al geocodificar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}
