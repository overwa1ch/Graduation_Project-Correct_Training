import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tokens Schema Validation Tests', () {
    test('colors.json should have valid structure', () {
      final file = File('lib/theme/tokens/colors.json');
      expect(file.existsSync(), isTrue, reason: 'colors.json should exist');

      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Validate structure
      expect(json.containsKey('brand'), isTrue);
      expect(json.containsKey('surface'), isTrue);
      expect(json.containsKey('text'), isTrue);
      expect(json.containsKey('error'), isTrue);

      // Validate brand colors
      final brand = json['brand'] as Map<String, dynamic>;
      expect(brand.containsKey('primary'), isTrue);
      expect(brand['primary'], matches(r'^#[0-9A-Fa-f]{6}$'));

      // Validate surface colors
      final surface = json['surface'] as Map<String, dynamic>;
      expect(surface.containsKey('primary'), isTrue);
      expect(surface['primary'], matches(r'^#[0-9A-Fa-f]{6}$'));

      // Validate text colors
      final text = json['text'] as Map<String, dynamic>;
      expect(text.containsKey('primary'), isTrue);
      expect(text['primary'], matches(r'^#[0-9A-Fa-f]{6}$'));

      // Validate error colors
      final error = json['error'] as Map<String, dynamic>;
      expect(error.containsKey('primary'), isTrue);
      expect(error['primary'], matches(r'^#[0-9A-Fa-f]{6}$'));
    });

    test('typography.json should have valid structure', () {
      final file = File('lib/theme/tokens/typography.json');
      expect(file.existsSync(), isTrue, reason: 'typography.json should exist');

      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Validate structure
      expect(json.containsKey('fontFamily'), isTrue);
      expect(json.containsKey('styles'), isTrue);

      // Validate font family
      expect(json['fontFamily'], 'Inter');

      // Validate styles
      final styles = json['styles'] as Map<String, dynamic>;
      expect(styles.containsKey('h1'), isTrue);
      expect(styles.containsKey('h2'), isTrue);
      expect(styles.containsKey('bodyBase'), isTrue);
      expect(styles.containsKey('button'), isTrue);

      // Validate h1 style
      final h1 = styles['h1'] as Map<String, dynamic>;
      expect(h1.containsKey('fontFamily'), isTrue);
      expect(h1.containsKey('fontWeight'), isTrue);
      expect(h1.containsKey('fontSize'), isTrue);
      expect(h1.containsKey('lineHeight'), isTrue);
      expect(h1['fontSize'], isA<num>());
      expect(h1['lineHeight'], isA<num>());
    });

    test('spacing.json should have valid structure', () {
      final file = File('lib/theme/tokens/spacing.json');
      expect(file.existsSync(), isTrue, reason: 'spacing.json should exist');

      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Validate structure
      expect(json.containsKey('spacing'), isTrue);
      expect(json.containsKey('padding'), isTrue);
      expect(json.containsKey('gap'), isTrue);

      // Validate spacing scale
      final spacing = json['spacing'] as Map<String, dynamic>;
      expect(spacing.containsKey('xs'), isTrue);
      expect(spacing.containsKey('sm'), isTrue);
      expect(spacing.containsKey('md'), isTrue);
      expect(spacing.containsKey('lg'), isTrue);
      expect(spacing['xs'], isA<num>());
      expect(spacing['sm'], isA<num>());

      // Validate padding presets
      final padding = json['padding'] as Map<String, dynamic>;
      expect(padding.containsKey('button'), isTrue);
      expect(padding.containsKey('card'), isTrue);
      expect(padding['button'], isA<num>());

      // Validate gap presets
      final gap = json['gap'] as Map<String, dynamic>;
      expect(gap.containsKey('xs'), isTrue);
      expect(gap.containsKey('sm'), isTrue);
      expect(gap['xs'], isA<num>());
    });

    test('radius.json should have valid structure', () {
      final file = File('lib/theme/tokens/radius.json');
      expect(file.existsSync(), isTrue, reason: 'radius.json should exist');

      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Validate structure
      expect(json.containsKey('radius'), isTrue);
      expect(json.containsKey('borderRadius'), isTrue);

      // Validate radius scale
      final radius = json['radius'] as Map<String, dynamic>;
      expect(radius.containsKey('sm'), isTrue);
      expect(radius.containsKey('md'), isTrue);
      expect(radius.containsKey('lg'), isTrue);
      expect(radius.containsKey('full'), isTrue);
      expect(radius['sm'], isA<num>());
      expect(radius['full'], isA<num>());

      // Validate component-specific radius
      final borderRadius = json['borderRadius'] as Map<String, dynamic>;
      expect(borderRadius.containsKey('button'), isTrue);
      expect(borderRadius.containsKey('card'), isTrue);
      expect(borderRadius['button'], isA<num>());
    });

    test('Assets tokens should match lib tokens', () {
      // Verify that assets/tokens contains copies of lib/theme/tokens
      final libColors = File('lib/theme/tokens/colors.json');
      final assetsColors = File('assets/tokens/colors.json');

      if (assetsColors.existsSync()) {
        expect(
          libColors.readAsStringSync(),
          assetsColors.readAsStringSync(),
          reason: 'assets/tokens/colors.json should match lib/theme/tokens/colors.json',
        );
      }
    });

    test('All token files should be valid JSON', () {
      final tokenFiles = [
        'lib/theme/tokens/colors.json',
        'lib/theme/tokens/typography.json',
        'lib/theme/tokens/spacing.json',
        'lib/theme/tokens/radius.json',
      ];

      for (final path in tokenFiles) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path should exist');

        final content = file.readAsStringSync();
        expect(
          () => jsonDecode(content),
          returnsNormally,
          reason: '$path should be valid JSON',
        );
      }
    });

    test('Color values should be valid hex codes', () {
      final file = File('lib/theme/tokens/colors.json');
      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;

      void validateColors(Map<String, dynamic> obj) {
        obj.forEach((key, value) {
          if (value is String && value.startsWith('#')) {
            expect(
              value,
              matches(r'^#[0-9A-Fa-f]{6}$'),
              reason: 'Color value for $key should be valid hex code',
            );
          } else if (value is Map<String, dynamic>) {
            validateColors(value);
          }
        });
      }

      validateColors(json);
    });

    test('Numeric values should be valid', () {
      final files = {
        'typography.json': 'lib/theme/tokens/typography.json',
        'spacing.json': 'lib/theme/tokens/spacing.json',
        'radius.json': 'lib/theme/tokens/radius.json',
      };

      files.forEach((name, path) {
        final file = File(path);
        final content = file.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;

        void validateNumbers(Map<String, dynamic> obj, String context) {
          obj.forEach((key, value) {
            if (value is num) {
              // letterSpacing can be negative, others should be non-negative
              if (key == 'letterSpacing') {
                expect(
                  value,
                  isA<num>(),
                  reason: '$context.$key should be a number in $name',
                );
              } else {
                expect(
                  value,
                  greaterThanOrEqualTo(0),
                  reason: '$context.$key should be non-negative in $name',
                );
              }
            } else if (value is Map<String, dynamic>) {
              validateNumbers(value, '$context.$key');
            }
          });
        }

        validateNumbers(json, name);
      });
    });
  });
}

