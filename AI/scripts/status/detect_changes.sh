#!/usr/bin/env bash
set -Eeuo pipefail

# detect_changes.sh
# プロジェクト内のファイル変更を検出して change_history.md に記録するスクリプト
# Git を使用して前回からの差分を検出します

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CHANGE_LOG="$PROJECT_ROOT/AI/logs/change_history.md"
SNAPSHOT_FILE="$PROJECT_ROOT/.agent/.file_snapshot"

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --clear-history     変更履歴をクリア（注意して使用）"
  echo "  --archive-old DAYS  指定日数以上前の履歴をアーカイブ"
  echo "  -h, --help         このヘルプを表示"
  exit 0
}

CLEAR_HISTORY=false
ARCHIVE_DAYS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clear-history)
      CLEAR_HISTORY=true; shift;;
    --archive-old)
      ARCHIVE_DAYS=$2; shift 2;;
    -h|--help)
      usage;;
    *)
      echo "Unknown option: $1"
      usage;;
  esac
done

echo -e "${BLUE}🔍 ファイル変更を検出中...${NC}\n"

# Git リポジトリかチェック
if [ ! -d "$PROJECT_ROOT/.git" ]; then
  echo -e "${YELLOW}⚠ Gitリポジトリではありません。簡易モードで動作します。${NC}"
  USE_GIT=false
else
  USE_GIT=true
fi

# 現在時刻
CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# .agent ディレクトリを作成
mkdir -p "$PROJECT_ROOT/.agent"

# 変更を検出
declare -a FILES_CREATED
declare -a FILES_MODIFIED
declare -a FILES_DELETED
declare -a DIRS_CREATED

if [ "$USE_GIT" = true ]; then
  # Git を使用して変更を検出
  
  # 未追跡ファイル（新規作成）
  while IFS= read -r file; do
    if [ -n "$file" ]; then
      FILES_CREATED+=("$file")
    fi
  done < <(git ls-files --others --exclude-standard)
  
  # 変更されたファイル
  while IFS= read -r file; do
    if [ -n "$file" ]; then
      FILES_MODIFIED+=("$file")
    fi
  done < <(git diff --name-only)
  
  # ステージングエリアの変更
  while IFS= read -r file; do
    if [ -n "$file" ] && [[ ! " ${FILES_MODIFIED[@]:-} " =~ " ${file} " ]]; then
      FILES_MODIFIED+=("$file")
    fi
  done < <(git diff --cached --name-only)
  
else
  # Git がない場合は、スナップショットと比較
  
  if [ -f "$SNAPSHOT_FILE" ]; then
    # 前回のスナップショットと比較
    # 簡易的な実装（ファイル一覧の差分）
    
    # 現在のファイル一覧を取得
    find "$PROJECT_ROOT/lib" -type f 2>/dev/null | sort > /tmp/current_files.txt || true
    
    # 新規ファイルを検出
    while IFS= read -r file; do
      if ! grep -q "^$file$" "$SNAPSHOT_FILE" 2>/dev/null; then
        rel_path="${file#$PROJECT_ROOT/}"
        FILES_CREATED+=("$rel_path")
      fi
    done < /tmp/current_files.txt
    
    # 削除ファイルを検出
    while IFS= read -r file; do
      if [ ! -f "$file" ]; then
        rel_path="${file#$PROJECT_ROOT/}"
        FILES_DELETED+=("$rel_path")
      fi
    done < "$SNAPSHOT_FILE"
    
    rm -f /tmp/current_files.txt
  fi
  
  # 新しいスナップショットを保存
  find "$PROJECT_ROOT/lib" -type f 2>/dev/null | sort > "$SNAPSHOT_FILE" || true
fi

