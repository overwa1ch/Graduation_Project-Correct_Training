import 'package:flutter/foundation.dart';

import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

import 'package:aiwa_app/services/fit/fit_service_hub.dart';

/// UI-facing state for fit pages: selected date and today's workout data.
/// Call [refreshHome], [refreshPlanDate], [refreshLibrary] after navigation.
class FitUiState extends ChangeNotifier {
  FitUiState(this._hub);

  final FitServiceHub _hub;

  DateOnly? _selectedDate;
  LogEditorDTO? _todayWorkoutLog;
  HomeDashboardDTO? _homeDashboard;

  DateOnly? get selectedDate => _selectedDate;
  LogEditorDTO? get todayWorkoutLog => _todayWorkoutLog;
  HomeDashboardDTO? get homeDashboard => _homeDashboard;

  set selectedDate(DateOnly? value) {
    if (_selectedDate == value) return;
    _selectedDate = value;
    notifyListeners();
  }

  /// Refresh home dashboard for [selectedDate] (or today if null).
  Future<void> refreshHome() async {
    final date =
        _selectedDate ?? DateOnly.fromDateTimeUtc(DateTime.now().toUtc());
    _selectedDate = date;
    try {
      final dto = await _hub.getHomeDashboardUseCase.execute(date);
      _homeDashboard = dto;
      _todayWorkoutLog = dto.logs.isNotEmpty ? dto.logs.first : null;
    } catch (_) {
      _homeDashboard = null;
      _todayWorkoutLog = null;
    }
    notifyListeners();
  }

  /// Refresh plan view for a given date (e.g. after selecting a day).
  Future<void> refreshPlanDate(DateOnly date) async {
    _selectedDate = date;
    try {
      final dto = await _hub.getHomeDashboardUseCase.execute(date);
      _todayWorkoutLog = dto.logs.isNotEmpty ? dto.logs.first : null;
    } catch (_) {
      _todayWorkoutLog = null;
    }
    notifyListeners();
  }

  /// Invalidate library catalog cache (call after add/rename/delete exercise or tag).
  void refreshLibrary() {
    notifyListeners();
  }
}
