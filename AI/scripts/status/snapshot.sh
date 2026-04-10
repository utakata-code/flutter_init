#!/usr/bin/env bash
set -Eeuo pipefail

# snapshot.sh
# lib/ の現在のディレクトリ構造を走査し、
# actual_architecture.yaml と preview/actual_architecture.md を生成する
#
# 使い方:
#   ./AI/scripts/status/snapshot.sh

# ========================================
# 環境設定（macOS homebrew 対応）
# ========================================
export PATH="/opt/homebrew/bin:$PATH"

# ========================================
# 色定義
# ========================================
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ========================================
# パス設定
# ========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

OUTPUT_YAML="$PROJECT_ROOT/AI/snapshots/actual_architecture.yaml"
OUTPUT_MD="$PROJECT_ROOT/AI/snapshots/preview/actual_architecture.md"

# ========================================
# yq の存在確認
# ========================================
if ! command -v yq &> /dev/null; then
  echo -e "\033[0;31m❌ yq がインストールされていません\033[0m"
  echo "   brew install yq でインストールしてください"
  exit 1
fi

# ========================================
# メイン: スナップショット生成
# ========================================
echo -e "${BLUE}📸 プロジェクト構造のスナップショットを生成中...${NC}\n"

CURRENT_TIME=$(date '+%Y-%m-%dT%H:%M:%S%z')

# lib/ が存在しなければ空の状態を出力
if [ ! -d "$PROJECT_ROOT/lib" ]; then
  echo -e "${YELLOW}⚠️  lib/ ディレクトリが存在しません。空のスナップショットを生成します${NC}\n"

  # 空の YAML を出力
  {
    echo "# actual_architecture.yaml"
    echo "# 自動生成 — 手動編集しないでください"
    echo "# 生成日時: $CURRENT_TIME"
    echo ""
    echo "project:"
    echo "  name: \"\""
    echo "  version: \"\""
    echo ""
    echo "structure:"
    echo "  lib: {}"
  } > "$OUTPUT_YAML"

  # 空の MD を出力
  {
    echo "# 現在の構造（actual_architecture）"
    echo ""
    echo "> 自動生成 — 手動編集しないでください"
    echo "> 生成日時: $CURRENT_TIME"
    echo ""
    echo "## lib/ 構造"
    echo ""
    echo "プロジェクトに lib ディレクトリが存在しません。"
  } > "$OUTPUT_MD"

  echo -e "${GREEN}✅ 空のスナップショットを生成しました${NC}"
  exit 0
fi

# ========================================
# lib/ からYAMLを構築する関数
# ========================================

# ディレクトリを再帰的に走査し、YAMLとして出力する
# 引数: $1=走査パス, $2=インデントレベル
generate_yaml_tree() {
  local dir="$1"
  local indent="$2"
  local prefix=""

  # インデントを生成
  for (( k=0; k<indent; k++ )); do
    prefix+="  "
  done

  # ディレクトリ内のサブディレクトリとファイルをソートして走査
  local entries=()
  while IFS= read -r entry; do
    entries+=("$entry")
  done < <(ls -1 "$dir" 2>/dev/null | sort)

  for entry in "${entries[@]}"; do
    local fullpath="$dir/$entry"

    if [ -d "$fullpath" ]; then
      # ディレクトリの場合
      echo "${prefix}${entry}:"
      generate_yaml_tree "$fullpath" $((indent + 1))
    elif [ -f "$fullpath" ]; then
      # ファイルの場合（.dart のみ、生成ファイルを除外）
      if [[ "$entry" == *.dart ]] && \
         [[ "$entry" != *.g.dart ]] && \
         [[ "$entry" != *.freezed.dart ]]; then
        echo "${prefix}${entry}:"
        echo "${prefix}  description: \"\""
      fi
    fi
  done
}

