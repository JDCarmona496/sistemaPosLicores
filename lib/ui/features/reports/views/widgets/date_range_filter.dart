import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeFilter extends StatelessWidget {
  final DateTime dateFrom;
  final DateTime dateTo;
  final ValueChanged<DateTime> onDateFromChanged;
  final ValueChanged<DateTime> onDateToChanged;

  const DateRangeFilter({
    super.key,
    required this.dateFrom,
    required this.dateTo,
    required this.onDateFromChanged,
    required this.onDateToChanged,
  });

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  void _setRange(int days) {
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day);
    final from = to.subtract(Duration(days: days));
    onDateFromChanged(from);
    onDateToChanged(to);
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final initial = isFrom ? dateFrom : dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isFrom) {
        onDateFromChanged(picked);
      } else {
        onDateToChanged(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rango de fechas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PresetChip(label: 'Hoy', onTap: () => _setRange(0)),
                _PresetChip(label: '7 días', onTap: () => _setRange(6)),
                _PresetChip(label: '30 días', onTap: () => _setRange(29)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Desde',
                    date: dateFrom,
                    onTap: () => _pickDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Hasta',
                    date: dateTo,
                    onTap: () => _pickDate(context, false),
                  ),
                ),
              ],
            ),
            if (dateFrom.isAfter(dateTo)) ...[
              const SizedBox(height: 8),
              Text(
                'La fecha inicial no puede ser posterior a la final',
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        color: colorScheme.onSurface,
      ),
      backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(128),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      onPressed: onTap,
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: Icon(
            Icons.calendar_today,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        child: Text(
          DateRangeFilter._dateFormat.format(date),
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
