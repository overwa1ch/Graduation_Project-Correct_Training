/// Catalog Cursor Pagination Tests – Storage layer（Catalog/Search V1.1+）
///
/// 覆盖场景：
///   1. keyword 大小写不敏感、子串匹配
///   2. includeDeprecated 过滤
///   3. 排序稳定：deprecated ASC, lower(name) ASC, id ASC (Exercise)
///   4. 排序稳定：lower(name) ASC, id ASC (Tag)
///   5. 翻页无重复、无漏项
///   6. pageSize+1 nextCursor 逻辑
library;

import 'dart:io';

import 'package:aiwa_core/fit_application/cursor/cursor_codec.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:aiwa_core/fit_storage.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

domain.Exercise _exercise({
  required String id,
  required String name,
  bool deprecated = false,
  List<String> tagIds = const [],
}) =>
    domain.Exercise(
      id: id,
      name: name,
      tagIds: tagIds,
      deprecated: deprecated,
    );

domain.Tag _tag({
  required String id,
  required String name,
}) =>
    domain.Tag(id: id, name: name);

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  group('Catalog Cursor Pagination – Storage layer', () {
    late Directory tempDir;
    late FitStoragePaths paths;
    late FitDatabase db;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fit_catalog_cursor_');
      paths = FitStoragePaths.fromAppDocumentsDir(tempDir);
      await paths.ensureInitialized();
      db = FitDatabase.openFile(paths.dbFile);
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    // =========================================================================
    // Exercise Catalog
    // =========================================================================

    group('ExerciseRepository.searchCatalogCursor', () {
      late DriftExerciseRepository repo;
      setUp(() => repo = DriftExerciseRepository(db));

      test('first page (cursor=null) returns up to pageSize items', () async {
        await repo.save(_exercise(id: 'ex-1', name: 'Squat'));
        await repo.save(_exercise(id: 'ex-2', name: 'Bench Press'));
        await repo.save(_exercise(id: 'ex-3', name: 'Deadlift'));

        final page = await repo.searchCatalogCursor(
          pageSize: 2,
        );

        expect(page.items.length, 2);
        expect(page.nextCursor, isNotNull);
      });

      test('keyword filter is case-insensitive and substring match', () async {
        await repo.save(_exercise(id: 'ex-1', name: 'Squat'));
        await repo.save(_exercise(id: 'ex-2', name: 'Bench Press'));
        await repo.save(_exercise(id: 'ex-3', name: 'Deadlift'));

        final page1 = await repo.searchCatalogCursor(
          keyword: 'squat',
          pageSize: 10,
        );
        expect(page1.items.length, 1);
        expect(page1.items.first.name, 'Squat');

        final page2 = await repo.searchCatalogCursor(
          keyword: 'PRESS',
          pageSize: 10,
        );
        expect(page2.items.length, 1);
        expect(page2.items.first.name, 'Bench Press');
      });

      test('includeDeprecated filter excludes deprecated items', () async {
        await repo.save(_exercise(id: 'ex-1', name: 'Active', deprecated: false));
        await repo.save(_exercise(id: 'ex-2', name: 'Old', deprecated: true));

        final page1 = await repo.searchCatalogCursor(
          includeDeprecated: false,
          pageSize: 10,
        );
        expect(page1.items.length, 1);
        expect(page1.items.first.id, 'ex-1');

        final page2 = await repo.searchCatalogCursor(
          includeDeprecated: true,
          pageSize: 10,
        );
        expect(page2.items.length, 2);
      });

      test('sort: deprecated ASC, lower(name) ASC, id ASC', () async {
        await repo.save(_exercise(id: 'ex-b', name: 'Zebra', deprecated: false));
        await repo.save(_exercise(id: 'ex-a', name: 'Apple', deprecated: false));
        await repo.save(_exercise(id: 'ex-c', name: 'Beta', deprecated: true));

        final page = await repo.searchCatalogCursor(
          includeDeprecated: true,
          pageSize: 10,
        );

        // deprecated ASC: false (0) < true (1)  → non-deprecated items first
        expect(page.items[0].id, 'ex-a'); // deprecated=0, 'apple'
        expect(page.items[1].id, 'ex-b'); // deprecated=0, 'zebra'
        expect(page.items[2].id, 'ex-c'); // deprecated=1, 'beta'
        expect(page.nextCursor, isNull);
      });

      test('second page via nextCursor has no overlaps', () async {
        await repo.save(_exercise(id: 'ex-1', name: 'A'));
        await repo.save(_exercise(id: 'ex-2', name: 'B'));
        await repo.save(_exercise(id: 'ex-3', name: 'C'));
        await repo.save(_exercise(id: 'ex-4', name: 'D'));

        final page1 = await repo.searchCatalogCursor(pageSize: 2);
        expect(page1.items.length, 2);
        expect(page1.nextCursor, isNotNull);

        final cursorKey = CursorCodec.decodeExerciseCatalog(page1.nextCursor!);
        final page2 = await repo.searchCatalogCursor(
          pageSize: 2,
          cursorKey: cursorKey,
        );
        expect(page2.items.length, 2);
        expect(page2.nextCursor, isNull);

        final ids1 = page1.items.map((e) => e.id).toSet();
        final ids2 = page2.items.map((e) => e.id).toSet();
        expect(ids1.intersection(ids2), isEmpty);
        expect(ids1.union(ids2).length, 4);
      });

      test('exactly pageSize items → nextCursor is null', () async {
        await repo.save(_exercise(id: 'ex-1', name: 'A'));
        await repo.save(_exercise(id: 'ex-2', name: 'B'));
        await repo.save(_exercise(id: 'ex-3', name: 'C'));

        final page = await repo.searchCatalogCursor(pageSize: 3);

        expect(page.items.length, 3);
        expect(page.nextCursor, isNull);
      });

      test('empty result → items=[], nextCursor=null', () async {
        final page = await repo.searchCatalogCursor(
          keyword: 'nonexistent',
          pageSize: 10,
        );

        expect(page.items, isEmpty);
        expect(page.nextCursor, isNull);
      });
    });

    // =========================================================================
    // Tag Catalog
    // =========================================================================

    group('TagRepository.searchCatalogCursor', () {
      late DriftTagRepository repo;
      setUp(() => repo = DriftTagRepository(db));

      test('first page returns up to pageSize items', () async {
        await repo.save(_tag(id: 'tag-1', name: 'Legs'));
        await repo.save(_tag(id: 'tag-2', name: 'Chest'));
        await repo.save(_tag(id: 'tag-3', name: 'Back'));

        final page = await repo.searchCatalogCursor(pageSize: 2);

        expect(page.items.length, 2);
        expect(page.nextCursor, isNotNull);
      });

      test('keyword filter is case-insensitive and substring match', () async {
        await repo.save(_tag(id: 'tag-1', name: 'Legs'));
        await repo.save(_tag(id: 'tag-2', name: 'Chest'));

        final page = await repo.searchCatalogCursor(
          keyword: 'LEG',
          pageSize: 10,
        );
        expect(page.items.length, 1);
        expect(page.items.first.name, 'Legs');
      });

      test('sort: lower(name) ASC, id ASC', () async {
        await repo.save(_tag(id: 'tag-b', name: 'Zebra'));
        await repo.save(_tag(id: 'tag-a', name: 'Apple'));
        await repo.save(_tag(id: 'tag-c', name: 'Beta'));

        final page = await repo.searchCatalogCursor(pageSize: 10);

        expect(page.items[0].id, 'tag-a'); // 'apple' < 'beta' < 'zebra'
        expect(page.items[1].id, 'tag-c');
        expect(page.items[2].id, 'tag-b');
        expect(page.nextCursor, isNull);
      });

      test('second page via nextCursor has no overlaps', () async {
        await repo.save(_tag(id: 'tag-1', name: 'A'));
        await repo.save(_tag(id: 'tag-2', name: 'B'));
        await repo.save(_tag(id: 'tag-3', name: 'C'));
        await repo.save(_tag(id: 'tag-4', name: 'D'));

        final page1 = await repo.searchCatalogCursor(pageSize: 2);
        expect(page1.nextCursor, isNotNull);

        final cursorKey = CursorCodec.decodeTagCatalog(page1.nextCursor!);
        final page2 = await repo.searchCatalogCursor(
          pageSize: 2,
          cursorKey: cursorKey,
        );
        expect(page2.nextCursor, isNull);

        final ids1 = page1.items.map((e) => e.id).toSet();
        final ids2 = page2.items.map((e) => e.id).toSet();
        expect(ids1.intersection(ids2), isEmpty);
        expect(ids1.union(ids2).length, 4);
      });

      test('exactly pageSize items → nextCursor is null', () async {
        await repo.save(_tag(id: 'tag-1', name: 'A'));
        await repo.save(_tag(id: 'tag-2', name: 'B'));

        final page = await repo.searchCatalogCursor(pageSize: 2);

        expect(page.items.length, 2);
        expect(page.nextCursor, isNull);
      });
    });
  });
}
