import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/providers/user_management_providers.dart';
import '../../../../domain/models/user.dart';
import 'widgets/user_role_badge.dart';

class UsersView extends ConsumerWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
      ),
      body: _buildBody(context, ref, state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/users/create'),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo usuario'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, UsersState state) {
    if (state.isLoading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(usersProvider.notifier).load(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.users.isEmpty) {
      return const Center(child: Text('No hay usuarios registrados'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(usersProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: state.users.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = state.users[index];
          return _UserCard(user: user);
        },
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final User user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.person,
            color: user.isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(user.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            if (user.phone != null && user.phone!.isNotEmpty)
              Text(user.phone!),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                UserRoleBadge(role: user.role),
                _StatusChip(isActive: user.isActive),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => context.push('/users/edit/${user.id}'),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.red;
    return Chip(
      label: Text(isActive ? 'Activo' : 'Inactivo'),
      backgroundColor: color.withAlpha(30),
      side: BorderSide(color: color.withAlpha(100)),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
