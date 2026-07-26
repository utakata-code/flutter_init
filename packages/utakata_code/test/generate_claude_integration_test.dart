import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:utakata/src/1_domain/3_usecases/generate_claude_integration_usecase.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/config_repository_impl.dart';

GenerateClaudeIntegrationUsecase _buildUsecase() => GenerateClaudeIntegrationUsecase(
      writeFile: (path, content) async {
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      },
      ensureDir: (path) async => Directory(path).create(recursive: true),
      fileExists: (path) => File(path).existsSync(),
      configRepo: const ConfigRepositoryImpl(FilesystemDataSource(), YamlDataSource()),
    );

void main() {
  test('writes .mcp.json, .claude/settings.json, skills, and an agent', () async {
    final dir = Directory.systemTemp.createTempSync('claude_integration_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    final usecase = _buildUsecase();

    await usecase.execute(dir.path);

    expect(File('${dir.path}/.mcp.json').existsSync(), isTrue);
    expect(File('${dir.path}/.claude/settings.json').existsSync(), isTrue);
    expect(
      File('${dir.path}/.claude/skills/utakata-structure/SKILL.md').existsSync(),
      isTrue,
    );
    expect(
      File('${dir.path}/.claude/skills/utakata-client-context/SKILL.md').existsSync(),
      isTrue,
    );
    expect(
      File('${dir.path}/.claude/skills/utakata-impl-flow/SKILL.md').existsSync(),
      isTrue,
    );
    expect(File('${dir.path}/.claude/agents/structure-auditor.md').existsSync(), isTrue);

    final settings = jsonDecode(await File('${dir.path}/.claude/settings.json').readAsString())
        as Map<String, dynamic>;
    expect(settings['permissions']['deny'], contains('Edit(doc/records/**)'));
    expect(settings['hooks'], contains('SessionStart'));
    expect(settings['hooks'], contains('PostToolUse'));
    expect(settings['hooks'], contains('Stop'));

    final mcp = jsonDecode(await File('${dir.path}/.mcp.json').readAsString())
        as Map<String, dynamic>;
    expect(mcp['mcpServers']['utakata']['command'], 'utakata');
  });

  test('writes CLAUDE.md with a team section when utakata.yaml defines team', () async {
    final dir = Directory.systemTemp.createTempSync('claude_integration_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    File('${dir.path}/utakata.yaml').writeAsStringSync('''
schema: 1
team:
  client: "山田さん(要件の決定権者)"
  developer: "私(最終レビュー)"
  ai_agents:
    - id: feature-builder
      role: "実装担当"
''');

    await _buildUsecase().execute(dir.path);

    final claudeMd = File('${dir.path}/CLAUDE.md').readAsStringSync();
    expect(claudeMd, contains('登場人物と役割'));
    expect(claudeMd, contains('山田さん'));
    expect(claudeMd, contains('feature-builder'));
    expect(claudeMd, contains('doc/records/'));
  });

  test('writes a generic CLAUDE.md without utakata.yaml, and never overwrites', () async {
    final dir = Directory.systemTemp.createTempSync('claude_integration_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    await _buildUsecase().execute(dir.path);
    final claudeMd = File('${dir.path}/CLAUDE.md').readAsStringSync();
    expect(claudeMd, contains('utakata CLI'));
    expect(claudeMd, isNot(contains('登場人物と役割')));

    // 既存 CLAUDE.md は上書きしない
    File('${dir.path}/CLAUDE.md').writeAsStringSync('user content');
    await _buildUsecase().execute(dir.path);
    expect(File('${dir.path}/CLAUDE.md').readAsStringSync(), 'user content');
  });
}
