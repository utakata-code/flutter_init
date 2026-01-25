#!/bin/bash
# Stage2 構造計画フェーズのステータス確認スクリプト
# このスクリプトはstatus.shのラッパーとして機能します

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

echo "🏗️ Stage2 構造計画フェーズ - ステータス確認"
echo "================================================"

# status.sh を実行
if [ -f "$PROJECT_ROOT/AI/scripts/bash/status.sh" ]; then
    "$PROJECT_ROOT/AI/scripts/bash/status.sh" check
else
    echo "⚠️ status.sh が見つかりません: $PROJECT_ROOT/AI/scripts/bash/status.sh"
    exit 1
fi
