#!/usr/bin/env bash
set -Eeuo pipefail

# diff_architecture.sh
# plan_architecture.yaml と actual_architecture.yaml を比較し、
# 差分レポートを YAML + preview MD で出力する
#
# 使い方:
#   ./AI/scripts/generate/diff_architecture.sh

# ========================================
# 環境設定（macOS homebrew 対応）
# ========================================
export PATH="/opt/homebrew/bin:$PATH"

# ========================================
# 色定義
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ========================================
# パス設定
# ========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

PLAN_YAML="$PROJECT_ROOT/AI/snapshots/plan_architecture.yaml"
ACTUAL_YAML="$PROJECT_ROOT/AI/snapshots/actual_architecture.yaml"
OUTPUT_YAML="$PROJECT_ROOT/AI/snapshots/architecture_diff.yaml"
OUTPUT_MD="$PROJECT_ROOT/AI/snapshots/preview/architecture_diff.md"

# ========================================
# yq の存在確認
# ========================================
if ! command -v yq &> /dev/null; then
  echo -e "${RED}❌ yq がインストールされていません${NC}"
  echo "   brew install yq でインストールしてください"
  exit 1
fi

# ========================================
# 引数処理
# ========================================
while [[ $# -gt 0 ]]; do
  case $1 in
    --plan|-p)
      PLAN_YAML="$2"; shift 2;;
    --actual|-a)
      ACTUAL_YAML="$2"; shift 2;;
    --help|-h)
      echo "Usage: $0 [--plan path] [--actual path]"
      echo ""
      echo "Options:"
      echo "  -p, --plan    計画YAML（デフォルト: AI/snapshots/plan_architecture.yaml）"
      echo "  -a, --actual  実績YAML（デフォルト: AI/snapshots/actual_architecture.yaml）"
      exit 0;;
    *)
      echo -e "${RED}❌ 不明なオプション: $1${NC}"; exit 1;;
  esac
done

# ========================================
# 入力ファイル確認
# ========================================
if [ ! -f "$PLAN_YAML" ]; then
  echo -e "${RED}❌ 計画ファイルが見つかりません: $PLAN_YAML${NC}"
  echo "   先に ./AI/scripts/generate/generate_plan.sh を実行してください"
  exit 1
fi

if [ ! -f "$ACTUAL_YAML" ]; then
  echo -e "${RED}❌ 実績ファイルが見つかりません: $ACTUAL_YAML${NC}"
  echo "   先に ./AI/scripts/status/snapshot.sh を実行してください"
  exit 1
fi

echo -e "${BLUE}🔍 計画 vs 実績の差分を検出中...${NC}\n"

# ========================================
# YAMLからファイルパスを抽出する関数
# .dart で終わるキーへのパスを全て取得し、
# "structure" プレフィックスを除去してファイルパスにする
# ========================================
extract_dart_paths() {
  local yaml_file="$1"

  # yq で structure 配下の全パスを取得し、.dart で終わるものを抽出
  # 出力例: lib/main.dart, lib/core/routing/app_router.dart
  yq '.structure | .. | path | select(length > 0) | select(.[-1] | test("\\.dart$")) | join("/")' "$yaml_file" 2>/dev/null \
    | sed 's|^structure/||' \
    | sort -u
}

# ========================================
# ファイルパス抽出
# ========================================
PLAN_TMP=$(mktemp)
ACTUAL_TMP=$(mktemp)

# クリーンアップ用トラップ
trap "rm -f $PLAN_TMP $ACTUAL_TMP" EXIT

extract_dart_paths "$PLAN_YAML" > "$PLAN_TMP"
extract_dart_paths "$ACTUAL_YAML" > "$ACTUAL_TMP"

PLAN_COUNT=$(wc -l < "$PLAN_TMP" | tr -d ' ')
ACTUAL_COUNT=$(wc -l < "$ACTUAL_TMP" | tr -d ' ')

