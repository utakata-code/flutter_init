/// Vault 内の1エントリ(1つの .md ファイル)。
final class VaultEntry {
  /// Vault ルートからの相対パス(拡張子なし。例: `Google/GCP/Firebase`)
  final String id;

  /// 見出し(ファイル先頭の `# `)。取れなければ id と同じ。
  final String title;

  const VaultEntry({required this.id, required this.title});
}

/// 実務ナレッジ Vault(外部サービスのアカウント取得手順・料金・審査要否など、
/// クライアントへの説明に使う知識)への読み取りアクセス。
///
/// AI がこれを読んでクライアント向けの説明文を生成し、人間が確認して送信、
/// 送った内容は `utakata log add` で記録する、という流れを想定する。
/// **AI は Vault に書き込まない**(知識の追記は人間が Vault リポジトリ側で行う)。
abstract interface class VaultRepository {
  /// Vault のルートディレクトリを解決する。未設定・未取得なら null。
  Future<String?> resolveRoot(String projectDir);

  /// エントリ一覧(テンプレート `_template.md` と索引 `README.md` は除く)。
  Future<List<VaultEntry>> list(String projectDir);

  /// [entryId](`Google/GCP/Firebase` 形式。`.md` 付きでも可)の本文を返す。
  Future<String?> read(String projectDir, String entryId);
}
