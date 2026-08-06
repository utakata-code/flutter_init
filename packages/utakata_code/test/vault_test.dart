import 'dart:io';

import 'package:test/test.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/2_remote/git_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/config_repository_impl.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/vault_repository_impl.dart';

void main() {
  late Directory tempDir;
  late String homeDir;
  late String projectDir;
  late String vaultDir;
  late VaultRepositoryImpl repo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('utakata_vault_test_');
    homeDir = '${tempDir.path}/home';
    projectDir = '${tempDir.path}/proj';
    vaultDir = '${tempDir.path}/vault';

    Directory('$homeDir/.utakata').createSync(recursive: true);
    Directory(projectDir).createSync(recursive: true);
    Directory('$vaultDir/Google/GCP').createSync(recursive: true);

    // ルート直下の説明ファイル(一覧に出ない)
    File('$vaultDir/README.md').writeAsStringSync('# vault index\n');
    File('$vaultDir/CLAUDE.md').writeAsStringSync('# agent rules\n');
    File('$vaultDir/_template.md').writeAsStringSync('# <サービス名>\n');
    // 実エントリ
    File('$vaultDir/Google/GCP/Firebase.md').writeAsStringSync('# Firebase\n\n## 概要\n');
    // ネストした README は共通前提の実体なので一覧に出る
    File('$vaultDir/Google/GCP/README.md')
        .writeAsStringSync('# Google Cloud Platform (GCP)\n');

    final configRepo =
        ConfigRepositoryImpl(const FilesystemDataSource(), const YamlDataSource(),
            homeDir: homeDir);
    repo = VaultRepositoryImpl(configRepo, const GitDataSource(), homeDir);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  void writeGlobalConfig(String body) =>
      File('$homeDir/.utakata/config.yaml').writeAsStringSync(body);
  void writeProjectConfig(String body) =>
      File('$projectDir/utakata.yaml').writeAsStringSync(body);

  test('未設定なら root は null・一覧は空', () async {
    expect(await repo.resolveRoot(projectDir), isNull);
    expect(await repo.list(projectDir), isEmpty);
  });

  test('~/.utakata/config.yaml の vault.path から解決する', () async {
    writeGlobalConfig('vault:\n  path: "$vaultDir"\n');
    expect(await repo.resolveRoot(projectDir), vaultDir);
  });

  test('プロジェクトの utakata.yaml がグローバル設定より優先される', () async {
    final other = '${tempDir.path}/other_vault';
    Directory(other).createSync();
    writeGlobalConfig('vault:\n  path: "$vaultDir"\n');
    writeProjectConfig('schema: 1\nvault:\n  path: "$other"\n');
    expect(await repo.resolveRoot(projectDir), other);
  });

  test('一覧: ルート直下の README/CLAUDE/_template は除外、ネスト README は含む', () async {
    writeGlobalConfig('vault:\n  path: "$vaultDir"\n');
    final ids = (await repo.list(projectDir)).map((e) => e.id).toList();
    expect(ids, ['Google/GCP/Firebase', 'Google/GCP/README']);
  });

  test('一覧は見出し(# )をタイトルとして拾う', () async {
    writeGlobalConfig('vault:\n  path: "$vaultDir"\n');
    final entries = await repo.list(projectDir);
    expect(entries.first.title, 'Firebase');
    expect(entries.last.title, 'Google Cloud Platform (GCP)');
  });

  test('read: 拡張子ありなしどちらでも読める', () async {
    writeGlobalConfig('vault:\n  path: "$vaultDir"\n');
    expect(await repo.read(projectDir, 'Google/GCP/Firebase'), contains('# Firebase'));
    expect(await repo.read(projectDir, 'Google/GCP/Firebase.md'), contains('# Firebase'));
  });

  test('read: Vault の外へのパス脱出を拒否する', () async {
    File('${tempDir.path}/secret.md').writeAsStringSync('secret');
    writeGlobalConfig('vault:\n  path: "$vaultDir"\n');
    expect(await repo.read(projectDir, '../secret'), isNull);
  });

  test('path が存在しなければ解決しない(url 未設定時)', () async {
    writeGlobalConfig('vault:\n  path: "${tempDir.path}/does_not_exist"\n');
    expect(await repo.resolveRoot(projectDir), isNull);
  });
}
