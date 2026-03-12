import 'package:aiwa_core/fit_application/fit_application.dart';

import '../db/fit_database.dart';

class DriftUnitOfWork implements UnitOfWork {
  final FitDatabase db;

  const DriftUnitOfWork(this.db);

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    try {
      return await db.transaction(() async => await action());
    } catch (_) {
      rethrow;
    }
  }
}
