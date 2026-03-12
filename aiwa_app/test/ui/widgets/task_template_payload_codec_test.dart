import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';

import 'package:aiwa_app/ui/widgets/appflowy_block_dto_codec.dart';
import 'package:aiwa_app/ui/widgets/task_template_payload_codec.dart';

void main() {
  group('task template payload codec', () {
    test('buildTaskTemplatePayload emits structured task fields', () {
      final payload = buildTaskTemplatePayload(
        title: 'Warmup',
        body: '',
      );

      expect(payload['taskBody'], '');
      expect(payload['taskNote'], '');
      expect(payload['taskBlocks'], isA<List<dynamic>>());
      expect((payload['taskBlocks'] as List).isNotEmpty, isTrue);
    });

    test('readTaskTemplateBodyFromPayload rebuilds body from taskBlocks', () {
      final blocks = buildTaskTemplateBlocks(
        title: 'Warmup',
        body: '',
      );
      final payload = <String, dynamic>{
        'taskBlocks': blocks.map((block) => block.toJson()).toList(),
      };

      final body = readTaskTemplateBodyFromPayload(
        payload,
        title: 'Warmup',
      );

      expect(body, buildTaskTemplateBodyFromBlocks(blocks));
    });

    test('normalizeTaskTemplatePayload preserves base fields', () {
      final snapshot = normalizeTaskTemplatePayload(
        <String, dynamic>{
          'repeatType': 'daily',
          'taskBlocks': buildTaskTemplateBlocks(
            title: 'Warmup',
            body: '',
          ).map((block) => block.toJson()).toList(),
        },
        title: 'Warmup',
      );

      expect(snapshot.title, 'Warmup');
      expect(snapshot.blocks, isNotEmpty);
      expect(snapshot.payload['repeatType'], 'daily');
      expect(snapshot.payload['taskBlocks'], isA<List<dynamic>>());
      expect(snapshot.payload.containsKey('taskBody'), isTrue);
      expect(snapshot.payload.containsKey('taskNote'), isTrue);
    });

    test('buildTaskTemplatePayloadFromBlocks preserves editor blocks', () {
      final payload = buildTaskTemplatePayloadFromBlocks(
        title: 'Warmup',
        bodyBlocks: <BlockDTO>[
          TextBlockDTO(id: 't1', text: 'Line 1\nLine 2'),
          TableBlockDTO(
            id: 'tb1',
            columnCount: 2,
            rows: const <List<String>>[
              <String>['A', 'B'],
              <String>['1', '2'],
            ],
          ),
        ],
      );

      final blocks = parseTaskTemplateBlocksFromPayload(
        payload,
        title: 'Warmup',
      );

      expect(blocks.length, 3);
      expect(blocks.first, isA<HeadingBlockDTO>());
      expect(blocks[1], isA<TextBlockDTO>());
      expect(blocks[2], isA<TableBlockDTO>());
      expect(payload['taskNote'], contains('Table 2 x 2'));
    });
  });
}
