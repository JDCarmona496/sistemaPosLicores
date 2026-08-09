import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/reports/shift_closing_report.dart';
import '../../domain/models/user.dart';
import '../repositories/shift_closing_report_repository.dart';
import '../services/auth_service.dart';

final shiftClosingReportRepositoryProvider = Provider<ShiftClosingReportRepository>((ref) {
  return ShiftClosingReportRepository();
});

/// Provider del reporte de cierres de caja para una fecha específica.
final shiftClosingReportsProvider = StateNotifierProvider.family<
    ShiftClosingReportsNotifier,
    ShiftClosingReportsState,
    DateTime>((ref, date) {
  final repository = ref.watch(shiftClosingReportRepositoryProvider);
  return ShiftClosingReportsNotifier(repository, date);
});

class ShiftClosingReportsState {
  final List<ShiftClosingReport> reports;
  final bool isLoading;
  final String? error;

  const ShiftClosingReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.error,
  });

  ShiftClosingReportsState copyWith({
    List<ShiftClosingReport>? reports,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ShiftClosingReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ShiftClosingReportsNotifier
    extends StateNotifier<ShiftClosingReportsState> {
  final ShiftClosingReportRepository _repository;
  final DateTime _date;

  ShiftClosingReportsNotifier(this._repository, this._date)
      : super(const ShiftClosingReportsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await AuthService().getCurrentUser();
      final userId = user.role == UserRole.admin ? null : user.id;

      final reports = await _repository.getByDate(
        date: _date,
        userId: userId,
      );

      state = state.copyWith(isLoading: false, reports: reports);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar cierres de caja: ${e.toString()}',
      );
    }
  }

}
