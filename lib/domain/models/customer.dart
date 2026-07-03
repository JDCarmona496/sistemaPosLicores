import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

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

CustomerType? _customerTypeFromDb(String value) {
  return CustomerType.values.cast<CustomerType?>().firstWhere(
        (e) => e?.name == value,
        orElse: () => null,
      );
}

CustomerStatus? _customerStatusFromDb(String value) {
  return CustomerStatus.values.cast<CustomerStatus?>().firstWhere(
        (e) => e?.name == value,
        orElse: () => null,
      );
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

  static Customer _fromJson(Map<String, dynamic> json) {
    return _$CustomerFromJson({
      ...json,
      'fullName': jsonStringRequired(json['full_name']),
      'identification': jsonString(json['identification']),
      'phone': jsonStringRequired(json['phone']),
      'email': jsonString(json['email']),
      'address': jsonString(json['address']),
      'latitude': jsonDouble(json['latitude']),
      'longitude': jsonDouble(json['longitude']),
      'type': jsonEnum(
        json['customer_type'],
        _customerTypeFromDb,
        defaultValue: CustomerType.occasional,
      ).name,
      'status': jsonEnum(
        json['status'],
        _customerStatusFromDb,
        defaultValue: CustomerStatus.active,
      ).name,
      'creditLimit': jsonDouble(json['credit_limit']),
      'currentBalance': jsonDouble(json['current_balance']),
      'notes': jsonString(json['notes']),
      'createdBy': jsonString(json['created_by']),
      'createdAt': jsonDateTime(json['created_at'])?.toIso8601String(),
      'updatedAt': jsonDateTime(json['updated_at'])?.toIso8601String(),
    });
  }
}
