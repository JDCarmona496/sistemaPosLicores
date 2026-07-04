import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/router.dart';
import 'config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseConfig.initialize();
  
  // En web, Supabase necesita un momento para restaurar la sesión desde
  // localStorage. Esperamos el evento inicial antes de construir el router,
  // de lo contrario currentSession puede ser null en el primer frame.
  if (kIsWeb) {
    await _waitForInitialSession();
  }
  
  runApp(
    const ProviderScope(
      child: LicoreriaApp(),
    ),
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
    );
  }
}