# ========================================
# YAML 生成
# ========================================
{
  echo "# actual_architecture.yaml"
  echo "# 自動生成 — 手動編集しないでください"
  echo "# 生成日時: $CURRENT_TIME"
  echo ""
  echo "project:"

  # pubspec.yaml からプロジェクト情報を取得
  if [ -f "$PROJECT_ROOT/pubspec.yaml" ]; then
    PROJ_NAME=$(yq '.name // ""' "$PROJECT_ROOT/pubspec.yaml")
    PROJ_VERSION=$(yq '.version // ""' "$PROJECT_ROOT/pubspec.yaml")
    echo "  name: \"$PROJ_NAME\""
    echo "  version: \"$PROJ_VERSION\""
  else
    echo "  name: \"\""
    echo "  version: \"\""
  fi

  echo ""
  echo "structure:"
  echo "  lib:"
  generate_yaml_tree "$PROJECT_ROOT/lib" 2

} > "$OUTPUT_YAML"

echo -e "${GREEN}✅ YAML 生成完了: ${OUTPUT_YAML}${NC}"

# ========================================
# Preview MD 生成
# ========================================
echo -e "${BLUE}📝 プレビュー MD を生成中...${NC}"

# 統計情報を収集
TOTAL_FILES=$(find "$PROJECT_ROOT/lib" -type f -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" 2>/dev/null | wc -l | tr -d ' ')
TOTAL_DIRS=$(find "$PROJECT_ROOT/lib" -type d 2>/dev/null | wc -l | tr -d ' ')

{
  echo "# 現在の構造（actual_architecture）"
  echo ""
  echo "> 自動生成 — 手動編集しないでください"
  echo "> 生成日時: $CURRENT_TIME"
  echo ""
  echo "## lib/ 構造"
  echo ""
  echo '```'

  # tree コマンドがあればそれを使う（見た目が良い）
  if command -v tree &> /dev/null; then
    tree -L 6 -I '*.g.dart|*.freezed.dart' "$PROJECT_ROOT/lib"
  else
    cd "$PROJECT_ROOT/lib"
    find . -type f -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" | sort | sed 's|^\./||'
  fi

  echo '```'
  echo ""
  echo "## 統計情報"
  echo ""
  echo "- **総ファイル数**: $TOTAL_FILES (生成ファイルを除く)"
  echo "- **総ディレクトリ数**: $TOTAL_DIRS"
  echo ""

  # Features の内訳
  if [ -d "$PROJECT_ROOT/lib/features" ]; then
    echo "## Features 内訳"
    echo ""
    echo "| パーミッション | フィーチャー | Domain | Infra | App | Presentation |"
    echo "|-------------|------------|--------|-------|-----|-------------|"

    for perm_dir in "$PROJECT_ROOT/lib/features"/*; do
      if [ ! -d "$perm_dir" ]; then continue; fi
      perm_name=$(basename "$perm_dir")

      for feature_dir in "$perm_dir"/*; do
        if [ ! -d "$feature_dir" ]; then continue; fi
        feature_name=$(basename "$feature_dir")

        domain_count=$(find "$feature_dir/1_domain" -type f -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" 2>/dev/null | wc -l | tr -d ' ')
        infra_count=$(find "$feature_dir/2_infrastructure" -type f -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" 2>/dev/null | wc -l | tr -d ' ')
        app_count=$(find "$feature_dir/3_application" -type f -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" 2>/dev/null | wc -l | tr -d ' ')
        pres_count=$(find "$feature_dir/4_presentation" -type f -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" 2>/dev/null | wc -l | tr -d ' ')

        echo "| $perm_name | $feature_name | $domain_count | $infra_count | $app_count | $pres_count |"
      done
    done
  fi

} > "$OUTPUT_MD"

echo -e "${GREEN}✅ プレビュー MD 生成完了: ${OUTPUT_MD}${NC}"
echo ""
echo -e "${GREEN}🎉 生成完了！${NC}"
echo -e "  YAML: ${OUTPUT_YAML}"
echo -e "  MD:   ${OUTPUT_MD}"
