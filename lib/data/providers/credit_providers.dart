import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:applicoresestacion/domain/models/credit_account.dart';
import 'package:applicoresestacion/domain/models/payment.dart';
import 'package:applicoresestacion/data/repositories/credit_repository.dart';
import 'payment_providers.dart';

final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  return CreditRepository();
});

/// Lista de créditos (pedidos a crédito) con pagos e ítems.
final creditsProvider =
    AsyncNotifierProvider<CreditsNotifier, List<CreditAccount>>(
  CreditsNotifier.new,
);

class CreditsNotifier extends AsyncNotifier<List<CreditAccount>> {
  CreditRepository get _repository => ref.read(creditRepositoryProvider);

  @override
  Future<List<CreditAccount>> build() async {
    return _repository.getCreditAccounts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getCreditAccounts);
  }
}

/// Detalle de un crédito por orderId.
final creditDetailProvider =
    FutureProvider.family<CreditAccount?, String>((ref, orderId) async {
  final repository = ref.watch(creditRepositoryProvider);
  return repository.getCreditAccountByOrderId(orderId);
});

/// Registra un abono/pago y refresca la lista de créditos.
final creditPaymentProvider = Provider<Future<void> Function({
  required String orderId,
  String? customerId,
  required PaymentMethod paymentMethod,
  required double amount,
  String? reference,
  required String receivedBy,
  String? notes,
})>((ref) {
  return ({
    required String orderId,
    String? customerId,
    required PaymentMethod paymentMethod,
    required double amount,
    String? reference,
    required String receivedBy,
    String? notes,
  }) async {
    final repository = ref.read(paymentRepositoryProvider);
    await repository.create(
      orderId: orderId,
      customerId: customerId,
      paymentMethod: paymentMethod,
      amount: amount,
      reference: reference,
      receivedBy: receivedBy,
      notes: notes,
    );
    await ref.read(creditsProvider.notifier).refresh();
  };
});
