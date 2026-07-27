import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'data/providers/printer_provider.dart';
import 'data/providers/settings_providers.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/window_size/window_size_service.dart';
import 'domain/models/delivery_config.dart';
import 'domain/models/invoice_config.dart';
import 'domain/models/printer_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Leer configuraciones guardadas en el directorio raíz de la app ANTES de
  // arrancar la UI. En escritorio la lectura es síncrona; en móvil cae en
  // SharedPreferences/app support si no hay archivo raíz.
  final preloadedConfigs = await _loadConfigs();

  await SupabaseConfig.initialize();

  // En web, Supabase necesita un momento para restaurar la sesión desde
  // localStorage. Esperamos el evento inicial antes de construir el router,
  // de lo contrario currentSession puede ser null en el primer frame.
  if (kIsWeb) {
    await _waitForInitialSession();
    await WindowSizeService.instance.initialize();
  }

  runApp(
    ProviderScope(
      overrides: [
        printerConfigProvider.overrideWith(
          (ref) => PrinterConfigNotifier.preloaded(preloadedConfigs.printer),
        ),
        invoiceConfigProvider.overrideWith(
          (ref) => InvoiceConfigNotifier.preloaded(preloadedConfigs.invoice),
        ),
        deliveryConfigProvider.overrideWith(
          (ref) => DeliveryConfigNotifier.preloaded(preloadedConfigs.delivery),
        ),
      ],
      child: const LicoreriaApp(),
    ),
  );
}

class _PreloadedConfigs {
  final PrinterConfig? printer;
  final InvoiceConfig invoice;
  final DeliveryConfig delivery;

  const _PreloadedConfigs({
    this.printer,
    required this.invoice,
    required this.delivery,
  });
}

Future<_PreloadedConfigs> _loadConfigs() async {
  PrinterConfig? printer;
  InvoiceConfig invoice = const InvoiceConfig();
  DeliveryConfig delivery = const DeliveryConfig();

  try {
    final printerStorage = LocalStorageService('printer_config');
    final printerJson = printerStorage.readSync();
    if (printerJson != null && printerJson.isNotEmpty) {
      printer = PrinterConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(printerJson)),
      );
      debugPrint('[main] Printer config pre-cargada: $printerJson');
    } else {
      final printerJsonAsync = await printerStorage.read();
      if (printerJsonAsync != null && printerJsonAsync.isNotEmpty) {
        printer = PrinterConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(printerJsonAsync)),
        );
        debugPrint('[main] Printer config pre-cargada (async): $printerJsonAsync');
      }
    }
  } catch (e, stack) {
    debugPrint('[main] Error pre-cargando printer config: $e');
    debugPrint(stack.toString());
  }

  try {
    final invoiceStorage = LocalStorageService('invoice_config');
    final invoiceJson = invoiceStorage.readSync();
    if (invoiceJson != null && invoiceJson.isNotEmpty) {
      invoice = InvoiceConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(invoiceJson)),
      );
      debugPrint('[main] Invoice config pre-cargada: $invoiceJson');
    } else {
      final invoiceJsonAsync = await invoiceStorage.read();
      if (invoiceJsonAsync != null && invoiceJsonAsync.isNotEmpty) {
        invoice = InvoiceConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(invoiceJsonAsync)),
        );
        debugPrint('[main] Invoice config pre-cargada (async): $invoiceJsonAsync');
      }
    }
  } catch (e, stack) {
    debugPrint('[main] Error pre-cargando invoice config: $e');
    debugPrint(stack.toString());
  }

  try {
    final deliveryStorage = LocalStorageService('delivery_config');
    final deliveryJson = deliveryStorage.readSync();
    if (deliveryJson != null && deliveryJson.isNotEmpty) {
      delivery = DeliveryConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(deliveryJson)),
      );
      debugPrint('[main] Delivery config pre-cargada: $deliveryJson');
    } else {
      final deliveryJsonAsync = await deliveryStorage.read();
      if (deliveryJsonAsync != null && deliveryJsonAsync.isNotEmpty) {
        delivery = DeliveryConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(deliveryJsonAsync)),
        );
        debugPrint('[main] Delivery config pre-cargada (async): $deliveryJsonAsync');
      }
    }
  } catch (e, stack) {
    debugPrint('[main] Error pre-cargando delivery config: $e');
    debugPrint(stack.toString());
  }

  return _PreloadedConfigs(
    printer: printer,
    invoice: invoice,
    delivery: delivery,
  );
}

Future<void> _waitForInitialSession() async {
  try {
    await Supabase.instance.client.auth.onAuthStateChange
        .firstWhere(
          (event) =>
              event.event == AuthChangeEvent.initialSession ||
              event.event == AuthChangeEvent.signedIn,
        )
        .timeout(const Duration(seconds: 2));
  } catch (_) {
    // Si no hay sesión o se agota el tiempo, continuamos de todos modos.
    // El redirect del router enviará al login si es necesario.
  }
}

class LicoreriaApp extends StatelessWidget {
  const LicoreriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Licorería',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Forzamos tema claro porque la UI aun no esta adaptada al modo oscuro.
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final width = mediaQuery.size.width;
        // Escalado de texto proporcional al ancho de pantalla para mantener
        // legibilidad sin overflows en dispositivos pequeños.
        double textScale;
        if (width < 360) {
          textScale = 0.85;
        } else if (width < 600) {
          textScale = 1.0;
        } else if (width < 1200) {
          textScale = 1.05;
        } else {
          textScale = 1.1;
        }
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: SafeArea(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
