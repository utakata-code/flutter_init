#!/bin/bash
# コードレビュー用Flutter静的解析スクリプト

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

echo "📝 コードレビュー - Flutter静的解析を実行中..."
echo "================================================"

cd "$PROJECT_ROOT" || exit 1

# flutter analyze を実行
flutter analyze

# 結果に応じたメッセージ
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 静的解析クリア！追加のレビュー観点を確認してください。"
else
    echo ""
    echo "⚠️ 静的解析で問題が見つかりました。まずこれらを解消してください。"
    exit 1
fi
