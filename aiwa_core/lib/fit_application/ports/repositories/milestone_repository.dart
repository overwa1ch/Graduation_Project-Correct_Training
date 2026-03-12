import 'package:aiwa_core/fit_application/cursor/cursor_models.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

/// MilestoneRepository — 精简接口（Spec §7.7 + Cursor Pagination V1.1+）
///
/// 只暴露 Application 层所需的操作。
/// 额外方法（findAll 等）由 InMemory 实现类自行提供，不在接口中。
abstract interface class MilestoneRepository {
  Future<MilestoneEvent?> findByDedupKey(String dedupKey);
  Future<void> save(MilestoneEvent event);

  /// 按 createdAtUtc 闭区间 [fromUtc, toUtc] 查询。
  ///
  /// 排序：createdAtUtc DESC, id ASC。
  /// [fromUtc] / [toUtc] 必须是 UTC（否则调用方应先断言）。
  /// [limit] / [offset] 可选分页。
  Future<List<MilestoneEvent>> findByCreatedAtUtcRange({
    required DateTime fromUtc,
    required DateTime toUtc,
    int? limit,
    int? offset,
  });

  /// 游标分页版本（Cursor Pagination V1.1+）。
  ///
  /// 排序：createdAtUtc DESC → id ASC。
  /// [fromUtc] / [toUtc] 必须是 UTC。
  /// [cursorKey] 为上一页最后一条的排序键；null 表示第一页。
  /// [pageSize] 由调用方 clamp(1, 200)。
  Future<CursorPage<MilestoneEvent>> findByCreatedAtUtcRangeCursor({
    required DateTime fromUtc,
    required DateTime toUtc,
    required int pageSize,
    MilestoneCursorKey? cursorKey,
  });
}
