import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/user.dart';
import '../repositories/user_management_repository.dart';

final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  return UserManagementRepository();
});

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final repository = ref.watch(userManagementRepositoryProvider);
  return UsersNotifier(repository);
});

class UsersState {
  final List<User> users;
  final bool isLoading;
  final String? error;

  const UsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UsersState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UsersNotifier extends StateNotifier<UsersState> {
  final UserManagementRepository _repository;

  UsersNotifier(this._repository) : super(const UsersState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final users = await _repository.getAll();
      state = state.copyWith(isLoading: false, users: users);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar usuarios: ${e.toString()}',
      );
    }
  }

  Future<User> create({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    bool isActive = true,
  }) async {
    final created = await _repository.create(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
      isActive: isActive,
    );
    state = state.copyWith(users: [created, ...state.users]);
    return created;
  }

  Future<User> update(User user) async {
    final updated = await _repository.update(user);
    state = state.copyWith(
      users: state.users.map((u) => u.id == updated.id ? updated : u).toList(),
    );
    return updated;
  }

  Future<void> toggleActive(User user) async {
    final newValue = !user.isActive;
    await _repository.toggleActive(user.id, newValue);
    state = state.copyWith(
      users: state.users
          .map((u) => u.id == user.id ? u.copyWith(isActive: newValue) : u)
          .toList(),
    );
  }
}
