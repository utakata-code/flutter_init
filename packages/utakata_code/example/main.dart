// utakata は CLI ツールです。ライブラリとしてではなく、コマンドとして使います。
//
// インストール:
//   dart pub global activate utakata
//
// 基本フロー(計画 → 生成 → 検証):
//   utakata doc init                        # doc/ ワークスペース + utakata.yaml を作成
//   utakata create my_app --org com.example # Flutter プロジェクト新規作成(.claude/ 込み)
//   utakata apply --scope feature           # doc/specs/plan.yaml の宣言どおりに生成
//   utakata check                           # 不足・余分・命名違反を1回で検証
//
// お客様との記録(人間が書き、AI が読む):
//   utakata log add "初回ヒアリング" -s client
//   utakata agree add --title "見積合意" --kind client_agreement --amount 500000
//   utakata summary                         # doc/summary.md の合意台帳を再生成
//
// AI エージェント統合:
//   utakata mcp                             # 読み取り専用 MCP サーバー(stdio)
//   utakata skills sync                     # utakata.yaml の skills を .claude/skills/ へ
//   utakata guide for lib/features/user/todo/1_domain/1_entities/todo_entity.dart
//
// 詳細: https://pub.dev/packages/utakata
void main() {
  print('utakata is a CLI tool — install it with: dart pub global activate utakata');
  print('Then run: utakata --help');
}
