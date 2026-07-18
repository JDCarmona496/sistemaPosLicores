import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/user_providers.dart';

class DeliveryPersonSelectorDialog extends ConsumerWidget {
  const DeliveryPersonSelectorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(deliveryUsersProvider);

    return AlertDialog(
      title: const Text('Asignar domiciliario'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: usersAsync.when(
          data: (users) => users.isEmpty
              ? const Center(child: Text('No hay domiciliarios activos'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.fullName[0].toUpperCase()),
                      ),
                      title: Text(user.fullName),
                      subtitle: Text(user.email),
                      onTap: () => Navigator.pop(context, user),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
