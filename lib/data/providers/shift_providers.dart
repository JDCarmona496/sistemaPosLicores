import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/cash_register.dart';
import '../../domain/models/shift.dart';
import '../services/auth_service.dart';
import '../repositories/shift_repository.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return ShiftRepository();
});

/// Lista de cajas activas disponibles para abrir un turno.
final cashRegistersProvider = FutureProvider<List<CashRegister>>((ref) async {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.getActiveCashRegisters();
});

/// Estado del turno abierto del usuario actual.
final currentShiftProvider =
    StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  final repository = ref.watch(shiftRepositoryProvider);
  return ShiftNotifier(repository);
});

class ShiftState {
  final Shift? shift;
  final bool isLoading;
  final String? error;

  const ShiftState({
    this.shift,
    this.isLoading = false,
    this.error,
  });

  ShiftState copyWith({
    Shift? shift,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearShift = false,
  }) {
    return ShiftState(
      shift: clearShift ? null : (shift ?? this.shift),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasOpenShift => shift != null;
}

class ShiftNotifier extends StateNotifier<ShiftState> {
  final ShiftRepository _repository;

  ShiftNotifier(this._repository) : super(const ShiftState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await AuthService().getCurrentUser();
      final shift = await _repository.getOpenShiftForUser(user.id);
      state = state.copyWith(shift: shift, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar turno: ${e.toString()}',
      );
    }
  }

  Future<Shift?> openShift({
    required String cashRegisterId,
    required double openingAmount,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await AuthService().getCurrentUser();
      final shift = Shift(
        id: '',
        cashRegisterId: cashRegisterId,
        openedBy: user.id,
        status: ShiftStatus.open,
        openingAmount: openingAmount,
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      );

      final created = await _repository.create(shift);
      state = state.copyWith(shift: created, isLoading: false);
      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al abrir turno: ${e.toString()}',
      );
      return null;
    }
  }

  Future<Shift?> closeShift({
    required double closingAmount,
    String? notes,
  }) async {
    final shift = state.shift;
    if (shift == null) return null;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final closed = await _repository.closeShift(
        shiftId: shift.id,
        closingAmount: closingAmount,
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      );
      state = state.copyWith(shift: null, isLoading: false);
      return closed;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cerrar turno: ${e.toString()}',
      );
      return null;
    }
  }
}
