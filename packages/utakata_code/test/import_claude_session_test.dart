import 'dart:convert';

import 'package:test/test.dart';
import 'package:utakata/src/1_domain/3_usecases/import_claude_session_usecase.dart';

String _user(String text, {bool sidechain = false}) => jsonEncode({
      'type': 'user',
      'isSidechain': sidechain,
      'timestamp': '2026-07-19T10:00:00Z',
      'message': {'role': 'user', 'content': text},
    });

String _assistant(List<Map<String, dynamic>> blocks) => jsonEncode({
      'type': 'assistant',
      'timestamp': '2026-07-19T10:00:05Z',
      'message': {'role': 'assistant', 'content': blocks},
    });

void main() {
  test('keeps user/assistant text; drops thinking, tool blocks, meta, sidechains', () {
    final lines = [
      '{"type":"mode","mode":"normal"}',
      _user('仕様を確認したい'),
      _assistant([
        {'type': 'thinking', 'thinking': 'секрет思考'},
        {'type': 'text', 'text': '仕様はこちらです'},
        {'type': 'tool_use', 'name': 'Bash', 'input': {}},
      ]),
      _user('サブエージェント発言', sidechain: true),
      'broken json {{{',
    ];

    final result = ImportClaudeSessionUsecase.parse(lines, sessionId: 'abc');
    expect(result.entries.map((e) => e.role), ['user', 'assistant']);
    expect(result.entries[1].text, '仕様はこちらです');
    expect(result.entries[1].text, isNot(contains('思考')));
    expect(result.skippedLines, 1);
    expect(result.entries.first.seq, 0);
  });

  test('--full includes thinking and tool_use names, never tool_result', () {
    final result = ImportClaudeSessionUsecase.parse(
      [
        _assistant([
          {'type': 'thinking', 'thinking': '検討中'},
          {'type': 'text', 'text': '結論'},
          {'type': 'tool_use', 'name': 'Bash', 'input': {}},
          {'type': 'tool_result', 'content': '巨大な出力'},
        ]),
      ],
      sessionId: 'abc',
      includeAll: true,
    );
    final text = result.entries.single.text;
    expect(text, contains('[thinking] 検討中'));
    expect(text, contains('[tool_use] Bash'));
    expect(text, isNot(contains('巨大な出力')));
  });

  test('redacts secret-looking content and counts it', () {
    final result = ImportClaudeSessionUsecase.parse(
      [
        _user('API_KEY=abc123secret と Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6 を貼った'),
        _user('AWS: AKIAIOSFODNN7EXAMPLE'),
      ],
      sessionId: 'abc',
    );
    expect(result.redactedCount, greaterThanOrEqualTo(3));
    expect(result.entries[0].text, isNot(contains('abc123secret')));
    expect(result.entries[1].text, isNot(contains('AKIAIOSFODNN7EXAMPLE')));
    expect(result.entries[0].text, contains('[REDACTED]'));
  });

  test('projectKeyOf mirrors Claude Code project dir naming', () {
    expect(
      ImportClaudeSessionUsecase.projectKeyOf(
          '/Users/haruma/development/git_tmp/utakata'),
      '-Users-haruma-development-git-tmp-utakata',
    );
  });
}
