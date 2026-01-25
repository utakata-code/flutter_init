#!/bin/bash
# フィーチャー生成ラッパースクリプト
# generate_feature.sh へのラッパーとして機能

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

# 引数をそのままgenerate_feature.shに渡す
if [ -f "$PROJECT_ROOT/AI/scripts/bash/generate_feature.sh" ]; then
    "$PROJECT_ROOT/AI/scripts/bash/generate_feature.sh" "$@"
else
    echo "⚠️ generate_feature.sh が見つかりません: $PROJECT_ROOT/AI/scripts/bash/generate_feature.sh"
    exit 1
fi
