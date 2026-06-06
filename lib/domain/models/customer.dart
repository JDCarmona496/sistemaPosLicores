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
      _$CustomerFromJson(json);
}
