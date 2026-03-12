import 'package:test/test.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

void main() {
  test('ApplicationMappers maps table blocks both directions', () {
    final domainBlock = LogBlock.tableBlock(
      id: 'table-1',
      columnCount: 3,
      rows: const <List<String>>[
        <String>['A', 'B', 'C'],
        <String>['1', '2', '3'],
      ],
    );

    final dto = ApplicationMappers.toBlockDTO(domainBlock);
    expect(dto, isA<TableBlockDTO>());
    expect((dto as TableBlockDTO).columnCount, 3);
    expect(dto.rows[1][2], '3');

    final restored = ApplicationMappers.toDomainBlock(dto);
    expect(restored, isA<TableBlock>());
    expect(
      restored.map(
        textBlock: (_) => 0,
        headingBlock: (_) => 0,
        dividerBlock: (_) => 0,
        exerciseBlock: (_) => 0,
        imageBlock: (_) => 0,
        videoBlock: (_) => 0,
        checklistBlock: (_) => 0,
        timerMarkerBlock: (_) => 0,
        referenceBlock: (_) => 0,
        linkBlock: (_) => 0,
        tableBlock: (value) => value.columnCount,
      ),
      3,
    );
  });
}
