import 'json_helpers.dart';

/// Caja registradora o punto de venta donde se abre un turno.
class CashRegister {
  final String id;
  final String name;
  final String? description;
  final bool isSafe;
  final bool isActive;

  const CashRegister({
    required this.id,
    required this.name,
    this.description,
    this.isSafe = false,
    this.isActive = true,
  });

  factory CashRegister.fromJson(Map<String, dynamic> json) {
    return CashRegister(
      id: jsonStringRequired(json['id']),
      name: jsonStringRequired(json['name']),
      description: jsonString(json['description']),
      isSafe: jsonBool(json['is_safe']),
      isActive: jsonBool(json['is_active'], defaultValue: true),
    );
  }
}
