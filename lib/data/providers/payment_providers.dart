import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/payment.dart';
import '../repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

final paymentsByOrderProvider =
    FutureProvider.family<List<Payment>, String>((ref, orderId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return await repository.getByOrder(orderId);
});

final paymentsByCustomerProvider =
    FutureProvider.family<List<Payment>, String>((ref, customerId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return await repository.getByCustomer(customerId);
});