# lib/ 配下の新規ディレクトリを検出
if [ -d "$PROJECT_ROOT/lib" ]; then
  while IFS= read -r dir; do
    if [ -d "$dir" ]; then
      # 最近作成されたディレクトリ（24時間以内）
      if [ $(uname) = "Darwin" ]; then
        # macOS
        dir_age=$(stat -f %B "$dir")
      else
        # Linux
        dir_age=$(stat -c %Y "$dir")
      fi
      
      current_time=$(date +%s)
      age_hours=$(( (current_time - dir_age) / 3600 ))
      
      if [ $age_hours -lt 24 ]; then
        rel_path="${dir#$PROJECT_ROOT/}"
        DIRS_CREATED+=("$rel_path")
      fi
    fi
  done < <(find "$PROJECT_ROOT/lib" -type d 2>/dev/null)
fi

# 結果表示
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 変更サマリー${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 各配列の要素数を安全に取得
NUM_CREATED=0
NUM_MODIFIED=0
NUM_DELETED=0
NUM_DIRS=0

[ -v FILES_CREATED ] && NUM_CREATED=${#FILES_CREATED[@]} || NUM_CREATED=0
[ -v FILES_MODIFIED ] && NUM_MODIFIED=${#FILES_MODIFIED[@]} || NUM_MODIFIED=0
[ -v FILES_DELETED ] && NUM_DELETED=${#FILES_DELETED[@]} || NUM_DELETED=0
[ -v DIRS_CREATED ] && NUM_DIRS=${#DIRS_CREATED[@]} || NUM_DIRS=0

TOTAL_CHANGES=$(( NUM_CREATED + NUM_MODIFIED + NUM_DELETED + NUM_DIRS ))

echo -e "総変更数: ${YELLOW}$TOTAL_CHANGES${NC}"
echo -e "ファイル作成: ${GREEN}$NUM_CREATED${NC}"
echo -e "ファイル変更: ${BLUE}$NUM_MODIFIED${NC}"
echo -e "ファイル削除: ${RED}$NUM_DELETED${NC}"
echo -e "ディレクトリ作成: ${YELLOW}$NUM_DIRS${NC}"

if [ $TOTAL_CHANGES -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✅ 変更はありません${NC}"
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 0
fi

echo ""

# change_history.md に記録
{
  echo ""
  echo "## [$CURRENT_TIME] 変更検出"
  echo ""
  
  if [ $NUM_CREATED -gt 0 ]; then
    echo "### 📄 ファイル作成 (${NUM_CREATED}件)"
    echo ""
    for file in "${FILES_CREATED[@]}"; do
      echo "- \`$file\`"
    done
    echo ""
  fi
  
  if [ $NUM_MODIFIED -gt 0 ]; then
    echo "### ✏️ ファイル変更 (${NUM_MODIFIED}件)"
    echo ""
    for file in "${FILES_MODIFIED[@]}"; do
      echo "- \`$file\`"
    done
    echo ""
  fi
  
  if [ $NUM_DELETED -gt 0 ]; then
    echo "### 🗑️ ファイル削除 (${NUM_DELETED}件)"
    echo ""
    for file in "${FILES_DELETED[@]}"; do
      echo "- \`$file\`"
    done
    echo ""
  fi
  
  if [ $NUM_DIRS -gt 0 ]; then
    echo "### 📁 ディレクトリ作成 (${NUM_DIRS}件)"
    echo ""
    for dir in "${DIRS_CREATED[@]}"; do
      echo "- \`$dir\`"
    done
    echo ""
  fi
  
  echo "### 💡 推定される作業内容"
  echo ""
  echo "(AIエージェントが推定)"
  echo ""
  
  echo "### 🔗 関連情報"
  echo ""
  echo "- 検出時刻: $CURRENT_TIME"
  echo "- 総変更数: $TOTAL_CHANGES"
  echo ""
  
  echo "---"
} >> "$CHANGE_LOG"

echo -e "${GREEN}✅ 変更を記録しました: $CHANGE_LOG${NC}"
echo ""
echo -e "${YELLOW}💡 AIエージェントはこのファイルを確認して変更を把握できます${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit 0
