/// Modelos de datos para el módulo de reportes.
library;

class SalesSummary {
  final double totalSales;
  final int totalOrders;
  final double averageTicket;
  final double totalDiscounts;
  final double totalDeliveryFees;

  const SalesSummary({
    required this.totalSales,
    required this.totalOrders,
    required this.averageTicket,
    required this.totalDiscounts,
    required this.totalDeliveryFees,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    return SalesSummary(
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      averageTicket: (json['average_ticket'] as num?)?.toDouble() ?? 0,
      totalDiscounts: (json['total_discounts'] as num?)?.toDouble() ?? 0,
      totalDeliveryFees: (json['total_delivery_fees'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SalesByPaymentMethod {
  final String paymentMethod;
  final double amount;
  final int paymentCount;

  const SalesByPaymentMethod({
    required this.paymentMethod,
    required this.amount,
    required this.paymentCount,
  });

  factory SalesByPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SalesByPaymentMethod(
      paymentMethod: json['payment_method'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentCount: (json['payment_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TopProductReport {
  final String productId;
  final String productName;
  final int totalQuantity;
  final double totalSales;

  const TopProductReport({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalSales,
  });

  factory TopProductReport.fromJson(Map<String, dynamic> json) {
    return TopProductReport(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Producto',
      totalQuantity: (json['total_quantity'] as num?)?.toInt() ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PendingOrdersSummary {
  final int pendingCount;
  final double pendingTotal;

  const PendingOrdersSummary({
    required this.pendingCount,
    required this.pendingTotal,
  });

  factory PendingOrdersSummary.fromJson(Map<String, dynamic> json) {
    return PendingOrdersSummary(
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      pendingTotal: (json['pending_total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SalesBySeller {
  final String sellerId;
  final String sellerName;
  final double totalSales;
  final int orderCount;

  const SalesBySeller({
    required this.sellerId,
    required this.sellerName,
    required this.totalSales,
    required this.orderCount,
  });

  factory SalesBySeller.fromJson(Map<String, dynamic> json) {
    return SalesBySeller(
      sellerId: json['seller_id'] as String? ?? '',
      sellerName: json['seller_name'] as String? ?? 'Vendedor',
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0,
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class HourlySales {
  final int hour;
  final double totalSales;
  final int orderCount;

  const HourlySales({
    required this.hour,
    required this.totalSales,
    required this.orderCount,
  });

  factory HourlySales.fromJson(Map<String, dynamic> json) {
    return HourlySales(
      hour: (json['sale_hour'] as num?)?.toInt() ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0,
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SalesTrendPoint {
  final DateTime date;
  final double totalSales;
  final int orderCount;

  const SalesTrendPoint({
    required this.date,
    required this.totalSales,
    required this.orderCount,
  });

  factory SalesTrendPoint.fromJson(Map<String, dynamic> json) {
    return SalesTrendPoint(
      date: DateTime.tryParse(json['sale_date'] as String? ?? '') ?? DateTime.now(),
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0,
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
    );
  }
}