# ========================================
# 差分計算
# ========================================
# 計画にあるが実績にない（未実装）
NOT_IMPLEMENTED_TMP=$(mktemp)
comm -23 "$PLAN_TMP" "$ACTUAL_TMP" > "$NOT_IMPLEMENTED_TMP"
NOT_IMPL_COUNT=$(wc -l < "$NOT_IMPLEMENTED_TMP" | tr -d ' ')

# 実績にあるが計画にない（無計画）
UNPLANNED_TMP=$(mktemp)
comm -13 "$PLAN_TMP" "$ACTUAL_TMP" > "$UNPLANNED_TMP"
UNPLANNED_COUNT=$(wc -l < "$UNPLANNED_TMP" | tr -d ' ')

# 両方にある（実装済み）
IMPLEMENTED_TMP=$(mktemp)
comm -12 "$PLAN_TMP" "$ACTUAL_TMP" > "$IMPLEMENTED_TMP"
IMPL_COUNT=$(wc -l < "$IMPLEMENTED_TMP" | tr -d ' ')

trap "rm -f $PLAN_TMP $ACTUAL_TMP $NOT_IMPLEMENTED_TMP $UNPLANNED_TMP $IMPLEMENTED_TMP" EXIT

# 進捗率の計算
if [ "$PLAN_COUNT" -gt 0 ]; then
  PROGRESS=$(( IMPL_COUNT * 100 / PLAN_COUNT ))
else
  PROGRESS=0
fi

CURRENT_TIME=$(date '+%Y-%m-%dT%H:%M:%S%z')

