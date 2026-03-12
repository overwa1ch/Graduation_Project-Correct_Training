import 'package:flutter/material.dart';

import 'package:aiwa_app/services/fit/fit_service_hub.dart';
import 'package:aiwa_app/services/fit/fit_ui_state.dart';

/// Provides [FitServiceHub] and [FitUiState] down the tree.
class FitScope extends InheritedWidget {
  const FitScope({
    super.key,
    required this.hub,
    required this.uiState,
    required super.child,
  });

  final FitServiceHub hub;
  final FitUiState uiState;

  static FitScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FitScope>();
    assert(scope != null, 'FitScope not found. Wrap app with FitScope.');
    return scope!;
  }

  static FitScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FitScope>();
  }

  @override
  bool updateShouldNotify(FitScope oldWidget) {
    return hub != oldWidget.hub || uiState != oldWidget.uiState;
  }
}
