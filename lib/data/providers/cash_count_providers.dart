import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/currency_denominations.dart';
import '../../domain/models/cash_count.dart';
import '../../domain/models/shift.dart';
import '../../domain/services/cash_count_calculator.dart';
import '../services/auth_service.dart';
import '../repositories/cash_count_repository.dart';
import '../repositories/shift_repository.dart';

export 'shift_providers.dart' show currentShiftProvider;

final cashCountRepositoryProvider = Provider<CashCountRepository>((ref) {
  return CashCountRepository();
});

/// Historial de conteos de un turno específico.
final cashCountHistoryProvider = StateNotifierProvider.family<
    CashCountHistoryNotifier, CashCountHistoryState, String>(
  (ref, shiftId) {
    final repository = ref.watch(cashCountRepositoryProvider);
    return CashCountHistoryNotifier(repository, shiftId);
  },
);

class CashCountHistoryState {
  final List<CashCount> counts;
  final bool isLoading;
  final String? error;

  const CashCountHistoryState({
    this.counts = const [],
    this.isLoading = false,
    this.error,
  });

  CashCountHistoryState copyWith({
    List<CashCount>? counts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CashCountHistoryState(
      counts: counts ?? this.counts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CashCountHistoryNotifier
    extends StateNotifier<CashCountHistoryState> {
  final CashCountRepository _repository;
  final String _shiftId;

  CashCountHistoryNotifier(this._repository, this._shiftId)
      : super(const CashCountHistoryState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final counts = await _repository.getByShift(_shiftId);
      state = state.copyWith(counts: counts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar historial: ${e.toString()}',
      );
    }
  }
}

/// Formulario de conteo de efectivo actual.
final cashCountFormProvider =
    StateNotifierProvider.autoDispose<CashCountFormNotifier, CashCountFormState>(
  (ref) {
    final repository = ref.watch(cashCountRepositoryProvider);
    return CashCountFormNotifier(repository);
  },
);

class CashCountFormState {
  final Map<int, int> quantities;
  final String notes;
  final bool isLoadingShift;
  final bool isSaving;
  final String? error;
    final CashCount? savedCashCount;
    final Shift? shift;
    final String? responsibleUserId;
    final String? responsibleUserName;

  const CashCountFormState({
    this.quantities = const {},
    this.notes = '',
    this.isLoadingShift = true,
    this.isSaving = false,
    this.error,
    this.savedCashCount,
    this.shift,
    this.responsibleUserId,
    this.responsibleUserName,
  });

  CashCountFormState copyWith({
    Map<int, int>? quantities,
    String? notes,
    bool? isLoadingShift,
    bool? isSaving,
    String? error,
    CashCount? savedCashCount,
    Shift? shift,
    String? responsibleUserId,
    String? responsibleUserName,
    bool clearError = false,
    bool clearSaved = false,
  }) {
    return CashCountFormState(
      quantities: quantities ?? this.quantities,
      notes: notes ?? this.notes,
      isLoadingShift: isLoadingShift ?? this.isLoadingShift,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      savedCashCount:
          clearSaved ? null : (savedCashCount ?? this.savedCashCount),
      shift: shift ?? this.shift,
      responsibleUserId: responsibleUserId ?? this.responsibleUserId,
      responsibleUserName: responsibleUserName ?? this.responsibleUserName,
    );
  }

  double get total {
    return copDenominations.fold<double>(
      0,
      (sum, denom) =>
          sum + denom.value * (quantities[denom.value] ?? 0),
    );
  }

  double get totalBills {
    return copDenominations
        .where((d) => d.type == DenominationType.bill)
        .fold<double>(
          0,
          (sum, denom) =>
              sum + denom.value * (quantities[denom.value] ?? 0),
        );
  }

  double get totalCoins {
    return copDenominations
        .where((d) => d.type == DenominationType.coin)
        .fold<double>(
          0,
          (sum, denom) =>
              sum + denom.value * (quantities[denom.value] ?? 0),
        );
  }
}

class CashCountFormNotifier extends StateNotifier<CashCountFormState> {
  final CashCountRepository _repository;
  final _calculator = const CashCountCalculator();

  CashCountFormNotifier(this._repository)
      : super(const CashCountFormState()) {
    _loadShift();
  }

  Future<void> _loadShift() async {
    state = state.copyWith(isLoadingShift: true, clearError: true);
    try {
      final user = await AuthService().getCurrentUser();
      final repository = ShiftRepository();
      final shift = await repository.getOpenShiftForUser(user.id);
      state = state.copyWith(
        isLoadingShift: false,
        shift: shift,
        responsibleUserId: user.id,
        responsibleUserName: user.fullName,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingShift: false,
        error: 'Error al cargar turno: ${e.toString()}',
      );
    }
  }

  void setQuantity(int value, int quantity) {
    final effective = quantity < 0 ? 0 : quantity;
    final updated = Map<int, int>.from(state.quantities);
    if (effective == 0) {
      updated.remove(value);
    } else {
      updated[value] = effective;
    }
    state = state.copyWith(quantities: updated, clearError: true);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  Future<CashCount?> save() async {
    final shift = state.shift;
    final userId = state.responsibleUserId;

    if (shift == null || userId == null) {
      state = state.copyWith(
        error: 'No hay un turno abierto para guardar el conteo.',
      );
      return null;
    }

    if (!_calculator.hasAnyQuantity(state.quantities)) {
      state = state.copyWith(
        error: 'Ingresa al menos una cantidad para guardar el conteo.',
      );
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final calculation = _calculator.calculate(state.quantities);
      final cashCount = CashCount(
        id: '',
        shiftId: shift.id,
        responsibleUserId: userId,
        responsibleName: state.responsibleUserName ?? '',
        total: calculation.total,
        totalBills: calculation.totalBills,
        totalCoins: calculation.totalCoins,
        notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
        denominations: calculation.denominations,
      );

      final saved = await _repository.create(cashCount);
      state = state.copyWith(isSaving: false, savedCashCount: saved);
      return saved;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Error al guardar: ${e.toString()}',
      );
      return null;
    }
  }

  void reset() {
    state = state.copyWith(
      quantities: const {},
      notes: '',
      clearError: true,
      clearSaved: true,
    );
  }
}
