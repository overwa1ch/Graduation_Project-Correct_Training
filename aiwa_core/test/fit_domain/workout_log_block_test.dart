import 'package:aiwa_core/fit_domain/fit_domain.dart';
import 'package:test/test.dart';

void main() {
  group('WorkoutLog block operations', () {
    test('insert/update/remove/reorder', () {
      final createdAt = DateTime.utc(2025, 1, 1, 10);
      final initialEdited = DateTime.utc(2025, 1, 1, 10, 5);
      final log = WorkoutLog(
        id: 'log-1',
        date: DateOnly(2025, 1, 1),
        createdAtUtc: createdAt,
        lastEditedAtUtc: initialEdited,
        blocks: [],
      );

      final now1 = DateTime.utc(2025, 1, 1, 11);
      final blockA = LogBlock.textBlock(id: 'b1', text: 'A');
      log.insertBlock(0, blockA, now1);
      expect(log.blocks.length, 1);
      expect(log.blocks.first.id, 'b1');
      expect(log.lastEditedAtUtc, now1);

      final now2 = DateTime.utc(2025, 1, 1, 12);
      final blockB = LogBlock.headingBlock(id: 'b2', text: 'B', level: 1);
      log.appendBlock(blockB, now2);
      expect(log.blocks.length, 2);
      expect(log.blocks[1].id, 'b2');
      expect(log.lastEditedAtUtc, now2);

      final now3 = DateTime.utc(2025, 1, 1, 13);
      final updatedA = LogBlock.textBlock(id: 'b1', text: 'A2');
      log.updateBlock('b1', updatedA, now3);
      expect(log.blocks.first, updatedA);
      expect(log.lastEditedAtUtc, now3);

      final now4 = DateTime.utc(2025, 1, 1, 14);
      log.reorderBlocks(0, 1, now4);
      expect(log.blocks[0].id, 'b2');
      expect(log.blocks[1].id, 'b1');
      expect(log.lastEditedAtUtc, now4);

      final now5 = DateTime.utc(2025, 1, 1, 15);
      log.removeBlock('b2', now5);
      expect(log.blocks.length, 1);
      expect(log.blocks.first.id, 'b1');
      expect(log.lastEditedAtUtc, now5);
    });

    test('replaceMetadata updates metadata and lastEditedAtUtc', () {
      final log = WorkoutLog(
        id: 'log-2',
        date: DateOnly(2025, 1, 2),
        createdAtUtc: DateTime.utc(2025, 1, 2, 8),
        lastEditedAtUtc: DateTime.utc(2025, 1, 2, 8, 30),
        blocks: const <LogBlock>[],
      );

      final now = DateTime.utc(2025, 1, 2, 9);
      log.replaceMetadata(
        <String, dynamic>{
          'actionProgressions': <Map<String, dynamic>>[
            <String, dynamic>{
              'exerciseId': 'ex-1',
              'targetWeightKg': 120,
            },
          ],
        },
        now,
      );

      expect(log.metadata['actionProgressions'], isNotNull);
      expect(log.lastEditedAtUtc, now);
    });
  });
}
