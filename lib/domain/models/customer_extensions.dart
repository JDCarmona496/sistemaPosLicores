import 'customer.dart';

extension CustomerSupabaseExtension on Customer {
  Map<String, dynamic> toSupabaseJson({bool includeId = false}) {
    final json = <String, dynamic>{
      'full_name': fullName,
      'phone': phone,
      'customer_type': type.dbValue,
      'status': status.dbValue,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
    };

    if (includeId) json['id'] = id;
    if (identification != null && identification!.isNotEmpty) {
      json['identification'] = identification;
    }
    if (email != null && email!.isNotEmpty) json['email'] = email;
    if (address != null && address!.isNotEmpty) json['address'] = address;
    if (latitude != null) json['latitude'] = latitude;
    if (longitude != null) json['longitude'] = longitude;
    if (notes != null && notes!.isNotEmpty) json['notes'] = notes;
    if (createdBy != null && createdBy!.isNotEmpty) {
      json['created_by'] = createdBy;
    }

    return json;
  }
}
