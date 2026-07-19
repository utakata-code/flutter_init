import 'dart:io';

/// git コマンドの薄いラッパ(knowledge_repo フェッチ専用)。
///
/// git はオプトイン機能(`arch get`)を使う場合のみ必要。不在時は
/// [GitNotFoundException 相当のメッセージ付き例外] を投げる。
class GitDataSource {
  const GitDataSource();

  Future<void> cloneDepth1(String url, String? ref, String targetDir) async {
    final result = await Process.run(
      'git',
      [
        'clone',
        '--depth',
        '1',
        if (ref != null && ref.isNotEmpty) ...['--branch', ref],
        url,
        targetDir,
      ],
      runInShell: true,
    ).catchError((Object e) {
      throw Exception('git が見つかりません。knowledge_repo の取得には git が必要です: $e');
    });
    if (result.exitCode != 0) {
      throw Exception('git clone failed (${result.exitCode}): ${result.stderr}');
    }
  }

  Future<String> revParseHead(String repoDir) async {
    final result = await Process.run(
      'git',
      ['-C', repoDir, 'rev-parse', 'HEAD'],
      runInShell: true,
    );
    if (result.exitCode != 0) {
      throw Exception('git rev-parse failed: ${result.stderr}');
    }
    return (result.stdout as String).trim();
  }
}
