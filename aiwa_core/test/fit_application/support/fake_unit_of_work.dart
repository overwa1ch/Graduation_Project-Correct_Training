import 'package:aiwa_core/fit_application/fit_application.dart';

import 'transactional_resource.dart';

class FakeUnitOfWork implements UnitOfWork {
  final List<TransactionalResource> resources;
  int runCount = 0;

  FakeUnitOfWork({this.resources = const []});

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    runCount += 1;
    final snapshots = <TransactionalResource, Object>{};
    for (final resource in resources) {
      snapshots[resource] = resource.snapshot();
    }
    try {
      return await action();
    } catch (_) {
      for (final resource in resources) {
        final snapshot = snapshots[resource];
        if (snapshot != null) resource.restore(snapshot);
      }
      rethrow;
    }
  }
}
