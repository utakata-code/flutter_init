import 'package:test/test.dart';
import 'package:utakata/src/1_domain/services/case_converter.dart';

void main() {
  group('CaseConverter.toSnakeCase', () {
    test('splits camelCase boundaries', () {
      expect(CaseConverter.toSnakeCase('myFeature'), 'my_feature');
      expect(CaseConverter.toSnakeCase('MyFeature'), 'my_feature');
    });

    test('normalizes separators', () {
      expect(CaseConverter.toSnakeCase('my-feature'), 'my_feature');
      expect(CaseConverter.toSnakeCase('my feature'), 'my_feature');
    });

    test('is idempotent on already-snake input', () {
      expect(CaseConverter.toSnakeCase('my_feature'), 'my_feature');
    });
  });

  group('CaseConverter.toPascalCase', () {
    test('capitalizes each word', () {
      expect(CaseConverter.toPascalCase('my_feature'), 'MyFeature');
      expect(CaseConverter.toPascalCase('my-feature'), 'MyFeature');
    });
  });

  group('CaseConverter.toCamelCase', () {
    test('lowercases first letter of pascal case', () {
      expect(CaseConverter.toCamelCase('my_feature'), 'myFeature');
    });
  });

  group('round-trip', () {
    test('toSnakeCase(toPascalCase(x)) is stable for simple snake input', () {
      const input = 'my_feature_name';
      final pascal = CaseConverter.toPascalCase(input);
      expect(CaseConverter.toSnakeCase(pascal), input);
    });
  });
}
