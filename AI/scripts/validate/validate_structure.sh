#!/usr/bin/env bash
set -Eeuo pipefail

# validate_structure.sh
# lib/以下のディレクトリ構造が定義に準拠しているか検証するスクリプト
# 違反があれば AI/logs/structure_violations.md に記録します

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
VIOLATIONS_FILE="$PROJECT_ROOT/AI/logs/structure_violations.md"

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --clear-violations  違反ログをクリア（すべての違反を解消した後に使用）"
  echo "  -h, --help         このヘルプを表示"
  exit 0
}

CLEAR_VIOLATIONS=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --clear-violations)
      CLEAR_VIOLATIONS=true; shift;;
    -h|--help)
      usage;;
    *)
      echo "Unknown option: $1"
      usage;;
  esac
done

echo -e "${BLUE}🔍 ディレクトリ構造を検証中...${NC}\n"

# 許可されたパターンを定義
declare -A ALLOWED_PATTERNS

# lib/直下
ALLOWED_PATTERNS["lib/core"]=1
ALLOWED_PATTERNS["lib/features"]=1
ALLOWED_PATTERNS["lib/main.dart"]=1
ALLOWED_PATTERNS["lib/app.dart"]=1

# lib/core/配下
ALLOWED_PATTERNS["lib/core/routing"]=1
ALLOWED_PATTERNS["lib/core/routing/path"]=1
ALLOWED_PATTERNS["lib/core/theme"]=1
ALLOWED_PATTERNS["lib/core/api"]=1
ALLOWED_PATTERNS["lib/core/env"]=1
ALLOWED_PATTERNS["lib/core/database"]=1
ALLOWED_PATTERNS["lib/core/database/table"]=1
ALLOWED_PATTERNS["lib/core/database/migration"]=1
ALLOWED_PATTERNS["lib/core/exceptions"]=1

# lib/features/ のパターン（動的にチェック）
# 許可される層とサブディレクトリ
VALID_LAYERS=(
  "1_domain"
  "2_infrastructure"
  "3_application"
  "4_presentation"
)

VALID_DOMAIN=(
  "1_entities"
  "2_repositories"
  "3_usecases"
  "exceptions"
)

VALID_INFRASTRUCTURE=(
  "1_models"
  "2_data_sources"
  "3_repositories"
)

VALID_DATA_SOURCES=(
  "1_local"
  "2_remote"
)

VALID_APPLICATION=(
  "1_states"
  "2_providers"
  "3_notifiers"
)

VALID_PRESENTATION=(
  "1_widgets"
  "2_pages"
)

VALID_WIDGETS=(
  "1_atoms"
  "2_molecules"
  "3_organisms"
)

# 違反を記録する配列（空で初期化）
VIOLATIONS=()

# libディレクトリが存在しない場合はスキップ
if [ ! -d "$PROJECT_ROOT/lib" ]; then
  echo -e "${YELLOW}⚠ lib/ ディレクトリが存在しません${NC}"
  exit 0
fi

