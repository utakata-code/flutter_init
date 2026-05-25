#!/usr/bin/env bash
set -Eeuo pipefail

# detect_changes.sh
# プロジェクト内のファイル変更を検出し、
# change_history.yaml と preview/change_history.md に記録する

# ========================================
# 環境設定（macOS homebrew 対応）
# ========================================
export PATH="/opt/homebrew/bin:$PATH"

# ========================================
# 色定義
# ========================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ========================================
# パス設定
# ========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

OUTPUT_YAML="$PROJECT_ROOT/AI/snapshots/change_history.yaml"
OUTPUT_MD="$PROJECT_ROOT/AI/snapshots/preview/change_history.md"
SNAPSHOT_FILE="$PROJECT_ROOT/.agent/.file_snapshot"

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
usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --clear-history     変更履歴をクリア"
  echo "  -h, --help         このヘルプを表示"
  exit 0
}

CLEAR_HISTORY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clear-history) CLEAR_HISTORY=true; shift;;
    -h|--help) usage;;
    *) echo "Unknown option: $1"; usage;;
  esac
done

echo -e "${BLUE}🔍 ファイル変更を検出中...${NC}\n"

# Git リポジトリかチェック
if [ ! -d "$PROJECT_ROOT/.git" ]; then
  echo -e "${YELLOW}⚠️ Gitリポジトリではありません。簡易モードで動作します。${NC}"
  USE_GIT=false
else
  USE_GIT=true
fi

CURRENT_TIME=$(date '+%Y-%m-%dT%H:%M:%S%z')
mkdir -p "$PROJECT_ROOT/.agent"

# ========================================
# 変更検出
# ========================================
declare -a FILES_CREATED=()
declare -a FILES_MODIFIED=()
declare -a FILES_DELETED=()
declare -a DIRS_CREATED=()

if [ "$USE_GIT" = true ]; then
  # 未追跡ファイル（新規作成）
  while IFS= read -r file; do
    [ -n "$file" ] && FILES_CREATED+=("$file")
  done < <(git -C "$PROJECT_ROOT" ls-files --others --exclude-standard 2>/dev/null)

  # 変更されたファイル
  while IFS= read -r file; do
    [ -n "$file" ] && FILES_MODIFIED+=("$file")
  done < <(git -C "$PROJECT_ROOT" diff --name-only 2>/dev/null)

  # ステージングエリアの変更
  while IFS= read -r file; do
    if [ -n "$file" ] && [[ ! " ${FILES_MODIFIED[*]:-} " =~ " ${file} " ]]; then
      FILES_MODIFIED+=("$file")
    fi
  done < <(git -C "$PROJECT_ROOT" diff --cached --name-only 2>/dev/null)
else
  # Git がない場合はスナップショット比較
  if [ -f "$SNAPSHOT_FILE" ] && [ -d "$PROJECT_ROOT/lib" ]; then
    find "$PROJECT_ROOT/lib" -type f 2>/dev/null | sort > /tmp/current_files.txt
    while IFS= read -r file; do
      if ! grep -q "^$file$" "$SNAPSHOT_FILE" 2>/dev/null; then
        FILES_CREATED+=("${file#$PROJECT_ROOT/}")
      fi
    done < /tmp/current_files.txt
    while IFS= read -r file; do
      if [ ! -f "$file" ]; then
        FILES_DELETED+=("${file#$PROJECT_ROOT/}")
      fi
    done < "$SNAPSHOT_FILE"
    rm -f /tmp/current_files.txt
  fi
  [ -d "$PROJECT_ROOT/lib" ] && find "$PROJECT_ROOT/lib" -type f 2>/dev/null | sort > "$SNAPSHOT_FILE" || true
fi

# lib/ 配下の新規ディレクトリ（24時間以内）
if [ -d "$PROJECT_ROOT/lib" ]; then
  while IFS= read -r dir; do
    if [ -d "$dir" ]; then
      dir_age=$(stat -f %B "$dir" 2>/dev/null || stat -c %Y "$dir" 2>/dev/null || echo "0")
      current_time=$(date +%s)
      age_hours=$(( (current_time - dir_age) / 3600 ))
      if [ $age_hours -lt 24 ]; then
        DIRS_CREATED+=("${dir#$PROJECT_ROOT/}")
      fi
    fi
  done < <(find "$PROJECT_ROOT/lib" -type d 2>/dev/null)
fi

