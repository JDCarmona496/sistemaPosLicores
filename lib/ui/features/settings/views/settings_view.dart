import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
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
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            subtitle: const Text('Versión 0.1.0'),
          ),
        ],
      ),
    );
  }
}
