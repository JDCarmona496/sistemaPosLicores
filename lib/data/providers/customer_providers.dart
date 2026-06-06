import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/customer_repository.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/customer_basket.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final customersProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomersNotifier(repository);
});

class CustomersState {
  final List<Customer> customers;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? selectedType;
  final String? selectedStatus;

  const CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.selectedType,
    this.selectedStatus,
  });

  CustomersState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedType,
    String? selectedStatus,
    bool clearSearch = false,
    bool clearType = false,
    bool clearStatus = false,
    bool clearError = false,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
    );
  }
}

class CustomersNotifier extends StateNotifier<CustomersState> {
  final CustomerRepository _repository;

  CustomersNotifier(this._repository) : super(const CustomersState()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final customers = await _repository.getAll(
        search: state.searchQuery,
        customerType: state.selectedType,
        status: state.selectedStatus,
      );

      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar clientes: ${e.toString()}',
      );
    }
  }

  void setSearch(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.isEmpty,
    );
    loadCustomers();
  }

  void setType(String? type) {
    state = state.copyWith(
      selectedType: type,
      clearType: type == null,
    );
    loadCustomers();
  }

  void setStatus(String? status) {
    state = state.copyWith(
      selectedStatus: status,
      clearStatus: status == null,
    );
    loadCustomers();
  }

  void clearFilters() {
    state = state.copyWith(
      clearSearch: true,
      clearType: true,
      clearStatus: true,
    );
    loadCustomers();
  }

  Future<Customer> createCustomer(Customer customer) async {
    try {
      final created = await _repository.create(customer);
      state = state.copyWith(customers: [...state.customers, created]);
      return created;
    } catch (e) {
      throw Exception('Error al crear cliente: ${e.toString()}');
    }
  }

  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final updated = await _repository.update(customer);
      state = state.copyWith(
        customers: state.customers.map((c) => c.id == updated.id ? updated : c).toList(),
      );
      return updated;
    } catch (e) {
      throw Exception('Error al actualizar cliente: ${e.toString()}');
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _repository.delete(id);
      state = state.copyWith(
        customers: state.customers.where((c) => c.id != id).toList(),
      );
    } catch (e) {
      throw Exception('Error al eliminar cliente: ${e.toString()}');
    }
  }

  Future<Customer?> getByIdentification(String identification) async {
    return await _repository.getByIdentification(identification);
  }

  Future<Customer?> getByPhone(String phone) async {
    return await _repository.getByPhone(phone);
  }
}

final customerByIdProvider = FutureProvider.family<Customer?, String>((ref, id) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getById(id);
});

final customerOrdersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getCustomerOrders(customerId);
});

final customerBasketsProvider =
    FutureProvider.family<List<CustomerBasket>, String>((ref, customerId) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getCustomerBaskets(customerId);
});

final customerStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, customerId) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getCustomerStats(customerId);
});
