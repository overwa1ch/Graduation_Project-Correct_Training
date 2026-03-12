/// Catalog Search Use Cases（Catalog/Search V1.1+）
///
/// 两个游标分页用例：
///   GetExerciseCatalogCursorUseCase
///   GetTagCatalogCursorUseCase
///
/// 责任分工：
/// - Application（本层）：校验输入、解码 cursor 字符串、在 Application 层做 tagId 过滤（A3）、
///   将 nextCursor 从 repository 的 CursorPage<Domain> 透传给调用方。
/// - Storage：执行 keyset SQL、编码 nextCursor（使用 CursorCodec）。
library;

import '../../cursor/cursor_codec.dart';
import '../../cursor/cursor_models.dart';
import '../../dtos/catalog_query_dto.dart';
import '../../ports/repositories/exercise_repository.dart';
import '../../ports/repositories/tag_repository.dart';
import '../../ports/use_case.dart';
import '../../services/mappers.dart';

// ---------------------------------------------------------------------------
// GetExerciseCatalogCursorUseCase
// ---------------------------------------------------------------------------

class GetExerciseCatalogCursorUseCase
    implements UseCase<CatalogCursorQuery, ExerciseCatalogPageDTO> {
  final ExerciseRepository exerciseRepository;

  const GetExerciseCatalogCursorUseCase({required this.exerciseRepository});

  @override
  Future<ExerciseCatalogPageDTO> execute(CatalogCursorQuery input) async {
    // Trim keyword: blank/whitespace → null
    final keyword = input.keyword?.trim();
    final normalizedKeyword =
        keyword != null && keyword.isEmpty ? null : keyword;

    // Clamp pageSize
    final pageSize = input.pageSize.clamp(1, 200);

    // Decode cursor → ApplicationException on error
    ExerciseCatalogCursorKey? cursorKey;
    if (input.cursor != null) {
      cursorKey = CursorCodec.decodeExerciseCatalog(input.cursor!);
    }

    // Call repository
    final page = await exerciseRepository.searchCatalogCursor(
      keyword: normalizedKeyword,
      includeDeprecated: input.includeDeprecated,
      pageSize: pageSize,
      cursorKey: cursorKey,
    );

    // A3: Application-layer tagId filter (no DB schema change)
    var filteredItems = page.items;
    if (input.tagId != null) {
      filteredItems = page.items
          .where((ex) => ex.tagIds.contains(input.tagId))
          .toList(growable: false);
    }

    // Map to DTO
    return ExerciseCatalogPageDTO(
      items: filteredItems
          .map(ApplicationMappers.toExerciseDTO)
          .toList(growable: false),
      nextCursor: page.nextCursor,
    );
  }
}

// ---------------------------------------------------------------------------
// GetTagCatalogCursorUseCase
// ---------------------------------------------------------------------------

class GetTagCatalogCursorUseCase
    implements UseCase<CatalogCursorQuery, TagCatalogPageDTO> {
  final TagRepository tagRepository;

  const GetTagCatalogCursorUseCase({required this.tagRepository});

  @override
  Future<TagCatalogPageDTO> execute(CatalogCursorQuery input) async {
    // Trim keyword: blank/whitespace → null
    final keyword = input.keyword?.trim();
    final normalizedKeyword =
        keyword != null && keyword.isEmpty ? null : keyword;

    // Clamp pageSize
    final pageSize = input.pageSize.clamp(1, 200);

    // Decode cursor → ApplicationException on error
    TagCatalogCursorKey? cursorKey;
    if (input.cursor != null) {
      cursorKey = CursorCodec.decodeTagCatalog(input.cursor!);
    }

    // Call repository
    final page = await tagRepository.searchCatalogCursor(
      keyword: normalizedKeyword,
      pageSize: pageSize,
      cursorKey: cursorKey,
    );

    // Map to DTO
    return TagCatalogPageDTO(
      items:
          page.items.map(ApplicationMappers.toTagDTO).toList(growable: false),
      nextCursor: page.nextCursor,
    );
  }
}
