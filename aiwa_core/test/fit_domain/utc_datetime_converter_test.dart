import 'package:aiwa_core/fit_domain/fit_domain.dart';
import 'package:test/test.dart';

void main() {
  group('UtcDateTimeConverter fromJson', () {
    final converter = UtcDateTimeConverter();

    test('rejects naive local DateTime string without timezone', () {
      expect(
        () => converter.fromJson('2025-01-01T12:00:00'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts UTC DateTime string with Z suffix', () {
      final dt = converter.fromJson('2025-01-01T12:00:00Z');
      expect(dt.isUtc, isTrue);
      expect(dt.year, 2025);
      expect(dt.month, 1);
      expect(dt.day, 1);
      expect(dt.hour, 12);
      expect(dt.minute, 0);
      expect(dt.second, 0);
    });

    test('accepts DateTime string with explicit non-UTC offset as UTC instant', () {
      final dt = converter.fromJson('2025-01-01T12:00:00+09:00');
      // 2025-01-01T12:00:00+09:00 == 2025-01-01T03:00:00Z
      expect(dt.isUtc, isTrue);
      expect(dt.year, 2025);
      expect(dt.month, 1);
      expect(dt.day, 1);
      expect(dt.hour, 3);
      expect(dt.minute, 0);
      expect(dt.second, 0);
    });
  });
}