# ========================================
# 結果表示
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 差分レポート${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "計画ファイル数:   ${CYAN}$PLAN_COUNT${NC}"
echo -e "実績ファイル数:   ${CYAN}$ACTUAL_COUNT${NC}"
echo ""
echo -e "✅ 実装済み:      ${GREEN}$IMPL_COUNT${NC}"
echo -e "📋 未実装:        ${YELLOW}$NOT_IMPL_COUNT${NC}"
echo -e "⚠️  無計画:        ${RED}$UNPLANNED_COUNT${NC}"
echo ""

# プログレスバー
BAR_WIDTH=30
if [ "$PLAN_COUNT" -gt 0 ]; then
  FILLED=$(( PROGRESS * BAR_WIDTH / 100 ))
  EMPTY=$(( BAR_WIDTH - FILLED ))
  BAR=$(printf '%0.s█' $(seq 1 $FILLED 2>/dev/null) || true)
  BAR_EMPTY=$(printf '%0.s░' $(seq 1 $EMPTY 2>/dev/null) || true)
  echo -e "進捗: [${GREEN}${BAR}${NC}${BAR_EMPTY}] ${GREEN}${PROGRESS}%${NC}"
else
  echo -e "進捗: ${YELLOW}計画ファイルが0件のため計算不可${NC}"
fi
echo ""

if [ "$NOT_IMPL_COUNT" -gt 0 ]; then
  echo -e "${YELLOW}📋 未実装ファイル:${NC}"
  while IFS= read -r file; do
    echo -e "  ${YELLOW}•${NC} $file"
  done < "$NOT_IMPLEMENTED_TMP"
  echo ""
fi

if [ "$UNPLANNED_COUNT" -gt 0 ]; then
  echo -e "${RED}⚠️  計画にないファイル:${NC}"
  while IFS= read -r file; do
    echo -e "  ${RED}•${NC} $file"
  done < "$UNPLANNED_TMP"
  echo ""
fi

# ========================================
# YAML 出力
# ========================================
{
  echo "# architecture_diff.yaml"
  echo "# 自動生成 — 手動編集しないでください"
  echo "# 生成日時: $CURRENT_TIME"
  echo ""
  echo "compared_at: \"$CURRENT_TIME\""
  echo "plan_file: \"$(basename "$PLAN_YAML")\""
  echo "actual_file: \"$(basename "$ACTUAL_YAML")\""
  echo ""
  echo "summary:"
  echo "  plan_count: $PLAN_COUNT"
  echo "  actual_count: $ACTUAL_COUNT"
  echo "  implemented: $IMPL_COUNT"
  echo "  not_implemented: $NOT_IMPL_COUNT"
  echo "  unplanned: $UNPLANNED_COUNT"
  echo "  progress_percent: $PROGRESS"

  # 未実装ファイル一覧
  if [ "$NOT_IMPL_COUNT" -eq 0 ]; then
    echo ""
    echo "not_implemented: []"
  else
    echo ""
    echo "not_implemented:"
    while IFS= read -r file; do
      echo "  - \"$file\""
    done < "$NOT_IMPLEMENTED_TMP"
  fi

  # 無計画ファイル一覧
  if [ "$UNPLANNED_COUNT" -eq 0 ]; then
    echo ""
    echo "unplanned: []"
  else
    echo ""
    echo "unplanned:"
    while IFS= read -r file; do
      echo "  - \"$file\""
    done < "$UNPLANNED_TMP"
  fi

  # 実装済みファイル一覧
  if [ "$IMPL_COUNT" -eq 0 ]; then
    echo ""
    echo "implemented: []"
  else
    echo ""
    echo "implemented:"
    while IFS= read -r file; do
      echo "  - \"$file\""
    done < "$IMPLEMENTED_TMP"
  fi

} > "$OUTPUT_YAML"

echo -e "${GREEN}✅ YAML 生成完了: ${OUTPUT_YAML}${NC}"

# ========================================
# Preview MD 出力
# ========================================
{
  echo "# 計画 vs 実績 差分レポート"
  echo ""
  echo "> 自動生成 — 手動編集しないでください"
  echo "> 比較日時: $CURRENT_TIME"
  echo ""
  echo "## サマリー"
  echo ""
  echo "| 指標 | 値 |"
  echo "|------|-----|"
  echo "| 計画ファイル数 | $PLAN_COUNT |"
  echo "| 実績ファイル数 | $ACTUAL_COUNT |"
  echo "| ✅ 実装済み | $IMPL_COUNT |"
  echo "| 📋 未実装 | $NOT_IMPL_COUNT |"
  echo "| ⚠️ 無計画 | $UNPLANNED_COUNT |"
  echo "| **進捗率** | **${PROGRESS}%** |"

  if [ "$NOT_IMPL_COUNT" -gt 0 ]; then
    echo ""
    echo "## 📋 未実装ファイル ($NOT_IMPL_COUNT 件)"
    echo ""
    echo "計画にあるが、まだ \`lib/\` に存在しないファイル:"
    echo ""
    while IFS= read -r file; do
      echo "- \`$file\`"
    done < "$NOT_IMPLEMENTED_TMP"
  fi

  if [ "$UNPLANNED_COUNT" -gt 0 ]; then
    echo ""
    echo "## ⚠️ 無計画ファイル ($UNPLANNED_COUNT 件)"
    echo ""
    echo "計画にないが、\`lib/\` に存在するファイル:"
    echo ""
    while IFS= read -r file; do
      echo "- \`$file\`"
    done < "$UNPLANNED_TMP"
  fi

  if [ "$IMPL_COUNT" -gt 0 ]; then
    echo ""
    echo "## ✅ 実装済みファイル ($IMPL_COUNT 件)"
    echo ""
    echo "<details>"
    echo "<summary>一覧を表示</summary>"
    echo ""
    while IFS= read -r file; do
      echo "- \`$file\`"
    done < "$IMPLEMENTED_TMP"
    echo ""
    echo "</details>"
  fi

} > "$OUTPUT_MD"

echo -e "${GREEN}✅ プレビュー MD 生成完了: ${OUTPUT_MD}${NC}"
echo ""
echo -e "${GREEN}🎉 生成完了！${NC}"
echo -e "  YAML: ${OUTPUT_YAML}"
echo -e "  MD:   ${OUTPUT_MD}"
