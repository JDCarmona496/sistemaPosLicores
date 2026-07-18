import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/providers/settings_providers.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geocodingContext = ref.watch(geocodingContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Impresora térmica'),
            subtitle: const Text('Bluetooth, USB o puerto COM'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/printer'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.location_city),
            title: const Text('Zona de operación'),
            subtitle: Text(geocodingContext),
            trailing: const Icon(Icons.edit),
            onTap: () => _editGeocodingContext(context, ref, geocodingContext),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Acerca de'),
            subtitle: Text('Versión 0.1.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _editGeocodingContext(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_city),
        title: const Text('Zona de operación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ciudad, departamento y país donde opera el domicilio. '
              'Se usa para geocodificar las direcciones de entrega.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Zona',
                hintText: 'Cerrito, Valle del Cauca, Colombia',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(geocodingContextProvider.notifier).resetToDefault();
              Navigator.pop(context);
            },
            child: const Text('Restablecer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved != null && saved.trim().isNotEmpty) {
      await ref.read(geocodingContextProvider.notifier).setContext(saved);
    }
    controller.dispose();
  }
}
