#!/usr/bin/env bash
set -Eeuo pipefail

# generate_plan.sh
# feature_request.yaml を読み込み、命名規則に基づいて
# plan_architecture.yaml と preview/plan_architecture.md を生成する
#
# 使い方:
#   ./AI/scripts/generate/generate_plan.sh
#   ./AI/scripts/generate/generate_plan.sh --input path/to/feature_request.yaml

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
NC='\033[0m'

# ========================================
# パス設定
# ========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

INPUT_FILE="$PROJECT_ROOT/AI/specs/feature_request.yaml"
OUTPUT_YAML="$PROJECT_ROOT/AI/snapshots/plan_architecture.yaml"
OUTPUT_MD="$PROJECT_ROOT/AI/snapshots/preview/plan_architecture.md"

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
    --input|-i)
      INPUT_FILE="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--input path/to/feature_request.yaml]"
      echo ""
      echo "Options:"
      echo "  -i, --input   入力ファイルのパス（デフォルト: AI/specs/feature_request.yaml）"
      echo "  -h, --help    このヘルプを表示"
      exit 0
      ;;
    *)
      echo -e "${RED}❌ 不明なオプション: $1${NC}"
      exit 1
      ;;
  esac
done

# ========================================
# 入力ファイル存在確認
# ========================================
if [ ! -f "$INPUT_FILE" ]; then
  echo -e "${RED}❌ 入力ファイルが見つかりません: $INPUT_FILE${NC}"
  exit 1
fi

# ========================================
# バリデーション関数
# ========================================
ERRORS=()

# snake_case チェック
validate_snake_case() {
  local value="$1"
  local context="$2"
  if [[ ! "$value" =~ ^[a-z][a-z0-9_]*$ ]]; then
    ERRORS+=("${context}: '${value}' は snake_case ではありません")
  fi
}

# permission チェック
validate_permission() {
  local value="$1"
  local context="$2"
  if [[ ! "$value" =~ ^(admin|user|shared|direct)$ ]]; then
    ERRORS+=("${context}: '${value}' は有効な permission ではありません（admin/user/shared/direct）")
  fi
}

# ========================================
# Step 1: 入力バリデーション
# ========================================
echo -e "${BLUE}🔍 入力ファイルを検証中: ${INPUT_FILE}${NC}"

# プロジェクト名の検証
PROJECT_NAME=$(yq '.project.name' "$INPUT_FILE")
PROJECT_VERSION=$(yq '.project.version' "$INPUT_FILE")

if [ "$PROJECT_NAME" = "null" ] || [ -z "$PROJECT_NAME" ] || [ "$PROJECT_NAME" = '""' ]; then
  ERRORS+=("project.name が未設定です")
fi
if [ "$PROJECT_VERSION" = "null" ] || [ -z "$PROJECT_VERSION" ] || [ "$PROJECT_VERSION" = '""' ]; then
  ERRORS+=("project.version が未設定です")
fi

# フィーチャー数の確認
FEATURE_COUNT=$(yq '.features | length' "$INPUT_FILE")
if [ "$FEATURE_COUNT" -eq 0 ]; then
  ERRORS+=("features が空です（1つ以上のフィーチャーが必要）")
fi

