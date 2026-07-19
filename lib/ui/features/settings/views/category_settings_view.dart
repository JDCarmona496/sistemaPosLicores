import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/product_providers.dart';
import '../../../../data/repositories/category_repository.dart';

class CategorySettingsView extends ConsumerWidget {
  const CategorySettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (categories) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              leading: const Icon(Icons.category),
              title: Text(category.name),
              subtitle: category.description != null && category.description!.isNotEmpty
                  ? Text(category.description!)
                  : null,
              trailing: Switch(
                value: category.isActive,
                onChanged: (value) async {
                  await _toggleActive(ref, category, value);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Categoría'),
      ),
    );
  }

  Future<void> _toggleActive(WidgetRef ref, Category category, bool value) async {
    final repository = ref.read(categoryRepositoryProvider);
    try {
      await repository.update(
        Category(
          id: category.id,
          name: category.name,
          slug: category.slug,
          description: category.description,
          parentId: category.parentId,
          iconUrl: category.iconUrl,
          isActive: value,
        ),
      );
      ref.invalidate(categoriesProvider);
    } catch (e) {
      // Errors handled by snackbars are not implemented here to keep simple.
    }
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.category),
        title: const Text('Nueva Categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final repository = ref.read(categoryRepositoryProvider);
      final name = nameController.text.trim();
      await repository.create(
        Category(
          id: '',
          name: name,
          slug: _slugify(name),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        ),
      );
      ref.invalidate(categoriesProvider);
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }
}
