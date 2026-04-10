#!/bin/bash

#
# Flutter Feature Generator Script
# ---------------------------------
# このスクリプトは、Flutterプロジェクトのルートディレクトリで実行してください。
# 対話形式でフィーチャー名と権限レベルを尋ね、
# 定義されたクリーンアーキテクチャに基づいてディレクトリ構造を自動生成します。
# Core の生成は AI/scripts/generate/generate_core.sh に分割されました。
#

# --- 初期設定 ---
# 色付けのためのエスケープシーケンス
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -n, --name NAME               Feature name (e.g., UserProfile or order_history)"
  echo "  -p, --permission NUM_OR_STR   Permission (1|2|3|4 or admin|user|shared|direct)."
  echo "  -l, --permission-level LEVEL  Same as --permission but uses explicit level string."
  echo "  -y, --yes                     Skip confirmation prompt (non-interactive)."
  echo "  -h, --help                    Show this help."
  echo ""
  echo "Note: Core scaffolding is now in AI/scripts/generate/generate_core.sh"
  exit 0
}

# --- 引数パース（追加） ---
CONFIRM=""  # if set to 'y' then skip confirmation prompt
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)
      FEATURE_NAME_INPUT="$2"
      shift 2
      ;;
    -p|--permission)
      PERMISSION_CHOICE="$2"
      shift 2
      ;;
    -l|--permission-level)
      PERMISSION_LEVEL="$2"
      shift 2
      ;;
    -y|--yes)
      CONFIRM="y"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

echo -e "${GREEN}✨ Flutterフィーチャー生成スクリプトを開始します ✨${NC}"

# --- フィーチャー名の入力 ---
# If not provided via args, prompt as before
if [ -z "$FEATURE_NAME_INPUT" ]; then
  echo -n "Enter the feature name (e.g., UserProfile, order_history): "
  read FEATURE_NAME_INPUT
fi

# 入力が空の場合は終了
if [ -z "$FEATURE_NAME_INPUT" ]; then
  echo "❌エラー: フィーチャー名が入力されていません。処理を中断します。"
  exit 1
fi

# --- 権限レベルの選択 ---
# If PERMISSION_LEVEL already specified via --permission-level use it.
if [ -n "$PERMISSION_LEVEL" ]; then
  # normalize to lowercase
  PERMISSION_LEVEL=$(echo "$PERMISSION_LEVEL" | tr '[:upper:]' '[:lower:]')
else
  # If a numeric or string permission was provided via -p/--permission, interpret it.
  if [ -n "$PERMISSION_CHOICE" ]; then
    case "$PERMISSION_CHOICE" in
      1) PERMISSION_LEVEL="admin" ;;
      2) PERMISSION_LEVEL="user" ;;
      3) PERMISSION_LEVEL="shared" ;;
      4) PERMISSION_LEVEL="direct" ;;
      admin|Admin|ADMIN) PERMISSION_LEVEL="admin" ;;
      user|User|USER) PERMISSION_LEVEL="user" ;;
      shared|Shared|SHARED) PERMISSION_LEVEL="shared" ;;
      direct|Direct|DIRECT) PERMISSION_LEVEL="direct" ;;
      *)
        echo "Unknown permission: ${PERMISSION_CHOICE}"
        usage
        ;;
    esac
  else
    # fallback to interactive prompt (existing behavior)
    echo "Select the permission level:"
    echo "  1) admin"
    echo "  2) user"
    echo "  3) shared"
    echo "  4) direct (features下に直接配置)"
    echo -n "Enter number (default: 2): "
    read PERMISSION_CHOICE
    case $PERMISSION_CHOICE in
      1)
        PERMISSION_LEVEL="admin"
        ;;
      3)
        PERMISSION_LEVEL="shared"
        ;;
      4)
        PERMISSION_LEVEL="direct"
        ;;
      *) # 2またはデフォルト
        PERMISSION_LEVEL="user"
        ;;
    esac
  fi
fi

echo -e "-> 選択された権限レベル: ${YELLOW}${PERMISSION_LEVEL}${NC}"

# --- パス用の変数を作成 ---
# 入力されたフィーチャー名をsnake_caseに変換 (例: UserProfile -> user_profile)
# 1. 大文字を小文字に変換
# 2. スペースやハイフンをアンダースコアに置換
FEATURE_NAME_SNAKE=$(echo "$FEATURE_NAME_INPUT" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g' | sed 's/-/_/g')

# パスの設定（directの場合はfeatures下に直接配置）
if [ "$PERMISSION_LEVEL" = "direct" ]; then
  BASE_PATH="lib/features/${FEATURE_NAME_SNAKE}"
else
  BASE_PATH="lib/features/${PERMISSION_LEVEL}/${FEATURE_NAME_SNAKE}"
fi

echo -e "-> 生成パス: ${YELLOW}${BASE_PATH}${NC}"
echo "-----------------------------------------------------"

# If CONFIRM is not set to 'y' by args, ask interactively (existing behavior)
if [ "$CONFIRM" != "y" ]; then
  echo "以下のディレクトリ構造を生成します。よろしいですか？ (y/n)"
  read CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    echo "処理を中断しました。"
    exit 0
  fi
fi
echo "-----------------------------------------------------"

# --- ディレクトリの一括生成 ---
echo "🚀 ディレクトリを生成中..."

# Featureディレクトリ
mkdir -p "${BASE_PATH}/1_domain/1_entities"
mkdir -p "${BASE_PATH}/1_domain/2_repositories"
mkdir -p "${BASE_PATH}/1_domain/3_usecases"
mkdir -p "${BASE_PATH}/1_domain/exceptions"

mkdir -p "${BASE_PATH}/3_application/3_notifiers"
mkdir -p "${BASE_PATH}/3_application/2_providers"
mkdir -p "${BASE_PATH}/3_application/1_states"

mkdir -p "${BASE_PATH}/2_infrastructure/2_data_sources/1_local"
mkdir -p "${BASE_PATH}/2_infrastructure/2_data_sources/1_local/exceptions"
mkdir -p "${BASE_PATH}/2_infrastructure/2_data_sources/2_remote"
mkdir -p "${BASE_PATH}/2_infrastructure/2_data_sources/2_remote/exceptions"
mkdir -p "${BASE_PATH}/2_infrastructure/1_models"
mkdir -p "${BASE_PATH}/2_infrastructure/3_repositories"

mkdir -p "${BASE_PATH}/4_presentation/2_pages"
mkdir -p "${BASE_PATH}/4_presentation/1_widgets/1_atoms"
mkdir -p "${BASE_PATH}/4_presentation/1_widgets/2_molecules"
mkdir -p "${BASE_PATH}/4_presentation/1_widgets/3_organisms"

# --- 完了メッセージ ---
echo -e "${GREEN}✅ 完了: フィーチャー「${FEATURE_NAME_SNAKE}」のディレクトリが正常に作成されました！${NC}"

