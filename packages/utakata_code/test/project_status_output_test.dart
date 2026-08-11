import 'dart:io';

import 'package:test/test.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/project_repository_impl.dart';

/// v1.6.0: status の導出結果は doc/preview/ に書く(旧 AI/snapshots/)。
void main() {
  late Directory tempDir;
  late ProjectRepositoryImpl repo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('utakata_status_out_');
    repo = const ProjectRepositoryImpl(
        FilesystemDataSource(), YamlDataSource());
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('project_status.yaml は doc/preview/ に書かれる', () async {
    await repo.writeProjectStatus(tempDir.path, {'features': 3});

    final target = File('${tempDir.path}/doc/preview/project_status.yaml');
    expect(target.existsSync(), isTrue);
    expect(target.readAsStringSync(), contains('features'));
    expect(Directory('${tempDir.path}/AI').existsSync(), isFalse,
        reason: 'AI/ を作ってはいけない(doc/ に統一)');
  });

  test('project_status.md は doc/preview/ に書かれる', () async {
    await repo.writeProjectStatusMarkdown(tempDir.path, '# 状態\n');

    final target = File('${tempDir.path}/doc/preview/project_status.md');
    expect(target.existsSync(), isTrue);
    expect(target.readAsStringSync(), contains('# 状態'));
    expect(Directory('${tempDir.path}/AI').existsSync(), isFalse);
  });
}
