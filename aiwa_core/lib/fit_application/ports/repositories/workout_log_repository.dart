import 'package:aiwa_core/fit_application/cursor/cursor_models.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

abstract interface class WorkoutLogRepository {
  Future<WorkoutLog?> findById(LogId id);
  Future<List<WorkoutLog>> findByDate(DateOnly date);
  Future<List<WorkoutLog>> findAll();

  /// 按日期闭区间 [from, to] 查询，排序：date DESC, createdAtUtc DESC, id ASC。
  ///
  /// [limit] / [offset] 可选分页。
  Future<List<WorkoutLog>> findByDateRange({
    required DateOnly from,
    required DateOnly to,
    int? limit,
    int? offset,
  });

  /// 游标分页版本（Cursor Pagination V1.1+）。
  ///
  /// 排序：date DESC → createdAtUtc DESC → id ASC。
  /// [cursorKey] 为上一页最后一条的排序键（由 Application 层解码传入）；
  /// null 表示第一页。
  /// [pageSize] 由调用方 clamp(1, 200)。
  /// 返回 [CursorPage]，其 nextCursor 已 Base64URL 编码。
  Future<CursorPage<WorkoutLog>> findByDateRangeCursor({
    required DateOnly from,
    required DateOnly to,
    required int pageSize,
    WorkoutLogCursorKey? cursorKey,
  });

  /// 按日期聚合计数（Dashboard Summary V1.1+）。
  ///
  /// 返回 [from, to] 范围内每天的 WorkoutLog 数量，排序：date DESC。
  /// [cursorDate] 非空时只返回 date < cursorDate 的行（游标分页条件）。
  /// 实际查询 pageSize+1 条以判断是否有更多页（CursorPage.nextCursor）。
  Future<CursorPage<DailyCountRow>> countByDateRangeCursor({
    required DateOnly from,
    required DateOnly to,
    required int pageSize,
    DateOnly? cursorDate,
  });

  Future<void> save(WorkoutLog log);
  Future<void> delete(LogId id);
}
