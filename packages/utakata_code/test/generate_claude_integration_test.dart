import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:utakata/src/1_domain/3_usecases/generate_claude_integration_usecase.dart';

void main() {
  test('writes .mcp.json, .claude/settings.json, skills, and an agent', () async {
    final dir = Directory.systemTemp.createTempSync('claude_integration_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    final usecase = GenerateClaudeIntegrationUsecase(
      writeFile: (path, content) async {
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      },
      ensureDir: (path) async => Directory(path).create(recursive: true),
    );

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
}
