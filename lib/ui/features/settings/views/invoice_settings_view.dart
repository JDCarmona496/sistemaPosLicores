import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../../data/providers/settings_providers.dart';
import '../../../../domain/models/invoice_config.dart';

class InvoiceSettingsView extends ConsumerStatefulWidget {
  const InvoiceSettingsView({super.key});

  @override
  ConsumerState<InvoiceSettingsView> createState() => _InvoiceSettingsViewState();
}

class _InvoiceSettingsViewState extends ConsumerState<InvoiceSettingsView> {
  final _businessNameController = TextEditingController();
  final _businessNitController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _sellerNameController = TextEditingController();
  final _invoiceFooterController = TextEditingController();
  final _legalTextController = TextEditingController();

  String _logoBase64 = '';
  bool _isPickingLogo = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(invoiceConfigProvider);
    _businessNameController.text = config.businessName;
    _businessNitController.text = config.businessNit;
    _businessAddressController.text = config.businessAddress;
    _businessPhoneController.text = config.businessPhone;
    _sellerNameController.text = config.sellerName;
    _invoiceFooterController.text = config.invoiceFooter;
    _legalTextController.text = config.legalText;
    _logoBase64 = config.logoBase64;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessNitController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _sellerNameController.dispose();
    _invoiceFooterController.dispose();
    _legalTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de factura'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildLogoSection(),
          const SizedBox(height: 24),
          _buildSectionTitle('Datos del negocio'),
          _buildTextField(
            controller: _businessNameController,
            label: 'Nombre del negocio *',
            icon: Icons.store,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _businessNitController,
            label: 'NIT / Identificación fiscal',
            icon: Icons.badge,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _businessAddressController,
            label: 'Dirección del negocio',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _businessPhoneController,
            label: 'Teléfono del negocio',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Recibo'),
          _buildTextField(
            controller: _sellerNameController,
            label: 'Nombre del vendedor por defecto',
            icon: Icons.person,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _invoiceFooterController,
            label: 'Pie de recibo',
            icon: Icons.notes,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _legalTextController,
            label: 'Texto legal / resolución (opcional)',
            icon: Icons.gavel,
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar configuración'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restore),
              label: const Text('Restablecer valores por defecto'),
            ),
          ),
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
              'Datos que aparecen en los recibos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta información se guarda en el dispositivo y se usa al imprimir recibos de pedidos.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    final hasLogo = _logoBase64.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Logo del negocio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Se imprime en la parte superior del recibo. Recomendado: fondo blanco, alto contraste.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (hasLogo)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.memory(
                    base64Decode(_logoBase64),
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (hasLogo) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPickingLogo ? null : _pickLogo,
                    icon: _isPickingLogo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.image),
                    label: Text(hasLogo ? 'Cambiar logo' : 'Seleccionar logo'),
                  ),
                ),
                if (hasLogo) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _removeLogo,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Quitar logo',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    setState(() => _isPickingLogo = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) return;

      final resized = await _resizeLogo(bytes);
      final base64 = base64Encode(resized);

      if (mounted) {
        setState(() => _logoBase64 = base64);
      }
    } catch (e) {
      debugPrint('Error picking logo: $e');
      if (mounted) {
        _showSnack('Error al seleccionar logo: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPickingLogo = false);
    }
  }

  Future<Uint8List> _resizeLogo(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('No se pudo decodificar la imagen');
    }

    // Para impresoras 58mm, 384 puntos de ancho es el máximo usable.
    const maxWidth = 384;
    img.Image resized = decoded;
    if (decoded.width > maxWidth) {
      resized = img.copyResize(decoded, width: maxWidth);
    }

    // Convertir a escala de grises para mejorar contraste en impresoras térmicas.
    final grayscale = img.grayscale(resized);

    return Uint8List.fromList(img.encodePng(grayscale));
  }

  void _removeLogo() {
    setState(() => _logoBase64 = '');
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Future<void> _save() async {
    final businessName = _businessNameController.text.trim();
    if (businessName.isEmpty) {
      _showSnack('El nombre del negocio es obligatorio', isError: true);
      return;
    }

    final config = InvoiceConfig(
      businessName: businessName,
      businessNit: _businessNitController.text.trim(),
      businessAddress: _businessAddressController.text.trim(),
      businessPhone: _businessPhoneController.text.trim(),
      sellerName: _sellerNameController.text.trim(),
      invoiceFooter: _invoiceFooterController.text.trim(),
      legalText: _legalTextController.text.trim(),
      logoBase64: _logoBase64,
    );

    await ref.read(invoiceConfigProvider.notifier).save(config);

    if (mounted) {
      _showSnack('Configuración guardada');
      context.pop();
    }
  }

  Future<void> _reset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer'),
        content: const Text(
          '¿Seguro que querés volver a los valores por defecto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await ref.read(invoiceConfigProvider.notifier).resetToDefault();
    final config = ref.read(invoiceConfigProvider);
    _businessNameController.text = config.businessName;
    _businessNitController.text = config.businessNit;
    _businessAddressController.text = config.businessAddress;
    _businessPhoneController.text = config.businessPhone;
    _sellerNameController.text = config.sellerName;
    _invoiceFooterController.text = config.invoiceFooter;
    _legalTextController.text = config.legalText;
    setState(() => _logoBase64 = config.logoBase64);

    if (mounted) _showSnack('Valores restablecidos');
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}
