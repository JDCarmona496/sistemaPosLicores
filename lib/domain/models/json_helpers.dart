/// Helpers seguros para convertir valores JSON de Supabase a tipos Dart.
///
/// Uso: en los `_fromJson` personalizados de modelos Freezed, reemplazar
/// casts directos por estas funciones para evitar errores de tipo cuando
/// PostgreSQL devuelve int donde Dart espera String, num donde espera double,
/// etc.
library;

String? jsonString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

String jsonStringRequired(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  return value.toString();
}

int jsonInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final parsed = int.tryParse(value.toString());
  return parsed ?? defaultValue;
}

double jsonDouble(dynamic value, {double defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value.toString());
  return parsed ?? defaultValue;
}

bool jsonBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final str = value.toString().toLowerCase();
  return str == 'true' || str == '1' || str == 't' || str == 'yes';
}

DateTime? jsonDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    return parsed;
  }
  return DateTime.tryParse(value.toString());
}

T jsonEnum<T>(
  dynamic value,
  T? Function(String) fromString, {
  required T defaultValue,
}) {
  if (value == null) return defaultValue;
  final result = fromString(value.toString());
  return result ?? defaultValue;
}