# 各フィーチャーのバリデーション
for (( i=0; i<FEATURE_COUNT; i++ )); do
  # 名前
  NAME=$(yq ".features[$i].name" "$INPUT_FILE")
  if [ "$NAME" = "null" ] || [ -z "$NAME" ]; then
    ERRORS+=("features[$i].name が未設定です")
  else
    validate_snake_case "$NAME" "features[$i].name"
  fi

  # permission
  PERM=$(yq ".features[$i].permission" "$INPUT_FILE")
  if [ "$PERM" = "null" ] || [ -z "$PERM" ]; then
    ERRORS+=("features[$i].permission が未設定です")
  else
    validate_permission "$PERM" "features[$i].permission"
  fi

  # description
  DESC=$(yq ".features[$i].description" "$INPUT_FILE")
  if [ "$DESC" = "null" ] || [ -z "$DESC" ]; then
    ERRORS+=("features[$i].description が未設定です")
  fi

  # entities（必須: 1つ以上）
  ENTITY_COUNT=$(yq ".features[$i].entities | length" "$INPUT_FILE")
  if [ "$ENTITY_COUNT" -eq 0 ]; then
    ERRORS+=("features[$i].entities が空です（1つ以上のエンティティが必要）")
  fi
  for (( j=0; j<ENTITY_COUNT; j++ )); do
    ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
    validate_snake_case "$ENTITY" "features[$i].entities[$j]"
  done

  # usecases（オプション、あれば snake_case チェック）
  USECASE_COUNT=$(yq ".features[$i].usecases | length" "$INPUT_FILE")
  for (( j=0; j<USECASE_COUNT; j++ )); do
    UC=$(yq ".features[$i].usecases[$j]" "$INPUT_FILE")
    validate_snake_case "$UC" "features[$i].usecases[$j]"
  done

  # pages（オプション、あれば snake_case チェック）
  PAGE_COUNT=$(yq ".features[$i].pages | length" "$INPUT_FILE")
  for (( j=0; j<PAGE_COUNT; j++ )); do
    PAGE=$(yq ".features[$i].pages[$j]" "$INPUT_FILE")
    validate_snake_case "$PAGE" "features[$i].pages[$j]"
  done

  # widgets（オプション、あれば snake_case チェック）
  for widget_type in atoms molecules organisms; do
    WIDGET_COUNT=$(yq ".features[$i].widgets.${widget_type} | length" "$INPUT_FILE")
    for (( j=0; j<WIDGET_COUNT; j++ )); do
      WIDGET=$(yq ".features[$i].widgets.${widget_type}[$j]" "$INPUT_FILE")
      validate_snake_case "$WIDGET" "features[$i].widgets.${widget_type}[$j]"
    done
  done
done

# Core のバリデーション（オプション、あれば snake_case チェック）
for core_field in "core.routing.files" "core.routing.paths" "core.theme.files" "core.database.tables"; do
  COUNT=$(yq ".${core_field} | length" "$INPUT_FILE")
  for (( j=0; j<COUNT; j++ )); do
    VAL=$(yq ".${core_field}[$j]" "$INPUT_FILE")
    validate_snake_case "$VAL" "${core_field}[$j]"
  done
done

# エラーがあれば中断
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo -e "\n${RED}❌ バリデーションエラー: ${#ERRORS[@]} 件${NC}\n"
  for err in "${ERRORS[@]}"; do
    echo -e "  ${RED}•${NC} $err"
  done
  echo -e "\n${YELLOW}入力ファイルを修正してから再実行してください${NC}"
  exit 1
fi

echo -e "${GREEN}✅ バリデーション通過${NC}\n"

# ========================================
# Step 2: plan_architecture.yaml の生成
# ========================================
echo -e "${BLUE}📐 plan_architecture.yaml を生成中...${NC}"

CURRENT_TIME=$(date '+%Y-%m-%dT%H:%M:%S%z')

# YAML ヘッダーを出力
{
  echo "# plan_architecture.yaml"
  echo "# 自動生成 — 手動編集しないでください"
  echo "# 生成元: $(basename "$INPUT_FILE")"
  echo "# 生成日時: $CURRENT_TIME"
  echo ""
  echo "project:"
  echo "  name: \"$PROJECT_NAME\""
  echo "  version: \"$PROJECT_VERSION\""
  echo ""
  echo "structure:"
  echo "  lib:"
  echo "    main.dart:"
  echo "      description: \"アプリケーションのエントリポイント\""
  echo "    app.dart:"
  echo "      description: \"最上位ウィジェット（MaterialApp）\""
} > "$OUTPUT_YAML"