# 集計
NUM_CREATED=${#FILES_CREATED[@]}
NUM_MODIFIED=${#FILES_MODIFIED[@]}
NUM_DELETED=${#FILES_DELETED[@]}
NUM_DIRS=${#DIRS_CREATED[@]}
TOTAL_CHANGES=$(( NUM_CREATED + NUM_MODIFIED + NUM_DELETED + NUM_DIRS ))

# ========================================
# 結果表示
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 変更サマリー${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "総変更数: ${YELLOW}$TOTAL_CHANGES${NC}"
echo -e "ファイル作成: ${GREEN}$NUM_CREATED${NC}"
echo -e "ファイル変更: ${BLUE}$NUM_MODIFIED${NC}"
echo -e "ファイル削除: ${RED}$NUM_DELETED${NC}"
echo -e "ディレクトリ作成: ${YELLOW}$NUM_DIRS${NC}"

# ========================================
# YAML 出力
# ========================================
{
  echo "# change_history.yaml"
  echo "# 自動生成 — 手動編集しないでください"
  echo "# 生成日時: $CURRENT_TIME"
  echo ""
  echo "last_detected: \"$CURRENT_TIME\""
  echo "summary:"
  echo "  total: $TOTAL_CHANGES"
  echo "  created: $NUM_CREATED"
  echo "  modified: $NUM_MODIFIED"
  echo "  deleted: $NUM_DELETED"
  echo "  directories_created: $NUM_DIRS"

  if [ $TOTAL_CHANGES -eq 0 ]; then
    echo "changes: []"
  else
    echo "changes:"
    for file in "${FILES_CREATED[@]:-}"; do
      [ -n "$file" ] && echo "  - timestamp: \"$CURRENT_TIME\""
      [ -n "$file" ] && echo "    type: \"created\""
      [ -n "$file" ] && echo "    path: \"$file\""
    done
    for file in "${FILES_MODIFIED[@]:-}"; do
      [ -n "$file" ] && echo "  - timestamp: \"$CURRENT_TIME\""
      [ -n "$file" ] && echo "    type: \"modified\""
      [ -n "$file" ] && echo "    path: \"$file\""
    done
    for file in "${FILES_DELETED[@]:-}"; do
      [ -n "$file" ] && echo "  - timestamp: \"$CURRENT_TIME\""
      [ -n "$file" ] && echo "    type: \"deleted\""
      [ -n "$file" ] && echo "    path: \"$file\""
    done
    for dir in "${DIRS_CREATED[@]:-}"; do
      [ -n "$dir" ] && echo "  - timestamp: \"$CURRENT_TIME\""
      [ -n "$dir" ] && echo "    type: \"directory_created\""
      [ -n "$dir" ] && echo "    path: \"$dir\""
    done
  fi
} > "$OUTPUT_YAML"

echo ""
echo -e "${GREEN}✅ YAML 生成完了: ${OUTPUT_YAML}${NC}"

# ========================================
# Preview MD 出力
# ========================================
{
  echo "# 変更履歴"
  echo ""
  echo "> 自動生成 — 手動編集しないでください"
  echo "> 検出日時: $CURRENT_TIME"
  echo ""
  echo "## サマリー"
  echo ""
  echo "| 種別 | 件数 |"
  echo "|------|------|"
  echo "| ファイル作成 | $NUM_CREATED |"
  echo "| ファイル変更 | $NUM_MODIFIED |"
  echo "| ファイル削除 | $NUM_DELETED |"
  echo "| ディレクトリ作成 | $NUM_DIRS |"
  echo "| **合計** | **$TOTAL_CHANGES** |"

  if [ $TOTAL_CHANGES -eq 0 ]; then
    echo ""
    echo "変更はありません。"
  else
    if [ $NUM_CREATED -gt 0 ]; then
      echo ""
      echo "## 📄 ファイル作成 (${NUM_CREATED}件)"
      echo ""
      for file in "${FILES_CREATED[@]}"; do
        echo "- \`$file\`"
      done
    fi
    if [ $NUM_MODIFIED -gt 0 ]; then
      echo ""
      echo "## ✏️ ファイル変更 (${NUM_MODIFIED}件)"
      echo ""
      for file in "${FILES_MODIFIED[@]}"; do
        echo "- \`$file\`"
      done
    fi
    if [ $NUM_DELETED -gt 0 ]; then
      echo ""
      echo "## 🗑️ ファイル削除 (${NUM_DELETED}件)"
      echo ""
      for file in "${FILES_DELETED[@]}"; do
        echo "- \`$file\`"
      done
    fi
    if [ $NUM_DIRS -gt 0 ]; then
      echo ""
      echo "## 📁 ディレクトリ作成 (${NUM_DIRS}件)"
      echo ""
      for dir in "${DIRS_CREATED[@]}"; do
        echo "- \`$dir\`"
      done
    fi
  fi
} > "$OUTPUT_MD"

echo -e "${GREEN}✅ プレビュー MD 生成完了: ${OUTPUT_MD}${NC}"
echo ""
echo -e "${GREEN}🎉 生成完了！${NC}"
echo -e "  YAML: ${OUTPUT_YAML}"
echo -e "  MD:   ${OUTPUT_MD}"
