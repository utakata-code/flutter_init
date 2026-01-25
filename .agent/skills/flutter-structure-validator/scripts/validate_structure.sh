#!/bin/bash
# 構造検証ラッパースクリプト
# validate_structure.sh へのラッパーとして機能

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

echo "🔍 ディレクトリ構造検証を実行中..."
echo "================================================"

if [ -f "$PROJECT_ROOT/AI/scripts/bash/validate_structure.sh" ]; then
    "$PROJECT_ROOT/AI/scripts/bash/validate_structure.sh" "$@"
else
    echo "⚠️ validate_structure.sh が見つかりません: $PROJECT_ROOT/AI/scripts/bash/validate_structure.sh"
    exit 1
fi
