import 'package:flutter/material.dart';

/// Paleta y estilos compartidos para los gráficos de reportes.
/// Diseño minimalista: colores suaves, grillas tenues y tipografía limpia.
abstract class ChartStyles {
  /// Colores acentuados suaves para gráficos circulares y categorías.
  static const palette = [
    Color(0xFF5B8DEE), // azul
    Color(0xFF42C9B0), // verde agua
    Color(0xFFF4A259), // naranja
    Color(0xFF9B7EDE), // lila
    Color(0xFFEF5DA8), // rosa
    Color(0xFF7FD3C4), // menta
    Color(0xFFE16036), // coral
    Color(0xFF5C6BC0), // índigo
  ];

  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  static Color dividerColor(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant.withAlpha(64);
  }

  static Color mutedTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static TextStyle axisTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: mutedTextColor(context),
    );
  }

  static TextStyle tooltipTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle chartTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle chartSubtitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      color: mutedTextColor(context),
    );
  }

  /// Formatea valores grandes de forma compacta (e.g. 1.2k).
  static String compactMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  /// Formatea moneda completa con separadores de miles.
  static String formatMoney(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }
}
