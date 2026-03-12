/// Catalog UseCase Tests（Catalog/Search V1.1+）
///
/// 覆盖：
///   GetExerciseCatalogCursorUseCase
///   GetTagCatalogCursorUseCase
///
/// 必覆盖场景：
///   1. keyword trim 空→null
///   2. tagId 过滤（A3，Application 层）
///   3. INVALID_CURSOR / CURSOR_MISMATCH / INVALID_CURSOR_VERSION
///   4. pageSize clamp(1,200)
///   5. DTO 字段映射正确
library;

import 'dart:convert';

import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';
import 'package:test/test.dart';

import 'support/in_memory_repositories.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Exercise _makeExercise({
  required String id,
  required String name,
  bool deprecated = false,
  List<String> tagIds = const [],
}) =>
    Exercise(
      id: id,
      name: name,
      tagIds: tagIds,
      deprecated: deprecated,
    );

Tag _makeTag({required String id, required String name}) =>
    Tag(id: id, name: name);

String _wrongNamespaceCursor() =>
    CursorCodec.encode('wrong:namespace:v1', <String, dynamic>{'k': 'v'});

String _badVersionCursor() {
  final payload = <String, dynamic>{
    'v': 99,
    'h': ExerciseCatalogCursorKey.namespace,
    'k': <String, dynamic>{},
  };
  return base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ==========================================================================
  // GetExerciseCatalogCursorUseCase
  // ==========================================================================

  group('GetExerciseCatalogCursorUseCase', () {
    late InMemoryExerciseRepository exerciseRepo;
    late GetExerciseCatalogCursorUseCase useCase;

    setUp(() {
      exerciseRepo = InMemoryExerciseRepository();
      useCase = GetExerciseCatalogCursorUseCase(
        exerciseRepository: exerciseRepo,
      );
    });

    test('keyword blank/whitespace → normalized to null', () async {
      await exerciseRepo.save(_makeExercise(id: 'ex-1', name: 'Squat'));
      await exerciseRepo.save(_makeExercise(id: 'ex-2', name: 'Bench'));

      final page1 = await useCase.execute(const CatalogCursorQuery(
        keyword: '',
        pageSize: 10,
      ));
      expect(page1.items.length, 2);

      final page2 = await useCase.execute(const CatalogCursorQuery(
        keyword: '   ',
        pageSize: 10,
      ));
      expect(page2.items.length, 2);
    });

    test('tagId filter returns only exercises with matching tag', () async {
      await exerciseRepo.save(_makeExercise(
        id: 'ex-1',
        name: 'Squat',
        tagIds: ['tag-1', 'tag-2'],
      ));
      await exerciseRepo.save(_makeExercise(
        id: 'ex-2',
        name: 'Bench',
        tagIds: ['tag-2', 'tag-3'],
      ));
      await exerciseRepo.save(_makeExercise(
        id: 'ex-3',
        name: 'Deadlift',
        tagIds: ['tag-3'],
      ));

      final page = await useCase.execute(const CatalogCursorQuery(
        tagId: 'tag-2',
        pageSize: 10,
      ));

      expect(page.items.length, 2);
      expect(page.items.map((e) => e.id).toSet(), {'ex-1', 'ex-2'});
    });

    test('invalid cursor → INVALID_CURSOR', () {
      expect(
        () => useCase.execute(const CatalogCursorQuery(
          cursor: 'invalid',
          pageSize: 10,
        )),
        throwsA(
          predicate((e) =>
              e is ApplicationException &&
              e.errorCode == AppErrorCodes.invalidCursor),
        ),
      );
    });

    test('wrong namespace cursor → CURSOR_MISMATCH', () {
      expect(
        () => useCase.execute(CatalogCursorQuery(
          cursor: _wrongNamespaceCursor(),
          pageSize: 10,
        )),
        throwsA(
          predicate((e) =>
              e is ApplicationException &&
              e.errorCode == AppErrorCodes.cursorMismatch),
        ),
      );
    });

    test('unsupported version cursor → INVALID_CURSOR_VERSION', () {
      expect(
        () => useCase.execute(CatalogCursorQuery(
          cursor: _badVersionCursor(),
          pageSize: 10,
        )),
        throwsA(
          predicate((e) =>
              e is ApplicationException &&
              e.errorCode == AppErrorCodes.invalidCursorVersion),
        ),
      );
    });

    test('pageSize is clamped to 1..200', () async {
      await exerciseRepo.save(_makeExercise(id: 'ex-1', name: 'A'));

      final page1 = await useCase.execute(const CatalogCursorQuery(
        pageSize: 0,
      ));
      expect(page1.items.length, 1);

      final page2 = await useCase.execute(const CatalogCursorQuery(
        pageSize: 500,
      ));
      expect(page2.items.length, 1);
    });

    test('DTO mapping includes all fields', () async {
      await exerciseRepo.save(_makeExercise(
        id: 'ex-1',
        name: 'Squat',
        deprecated: false,
        tagIds: ['tag-1'],
      ));

      final page = await useCase.execute(const CatalogCursorQuery(
        pageSize: 10,
      ));

      expect(page.items.length, 1);
      final dto = page.items.first;
      expect(dto.id, 'ex-1');
      expect(dto.name, 'Squat');
      expect(dto.deprecated, false);
      expect(dto.tagIds, ['tag-1']);
    });

    test('first page with cursor=null works', () async {
      await exerciseRepo.save(_makeExercise(id: 'ex-1', name: 'A'));
      await exerciseRepo.save(_makeExercise(id: 'ex-2', name: 'B'));

      final page = await useCase.execute(const CatalogCursorQuery(
        pageSize: 10,
      ));

      expect(page.items.length, 2);
    });
  });

  // ==========================================================================
  // GetTagCatalogCursorUseCase
  // ==========================================================================

  group('GetTagCatalogCursorUseCase', () {
    late InMemoryTagRepository tagRepo;
    late GetTagCatalogCursorUseCase useCase;

    setUp(() {
      tagRepo = InMemoryTagRepository();
      useCase = GetTagCatalogCursorUseCase(tagRepository: tagRepo);
    });

    test('keyword blank/whitespace → normalized to null', () async {
      await tagRepo.save(_makeTag(id: 'tag-1', name: 'Legs'));
      await tagRepo.save(_makeTag(id: 'tag-2', name: 'Chest'));

      final page1 = await useCase.execute(const CatalogCursorQuery(
        keyword: '',
        pageSize: 10,
      ));
      expect(page1.items.length, 2);

      final page2 = await useCase.execute(const CatalogCursorQuery(
        keyword: '   ',
        pageSize: 10,
      ));
      expect(page2.items.length, 2);
    });

    test('invalid cursor → INVALID_CURSOR', () {
      expect(
        () => useCase.execute(const CatalogCursorQuery(
          cursor: 'invalid',
          pageSize: 10,
        )),
        throwsA(
          predicate((e) =>
              e is ApplicationException &&
              e.errorCode == AppErrorCodes.invalidCursor),
        ),
      );
    });

    test('wrong namespace cursor → CURSOR_MISMATCH', () {
      expect(
        () => useCase.execute(CatalogCursorQuery(
          cursor: CursorCodec.encodeExerciseCatalog(
            const ExerciseCatalogCursorKey(
              deprecated: 0,
              nameNormalized: 'test',
              id: 'ex-1',
            ),
          ),
          pageSize: 10,
        )),
        throwsA(
          predicate((e) =>
              e is ApplicationException &&
              e.errorCode == AppErrorCodes.cursorMismatch),
        ),
      );
    });

    test('pageSize is clamped to 1..200', () async {
      await tagRepo.save(_makeTag(id: 'tag-1', name: 'A'));

      final page1 = await useCase.execute(const CatalogCursorQuery(
        pageSize: 0,
      ));
      expect(page1.items.length, 1);

      final page2 = await useCase.execute(const CatalogCursorQuery(
        pageSize: 500,
      ));
      expect(page2.items.length, 1);
    });

    test('DTO mapping includes all fields', () async {
      await tagRepo.save(_makeTag(id: 'tag-1', name: 'Legs'));

      final page = await useCase.execute(const CatalogCursorQuery(
        pageSize: 10,
      ));

      expect(page.items.length, 1);
      final dto = page.items.first;
      expect(dto.id, 'tag-1');
      expect(dto.name, 'Legs');
    });

    test('first page with cursor=null works', () async {
      await tagRepo.save(_makeTag(id: 'tag-1', name: 'A'));
      await tagRepo.save(_makeTag(id: 'tag-2', name: 'B'));

      final page = await useCase.execute(const CatalogCursorQuery(
        pageSize: 10,
      ));

      expect(page.items.length, 2);
    });
  });
}
