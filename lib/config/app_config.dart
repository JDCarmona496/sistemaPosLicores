/// Configuración centralizada de la aplicación.
///
/// Las credenciales de Supabase **no deben estar en el código fuente**.
/// Se esperan como variables de entorno en tiempo de compilación:
///
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=tu-anon-key
/// ```
///
/// En VS Code se pueden configurar en `.vscode/launch.json`.
class AppConfig {
  static const String appName = 'Licorería';
  static const String appVersion = '0.1.0';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const int defaultPageSize = 20;

  static const Duration sessionTimeout = Duration(hours: 8);

  static const Duration reminderFirstAlert = Duration(minutes: 30);
  static const Duration reminderSecondAlert = Duration(hours: 1);
  static const Duration reminderCriticalAlert = Duration(hours: 2);
  static const Duration reminderPartialDeliveryAlert = Duration(hours: 24);
}