# ── Core 層の生成 ──
{
  echo ""
  echo "    core:"

  # routing
  ROUTING_FILES_COUNT=$(yq '.core.routing.files | length' "$INPUT_FILE")
  ROUTING_PATHS_COUNT=$(yq '.core.routing.paths | length' "$INPUT_FILE")
  if [ "$ROUTING_FILES_COUNT" -gt 0 ] || [ "$ROUTING_PATHS_COUNT" -gt 0 ]; then
    echo "      routing:"
    for (( j=0; j<ROUTING_FILES_COUNT; j++ )); do
      FILE=$(yq ".core.routing.files[$j]" "$INPUT_FILE")
      echo "        ${FILE}.dart:"
      echo "          description: \"ルーティング設定\""
    done
    if [ "$ROUTING_PATHS_COUNT" -gt 0 ]; then
      echo "        path:"
      for (( j=0; j<ROUTING_PATHS_COUNT; j++ )); do
        PATH_FILE=$(yq ".core.routing.paths[$j]" "$INPUT_FILE")
        echo "          ${PATH_FILE}.dart:"
        echo "            description: \"パス定義\""
      done
    fi
  fi

  # theme
  THEME_COUNT=$(yq '.core.theme.files | length' "$INPUT_FILE")
  if [ "$THEME_COUNT" -gt 0 ]; then
    echo "      theme:"
    for (( j=0; j<THEME_COUNT; j++ )); do
      FILE=$(yq ".core.theme.files[$j]" "$INPUT_FILE")
      echo "        ${FILE}.dart:"
      echo "          description: \"テーマ設定\""
    done
  fi

  # database
  TABLE_COUNT=$(yq '.core.database.tables | length' "$INPUT_FILE")
  if [ "$TABLE_COUNT" -gt 0 ]; then
    echo "      database:"
    echo "        database.dart:"
    echo "          description: \"データベース接続設定\""
    echo "        table:"
    for (( j=0; j<TABLE_COUNT; j++ )); do
      TABLE=$(yq ".core.database.tables[$j]" "$INPUT_FILE")
      echo "          ${TABLE}_table.dart:"
      echo "            description: \"${TABLE}テーブル定義\""
    done
  fi

  # exceptions（常に生成）
  echo "      exceptions:"
  echo "        app_exception.dart:"
  echo "          description: \"共通例外クラス\""

} >> "$OUTPUT_YAML"

# ── Features 層の生成 ──
{
  echo ""
  echo "    features:"
} >> "$OUTPUT_YAML"

