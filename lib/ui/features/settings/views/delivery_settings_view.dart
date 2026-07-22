import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/settings_providers.dart';
import '../../../../domain/models/delivery_config.dart';

class DeliverySettingsView extends ConsumerWidget {
  const DeliverySettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(deliveryConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Domicilios'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Asignación de domiciliarios',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elige cómo se asignan los pedidos de domicilio al crearlos.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...DeliveryAssignmentMode.values.map((mode) {
                    return RadioListTile<DeliveryAssignmentMode>(
                      title: Text(mode.label),
                      subtitle: Text(
                        mode.description,
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: mode,
                      // ignore: deprecated_member_use
                      groupValue: config.assignmentMode,
                      // ignore: deprecated_member_use
                      onChanged: (value) async {
                        if (value == null) return;
                        final saved = await ref
                            .read(deliveryConfigProvider.notifier)
                            .save(config.copyWith(assignmentMode: value));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                saved
                                    ? 'Configuración guardada'
                                    : 'Error al guardar la configuración',
                              ),
                              backgroundColor: saved ? null : Colors.red,
                            ),
                          );
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nota',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'En modo automático el sistema busca el domiciliario con menos pedidos activos (pendientes, listos o en camino) y lo asigna al crear el pedido. Si todos están ocupados, elige el menos ocupado. Desde el detalle del pedido siempre podés cambiar la asignación manualmente.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
