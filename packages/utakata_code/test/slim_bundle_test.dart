import 'dart:io';

import 'package:test/test.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/2_remote/git_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/knowledge_repository_impl.dart';

/// Issue #15(slim 同梱): 同梱テンプレートは実行時必須の
/// arch_definition.yaml + skills/ のみで、読み物は同梱しない。
void main() {
  const fs = FilesystemDataSource();

  test('同梱は arch_definition.yaml と skills/ のみ(読み物は含まない)', () async {
    for (final archId in ['clean_architecture', 'mvvm']) {
      final root = await fs.resolvePackageTemplatePath('architectures/$archId');
      final topLevel = Directory(root)
          .listSync()
          .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
          .toSet();
      expect(topLevel, {'arch_definition.yaml', 'skills'},
          reason: '$archId の同梱が slim になっていない(Issue #15)');
    }
  });

  test('構造コマンドに必要な定義は同梱されている(オフライン保証)', () async {
    for (final archId in ['clean_architecture', 'mvvm']) {
      final path = await fs
          .resolvePackageTemplatePath('architectures/$archId/arch_definition.yaml');
      expect(File(path).existsSync(), isTrue);
      // 定義がパース可能で、層と命名規則を持つこと
      final doc = const YamlDataSource()
          .parse(File(path).readAsStringSync(), source: path);
      expect((doc['layers'] as List), isNotEmpty);
      expect((doc['naming_rules'] as List), isNotEmpty);
    }
  });

  test('ensureDefaultAvailable(autoFetch: false) はキャッシュ無しなら null(ネット非依存)',
      () async {
    final tempHome = Directory.systemTemp.createTempSync('utakata_slim_home_');
    addTearDown(() => tempHome.deleteSync(recursive: true));
    final repo = KnowledgeRepositoryImpl(
        const GitDataSource(), const YamlDataSource(), tempHome.path);
    expect(await repo.ensureDefaultAvailable(autoFetch: false), isNull);
  });
}