for (( i=0; i<FEATURE_COUNT; i++ )); do
  NAME=$(yq ".features[$i].name" "$INPUT_FILE")
  PERM=$(yq ".features[$i].permission" "$INPUT_FILE")
  DESC=$(yq ".features[$i].description" "$INPUT_FILE")

  ENTITY_COUNT=$(yq ".features[$i].entities | length" "$INPUT_FILE")
  USECASE_COUNT=$(yq ".features[$i].usecases | length" "$INPUT_FILE")
  LOCAL_DS=$(yq ".features[$i].data_sources.local // true" "$INPUT_FILE")
  REMOTE_DS=$(yq ".features[$i].data_sources.remote // false" "$INPUT_FILE")
  PAGE_COUNT=$(yq ".features[$i].pages | length" "$INPUT_FILE")
  ATOM_COUNT=$(yq ".features[$i].widgets.atoms | length" "$INPUT_FILE")
  MOLECULE_COUNT=$(yq ".features[$i].widgets.molecules | length" "$INPUT_FILE")
  ORGANISM_COUNT=$(yq ".features[$i].widgets.organisms | length" "$INPUT_FILE")

  {
    echo "      ${PERM}:"
    echo "        ${NAME}:"
    echo "          _meta:"
    echo "            description: \"${DESC}\""
    echo "            permission: ${PERM}"

    # 1_domain
    echo "          1_domain:"
    echo "            1_entities:"
    for (( j=0; j<ENTITY_COUNT; j++ )); do
      ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
      echo "              ${ENTITY}_entity.dart:"
      echo "                description: \"${ENTITY}エンティティ（@freezed）\""
    done
    echo "            2_repositories:"
    for (( j=0; j<ENTITY_COUNT; j++ )); do
      ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
      echo "              ${ENTITY}_repository.dart:"
      echo "                description: \"${ENTITY}リポジトリインターフェース\""
    done
    if [ "$USECASE_COUNT" -gt 0 ]; then
      echo "            3_usecases:"
      for (( j=0; j<USECASE_COUNT; j++ )); do
        UC=$(yq ".features[$i].usecases[$j]" "$INPUT_FILE")
        echo "              ${UC}_usecase.dart:"
        echo "                description: \"${UC}ユースケース\""
      done
    fi
    echo "            exceptions:"
    echo "              ${NAME}_exceptions.dart:"
    echo "                description: \"${NAME}ドメイン例外\""

    # 2_infrastructure
    echo "          2_infrastructure:"
    echo "            1_models:"
    for (( j=0; j<ENTITY_COUNT; j++ )); do
      ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
      echo "              ${ENTITY}_model.dart:"
      echo "                description: \"${ENTITY}データモデル\""
    done
    echo "            2_data_sources:"
    if [ "$LOCAL_DS" = "true" ]; then
      echo "              1_local:"
      for (( j=0; j<ENTITY_COUNT; j++ )); do
        ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
        echo "                ${ENTITY}_local_data_source.dart:"
        echo "                  description: \"${ENTITY}ローカルデータソース\""
      done
    fi
    if [ "$REMOTE_DS" = "true" ]; then
      echo "              2_remote:"
      for (( j=0; j<ENTITY_COUNT; j++ )); do
        ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
        echo "                ${ENTITY}_remote_data_source.dart:"
        echo "                  description: \"${ENTITY}リモートデータソース\""
      done
    fi
    echo "            3_repositories:"
    for (( j=0; j<ENTITY_COUNT; j++ )); do
      ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
      echo "              ${ENTITY}_repository_impl.dart:"
      echo "                description: \"${ENTITY}リポジトリ実装\""
    done

    # 3_application（フィーチャー名ベースで生成）
    echo "          3_application:"
    echo "            1_states:"
    echo "              ${NAME}_state.dart:"
    echo "                description: \"${NAME}状態クラス（@freezed）\""
    echo "            2_providers:"
    echo "              ${NAME}_providers.dart:"
    echo "                description: \"${NAME}DIプロバイダー\""
    echo "            3_notifiers:"
    echo "              ${NAME}_notifier.dart:"
    echo "                description: \"${NAME}Notifier（@riverpod）\""

    # 4_presentation
    echo "          4_presentation:"
    if [ "$ATOM_COUNT" -gt 0 ] || [ "$MOLECULE_COUNT" -gt 0 ] || [ "$ORGANISM_COUNT" -gt 0 ]; then
      echo "            1_widgets:"
      if [ "$ATOM_COUNT" -gt 0 ]; then
        echo "              1_atoms:"
        for (( j=0; j<ATOM_COUNT; j++ )); do
          WIDGET=$(yq ".features[$i].widgets.atoms[$j]" "$INPUT_FILE")
          echo "                ${WIDGET}_atom.dart:"
          echo "                  description: \"${WIDGET}（Atom）\""
        done
      fi
      if [ "$MOLECULE_COUNT" -gt 0 ]; then
        echo "              2_molecules:"
        for (( j=0; j<MOLECULE_COUNT; j++ )); do
          WIDGET=$(yq ".features[$i].widgets.molecules[$j]" "$INPUT_FILE")
          echo "                ${WIDGET}_molecule.dart:"
          echo "                  description: \"${WIDGET}（Molecule）\""
        done
      fi
      if [ "$ORGANISM_COUNT" -gt 0 ]; then
        echo "              3_organisms:"
        for (( j=0; j<ORGANISM_COUNT; j++ )); do
          WIDGET=$(yq ".features[$i].widgets.organisms[$j]" "$INPUT_FILE")
          echo "                ${WIDGET}_organism.dart:"
          echo "                  description: \"${WIDGET}（Organism）\""
        done
      fi
    fi
    if [ "$PAGE_COUNT" -gt 0 ]; then
      echo "            2_pages:"
      for (( j=0; j<PAGE_COUNT; j++ )); do
        PAGE=$(yq ".features[$i].pages[$j]" "$INPUT_FILE")
        echo "              ${PAGE}_page.dart:"
        echo "                description: \"${PAGE}ページ\""
      done
    fi

  } >> "$OUTPUT_YAML"
done

echo -e "${GREEN}✅ YAML 生成完了: ${OUTPUT_YAML}${NC}"

# ========================================
# Step 3: preview MD の生成
# ========================================
echo -e "${BLUE}📝 プレビュー MD を生成中...${NC}"

