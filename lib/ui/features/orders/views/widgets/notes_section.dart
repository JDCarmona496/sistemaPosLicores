import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import 'section_header.dart';

/// Sección de notas u observaciones del pedido.
class NotesSection extends ConsumerWidget {
  final TextEditingController notesController;

  const NotesSection({super.key, required this.notesController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              icon: Icons.note_alt_outlined,
              title: 'Notas',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Observaciones',
                prefixIcon: Icon(Icons.note_outlined,
                    color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              onChanged: (value) => ref
                  .read(currentOrderCartProvider.notifier)
                  .setNotes(value),
            ),
          ],
        ),
      ),
    );
  }
}
