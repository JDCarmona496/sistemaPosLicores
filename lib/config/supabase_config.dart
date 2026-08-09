import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        // No se persiste la sesión entre cierres de la app.
        // Esto garantiza que siempre se pida login al abrir la app.
        localStorage: EmptyLocalStorage(),
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
