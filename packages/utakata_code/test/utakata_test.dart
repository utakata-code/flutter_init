import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:utakata/src/1_domain/1_entities/dependency_stack_entity.dart';
import 'package:utakata/utakata.dart';
import 'package:test/test.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/architecture_repository_impl.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/template_repository_impl.dart';
import 'package:utakata/src/1_domain/3_usecases/list_architectures_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/show_architecture_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/export_architecture_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/create_architecture_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/create_project_usecase.dart';
import 'package:utakata/src/1_domain/messages/ja_messages.dart';

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

  group('CheckReport', () {
    test('isClean は missing/extra/namingViolations が全て空の場合 true', () {
      const report = CheckReport(
        missingPaths: [],
        extraPaths: [],
        namingViolations: [],
      );
      expect(report.isClean, isTrue);
    });

    test('isClean はいずれかに要素があれば false', () {
      const report = CheckReport(missingPaths: ['user/memo']);
      expect(report.isClean, isFalse);
      expect(report.violationCount, 1);
    });
  });

  group('Local-First Loading', () {
    late Directory tempDir;
    late Directory originalDir;
    late FilesystemDataSource fs;
    late YamlDataSource yaml;
    late ArchitectureRepositoryImpl archRepo;
    late TemplateRepositoryImpl templateRepo;

    setUp(() {
      originalDir = Directory.current;
      tempDir = Directory.systemTemp.createTempSync('utakata_test_');
      Directory.current = tempDir;

      fs = const FilesystemDataSource();
      yaml = const YamlDataSource();
      archRepo = ArchitectureRepositoryImpl(fs, yaml);
      templateRepo = TemplateRepositoryImpl(fs);
    });

    tearDown(() {
      Directory.current = originalDir;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('ArchitectureRepositoryImpl.getById loads local definition if it exists and matches', () async {
      // 1. Create a local custom arch definition
      final localArchDir = Directory(p.join(tempDir.path, 'AI', 'architecture'));
      localArchDir.createSync(recursive: true);

      final localYamlFile = File(p.join(localArchDir.path, 'arch_definition.yaml'));
      localYamlFile.writeAsStringSync('''
id: clean_architecture
displayName: "My Custom Local Clean Architecture"
layers:
  - name: 1_domain
    dirs:
      - 1_entities
naming_rules: []
''');

      // 2. Fetch the architecture
      final definition = await archRepo.getById('clean_architecture');

      // 3. Verify it is our custom local definition instead of the package default
      expect(definition.displayName, 'My Custom Local Clean Architecture');
      expect(definition.layers.length, 1);
      expect(definition.layers.first.name, '1_domain');
    });

    test('ArchitectureRepositoryImpl.getById falls back to package template if local does not exist', () async {
      // No local files created. It should load package default
      final definition = await archRepo.getById('clean_architecture');
      expect(definition.displayName, 'Clean Architecture (4-layer)');
      expect(definition.layers.length, 4);
    });

    test('TemplateRepositoryImpl.getFeatureTemplates loads local feature templates if directory exists', () async {
      // 1. Create a local features template directory
      final localFeaturesDir = Directory(p.join(tempDir.path, 'AI', 'architecture', 'features'));
      localFeaturesDir.createSync(recursive: true);

      // Create a customized template file
      final localTmplFile = File(p.join(localFeaturesDir.path, 'custom_entity.dart.tmpl'));
      localTmplFile.writeAsStringSync('// My Local Custom Template: {{EntityName}}');

      // 2. Fetch templates
      final templates = await templateRepo.getFeatureTemplates('clean_architecture');

      // 3. Verify only our local template was loaded
      expect(templates.length, 1);
      expect(templates.first.relativePath, 'custom_entity.dart');
      expect(templates.first.content, '// My Local Custom Template: {{EntityName}}');
    });

    test('TemplateRepositoryImpl.getFeatureTemplates package fallback is empty (.tmpl abolished in S2)', () async {
      // .tmpl は同梱テンプレートから廃止された(v0.13.0)。feature 生成は
      // arch_definition.yaml 駆動のディレクトリ + 動的 GUIDE 生成で完結し、
      // ローカルに .tmpl を置いた場合のみ(前のテスト)ファイル展開が走る。
      final templates = await templateRepo.getFeatureTemplates('clean_architecture');
      expect(templates, isEmpty);
    });
  });

  group('Phase 1: arch subcommands UseCases', () {
    late Directory tempDir;
    late Directory originalDir;
    late FilesystemDataSource fs;
    late YamlDataSource yaml;
    late ArchitectureRepositoryImpl archRepo;

    setUp(() {
      originalDir = Directory.current;
      tempDir = Directory.systemTemp.createTempSync('utakata_arch_test_');
      Directory.current = tempDir;

      fs = const FilesystemDataSource();
      yaml = const YamlDataSource();
      archRepo = ArchitectureRepositoryImpl(fs, yaml);
    });

    tearDown(() {
      Directory.current = originalDir;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('getRawDefinition loads local raw yaml if matches, else falls back to package', () async {
      // package default definition
      final defaultRaw = await archRepo.getRawDefinition('clean_architecture');
      expect(defaultRaw, contains('id: clean_architecture'));
      expect(defaultRaw, contains('displayName: "Clean Architecture (4-layer)"'));

      // Create a local custom arch definition
      final localArchDir = Directory(p.join(tempDir.path, 'AI', 'architecture'));
      localArchDir.createSync(recursive: true);

      final localYamlFile = File(p.join(localArchDir.path, 'arch_definition.yaml'));
      const localContent = '''
id: clean_architecture
displayName: "My Custom Local Raw Clean Architecture"
layers: []
naming_rules: []
''';
      localYamlFile.writeAsStringSync(localContent);

      // Verify getRawDefinition loads local content now
      final localRaw = await archRepo.getRawDefinition('clean_architecture');
      expect(localRaw, equals(localContent));
    });

    test('ListArchitecturesUsecase gets all architectures', () async {
      final usecase = ListArchitecturesUsecase(archRepo: archRepo);
      final result = await usecase.execute();
      expect(result.isNotEmpty, isTrue);
      expect(result.any((a) => a.id == 'clean_architecture'), isTrue);
    });

    test('ShowArchitectureUsecase gets specific architecture by id', () async {
      final usecase = ShowArchitectureUsecase(archRepo: archRepo);
      final result = await usecase.execute('clean_architecture');
      expect(result.id, equals('clean_architecture'));
      expect(result.displayName, equals('Clean Architecture (4-layer)'));
    });

    test('ExportArchitectureUsecase exports raw yaml to target path', () async {
      final usecase = ExportArchitectureUsecase(
        archRepo: archRepo,
        writeFile: fs.writeFile,
        ensureDir: fs.ensureDir,
      );

      final exportPath = p.join(tempDir.path, 'exported_arch.yaml');
      await usecase.execute('clean_architecture', exportPath);

      final file = File(exportPath);
      expect(file.existsSync(), isTrue);
      
      final content = file.readAsStringSync();
      expect(content, contains('id: clean_architecture'));
    });

    test('CreateArchitectureUsecase creates boilerplate arch_definition.yaml', () async {
      final usecase = CreateArchitectureUsecase(
        writeFile: fs.writeFile,
        ensureDir: fs.ensureDir,
        fileExists: fs.fileExists,
        msg: const JaMessages(), // テストでは JaMessages を使用
      );

      await usecase.execute('my_mvvm', tempDir.path);

      final targetFile = File(p.join(tempDir.path, 'AI', 'architecture', 'arch_definition.yaml'));
      expect(targetFile.existsSync(), isTrue);

      final content = targetFile.readAsStringSync();
      expect(content, contains('id: my_mvvm'));
      expect(content, contains('displayName: "MyMvvm"'));

      // If we run it again, it should fail since it already exists
      expect(
        () => usecase.execute('my_mvvm', tempDir.path),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Phase 2: YAML-driven Guides & Renderer', () {
    test('ArchitectureRepository loads guides from yaml', () async {
      final fs = const FilesystemDataSource();
      final yaml = const YamlDataSource();
      final archRepo = ArchitectureRepositoryImpl(fs, yaml);

      final definition = await archRepo.getById('clean_architecture');
      expect(definition.guides.isNotEmpty, isTrue);

      // エンティティ層のガイドが正しくパースされているか検証
      // (v2 スリム書式: apply_to / detail_content_path / naming_pattern は
      //  規約から導出される)
      final entityGuide = definition.guides.firstWhere((g) => g.layerPath == '1_domain/1_entities');
      expect(entityGuide.title, contains('Entity Layer'));
      expect(entityGuide.doList, contains(contains('ビジネスオブジェクトの定義')));
      expect(entityGuide.applyTo,
          'lib/features/**/1_domain/1_entities/**');
      expect(entityGuide.detailContentPath,
          'architectures/clean_architecture/layers/features/1_domain/1_entities/GUIDE.md');
      expect(entityGuide.namingPattern, '{name}_entity.dart');
    });

    test('GuideEntity.render renders GUIDE.md correctly', () {
      const guide = GuideEntity(
        title: 'Test Entity Layer',
        layerPath: '1_domain/1_entities',
        applyTo: 'lib/features/**/1_domain/1_entities/**',
        doList: ['Do A', 'Do B'],
        dontList: ['Dont C'],
        allowedImports: ["import 'dart:core';"],
        forbiddenImports: ["import 'package:flutter/material.dart';"],
        namingPattern: '{name}_entity.dart',
        detailContentPath: 'some/path/GUIDE.md',
      );

      final rendered = guide.render('# Detailed Content Examples');

      expect(rendered, contains('# Test Entity Layer'));
      expect(rendered, contains('### ✅ すべきこと'));
      expect(rendered, contains('- Do A'));
      expect(rendered, contains('### ❌ してはいけないこと'));
      expect(rendered, contains('- Dont C'));
      expect(rendered, contains("import 'package:flutter/material.dart';"));
      expect(rendered, contains('# Detailed Content Examples'));
    });

  });

  group('Phase 3: Automatically Insert Dependencies', () {
    test('ArchitectureRepository loads the dependency stack from dependencies/*.yaml',
        () async {
      final fs = const FilesystemDataSource();
      final yaml = const YamlDataSource();
      final archRepo = ArchitectureRepositoryImpl(fs, yaml);

      final stack = await archRepo.getDependencyStack('clean_architecture');
      expect(stack.dependencies.containsKey('freezed_annotation'), isTrue);
      expect(stack.dependencies['freezed_annotation'], equals('^3.0.0'));
      expect(stack.dependencies['flutter'], equals({'sdk': 'flutter'}));
      expect(stack.devDependencies.containsKey('build_runner'), isTrue);
      // 配置宣言: drift はローカルデータソース層のみ
      final drift =
          stack.placements.firstWhere((pl) => pl.package == 'drift');
      expect(drift.layers, ['2_infrastructure/2_data_sources/1_local']);
      // recommended.yaml の配置宣言も読まれる
      expect(stack.placements.any((pl) => pl.package == 'dio'), isTrue);
    });

    test('CreateProjectUsecase merges dependencies into pubspec.yaml', () async {
      String? writtenPubspecContent;

      final usecase = CreateProjectUsecase(
        archRepo: DummyArchitectureRepository(),
        templateRepo: DummyTemplateRepository(),
        msg: const JaMessages(),
        runFlutterCreate: ({
          required appName,
          required projectName,
          required org,
          required platforms,
          required description,
        }) async => true,
        runBuildRunner: ({required appName}) async => true,
        readFile: (path) async {
          if (path.endsWith('pubspec.yaml')) {
            return '''
name: test_project
description: Test
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
''';
          }
          return null;
        },
        writeFile: (path, content) async {
          if (path.endsWith('pubspec.yaml')) {
            writtenPubspecContent = content;
          }
        },
        ensureDir: (path) async {},
      );

      const spec = ProjectSpecEntity(
        appName: 'test_project',
        projectName: 'test_project',
        org: 'com.example',
        platforms: 'android,ios',
        description: 'Test',
        architectureId: 'clean_architecture',
      );

      await usecase.execute(spec);

      expect(writtenPubspecContent, isNotNull);
      expect(writtenPubspecContent, contains('freezed_annotation: ^2.4.4'));
      expect(writtenPubspecContent, contains('build_runner: ^2.4.9'));
      // 重複しない、既存の flutter 依存関係が残っていることの確認
      expect(writtenPubspecContent, contains('cupertino_icons: ^1.0.2'));
      // 範囲指定はクォートされ、出力全体が有効な YAML であること(1.5.1)
      expect(writtenPubspecContent, contains('drift_dev: ">=2.25.0 <2.28.2"'));
      final parsed = const YamlDataSource()
          .parse(writtenPubspecContent!, source: 'pubspec.yaml');
      expect(parsed['dev_dependencies']['drift_dev'], '>=2.25.0 <2.28.2');
    });
  });

  group('Phase 3.5: Generifying project_status and update_status', () {
    test('ArchitectureRepository loads core_modules from yaml', () async {
      final fs = const FilesystemDataSource();
      final yaml = const YamlDataSource();
      final archRepo = ArchitectureRepositoryImpl(fs, yaml);

      final definition = await archRepo.getById('clean_architecture');
      expect(definition.coreModules.isNotEmpty, isTrue);

      final routingModule = definition.coreModules.firstWhere((m) => m.id == 'routing');
      expect(routingModule.path, equals('lib/core/routing'));
      expect(routingModule.displayName, equals('routing/'));
    });

    test('CreateProjectUsecase dynamic replacement for core_modules in .tmpl files', () async {
      String? writtenTemplateContent;
      String? writtenPath;

      final usecase = CreateProjectUsecase(
        archRepo: DummyArchitectureRepositoryWithCoreModules(),
        templateRepo: DummyTemplateRepositoryWithCoreModules(),
        msg: const JaMessages(),
        runFlutterCreate: ({
          required appName,
          required projectName,
          required org,
          required platforms,
          required description,
        }) async => true,
        runBuildRunner: ({required appName}) async => true,
        readFile: (path) async {
          if (path.endsWith('pubspec.yaml')) {
            return 'dependencies:\n';
          }
          return null;
        },
        writeFile: (path, content) async {
          if (path.endsWith('project_status.yaml') || path.endsWith('update_status.sh')) {
            writtenPath = path;
            writtenTemplateContent = content;
          }
        },
        ensureDir: (path) async {},
      );

      const spec = ProjectSpecEntity(
        appName: 'test_project',
        projectName: 'test_project',
        org: 'com.example',
        platforms: 'android,ios',
        description: 'Test',
        architectureId: 'clean_architecture',
      );

      await usecase.execute(spec);

      expect(writtenPath, isNotNull);
      expect(writtenPath, endsWith('project_status.yaml')); // .tmpl が除去されていること
      expect(writtenTemplateContent, isNotNull);
      expect(writtenTemplateContent, contains('routing: false')); // 置換されていること
    });
  });
}

class DummyArchitectureRepository implements ArchitectureRepository {
  @override
  Future<DependencyStack> getDependencyStack(String architectureId) async {
    // 実装のフォールバックと同じ: 定義内の dependencies を使う
    final arch = await getById(architectureId);
    return DependencyStack(
      dependencies: arch.dependencies,
      devDependencies: arch.devDependencies,
    );
  }

  @override
  Future<ArchitectureDefinitionEntity> getById(String id) async {
    return const ArchitectureDefinitionEntity(
      id: 'clean_architecture',
      displayName: 'Clean',
      layers: [],
      dependencies: {
        'freezed_annotation': '^2.4.4',
      },
      devDependencies: {
        'build_runner': '^2.4.9',
        // 範囲指定はクォート必須('>' はブロックスカラー指示子。1.5.1 の回帰テスト)
        'drift_dev': '>=2.25.0 <2.28.2',
      },
    );
  }

  @override
  Future<List<ArchitectureDefinitionEntity>> getAll() async => [];

  @override
  Future<String> getRawDefinition(String architectureId) async => '';
}

class DummyTemplateRepository implements TemplateRepository {
  @override
  Future<List<TemplateFileEntity>> getProjectTemplates(String architectureId) async => [];
  @override
  Future<List<TemplateFileEntity>> getFeatureTemplates(String architectureId) async => [];
}

class DummyArchitectureRepositoryWithCoreModules implements ArchitectureRepository {
  @override
  Future<DependencyStack> getDependencyStack(String architectureId) async =>
      DependencyStack.empty;

  @override
  Future<ArchitectureDefinitionEntity> getById(String id) async {
    return const ArchitectureDefinitionEntity(
      id: 'clean_architecture',
      displayName: 'Clean',
      layers: [],
      coreModules: [
        CoreModuleEntity(
          id: 'routing',
          path: 'lib/core/routing',
          displayName: 'routing/',
        ),
      ],
    );
  }

  @override
  Future<List<ArchitectureDefinitionEntity>> getAll() async => [];

  @override
  Future<String> getRawDefinition(String architectureId) async => '';
}

class DummyTemplateRepositoryWithCoreModules implements TemplateRepository {
  @override
  Future<List<TemplateFileEntity>> getProjectTemplates(String architectureId) async {
    return const [
      TemplateFileEntity(
        relativePath: 'AI/snapshots/project_status.yaml.tmpl',
        content: 'core:\n{{core_modules_yaml_initial}}',
      ),
    ];
  }

  @override
  Future<List<TemplateFileEntity>> getFeatureTemplates(String architectureId) async => [];
}

