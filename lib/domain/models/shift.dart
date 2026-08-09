import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

part 'shift.freezed.dart';
part 'shift.g.dart';

enum ShiftStatus { open, closed }

ShiftStatus? _shiftStatusFromDb(String value) {
  return ShiftStatus.values.cast<ShiftStatus?>().firstWhere(
        (e) => e?.name == value,
        orElse: () => null,
      );
}

@freezed
class Shift with _$Shift {
  const factory Shift({
    required String id,
    required String cashRegisterId,
    required String openedBy,
    @Default(ShiftStatus.open) ShiftStatus status,
    @Default(0) double openingAmount,
    DateTime? openedAt,
    DateTime? closedAt,
    String? notes,
  }) = _Shift;

  factory Shift.fromJson(Map<String, dynamic> json) => Shift._fromJson(json);

  static Shift _fromJson(Map<String, dynamic> json) {
    return _$ShiftFromJson({
      ...json,
      'cashRegisterId': jsonStringRequired(json['cash_register_id']),
      'openedBy': jsonStringRequired(json['opened_by']),
      'status': jsonEnum(
        json['status'],
        _shiftStatusFromDb,
        defaultValue: ShiftStatus.open,
      ).name,
      'openingAmount': jsonDouble(json['opening_amount']),
      'openedAt': jsonDateTime(json['opened_at'])?.toIso8601String(),
      'closedAt': jsonDateTime(json['closed_at'])?.toIso8601String(),
      'notes': jsonString(json['notes']),
    });
  }
}

extension ShiftSupabaseExtension on Shift {
  Map<String, dynamic> toSupabaseJson() {
    return {
      'cash_register_id': cashRegisterId,
      'opened_by': openedBy,
      'status': status.name,
      'opening_amount': openingAmount,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
