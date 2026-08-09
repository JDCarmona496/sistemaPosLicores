import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/constants/currency_denominations.dart';
import 'json_helpers.dart';

part 'cash_count.freezed.dart';
part 'cash_count.g.dart';

DenominationType? _denominationTypeFromDb(String value) {
  return DenominationType.values.cast<DenominationType?>().firstWhere(
        (e) => e?.name == value,
        orElse: () => null,
      );
}

@freezed
class CashCount with _$CashCount {
  const factory CashCount({
    required String id,
    required String shiftId,
    required String responsibleUserId,
    String? responsibleName,
    @Default(0) double total,
    @Default(0) double totalBills,
    @Default(0) double totalCoins,
    String? notes,
    DateTime? createdAt,
    @Default(<CashCountDenomination>[]) List<CashCountDenomination> denominations,
  }) = _CashCount;

  factory CashCount.fromJson(Map<String, dynamic> json) =>
      CashCount._fromJson(json);

  static CashCount _fromJson(Map<String, dynamic> json) {
    final denominationsJson = json['cash_count_denominations'] as List<dynamic>?;
    return _$CashCountFromJson({
      ...json,
      'shiftId': jsonStringRequired(json['shift_id']),
      'responsibleUserId': jsonStringRequired(json['responsible_user_id']),
      'responsibleName': jsonString(json['responsible_name']),
      'total': jsonDouble(json['total']),
      'totalBills': jsonDouble(json['total_bills']),
      'totalCoins': jsonDouble(json['total_coins']),
      'notes': jsonString(json['notes']),
      'createdAt': jsonDateTime(json['created_at'])?.toIso8601String(),
      'denominations': denominationsJson ?? [],
    });
  }
}

@freezed
class CashCountDenomination with _$CashCountDenomination {
  const factory CashCountDenomination({
    String? id,
    String? cashCountId,
    required int value,
    @Default(DenominationType.bill) DenominationType type,
    @Default(0) int quantity,
    @Default(0) double subtotal,
  }) = _CashCountDenomination;

  factory CashCountDenomination.fromJson(Map<String, dynamic> json) =>
      CashCountDenomination._fromJson(json);

  static CashCountDenomination _fromJson(Map<String, dynamic> json) {
    return _$CashCountDenominationFromJson({
      ...json,
      'value': jsonInt(json['value']),
      'type': jsonEnum(
        json['type'],
        _denominationTypeFromDb,
        defaultValue: DenominationType.bill,
      ).name,
      'quantity': jsonInt(json['quantity']),
      'subtotal': jsonDouble(json['subtotal']),
    });
  }
}

extension CashCountSupabaseExtension on CashCount {
  Map<String, dynamic> toSupabaseJson() {
    return {
      'shift_id': shiftId,
      'responsible_user_id': responsibleUserId,
      if (responsibleName != null && responsibleName!.isNotEmpty)
        'responsible_name': responsibleName,
      'total': total,
      'total_bills': totalBills,
      'total_coins': totalCoins,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

extension CashCountDenominationSupabaseExtension on CashCountDenomination {
  Map<String, dynamic> toSupabaseJson() {
    return {
      'value': value,
      'type': type.name,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}