# lib/直下のチェック
for item in "$PROJECT_ROOT/lib"/*; do
  if [ ! -e "$item" ]; then continue; fi
  
  rel_path="lib/$(basename "$item")"
  
  # main.dart, app.dart, core/, features/ 以外は違反
  if [[ ! -v ALLOWED_PATTERNS["$rel_path"] ]]; then
    VIOLATIONS+=("lib/ 直下に不正な項目: $rel_path")
  fi
done

# lib/core/配下のチェック
if [ -d "$PROJECT_ROOT/lib/core" ]; then
  for item in "$PROJECT_ROOT/lib/core"/*; do
    if [ ! -e "$item" ]; then continue; fi
    
    rel_path="lib/core/$(basename "$item")"
    
    if [[ ! -v ALLOWED_PATTERNS["$rel_path"] ]]; then
      VIOLATIONS+=("lib/core/ 配下に不正なディレクトリ: $rel_path")
    fi
  done
  
  # routing/path のチェック
  if [ -d "$PROJECT_ROOT/lib/core/routing" ]; then
    for item in "$PROJECT_ROOT/lib/core/routing"/*; do
      if [ ! -e "$item" ]; then continue; fi
      basename_item=$(basename "$item")
      
      if [[ "$basename_item" != "path" && ! "$basename_item" =~ \.dart$ ]]; then
        VIOLATIONS+=("lib/core/routing/ 配下に不正な項目: lib/core/routing/$basename_item")
      fi
    done
  fi
  
  # database/table のチェック
  if [ -d "$PROJECT_ROOT/lib/core/database" ]; then
    for item in "$PROJECT_ROOT/lib/core/database"/*; do
      if [ ! -e "$item" ]; then continue; fi
      basename_item=$(basename "$item")
      
      if [[ "$basename_item" != "table" && "$basename_item" != "migration" && ! "$basename_item" =~ \.dart$ ]]; then
        VIOLATIONS+=("lib/core/database/ 配下に不正な項目: lib/core/database/$basename_item")
      fi
    done
  fi
fi

# lib/features/配下のチェック
if [ -d "$PROJECT_ROOT/lib/features" ]; then
  has_any_layer_dir() {
    local dir="$1"
    local layer
    for layer in "${VALID_LAYERS[@]}"; do
      if [ -e "$dir/$layer" ]; then
        return 0
      fi
    done
    return 1
  }

  validate_feature_dir() {
    local feature_dir="$1"
    local feature_rel="$2"

    # 各フィーチャー内の層をチェック
    for layer_dir in "$feature_dir"/*; do
      if [ ! -e "$layer_dir" ]; then continue; fi

      local layer_name
      layer_name=$(basename "$layer_dir")

      # 許可された層かチェック
      if [[ ! " ${VALID_LAYERS[@]} " =~ " ${layer_name} " ]]; then
        VIOLATIONS+=("lib/features/$feature_rel/ 配下に不正な層: $layer_name")
        continue
      fi

      # 層ごとの詳細チェック
      case "$layer_name" in
        "1_domain")
          if [ -d "$layer_dir" ]; then
            for subdir in "$layer_dir"/*; do
              if [ ! -e "$subdir" ]; then continue; fi
              subdir_name=$(basename "$subdir")
              
              if [[ ! " ${VALID_DOMAIN[@]} " =~ " ${subdir_name} " ]]; then
                VIOLATIONS+=("lib/features/$feature_rel/1_domain/ 配下に不正なディレクトリ: $subdir_name")
              else
                # ファイル命名規則のチェック
                if [ -d "$subdir" ]; then
                  for file in "$subdir"/*.dart; do
                    if [ ! -f "$file" ]; then continue; fi
                    filename=$(basename "$file")
                    # 生成ファイル(.freezed.dart, .g.dart)はスキップ
                    if [[ "$filename" =~ \.(freezed|g)\.dart$ ]]; then continue; fi
                    
                    case "$subdir_name" in
                      "1_entities")
                        if [[ ! "$filename" =~ ^[a-z_]+_entity\.dart$ ]]; then
                          VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/1_domain/1_entities/$filename (期待: {name}_entity.dart)")
                        fi
                        ;;
                      "2_repositories")
                        if [[ ! "$filename" =~ ^[a-z_]+_repository\.dart$ ]]; then
                          VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/1_domain/2_repositories/$filename (期待: {name}_repository.dart)")
                        fi
                        ;;
                      "3_usecases")
                        if [[ ! "$filename" =~ ^[a-z_]+_usecase\.dart$ ]]; then
                          VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/1_domain/3_usecases/$filename (期待: {verb}_{name}_usecase.dart)")
                        fi
                        ;;
                      "exceptions")
                        if [[ ! "$filename" =~ ^[a-z_]+(exceptions|_exception)\.dart$ ]]; then
                          VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/1_domain/exceptions/$filename (期待: {name}_exceptions.dart または {name}_exception.dart)")
                        fi
                        ;;
                    esac
                  done
                fi
              fi
            done
          fi
          ;;
        "2_infrastructure")
          if [ -d "$layer_dir" ]; then
            for subdir in "$layer_dir"/*; do
              if [ ! -e "$subdir" ]; then continue; fi
              subdir_name=$(basename "$subdir")
              
              if [[ ! " ${VALID_INFRASTRUCTURE[@]} " =~ " ${subdir_name} " ]]; then
                VIOLATIONS+=("lib/features/$feature_rel/2_infrastructure/ 配下に不正なディレクトリ: $subdir_name")
                continue
              fi
              
              # ファイル命名規則のチェック
              if [ "$subdir_name" = "1_models" ]; then
                for file in "$subdir"/*.dart; do
                  if [ ! -f "$file" ]; then continue; fi
                  filename=$(basename "$file")
                  # 生成ファイル(.freezed.dart, .g.dart)はスキップ
                  if [[ "$filename" =~ \.(freezed|g)\.dart$ ]]; then continue; fi
                  if [[ ! "$filename" =~ ^[a-z_]+_model\.dart$ ]]; then
                    VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/2_infrastructure/1_models/$filename (期待: {name}_model.dart)")
                  fi
                done
              elif [ "$subdir_name" = "3_repositories" ]; then
                for file in "$subdir"/*.dart; do
                  if [ ! -f "$file" ]; then continue; fi
                  filename=$(basename "$file")
                  if [[ ! "$filename" =~ ^[a-z_]+_repository_impl\.dart$ ]]; then
                    VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/2_infrastructure/3_repositories/$filename (期待: {name}_repository_impl.dart)")
                  fi
                done
              elif [ "$subdir_name" = "2_data_sources" ]; then
                # 2_data_sources のサブディレクトリチェック
                # 2_data_sources 直下には .dart ファイルを許可しない
                for file in "$subdir"/*.dart; do
                  if [ -f "$file" ]; then
                    VIOLATIONS+=("lib/features/$feature_rel/2_infrastructure/2_data_sources/ 配下に不正なファイル: $(basename "$file") (サブディレクトリのみ許可)")
                  fi
                done

                for ds_subdir in "$subdir"/*; do
                  if [ ! -e "$ds_subdir" ]; then continue; fi
                  ds_subdir_name=$(basename "$ds_subdir")
                  
                  if [[ ! " ${VALID_DATA_SOURCES[@]} " =~ " ${ds_subdir_name} " ]]; then
                    VIOLATIONS+=("lib/features/$feature_rel/2_infrastructure/2_data_sources/ 配下に不正なディレクトリ: $ds_subdir_name")
                  else
                    # データソースのファイル命名規則チェック
                    if [ -d "$ds_subdir" ]; then
                      for file in "$ds_subdir"/*.dart; do
                        if [ ! -f "$file" ]; then continue; fi
                        filename=$(basename "$file")
                        # 生成ファイル(.freezed.dart, .g.dart)はスキップ
                        if [[ "$filename" =~ \.(freezed|g)\.dart$ ]]; then continue; fi
                        
                        if [ "$ds_subdir_name" = "1_local" ]; then
                          # インターフェース(_local_data_source.dart)または実装(_local_data_source_impl.dart)を許可
                          if [[ ! "$filename" =~ ^[a-z_]+_local_data_source(_impl)?\.dart$ ]]; then
                            VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/2_infrastructure/2_data_sources/1_local/$filename (期待: {name}_local_data_source.dart または {name}_local_data_source_impl.dart)")
                          fi
                        elif [ "$ds_subdir_name" = "2_remote" ]; then
                          # インターフェース(_remote_data_source.dart)または実装(_remote_data_source_impl.dart)を許可
                          if [[ ! "$filename" =~ ^[a-z_]+_remote_data_source(_impl)?\.dart$ ]]; then
                            VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/2_infrastructure/2_data_sources/2_remote/$filename (期待: {name}_remote_data_source.dart または {name}_remote_data_source_impl.dart)")
                          fi
                        fi
                      done
                    fi
                  fi
                done
              fi
            done
          fi
          ;;
        "3_application")
          if [ -d "$layer_dir" ]; then
            for subdir in "$layer_dir"/*; do
              if [ ! -e "$subdir" ]; then continue; fi
              subdir_name=$(basename "$subdir")
              
              if [[ ! " ${VALID_APPLICATION[@]} " =~ " ${subdir_name} " ]]; then
                VIOLATIONS+=("lib/features/$feature_rel/3_application/ 配下に不正なディレクトリ: $subdir_name")
              else
                # ファイル命名規則のチェック
                if [ -d "$subdir" ]; then
                  for file in "$subdir"/*.dart; do
                    if [ ! -f "$file" ]; then continue; fi
                    filename=$(basename "$file")
                    # 生成ファイル(.freezed.dart, .g.dart)はスキップ
                    if [[ "$filename" =~ \.(freezed|g)\.dart$ ]]; then continue; fi
                    
                    case "$subdir_name" in
                      "1_states")
                        if [[ ! "$filename" =~ ^[a-z_]+_state\.dart$ ]]; then
                          VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/3_application/1_states/$filename (期待: {name}_state.dart)")
                        fi
                        ;;
                      "2_providers")
                        if [[ ! "$filename" =~ ^[a-z_]+_providers?\.dart$ ]]; then
                          VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/3_application/2_providers/$filename (期待: {name}_providers.dart)")
                        fi
                        ;;
                      "3_notifiers")
                        if [[ ! "$filename" =~ ^[a-z_]+_notifier\.dart$ ]]; then
                          VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/3_application/3_notifiers/$filename (期待: {name}_notifier.dart)")
                        fi
                        ;;
                    esac
                  done
                fi
              fi
            done
          fi
          ;;
        "4_presentation")
          if [ -d "$layer_dir" ]; then
            for subdir in "$layer_dir"/*; do
              if [ ! -e "$subdir" ]; then continue; fi
              subdir_name=$(basename "$subdir")
              
              if [[ ! " ${VALID_PRESENTATION[@]} " =~ " ${subdir_name} " ]]; then
                VIOLATIONS+=("lib/features/$feature_rel/4_presentation/ 配下に不正なディレクトリ: $subdir_name")
                continue
              fi
              
              # ページのファイル命名規則チェック
              if [ "$subdir_name" = "2_pages" ]; then
                for file in "$subdir"/*.dart; do
                  if [ ! -f "$file" ]; then continue; fi
                  filename=$(basename "$file")
                  # 生成ファイル(.freezed.dart, .g.dart)はスキップ
                  if [[ "$filename" =~ \.(freezed|g)\.dart$ ]]; then continue; fi
                  if [[ ! "$filename" =~ ^[a-z_]+_page\.dart$ ]]; then
                    VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/4_presentation/2_pages/$filename (期待: {name}_page.dart)")
                  fi
                done
              elif [ "$subdir_name" = "1_widgets" ]; then
                # 1_widgets のサブディレクトリチェック
                for widget_subdir in "$subdir"/*; do
                  if [ ! -e "$widget_subdir" ]; then continue; fi
                  widget_subdir_name=$(basename "$widget_subdir")
                  
                  if [[ ! " ${VALID_WIDGETS[@]} " =~ " ${widget_subdir_name} " ]]; then
                    VIOLATIONS+=("lib/features/$feature_rel/4_presentation/1_widgets/ 配下に不正なディレクトリ: $widget_subdir_name")
                  else
                    # ウィジェットのファイル命名規則チェック
                    if [ -d "$widget_subdir" ]; then
                      for file in "$widget_subdir"/*.dart; do
                        if [ ! -f "$file" ]; then continue; fi
                        filename=$(basename "$file")
                        # 生成ファイル(.freezed.dart, .g.dart)はスキップ
                        if [[ "$filename" =~ \.(freezed|g)\.dart$ ]]; then continue; fi
                        
                        case "$widget_subdir_name" in
                          "1_atoms")
                            if [[ ! "$filename" =~ ^[a-z_]+_atom\.dart$ ]]; then
                              VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/4_presentation/1_widgets/1_atoms/$filename (期待: {name}_atom.dart)")
                            fi
                            ;;
                          "2_molecules")
                            if [[ ! "$filename" =~ ^[a-z_]+_molecule\.dart$ ]]; then
                              VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/4_presentation/1_widgets/2_molecules/$filename (期待: {name}_molecule.dart)")
                            fi
                            ;;
                          "3_organisms")
                            if [[ ! "$filename" =~ ^[a-z_]+_organism\.dart$ ]]; then
                              VIOLATIONS+=("命名規則違反: lib/features/$feature_rel/4_presentation/1_widgets/3_organisms/$filename (期待: {name}_organism.dart)")
                            fi
                            ;;
                        esac
                      done
                    fi
                  fi
                done
              fi
            done
          fi
          ;;
      esac
    done

  }

  # features直下は「feature直置き」または「権限/namespace配下にfeature」を許可する
  for features_child in "$PROJECT_ROOT/lib/features"/*; do
    if [ ! -d "$features_child" ]; then continue; fi

    if has_any_layer_dir "$features_child"; then
      validate_feature_dir "$features_child" "$(basename "$features_child")"
      continue
    fi

    namespace_name=$(basename "$features_child")
    for feature_dir in "$features_child"/*; do
      if [ ! -d "$feature_dir" ]; then continue; fi
      validate_feature_dir "$feature_dir" "$namespace_name/$(basename "$feature_dir")"
    done
  done
fi

# 結果表示
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 検証結果${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

VIOLATION_COUNT=${#VIOLATIONS[@]}
if [ "$VIOLATION_COUNT" -eq 0 ]; then
  echo -e "${GREEN}✅ 違反は見つかりませんでした${NC}"
  echo ""
  
  if [ "$CLEAR_VIOLATIONS" = true ]; then
    # 違反ログをクリア（テンプレートを保持）
    echo -e "${YELLOW}📝 違反ログをクリアしています...${NC}"
    # ここでは何もしない（違反がないため）
  fi
else
  echo -e "${RED}❌ ${#VIOLATIONS[@]} 件の違反が見つかりました:${NC}"
  echo ""
  
  for violation in "${VIOLATIONS[@]}"; do
    echo -e "${RED}  • $violation${NC}"
  done
  
  echo ""
  echo -e "${YELLOW}📝 違反を structure_violations.md に記録しています...${NC}"
  
  # 現在時刻
  CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
  
  # violations.mdに追記
  {
    echo ""
    echo "## [$CURRENT_TIME] 違反検出"
    echo ""
    echo "### 🔴 検出された違反 (${#VIOLATIONS[@]} 件)"
    echo ""
    for violation in "${VIOLATIONS[@]}"; do
      echo "- **$violation**"
    done
    echo ""
    echo "### 推奨アクション"
    echo ""
    echo "1. 上記の不正なディレクトリ/ファイルを確認"
    echo "2. 定義された構造に従って正しい場所に移動"
    echo "3. または削除して再作成"
    echo "4. 構造計画書を確認: \`AI/document/structure_plan.md\`"
    echo "5. Features アーキテクチャを参照: \`AI/architecture/lib/features/features_architecture.md\`"
    echo ""
    echo "### 修正後の確認"
    echo ""
    echo "\`\`\`bash"
    echo "./AI/scripts/bash/validate_structure.sh"
    echo "\`\`\`"
    echo ""
    echo "---"
  } >> "$VIOLATIONS_FILE"
  
  echo -e "${GREEN}✅ 記録完了: $VIOLATIONS_FILE${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit 0
