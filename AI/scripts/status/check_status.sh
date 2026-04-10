#!/usr/bin/env bash
set -Eeuo pipefail

# check_status.sh
# プロジェクト状態をチェックして表示する（表示のみ、ファイル変更なし）

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# ========================================
# 共通チェック関数
# ========================================

check_exists() {
  [ -e "$1" ] && echo "[x]" || echo "[ ]"
}

check_dir_with_msg() {
  local dir="$PROJECT_ROOT/lib/core/$1"
  local name=$2
  if [ -d "$dir" ]; then
    echo -e "${GREEN}  ✓ $name${NC}"
    echo "[x]"
  else
    echo -e "${RED}  ✗ $name${NC}"
    echo "[ ]"
  fi
}

check_file_with_msg() {
  local file=$1
  local name=$2
  if [ -f "$file" ]; then
    echo -e "${GREEN}  ✓ $name${NC}"
    echo "[x]"
  else
    echo -e "${RED}  ✗ $name${NC}"
    echo "[ ]"
  fi
}

get_document_status() {
  local file=$1
  if [ -f "$file" ]; then
    if grep -q "^- プロジェクト名: $" "$file" 2>/dev/null; then
      echo "テンプレートのみ"
    else
      echo "作成済み"
    fi
  else
    echo "未作成"
  fi
}

# ========================================
# メイン: プロジェクト状態をチェックして表示
# ========================================

echo -e "${BLUE}🔍 プロジェクトステータスをチェック中...${NC}\n"

CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Flutter プロジェクト初期化状態
echo -e "${YELLOW}📦 Flutter プロジェクトの状態:${NC}"

PUBSPEC_EXISTS="[ ]"
LIB_EXISTS="[ ]"
FLUTTER_CREATED="[ ]"

if [ -f "$PROJECT_ROOT/pubspec.yaml" ]; then
  PUBSPEC_EXISTS="[x]"
  echo -e "${GREEN}  ✓ pubspec.yaml 存在${NC}"
else
  echo -e "${RED}  ✗ pubspec.yaml なし${NC}"
fi

if [ -d "$PROJECT_ROOT/lib" ]; then
  LIB_EXISTS="[x]"
  echo -e "${GREEN}  ✓ lib/ ディレクトリ存在${NC}"
else
  echo -e "${RED}  ✗ lib/ ディレクトリなし${NC}"
fi

if [ "$PUBSPEC_EXISTS" = "[x]" ] && [ "$LIB_EXISTS" = "[x]" ]; then
  FLUTTER_CREATED="[x]"
  echo -e "${GREEN}  ✓ Flutterプロジェクト初期化済み${NC}"
else
  echo -e "${YELLOW}  ⚠ Flutterプロジェクト未初期化${NC}"
fi

echo ""

# Core 基盤の状態
echo -e "${YELLOW}🏗️  Core 基盤の状態:${NC}"

CORE_ROUTING=$(check_dir_with_msg "routing" "routing/")
CORE_THEME=$(check_dir_with_msg "theme" "theme/")
CORE_API=$(check_dir_with_msg "api" "api/")
CORE_ENV=$(check_dir_with_msg "env" "env/")
CORE_DATABASE=$(check_dir_with_msg "database" "database/")
CORE_EXCEPTIONS=$(check_dir_with_msg "exceptions" "exceptions/")

echo ""

# エントリポイントの状態
echo -e "${YELLOW}🚪 エントリポイントの状態:${NC}"

MAIN_DART=$(check_file_with_msg "$PROJECT_ROOT/lib/main.dart" "lib/main.dart")
APP_DART=$(check_file_with_msg "$PROJECT_ROOT/lib/app.dart" "lib/app.dart")

echo ""

# ドキュメントの状態
echo -e "${YELLOW}📄 ドキュメントの状態:${NC}"

SPEC_STATUS=$(get_document_status "$PROJECT_ROOT/AI/specs/application_specification.md")
PLAN_STATUS=$(get_document_status "$PROJECT_ROOT/AI/specs/structure_plan.md")

if [ "$SPEC_STATUS" = "作成済み" ]; then
  echo -e "${GREEN}  ✓ 仕様書作成済み${NC}"
else
  echo -e "${RED}  ✗ 仕様書未作成${NC}"
fi

if [ "$PLAN_STATUS" = "作成済み" ]; then
  echo -e "${GREEN}  ✓ 構造計画書作成済み${NC}"
else
  echo -e "${RED}  ✗ 構造計画書未作成${NC}"
fi

echo ""

# Features の状態
echo -e "${YELLOW}🎯 Features の状態:${NC}"

FEATURES_COUNT=0
if [ -d "$PROJECT_ROOT/lib/features" ]; then
  FEATURES_COUNT=$(find "$PROJECT_ROOT/lib/features" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  if [ "$FEATURES_COUNT" -gt 0 ]; then
    echo -e "${GREEN}  ✓ $FEATURES_COUNT 個のフィーチャーを検出${NC}"
  else
    echo -e "${YELLOW}  ⚠ フィーチャー未実装${NC}"
  fi
else
  echo -e "${YELLOW}  ⚠ lib/features/ ディレクトリなし${NC}"
fi

echo ""

# サマリー表示
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 ステータスサマリー${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "最終更新: $CURRENT_TIME"
echo ""
echo "Flutter プロジェクト:"
echo "  - pubspec.yaml: $PUBSPEC_EXISTS"
echo "  - lib/ ディレクトリ: $LIB_EXISTS"
echo ""
echo "Core 基盤:"
echo "  - routing/: $(echo "$CORE_ROUTING" | tail -n1)"
echo "  - theme/: $(echo "$CORE_THEME" | tail -n1)"
echo "  - api/: $(echo "$CORE_API" | tail -n1)"
echo "  - env/: $(echo "$CORE_ENV" | tail -n1)"
echo "  - database/: $(echo "$CORE_DATABASE" | tail -n1)"
echo "  - exceptions/: $(echo "$CORE_EXCEPTIONS" | tail -n1)"
echo ""
echo "エントリポイント:"
echo "  - main.dart: $(echo "$MAIN_DART" | tail -n1)"
echo "  - app.dart: $(echo "$APP_DART" | tail -n1)"
echo ""
echo "ドキュメント:"
echo "  - 仕様書: $SPEC_STATUS"
echo "  - 構造計画書: $PLAN_STATUS"
echo ""
echo "Features: $FEATURES_COUNT 個実装済み"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ ステータスチェック完了${NC}"
