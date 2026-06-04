class AppConfig {
  static const String appName = 'Licorería';
  static const String appVersion = '0.1.0';
  
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'TU_SUPABASE_URL',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'TU_SUPABASE_ANON_KEY',
  );

  static const int defaultPageSize = 20;
  
  static const Duration sessionTimeout = Duration(hours: 8);
  
  static const Duration reminderFirstAlert = Duration(minutes: 30);
  static const Duration reminderSecondAlert = Duration(hours: 1);
  static const Duration reminderCriticalAlert = Duration(hours: 2);
  static const Duration reminderPartialDeliveryAlert = Duration(hours: 24);
}
