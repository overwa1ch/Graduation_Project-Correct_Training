/// UnitOfWork — 事务边界抽象（Spec §6）
///
/// 所有跨 Repository 写操作必须在 [runInTransaction] 内完成。
/// 若 action 抛出异常，必须回滚，不允许产生部分写入。
abstract interface class UnitOfWork {
  Future<T> runInTransaction<T>(Future<T> Function() action);
}
