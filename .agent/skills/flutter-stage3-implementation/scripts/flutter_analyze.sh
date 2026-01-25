#!/bin/bash
# Flutter静的解析スクリプト
# flutter analyze を実行して結果を表示します

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

echo "🔍 Flutter 静的解析を実行中..."
echo "================================================"

cd "$PROJECT_ROOT" || exit 1

# flutter analyze を実行
flutter analyze

# 終了コードをチェック
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 静的解析が正常に完了しました。問題は見つかりませんでした。"
else
    echo ""
    echo "⚠️ 静的解析で問題が見つかりました。上記の内容を確認してください。"
    exit 1
fi
