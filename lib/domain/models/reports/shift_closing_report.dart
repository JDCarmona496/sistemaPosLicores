/// Modelos para el reporte de cierre de caja por turno.
class ShiftClosingReport {
  final String shiftId;
  final String cashRegisterName;
  final String openedById;
  final String openedByName;
  final DateTime openedAt;
  final DateTime closedAt;
  final double openingAmount;
  final double closingAmount;
  final double expectedAmount;
  final double difference;
  final double netCashTotal;
  final double expectedCashSales;
  final double paymentsTotal;
  final List<ShiftUserSales> salesByUser;

  const ShiftClosingReport({
    required this.shiftId,
    required this.cashRegisterName,
    required this.openedById,
    required this.openedByName,
    required this.openedAt,
    required this.closedAt,
    required this.openingAmount,
    required this.closingAmount,
    required this.expectedAmount,
    required this.difference,
    required this.netCashTotal,
    required this.expectedCashSales,
    required this.paymentsTotal,
    required this.salesByUser,
  });

  factory ShiftClosingReport.fromJson(Map<String, dynamic> json) {
    final salesJson = json['sales_by_user'] as List<dynamic>? ?? [];
    return ShiftClosingReport(
      shiftId: json['shift_id'] as String? ?? '',
      cashRegisterName: json['cash_register_name'] as String? ?? 'Caja',
      openedById: json['opened_by_id'] as String? ?? '',
      openedByName: json['opened_by_name'] as String? ?? 'Usuario',
      openedAt: _parseDateTime(json['opened_at']),
      closedAt: _parseDateTime(json['closed_at']),
      openingAmount: _toDouble(json['opening_amount']),
      closingAmount: _toDouble(json['closing_amount']),
      expectedAmount: _toDouble(json['expected_amount']),
      difference: _toDouble(json['difference']),
      netCashTotal: _toDouble(json['net_cash_total']),
      expectedCashSales: _toDouble(json['expected_cash_sales']),
      paymentsTotal: _toDouble(json['payments_total']),
      salesByUser: salesJson
          .map((e) => ShiftUserSales.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

class ShiftUserSales {
  final String userId;
  final String userName;
  final double totalPayments;

  const ShiftUserSales({
    required this.userId,
    required this.userName,
    required this.totalPayments,
  });

  factory ShiftUserSales.fromJson(Map<String, dynamic> json) {
    return ShiftUserSales(
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? 'Usuario',
      totalPayments: ShiftClosingReport._toDouble(json['total_payments']),
    );
  }
}
