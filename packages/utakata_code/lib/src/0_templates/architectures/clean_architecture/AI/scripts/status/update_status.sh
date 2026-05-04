#!/usr/bin/env bash
set -Eeuo pipefail

# update_status.sh
# プロジェクトの現在状態を検出し、
# project_status.yaml と preview/project_status.md を生成する

# ========================================
# 環境設定（macOS homebrew 対応）
# ========================================
export PATH="/opt/homebrew/bin:$PATH"

# ========================================
# 色定義
# ========================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ========================================
# パス設定
# ========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

OUTPUT_YAML="$PROJECT_ROOT/utakata/snapshots/project_status.yaml"
OUTPUT_MD="$PROJECT_ROOT/utakata/snapshots/preview/project_status.md"

# ========================================
# yq の存在確認
# ========================================
if ! command -v yq &> /dev/null; then
  echo -e "\033[0;31m❌ yq がインストールされていません\033[0m"
  echo "   brew install yq でインストールしてください"
  exit 1
fi

# ========================================
# 引数処理
# ========================================
CONFIRM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes) CONFIRM="y"; shift;;
    -h|--help)
      echo "Usage: $0 [-y|--yes]"
      echo "  -y, --yes   確認なしで実行"
      exit 0;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

if [ "$CONFIRM" != "y" ]; then
  echo "project_status.yaml を現在の状態で更新しますか？ (y/n)"
  read CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    echo "処理を中断しました。"
    exit 0
  fi
fi

# ========================================
# チェック関数
# ========================================
check_bool() {
  [ -e "$1" ] && echo "true" || echo "false"
}

get_document_status() {
  local file=$1
  if [ -f "$file" ]; then
    if grep -q "^- プロジェクト名: $" "$file" 2>/dev/null; then
      echo "template_only"
    else
      echo "created"
    fi
  else
    echo "not_created"
  fi
}

# ========================================
# 状態収集
# ========================================
echo -e "${BLUE}📝 プロジェクト状態を収集中...${NC}\n"

CURRENT_TIME=$(date '+%Y-%m-%dT%H:%M:%S%z')

# Flutter プロジェクト
PUBSPEC_EXISTS=$(check_bool "$PROJECT_ROOT/pubspec.yaml")
LIB_EXISTS=$(check_bool "$PROJECT_ROOT/lib")
FLUTTER_INIT="false"
if [ "$PUBSPEC_EXISTS" = "true" ] && [ "$LIB_EXISTS" = "true" ]; then
  FLUTTER_INIT="true"
fi

# プロジェクト名・バージョン
PROJ_NAME=""
PROJ_VERSION=""
if [ -f "$PROJECT_ROOT/pubspec.yaml" ]; then
  PROJ_NAME=$(yq '.name // ""' "$PROJECT_ROOT/pubspec.yaml")
  PROJ_VERSION=$(yq '.version // ""' "$PROJECT_ROOT/pubspec.yaml")
fi

# Core 基盤
ROUTING=$(check_bool "$PROJECT_ROOT/lib/core/routing")
ROUTING_PATH=$(check_bool "$PROJECT_ROOT/lib/core/routing/path")
THEME=$(check_bool "$PROJECT_ROOT/lib/core/theme")
API=$(check_bool "$PROJECT_ROOT/lib/core/api")
ENV=$(check_bool "$PROJECT_ROOT/lib/core/env")
DATABASE=$(check_bool "$PROJECT_ROOT/lib/core/database")
DATABASE_TABLE=$(check_bool "$PROJECT_ROOT/lib/core/database/table")
EXCEPTIONS=$(check_bool "$PROJECT_ROOT/lib/core/exceptions")

# エントリポイント
MAIN_DART=$(check_bool "$PROJECT_ROOT/lib/main.dart")
APP_DART=$(check_bool "$PROJECT_ROOT/lib/app.dart")

# ドキュメント
SPEC_STATUS=$(get_document_status "$PROJECT_ROOT/utakata/specs/application_specification.md")
PLAN_STATUS=$(get_document_status "$PROJECT_ROOT/utakata/specs/structure_plan.md")

# フィーチャー
FEATURES_COUNT=0
if [ -d "$PROJECT_ROOT/lib/features" ]; then
  # permission 配下のフィーチャーを数える
  FEATURES_COUNT=$(find "$PROJECT_ROOT/lib/features" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | wc -l | tr -d ' ')
fi

