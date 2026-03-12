import 'package:aiwa_core/fit_application/fit_application.dart';

import 'transactional_resource.dart';

class InMemoryUnitOfWork implements UnitOfWork {
  final List<TransactionalResource> _resources;

  InMemoryUnitOfWork({List<TransactionalResource> resources = const []})
      : _resources = List<TransactionalResource>.from(resources);

  void register(TransactionalResource resource) {
    if (!_resources.contains(resource)) {
      _resources.add(resource);
    }
  }

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    final snapshots = <TransactionalResource, Object>{};
    for (final resource in _resources) {
      snapshots[resource] = resource.snapshot();
    }

    try {
      return await action();
    } catch (_) {
      for (final resource in _resources) {
        final snapshot = snapshots[resource];
        if (snapshot != null) {
          resource.restore(snapshot);
        }
      }
      rethrow;
    }
  }
}
