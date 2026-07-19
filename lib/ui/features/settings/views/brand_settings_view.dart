import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/product_providers.dart';
import '../../../../data/repositories/brand_repository.dart';

class BrandSettingsView extends ConsumerWidget {
  const BrandSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcas'),
      ),
      body: brandsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (brands) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: brands.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final brand = brands[index];
            return ListTile(
              leading: const Icon(Icons.branding_watermark),
              title: Text(brand.name),
              subtitle: brand.description != null && brand.description!.isNotEmpty
                  ? Text(brand.description!)
                  : null,
              trailing: Switch(
                value: brand.isActive,
                onChanged: (value) async {
                  await _toggleActive(ref, brand, value);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Marca'),
      ),
    );
  }

  Future<void> _toggleActive(WidgetRef ref, Brand brand, bool value) async {
    final repository = ref.read(brandRepositoryProvider);
    try {
      await repository.update(
        Brand(
          id: brand.id,
          name: brand.name,
          slug: brand.slug,
          description: brand.description,
          logoUrl: brand.logoUrl,
          isActive: value,
        ),
      );
      ref.invalidate(brandsProvider);
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
        icon: const Icon(Icons.branding_watermark),
        title: const Text('Nueva Marca'),
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
      final repository = ref.read(brandRepositoryProvider);
      final name = nameController.text.trim();
      await repository.create(
        Brand(
          id: '',
          name: name,
          slug: _slugify(name),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        ),
      );
      ref.invalidate(brandsProvider);
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
