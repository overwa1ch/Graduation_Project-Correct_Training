import 'package:aiwa_core/fit_application/cursor/cursor_models.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

abstract interface class ExerciseRepository {
  Future<Exercise?> findById(ExerciseId id);
  Future<List<Exercise>> findAll();
  Future<void> save(Exercise exercise);

  /// 游标分页搜索 Exercise Catalog（Catalog/Search V1.1+）。
  ///
  /// 排序：deprecated ASC → lower(name) ASC → id ASC。
  /// [keyword] 大小写不敏感、子串匹配（lower(name) LIKE '%keyword%'）。
  /// [includeDeprecated] 为 false 时只返回 deprecated=0 的项。
  /// [cursorKey] 为上一页最后一条的排序键（由 Application 层解码传入）；null 表示第一页。
  /// [pageSize] 由调用方 clamp(1, 200)。
  /// 返回 [CursorPage]，其 nextCursor 已 Base64URL 编码。
  Future<CursorPage<Exercise>> searchCatalogCursor({
    String? keyword,
    bool includeDeprecated = false,
    required int pageSize,
    ExerciseCatalogCursorKey? cursorKey,
  });
}
