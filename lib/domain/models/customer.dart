import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

enum CustomerType { occasional, frequent, wholesale, credit, consignment }

enum CustomerStatus { active, inactive, blocked }

@freezed
class Customer with _$Customer {
  const factory Customer({
    required String id,
    required String fullName,
    required String phone,
    required CustomerType customerType,
    required CustomerStatus status,
    String? identification,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
    @Default(0) double creditLimit,
    @Default(0) double currentBalance,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);

  Map<String, dynamic> toSupabaseJson() {
    final json = <String, dynamic>{
      'full_name': fullName,
      'phone': phone,
      'customer_type': customerType.name,
      'status': status.name,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
    };

    if (identification != null && identification!.isNotEmpty) {
      json['identification'] = identification;
    }

    if (email != null && email!.isNotEmpty) {
      json['email'] = email;
    }

    if (address != null && address!.isNotEmpty) {
      json['address'] = address;
    }

    if (latitude != null) {
      json['latitude'] = latitude;
    }

    if (longitude != null) {
      json['longitude'] = longitude;
    }

    if (notes != null && notes!.isNotEmpty) {
      json['notes'] = notes;
    }

    if (createdBy != null && createdBy!.isNotEmpty) {
      json['created_by'] = createdBy;
    }

    return json;
  }
}
