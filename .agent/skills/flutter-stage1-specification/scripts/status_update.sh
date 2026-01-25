#!/bin/bash
# Stage1 仕様策定フェーズのステータス更新スクリプト
# このスクリプトはstatus.shのラッパーとして機能します

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

echo "📝 Stage1 仕様策定フェーズ - ステータス更新"
echo "================================================"

# status.sh を実行
if [ -f "$PROJECT_ROOT/AI/scripts/bash/status.sh" ]; then
    "$PROJECT_ROOT/AI/scripts/bash/status.sh" update
else
    echo "⚠️ status.sh が見つかりません: $PROJECT_ROOT/AI/scripts/bash/status.sh"
    exit 1
fi
