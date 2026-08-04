import 'dart:io';

import 'package:test/test.dart';
import 'package:utakata/src/1_domain/3_usecases/architecture_resolver.dart';
import 'package:utakata/src/1_domain/3_usecases/init_doc_usecase.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_edit_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/config_repository_impl.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/plan_repository_impl.dart';

void main() {
  const fs = FilesystemDataSource();
  const configRepo = ConfigRepositoryImpl(fs, YamlDataSource());
  final planRepo = PlanRepositoryImpl(
    fs,
    const YamlDataSource(),
    const YamlEditDataSource(),
    configRepo: configRepo,
  );
  final resolver = ArchitectureResolver(configRepo: configRepo, planRepo: planRepo);

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('utakata_arch_resolver_');
    Directory('${tempDir.path}/doc/specs').createSync(recursive: true);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  void writeConfig(String content) =>
      File('${tempDir.path}/utakata.yaml').writeAsStringSync(content);
  void writePlan(String content) =>
      File('${tempDir.path}/doc/specs/plan.yaml').writeAsStringSync(content);

  group('ArchitectureResolver (Issue #11)', () {
    test('falls back to clean_architecture when nothing is configured', () async {
      expect(await resolver.resolve(tempDir.path), 'clean_architecture');
    });

    test('resolves from utakata.yaml', () async {
      writeConfig('schema: 1\nproject:\n  architecture: mvvm\n');
      expect(await resolver.resolve(tempDir.path), 'mvvm');
    });

    test('resolves from plan.yaml when utakata.yaml is absent', () async {
      writePlan('schema: 1\nproject:\n  architecture: mvvm\nfeatures: []\n');
      expect(await resolver.resolve(tempDir.path), 'mvvm');
    });

    test('explicit --arch wins over utakata.yaml', () async {
      writeConfig('schema: 1\nproject:\n  architecture: mvvm\n');
      expect(
        await resolver.resolve(tempDir.path, explicit: 'clean_architecture'),
        'clean_architecture',
      );
    });

    test('empty explicit value is ignored (treated as unspecified)', () async {
      writeConfig('schema: 1\nproject:\n  architecture: mvvm\n');
      expect(await resolver.resolve(tempDir.path, explicit: ''), 'mvvm');
    });
  });

  group('InitDocUsecase (Issue #14)', () {
    late InitDocUsecase usecase;

    setUp(() {
      usecase = InitDocUsecase(
        ensureDir: fs.ensureDir,
        writeFile: fs.writeFile,
        fileExists: fs.fileExists,
      );
    });

    test('creates doc/specs/plan.yaml so check/apply work right after init', () async {
      final dir = Directory.systemTemp.createTempSync('utakata_doc_init_plan_');
      addTearDown(() => dir.deleteSync(recursive: true));

      expect(await usecase.execute(dir.path), isTrue);

      final plan = File('${dir.path}/doc/specs/plan.yaml');
      expect(plan.existsSync(), isTrue,
          reason: 'doc init must generate plan.yaml (Issue #14)');
      final content = plan.readAsStringSync();
      expect(content, contains('schema: 1'));
      expect(content, contains('features: []'));

      // 生成された plan.yaml がそのまま読めること(パースできる形であること)
      final parsed = await planRepo.read(dir.path);
      expect(parsed, isNotNull);
      expect(parsed!.features, isEmpty);
    });

    test('never overwrites an existing plan.yaml', () async {
      final dir = Directory.systemTemp.createTempSync('utakata_doc_init_plan_');
      addTearDown(() => dir.deleteSync(recursive: true));

      Directory('${dir.path}/doc/specs').createSync(recursive: true);
      File('${dir.path}/doc/specs/plan.yaml').writeAsStringSync('user content');

      await usecase.execute(dir.path);
      expect(File('${dir.path}/doc/specs/plan.yaml').readAsStringSync(),
          'user content');
    });

    test('repairs a missing plan.yaml when utakata.yaml already exists', () async {
      final dir = Directory.systemTemp.createTempSync('utakata_doc_init_plan_');
      addTearDown(() => dir.deleteSync(recursive: true));

      await usecase.execute(dir.path);
      File('${dir.path}/doc/specs/plan.yaml').deleteSync();

      // 2 回目は「初期化済み」なので false を返すが、欠けた plan.yaml は補われる
      expect(await usecase.execute(dir.path), isFalse);
      expect(File('${dir.path}/doc/specs/plan.yaml').existsSync(), isTrue);
    });
  });
}
