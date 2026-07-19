import 'dart:io';

import 'package:test/test.dart';
import 'package:utakata/src/1_domain/3_usecases/sync_skills_usecase.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/config_repository_impl.dart';

void main() {
  late Directory tempDir;
  late String projectDir;
  late String skillsSourceDir;
  late SyncSkillsUsecase usecase;

  const fs = FilesystemDataSource();

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('utakata_skills_test_');
    projectDir = '${tempDir.path}/proj';
    skillsSourceDir =
        '${tempDir.path}/templates/architectures/clean_architecture/skills';
    Directory('$skillsSourceDir/my-auditor').createSync(recursive: true);
    File('$skillsSourceDir/my-auditor/SKILL.md').writeAsStringSync('# audit v1\n');
    Directory(projectDir).createSync(recursive: true);
    File('$projectDir/utakata.yaml').writeAsStringSync('''
schema: 1
project:
  architecture: clean_architecture
skills:
  - my-auditor
''');

    usecase = SyncSkillsUsecase(
      configRepo: const ConfigRepositoryImpl(fs, YamlDataSource()),
      resolveTemplatePath: (relative) async => '${tempDir.path}/templates/$relative',
      readFile: fs.readFile,
      writeFile: fs.writeFile,
      ensureDir: fs.ensureDir,
      dirExists: fs.dirExists,
      listEntries: fs.listEntries,
    );
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  String targetPath() => '$projectDir/.claude/skills/my-auditor/SKILL.md';

  test('initial sync writes marker + content; re-sync updates unmodified file', () async {
    final result = await usecase.execute(projectDir);
    expect(result.synced, ['my-auditor/SKILL.md']);
    final written = File(targetPath()).readAsStringSync();
    expect(written, startsWith('<!-- utakata:managed from=clean_architecture/my-auditor hash='));
    expect(written, contains('# audit v1'));

    // ソース更新 → 未編集 managed は更新される
    File('$skillsSourceDir/my-auditor/SKILL.md').writeAsStringSync('# audit v2\n');
    final second = await usecase.execute(projectDir);
    expect(second.synced, ['my-auditor/SKILL.md']);
    expect(File(targetPath()).readAsStringSync(), contains('# audit v2'));
  });

  test('unmanaged (human-created) file is never overwritten, even with --force', () async {
    Directory('$projectDir/.claude/skills/my-auditor').createSync(recursive: true);
    File(targetPath()).writeAsStringSync('human content');

    final result = await usecase.execute(projectDir, force: true);
    expect(result.skippedUnmanaged, ['my-auditor/SKILL.md']);
    expect(File(targetPath()).readAsStringSync(), 'human content');
  });

  test('human-edited managed file is skipped; --force overwrites', () async {
    await usecase.execute(projectDir);
    // 人間が managed ファイルを編集
    final edited = '${File(targetPath()).readAsStringSync()}\nhuman edit\n';
    File(targetPath()).writeAsStringSync(edited);

    final skipped = await usecase.execute(projectDir);
    expect(skipped.skippedModified, ['my-auditor/SKILL.md']);
    expect(File(targetPath()).readAsStringSync(), edited);

    final forced = await usecase.execute(projectDir, force: true);
    expect(forced.synced, ['my-auditor/SKILL.md']);
    expect(File(targetPath()).readAsStringSync(), isNot(contains('human edit')));
  });

  test('unknown skill id is reported; delisted managed skill becomes removal candidate', () async {
    await usecase.execute(projectDir);

    File('$projectDir/utakata.yaml').writeAsStringSync('''
schema: 1
project:
  architecture: clean_architecture
skills:
  - no-such-skill
''');
    final result = await usecase.execute(projectDir);
    expect(result.notFound, ['no-such-skill']);
    expect(result.removalCandidates, ['my-auditor']);
    // 削除候補は報告のみで、実体は残る
    expect(File(targetPath()).existsSync(), isTrue);
  });
}
