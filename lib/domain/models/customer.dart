import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

enum CustomerType { occasional, frequent, wholesale, credit, consignment }

enum CustomerStatus { active, inactive, blocked }

extension CustomerTypeX on CustomerType {
  String get label {
    switch (this) {
      case CustomerType.occasional:
        return 'Ocasional';
      case CustomerType.frequent:
        return 'Frecuente';
      case CustomerType.wholesale:
        return 'Mayorista';
      case CustomerType.credit:
        return 'Crédito';
      case CustomerType.consignment:
        return 'Consignatario';
    }
  }

  String get dbValue => name;
}

extension CustomerStatusX on CustomerStatus {
  String get label {
    switch (this) {
      case CustomerStatus.active:
        return 'Activo';
      case CustomerStatus.inactive:
        return 'Inactivo';
      case CustomerStatus.blocked:
        return 'Bloqueado';
    }
  }

  String get dbValue => name;
}

@freezed
class Customer with _$Customer {
  const factory Customer({
    required String id,
    String? identification,
    required String fullName,
    required String phone,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
    @Default(CustomerType.occasional) CustomerType type,
    @Default(CustomerStatus.active) CustomerStatus status,
    @Default(0) double creditLimit,
    @Default(0) double currentBalance,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      Customer._fromJson(json);

  static CustomerType _typeFromDb(dynamic value) {
    final str = value?.toString() ?? '';
    return CustomerType.values.firstWhere(
      (e) => e.name == str,
      orElse: () => CustomerType.occasional,
    );
  }

  static CustomerStatus _statusFromDb(dynamic value) {
    final str = value?.toString() ?? '';
    return CustomerStatus.values.firstWhere(
      (e) => e.name == str,
      orElse: () => CustomerStatus.active,
    );
  }

  static Customer _fromJson(Map<String, dynamic> json) {
    return _$CustomerFromJson({
      ...json,
      'fullName': json['full_name'],
      'identification': json['identification'],
      'phone': json['phone'],
      'email': json['email'],
      'address': json['address'],
      'latitude': (json['latitude'] as num?)?.toDouble(),
      'longitude': (json['longitude'] as num?)?.toDouble(),
      'type': _typeFromDb(json['customer_type']).name,
      'status': _statusFromDb(json['status']).name,
      'creditLimit': (json['credit_limit'] as num?)?.toDouble() ?? 0,
      'currentBalance': (json['current_balance'] as num?)?.toDouble() ?? 0,
      'notes': json['notes'],
      'createdBy': json['created_by'],
      'createdAt': json['created_at'],
      'updatedAt': json['updated_at'],
    });
  }
}
