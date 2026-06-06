class AppConfig {
  static const String appName = 'Licorería';
  static const String appVersion = '0.1.0';
  
  static const String supabaseUrl = 'https://afmmyqzkbhpgljdqitzl.supabase.co';
  
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFmbW15cXprYmhwZ2xqZHFpdHpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0NDYzNjksImV4cCI6MjA5NjAyMjM2OX0.-cuGYai4pMJlRhJ0Fw9wVSu0QvO8LILTFLURqQLHw8w';

  static const int defaultPageSize = 20;
  
  static const Duration sessionTimeout = Duration(hours: 8);
  
  static const Duration reminderFirstAlert = Duration(minutes: 30);
  static const Duration reminderSecondAlert = Duration(hours: 1);
  static const Duration reminderCriticalAlert = Duration(hours: 2);
  static const Duration reminderPartialDeliveryAlert = Duration(hours: 24);
}
