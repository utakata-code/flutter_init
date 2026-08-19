import 'dart:io';

import 'package:test/test.dart';
import 'package:utakata/src/1_domain/1_entities/config/utakata_config_entity.dart';
import 'package:utakata/src/1_domain/3_usecases/init_doc_usecase.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_edit_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/config_repository_impl.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/plan_repository_impl.dart';

void main() {
  group('UtakataConfig.fromMap', () {
    test('parses a fully-specified config', () {
      final config = UtakataConfig.fromMap({
        'schema': 1,
        'project': {
          'architecture': 'mvvm',
          'knowledge_repo': {
            'url': 'https://example.com/arch_lib.git',
            'ref': 'v1.0.0',
          },
        },
        'skills': ['utakata-structure', 'clean-arch-auditor'],
        'team': {
          'client': '山田さん',
          'developer': '私',
          'ai_agents': [
            {'id': 'feature-builder', 'role': '実装担当'},
          ],
        },
        'enforcement': {'impl_plan': 'off'},
        'records': {'git': 'ignore'},
        'lang': 'en',
      });

      expect(config.schema, 1);
      expect(config.architecture, 'mvvm');
      expect(config.knowledgeRepo?.url, 'https://example.com/arch_lib.git');
      expect(config.knowledgeRepo?.ref, 'v1.0.0');
      expect(config.skills, ['utakata-structure', 'clean-arch-auditor']);
      expect(config.team.client, '山田さん');
      expect(config.team.aiAgents.single.id, 'feature-builder');
      expect(config.implPlanEnforcement, 'off');
      expect(config.recordsGit, 'ignore');
      expect(config.lang, 'en');
    });

    test('all fields optional — empty map yields defaults', () {
      final config = UtakataConfig.fromMap({});
      expect(config.schema, UtakataConfig.currentSchema);
      expect(config.architecture, isNull);
      expect(config.knowledgeRepo, isNull);
      expect(config.skills, isEmpty);
      expect(config.team.isEmpty, isTrue);
      // v1.7.0: ゲートが実際に効くようになったため既定は off
      // (CLI を上げただけで既存プロジェクトの apply が止まらないように)
      expect(config.implPlanEnforcement, 'off');
      expect(config.recordsGit, 'commit');
    });
  });

  group('ConfigRepositoryImpl', () {
    late Directory tempDir;
    const repo = ConfigRepositoryImpl(FilesystemDataSource(), YamlDataSource());

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('utakata_config_test_');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('read returns null when utakata.yaml is missing', () async {
      expect(await repo.read(tempDir.path), isNull);
    });

    test('validate flags unknown top-level keys and future schema', () async {
      File('${tempDir.path}/utakata.yaml').writeAsStringSync('''
schema: 99
project:
  architecture: clean_architecture
teem:
  client: typo
''');
      final issues = await repo.validate(tempDir.path);
      expect(issues, hasLength(2));
      expect(issues.first, contains('schema: 99'));
      expect(issues.last, contains('"teem"'));
    });

    test('validate returns empty for a valid file and a missing file', () async {
      expect(await repo.validate(tempDir.path), isEmpty);
      File('${tempDir.path}/utakata.yaml')
          .writeAsStringSync('schema: 1\nproject:\n  architecture: mvvm\n');
      expect(await repo.validate(tempDir.path), isEmpty);
    });
  });

  group('PlanRepositoryImpl architecture resolution (D6)', () {
    late Directory tempDir;
    const configRepo = ConfigRepositoryImpl(FilesystemDataSource(), YamlDataSource());
    final planRepo = PlanRepositoryImpl(
      const FilesystemDataSource(),
      const YamlDataSource(),
      const YamlEditDataSource(),
      configRepo: configRepo,
    );

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('utakata_plan_config_test_');
      Directory('${tempDir.path}/doc/specs').createSync(recursive: true);
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    void writePlan(String content) =>
        File('${tempDir.path}/doc/specs/plan.yaml').writeAsStringSync(content);

    void writeConfig(String content) =>
        File('${tempDir.path}/utakata.yaml').writeAsStringSync(content);

    test('utakata.yaml wins over an explicit plan.yaml architecture', () async {
      writeConfig('project:\n  architecture: mvvm\n');
      writePlan('schema: 1\nproject:\n  architecture: clean_architecture\nfeatures: []\n');
      final plan = await planRepo.read(tempDir.path);
      expect(plan!.defaultArchitectureId, 'mvvm');
    });

    test('utakata.yaml fills in when plan.yaml omits architecture', () async {
      writeConfig('project:\n  architecture: mvvm\n');
      writePlan('schema: 1\nfeatures: []\n');
      final plan = await planRepo.read(tempDir.path);
      expect(plan!.defaultArchitectureId, 'mvvm');
    });

    test('plan.yaml value is used when utakata.yaml is absent', () async {
      writePlan('schema: 1\nproject:\n  architecture: clean_architecture\nfeatures: []\n');
      final plan = await planRepo.read(tempDir.path);
      expect(plan!.defaultArchitectureId, 'clean_architecture');
    });
  });

  group('InitDocUsecase template', () {
    test('default utakata.yaml declares schema 1 with commented team/skills', () async {
      final tempDir = Directory.systemTemp.createTempSync('utakata_doc_init_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final usecase = InitDocUsecase(
        ensureDir: (path) async => Directory(path).create(recursive: true),
        writeFile: (path, content) async {
          final file = File(path);
          await file.parent.create(recursive: true);
          await file.writeAsString(content);
        },
        fileExists: (path) => File(path).existsSync(),
      );

      expect(await usecase.execute(tempDir.path), isTrue);
      final content = File('${tempDir.path}/utakata.yaml').readAsStringSync();
      expect(content, contains('schema: 1'));
      expect(content, contains('# team:'));
      expect(content, contains('# skills:'));
      expect(content, contains('# knowledge_repo:'));

      // 生成されたテンプレートは validate をエラーなく通ること
      const repo = ConfigRepositoryImpl(FilesystemDataSource(), YamlDataSource());
      expect(await repo.validate(tempDir.path), isEmpty);
    });
  });
}
