import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services/secure_local_storage.dart';
import 'app_config.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
      throw StateError(
        'Faltan las variables SUPABASE_URL y/o SUPABASE_ANON_KEY. '
        'Definilas con --dart-define al compilar.',
      );
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        // Persistencia segura de la sesión con flutter_secure_storage.
        localStorage: SecureLocalStorage(),
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