# ========================================
# YAML 出力
# ========================================
{
  echo "# project_status.yaml"
  echo "# 自動生成 — 手動編集しないでください"
  echo "# 生成日時: $CURRENT_TIME"
  echo ""
  echo "project:"
  echo "  name: \"$PROJ_NAME\""
  echo "  version: \"$PROJ_VERSION\""
  echo "  mode: null"
  echo "  started_at: null"
  echo "  last_worked_at: null"
  echo ""
  echo "stage:"
  echo "  current: null"
  echo "  stage1:"
  echo "    status: \"not_started\""
  echo "  stage2:"
  echo "    status: \"not_started\""
  echo "  stage3:"
  echo "    status: \"not_started\""
  echo ""
  echo "flutter:"
  echo "  pubspec_exists: $PUBSPEC_EXISTS"
  echo "  lib_exists: $LIB_EXISTS"
  echo "  initialized: $FLUTTER_INIT"
  echo ""
  echo "core:"
  echo "  routing: $ROUTING"
  echo "  routing_path: $ROUTING_PATH"
  echo "  theme: $THEME"
  echo "  api: $API"
  echo "  env: $ENV"
  echo "  database: $DATABASE"
  echo "  database_table: $DATABASE_TABLE"
  echo "  exceptions: $EXCEPTIONS"
  echo ""
  echo "entry_points:"
  echo "  main_dart: $MAIN_DART"
  echo "  app_dart: $APP_DART"
  echo ""
  echo "documents:"
  echo "  specification: \"$SPEC_STATUS\""
  echo "  structure_plan: \"$PLAN_STATUS\""
  echo ""
  echo "features:"
  echo "  count: $FEATURES_COUNT"
  echo ""
  echo "updated_at: \"$CURRENT_TIME\""
  echo "updated_by: \"update_status.sh\""
} > "$OUTPUT_YAML"

echo -e "${GREEN}✅ YAML 生成完了: ${OUTPUT_YAML}${NC}"

# ========================================
# Preview MD 出力
# ========================================
echo -e "${BLUE}📝 プレビュー MD を生成中...${NC}"

bool_to_icon() {
  [ "$1" = "true" ] && echo "✅" || echo "❌"
}

doc_to_label() {
  case "$1" in
    "not_created") echo "未作成";;
    "template_only") echo "テンプレートのみ";;
    "created") echo "作成済み";;
    *) echo "$1";;
  esac
}

{
  echo "# プロジェクトステータス"
  echo ""
  echo "> 自動生成 — 手動編集しないでください"
  echo "> 生成日時: $CURRENT_TIME"
  echo ""
  echo "## Flutter プロジェクト"
  echo ""
  echo "| 項目 | 状態 |"
  echo "|------|------|"
  echo "| pubspec.yaml | $(bool_to_icon $PUBSPEC_EXISTS) |"
  echo "| lib/ | $(bool_to_icon $LIB_EXISTS) |"
  echo "| 初期化済み | $(bool_to_icon $FLUTTER_INIT) |"
  echo ""
  echo "## エントリポイント"
  echo ""
  echo "| ファイル | 状態 |"
  echo "|---------|------|"
  echo "| main.dart | $(bool_to_icon $MAIN_DART) |"
  echo "| app.dart | $(bool_to_icon $APP_DART) |"
  echo ""
  echo "## Core 基盤"
  echo ""
  echo "| コンポーネント | 状態 |"
  echo "|-------------|------|"
  echo "| routing/ | $(bool_to_icon $ROUTING) |"
  echo "| routing/path/ | $(bool_to_icon $ROUTING_PATH) |"
  echo "| theme/ | $(bool_to_icon $THEME) |"
  echo "| api/ | $(bool_to_icon $API) |"
  echo "| env/ | $(bool_to_icon $ENV) |"
  echo "| database/ | $(bool_to_icon $DATABASE) |"
  echo "| database/table/ | $(bool_to_icon $DATABASE_TABLE) |"
  echo "| exceptions/ | $(bool_to_icon $EXCEPTIONS) |"
  echo ""
  echo "## ドキュメント"
  echo ""
  echo "| ドキュメント | 状態 |"
  echo "|-----------|------|"
  echo "| 仕様書 | $(doc_to_label $SPEC_STATUS) |"
  echo "| 構造計画書 | $(doc_to_label $PLAN_STATUS) |"
  echo ""
  echo "## フィーチャー"
  echo ""
  echo "- **検出数**: $FEATURES_COUNT"

  if [ "$FEATURES_COUNT" -gt 0 ]; then
    echo ""
    echo "| パーミッション | フィーチャー |"
    echo "|-------------|------------|"
    for perm_dir in "$PROJECT_ROOT/lib/features"/*; do
      if [ ! -d "$perm_dir" ]; then continue; fi
      perm_name=$(basename "$perm_dir")
      for feature_dir in "$perm_dir"/*; do
        if [ ! -d "$feature_dir" ]; then continue; fi
        feature_name=$(basename "$feature_dir")
        echo "| $perm_name | $feature_name |"
      done
    done
  fi

} > "$OUTPUT_MD"

echo -e "${GREEN}✅ プレビュー MD 生成完了: ${OUTPUT_MD}${NC}"
echo ""
echo -e "${GREEN}🎉 生成完了！${NC}"
echo -e "  YAML: ${OUTPUT_YAML}"
echo -e "  MD:   ${OUTPUT_MD}"
