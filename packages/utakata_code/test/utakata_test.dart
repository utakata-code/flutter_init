import 'package:utakata/utakata.dart';
import 'package:test/test.dart';

void main() {
  group('FeatureSpecEntity', () {
    test('relativePath は permission が user の場合 lib/features/user/{name}', () {
      const spec = FeatureSpecEntity(
        featureName: 'memo',
        entityName: 'memo',
        permission: 'user',
      );
      expect(spec.relativePath, 'lib/features/user/memo');
    });

    test('relativePath は permission が direct の場合 lib/features/{name}', () {
      const spec = FeatureSpecEntity(
        featureName: 'auth',
        entityName: 'auth',
        permission: 'direct',
      );
      expect(spec.relativePath, 'lib/features/auth');
    });
  });

  group('TemplateFileEntity', () {
    test('プレースホルダーを正しく置換する', () {
      const template = TemplateFileEntity(
        relativePath: '{{entity_name}}_entity.dart',
        content: 'class {{EntityName}}Entity {}',
      );
      final variables = {
        'entity_name': 'user',
        'EntityName': 'User',
      };
      expect(template.resolvedPath(variables), 'user_entity.dart');
      expect(template.resolvedContent(variables), 'class UserEntity {}');
    });
  });

  group('ArchitectureDiffEntity', () {
    test('isClean は missingPaths と extraPaths が空の場合 true', () {
      const diff = ArchitectureDiffEntity(
        missingPaths: [],
        extraPaths: [],
      );
      expect(diff.isClean, isTrue);
    });
  });
}