{
  echo "# 構造計画書（plan_architecture）"
  echo ""
  echo "> 自動生成 — 手動編集しないでください"
  echo "> 生成元: $(basename "$INPUT_FILE")"
  echo "> 生成日時: $CURRENT_TIME"
  echo ""
  echo "## プロジェクト情報"
  echo ""
  echo "- **名前**: $PROJECT_NAME"
  echo "- **バージョン**: $PROJECT_VERSION"
  echo ""
  echo "---"
  echo ""
  echo "## ディレクトリ構造"
  echo ""
  echo '```'
  echo "lib/"
  echo "├── main.dart"
  echo "├── app.dart"
  echo "├── core/"

  # Core のツリー表示
  ROUTING_FILES_COUNT=$(yq '.core.routing.files | length' "$INPUT_FILE")
  ROUTING_PATHS_COUNT=$(yq '.core.routing.paths | length' "$INPUT_FILE")
  THEME_COUNT=$(yq '.core.theme.files | length' "$INPUT_FILE")
  TABLE_COUNT=$(yq '.core.database.tables | length' "$INPUT_FILE")

  if [ "$ROUTING_FILES_COUNT" -gt 0 ] || [ "$ROUTING_PATHS_COUNT" -gt 0 ]; then
    echo "│   ├── routing/"
    for (( j=0; j<ROUTING_FILES_COUNT; j++ )); do
      FILE=$(yq ".core.routing.files[$j]" "$INPUT_FILE")
      echo "│   │   ├── ${FILE}.dart"
    done
    if [ "$ROUTING_PATHS_COUNT" -gt 0 ]; then
      echo "│   │   └── path/"
      for (( j=0; j<ROUTING_PATHS_COUNT; j++ )); do
        PATH_FILE=$(yq ".core.routing.paths[$j]" "$INPUT_FILE")
        if [ "$j" -eq $((ROUTING_PATHS_COUNT-1)) ]; then
          echo "│   │       └── ${PATH_FILE}.dart"
        else
          echo "│   │       ├── ${PATH_FILE}.dart"
        fi
      done
    fi
  fi
  if [ "$THEME_COUNT" -gt 0 ]; then
    echo "│   ├── theme/"
    for (( j=0; j<THEME_COUNT; j++ )); do
      FILE=$(yq ".core.theme.files[$j]" "$INPUT_FILE")
      echo "│   │   └── ${FILE}.dart"
    done
  fi
  if [ "$TABLE_COUNT" -gt 0 ]; then
    echo "│   ├── database/"
    echo "│   │   ├── database.dart"
    echo "│   │   └── table/"
    for (( j=0; j<TABLE_COUNT; j++ )); do
      TABLE=$(yq ".core.database.tables[$j]" "$INPUT_FILE")
      if [ "$j" -eq $((TABLE_COUNT-1)) ]; then
        echo "│   │       └── ${TABLE}_table.dart"
      else
        echo "│   │       ├── ${TABLE}_table.dart"
      fi
    done
  fi
  echo "│   └── exceptions/"
  echo "│       └── app_exception.dart"

  echo "└── features/"

  # Features のツリー表示
  for (( i=0; i<FEATURE_COUNT; i++ )); do
    NAME=$(yq ".features[$i].name" "$INPUT_FILE")
    PERM=$(yq ".features[$i].permission" "$INPUT_FILE")

    ENTITY_COUNT=$(yq ".features[$i].entities | length" "$INPUT_FILE")
    USECASE_COUNT=$(yq ".features[$i].usecases | length" "$INPUT_FILE")
    LOCAL_DS=$(yq ".features[$i].data_sources.local // true" "$INPUT_FILE")
    REMOTE_DS=$(yq ".features[$i].data_sources.remote // false" "$INPUT_FILE")
    PAGE_COUNT=$(yq ".features[$i].pages | length" "$INPUT_FILE")

    echo "    └── ${PERM}/"
    echo "        └── ${NAME}/"
    echo "            ├── 1_domain/"
    echo "            │   ├── 1_entities/"
    for (( j=0; j<ENTITY_COUNT; j++ )); do
      ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
      echo "            │   │   └── ${ENTITY}_entity.dart"
    done
    echo "            │   ├── 2_repositories/"
    for (( j=0; j<ENTITY_COUNT; j++ )); do
      ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
      echo "            │   │   └── ${ENTITY}_repository.dart"
    done
    if [ "$USECASE_COUNT" -gt 0 ]; then
      echo "            │   ├── 3_usecases/"
      for (( j=0; j<USECASE_COUNT; j++ )); do
        UC=$(yq ".features[$i].usecases[$j]" "$INPUT_FILE")
        echo "            │   │   └── ${UC}_usecase.dart"
      done
    fi
    echo "            │   └── exceptions/"
    echo "            │       └── ${NAME}_exceptions.dart"
    echo "            ├── 2_infrastructure/"
    echo "            │   ├── 1_models/"
    for (( j=0; j<ENTITY_COUNT; j++ )); do
      ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
      echo "            │   │   └── ${ENTITY}_model.dart"
    done
    echo "            │   ├── 2_data_sources/"
    if [ "$LOCAL_DS" = "true" ]; then
      echo "            │   │   ├── 1_local/"
      for (( j=0; j<ENTITY_COUNT; j++ )); do
        ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
        echo "            │   │   │   └── ${ENTITY}_local_data_source.dart"
      done
    fi
    if [ "$REMOTE_DS" = "true" ]; then
      echo "            │   │   └── 2_remote/"
      for (( j=0; j<ENTITY_COUNT; j++ )); do
        ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
        echo "            │   │       └── ${ENTITY}_remote_data_source.dart"
      done
    fi
    echo "            │   └── 3_repositories/"
    for (( j=0; j<ENTITY_COUNT; j++ )); do
      ENTITY=$(yq ".features[$i].entities[$j]" "$INPUT_FILE")
      echo "            │       └── ${ENTITY}_repository_impl.dart"
    done
    echo "            ├── 3_application/"
    echo "            │   ├── 1_states/"
    echo "            │   │   └── ${NAME}_state.dart"
    echo "            │   ├── 2_providers/"
    echo "            │   │   └── ${NAME}_providers.dart"
    echo "            │   └── 3_notifiers/"
    echo "            │       └── ${NAME}_notifier.dart"
    echo "            └── 4_presentation/"

    ATOM_COUNT=$(yq ".features[$i].widgets.atoms | length" "$INPUT_FILE")
    MOLECULE_COUNT=$(yq ".features[$i].widgets.molecules | length" "$INPUT_FILE")
    ORGANISM_COUNT=$(yq ".features[$i].widgets.organisms | length" "$INPUT_FILE")

    if [ "$ATOM_COUNT" -gt 0 ] || [ "$MOLECULE_COUNT" -gt 0 ] || [ "$ORGANISM_COUNT" -gt 0 ]; then
      echo "                ├── 1_widgets/"
      if [ "$ATOM_COUNT" -gt 0 ]; then
        echo "                │   ├── 1_atoms/"
        for (( j=0; j<ATOM_COUNT; j++ )); do
          WIDGET=$(yq ".features[$i].widgets.atoms[$j]" "$INPUT_FILE")
          echo "                │   │   └── ${WIDGET}_atom.dart"
        done
      fi
      if [ "$MOLECULE_COUNT" -gt 0 ]; then
        echo "                │   ├── 2_molecules/"
        for (( j=0; j<MOLECULE_COUNT; j++ )); do
          WIDGET=$(yq ".features[$i].widgets.molecules[$j]" "$INPUT_FILE")
          echo "                │   │   └── ${WIDGET}_molecule.dart"
        done
      fi
      if [ "$ORGANISM_COUNT" -gt 0 ]; then
        echo "                │   └── 3_organisms/"
        for (( j=0; j<ORGANISM_COUNT; j++ )); do
          WIDGET=$(yq ".features[$i].widgets.organisms[$j]" "$INPUT_FILE")
          echo "                │       └── ${WIDGET}_organism.dart"
        done
      fi
    fi
    if [ "$PAGE_COUNT" -gt 0 ]; then
      echo "                └── 2_pages/"
      for (( j=0; j<PAGE_COUNT; j++ )); do
        PAGE=$(yq ".features[$i].pages[$j]" "$INPUT_FILE")
        if [ "$j" -eq $((PAGE_COUNT-1)) ]; then
          echo "                    └── ${PAGE}_page.dart"
        else
          echo "                    ├── ${PAGE}_page.dart"
        fi
      done
    fi
  done

  echo '```'
  echo ""

  # フィーチャーサマリーテーブル
  echo "## フィーチャー一覧"
  echo ""
  echo "| フィーチャー | 権限 | エンティティ | ユースケース | ページ | 説明 |"
  echo "|------------|------|------------|------------|-------|------|"
  for (( i=0; i<FEATURE_COUNT; i++ )); do
    NAME=$(yq ".features[$i].name" "$INPUT_FILE")
    PERM=$(yq ".features[$i].permission" "$INPUT_FILE")
    DESC=$(yq ".features[$i].description" "$INPUT_FILE")
    ENTITY_COUNT=$(yq ".features[$i].entities | length" "$INPUT_FILE")
    USECASE_COUNT=$(yq ".features[$i].usecases | length" "$INPUT_FILE")
    PAGE_COUNT=$(yq ".features[$i].pages | length" "$INPUT_FILE")
    echo "| ${NAME} | ${PERM} | ${ENTITY_COUNT} | ${USECASE_COUNT} | ${PAGE_COUNT} | ${DESC} |"
  done

} > "$OUTPUT_MD"

echo -e "${GREEN}✅ プレビュー MD 生成完了: ${OUTPUT_MD}${NC}"
echo ""
echo -e "${GREEN}🎉 生成完了！${NC}"
echo -e "  YAML: ${OUTPUT_YAML}"
echo -e "  MD:   ${OUTPUT_MD}"
