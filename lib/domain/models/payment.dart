import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

enum PaymentMethod { cash, card, transfer, nequi, daviplata, other }

enum PaymentStatus { pending, completed, failed, refunded }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.nequi:
        return 'Nequi';
      case PaymentMethod.daviplata:
        return 'Daviplata';
      case PaymentMethod.other:
        return 'Otro';
    }
  }
}

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.completed:
        return 'Completado';
      case PaymentStatus.failed:
        return 'Fallido';
      case PaymentStatus.refunded:
        return 'Reembolsado';
    }
  }
}

PaymentMethod? _paymentMethodFromDb(String value) {
  return PaymentMethod.values.cast<PaymentMethod?>().firstWhere(
        (e) => e?.name == value,
        orElse: () => null,
      );
}

PaymentStatus? _paymentStatusFromDb(String value) {
  return PaymentStatus.values.cast<PaymentStatus?>().firstWhere(
        (e) => e?.name == value,
        orElse: () => null,
      );
}

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    String? orderId,
    String? customerId,
    required PaymentMethod paymentMethod,
    required double amount,
    String? reference,
    @Default(PaymentStatus.completed) PaymentStatus status,
    required String receivedBy,
    String? notes,
    DateTime? createdAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment._fromJson(json);

  static Payment _fromJson(Map<String, dynamic> json) {
    return _$PaymentFromJson({
      ...json,
      'orderId': jsonString(json['order_id']),
      'customerId': jsonString(json['customer_id']),
      'paymentMethod': jsonEnum(
        json['payment_method'],
        _paymentMethodFromDb,
        defaultValue: PaymentMethod.cash,
      ).name,
      'amount': jsonDouble(json['amount']),
      'reference': jsonString(json['reference']),
      'status': jsonEnum(
        json['status'],
        _paymentStatusFromDb,
        defaultValue: PaymentStatus.completed,
      ).name,
      'receivedBy': jsonStringRequired(json['received_by']),
      'notes': jsonString(json['notes']),
      'createdAt': jsonDateTime(json['created_at'])?.toIso8601String(),
    });
  }
}

extension PaymentSupabaseExtension on Payment {
  Map<String, dynamic> toSupabaseJson() {
    return {
      if (orderId != null) 'order_id': orderId,
      if (customerId != null) 'customer_id': customerId,
      'payment_method': paymentMethod.name,
      'amount': amount,
      if (reference != null && reference!.isNotEmpty) 'reference': reference,
      'status': status.name,
      'received_by': receivedBy,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
