import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

enum CustomerType { occasional, frequent, wholesale, credit, consignment }

@freezed
class Customer with _$Customer {
  const factory Customer({
    required String id,
    required String name,
    required String phone,
    required CustomerType type,
    String? documentId,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
    @Default(0) double creditLimit,
    @Default(0) double currentBalance,
    String? notes,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}
