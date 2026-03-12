import 'package:aiwa_core/fit_application/cursor/cursor_models.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

abstract interface class TagRepository {
  Future<Tag?> findById(TagId id);
  Future<List<Tag>> findAll();
  Future<void> save(Tag tag);
  Future<void> delete(TagId id);

  /// 游标分页搜索 Tag Catalog（Catalog/Search V1.1+）。
  ///
  /// 排序：lower(name) ASC → id ASC。
  /// [keyword] 大小写不敏感、子串匹配（lower(name) LIKE '%keyword%'）。
  /// [cursorKey] 为上一页最后一条的排序键（由 Application 层解码传入）；null 表示第一页。
  /// [pageSize] 由调用方 clamp(1, 200)。
  /// 返回 [CursorPage]，其 nextCursor 已 Base64URL 编码。
  Future<CursorPage<Tag>> searchCatalogCursor({
    String? keyword,
    required int pageSize,
    TagCatalogCursorKey? cursorKey,
  });
}
