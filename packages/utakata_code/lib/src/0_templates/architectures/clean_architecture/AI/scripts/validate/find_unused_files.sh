#!/bin/bash

# ==========================================
# 未使用ファイル（孤立ファイル）検出スクリプト v2
# ==========================================
# 改善点:
#   - パッケージ名と相対パスの両方を解析
#   - basename だけでなく正確なパスパターンでマッチング
#   - barrel (index.dart / exports.dart) を経由した間接参照を追跡
#   - カウンターのサブシェル問題を修正
#   - 除外パターンの拡充
# ==========================================

set -euo pipefail

# ──────────────────────────────────────────
# 引数・設定
# ──────────────────────────────────────────
TARGET_DIR="${1:-lib}"
PUBSPEC="${2:-pubspec.yaml}"
VERBOSE="${VERBOSE:-0}"          # VERBOSE=1 で詳細ログ
SHOW_IMPORTS="${SHOW_IMPORTS:-0}" # SHOW_IMPORTS=1 で参照元を表示

# ──────────────────────────────────────────
# バリデーション
# ──────────────────────────────────────────
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ エラー: ディレクトリ '$TARGET_DIR' が存在しません。"
    exit 1
fi

if [ ! -f "$PUBSPEC" ]; then
    echo "❌ エラー: '$PUBSPEC' が存在しません。プロジェクトルートで実行してください。"
    exit 1
fi

# pubspec.yaml からパッケージ名を取得
PACKAGE_NAME=$(grep -E '^name:' "$PUBSPEC" | head -1 | sed 's/name:[[:space:]]*//')
if [ -z "$PACKAGE_NAME" ]; then
    echo "❌ エラー: pubspec.yaml からパッケージ名を取得できませんでした。"
    exit 1
fi

echo "🔍 未使用の可能性が高いDartファイルを検索中..."
echo "  対象ディレクトリ : $TARGET_DIR"
echo "  パッケージ名     : $PACKAGE_NAME"
echo "────────────────────────────────────────────────"

# ──────────────────────────────────────────
# 全 Dart ファイルをリストアップ（除外パターン）
# ──────────────────────────────────────────
ALL_DART_FILES=$(find "$TARGET_DIR" -type f -name "*.dart" \
    ! -name "*.g.dart" \
    ! -name "*.freezed.dart" \
    ! -name "*.gen.dart" \
    ! -name "*.mocks.dart" \
    ! -name "*.config.dart" \
    | sort)

# ──────────────────────────────────────────
# スキップ対象ファイル名（エントリポイント等）
# ──────────────────────────────────────────
SKIP_FILES="main.dart app.dart firebase_options.dart router.dart routes.dart"

# ──────────────────────────────────────────
# barrel ファイルの検出（index.dart / exports.dart）
# barrel 経由で公開されているファイルは「barrel から参照されている = 使用中」とみなす
# ──────────────────────────────────────────
BARREL_EXPORTS_PATTERN=""
BARREL_FILES=$(echo "$ALL_DART_FILES" | grep -E '/(index|exports)\.dart$' || true)

if [ -n "$BARREL_FILES" ]; then
    # barrel ファイルが export している相対パス・パッケージパスを収集
    # 例: export '../user_entity.dart'; → user_entity.dart を参照
    BARREL_REFS=$(echo "$BARREL_FILES" | xargs grep -h "^export " 2>/dev/null \
        | sed "s/export[[:space:]]*['\"]//g" \
        | sed "s/['\";].*//g" \
        | sed "s|^package:$PACKAGE_NAME/||" \
        | xargs -I{} basename {} 2>/dev/null \
        | sort -u || true)
fi

# ──────────────────────────────────────────
# メイン処理
# ──────────────────────────────────────────
UNUSED_COUNT=0
SKIPPED_COUNT=0
CHECKED_COUNT=0

while IFS= read -r file; do
    filename=$(basename "$file")
    name_no_ext="${filename%.dart}"

    # ── スキップ判定 ──────────────────────
    skip=0
    for skip_f in $SKIP_FILES; do
        if [[ "$filename" == "$skip_f" ]]; then
            skip=1
            break
        fi
    done
    # _test.dart は除外
    if [[ "$filename" == *_test.dart ]]; then
        skip=1
    fi
    if [ "$skip" -eq 1 ]; then
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        [ "$VERBOSE" = "1" ] && echo "  ⏭️  スキップ: $file"
        continue
    fi

    CHECKED_COUNT=$((CHECKED_COUNT + 1))

    # ── パス正規化 ────────────────────────
    # TARGET_DIR 以下の相対パス（lib/ 基準）
    # 例: lib/features/user/user_entity.dart → features/user/user_entity.dart
    relative_to_lib="${file#$TARGET_DIR/}"

    # パッケージ import パターン
    # 例: package:my_app/features/user/user_entity.dart
    pkg_import_path="package:$PACKAGE_NAME/$relative_to_lib"

    # ── grep パターン構築 ─────────────────
    # 1) ファイル名のみ（相対インポート末尾）例: 'user_entity.dart'
    # 2) パッケージフルパス例: package:my_app/features/user/user_entity.dart
    # 3) lib/ 以降のパス（相対インポートの部分省略形）例: features/user/user_entity.dart
    # 4) ディレクトリ直下相対パス例: ./user_entity.dart  ../user/user_entity.dart
    PATTERN="$filename\|$pkg_import_path\|$relative_to_lib"

    # 全 dart ファイル（自分自身を除く）に対して grep
    match_lines=$(grep -rn --include="*.dart" -F \
        -e "$filename" \
        -e "$pkg_import_path" \
        -e "$relative_to_lib" \
        "$TARGET_DIR" 2>/dev/null \
        | grep -v "^${file}:" \
        | grep -E "import |export " \
        || true)

    match_count=$(echo "$match_lines" | grep -c . || true)

    # ── barrel 経由チェック ───────────────
    barrel_ref=0
    if [ -n "${BARREL_REFS:-}" ]; then
        if echo "$BARREL_REFS" | grep -qx "$filename"; then
            barrel_ref=1
        fi
    fi

    # ── 結果判定 ──────────────────────────
    if [ "$match_count" -eq 0 ] && [ "$barrel_ref" -eq 0 ]; then
        echo "⚠️  未使用の可能性: $file"
        UNUSED_COUNT=$((UNUSED_COUNT + 1))

        if [ "$SHOW_IMPORTS" = "1" ]; then
            echo "   └─ (どこからもインポートされていません)"
        fi
    else
        [ "$VERBOSE" = "1" ] && echo "  ✅ 使用中($match_count箇所): $file"
        if [ "$SHOW_IMPORTS" = "1" ] && [ "$VERBOSE" = "1" ]; then
            echo "$match_lines" | head -5 | while IFS= read -r line; do
                echo "   └─ $line"
            done
        fi
    fi

done <<< "$ALL_DART_FILES"

# ──────────────────────────────────────────
# サマリー
# ──────────────────────────────────────────
echo "────────────────────────────────────────────────"
echo "✅ 検索完了！"
echo "  チェック対象 : $CHECKED_COUNT ファイル"
echo "  スキップ     : $SKIPPED_COUNT ファイル"
echo "  未使用疑い   : $UNUSED_COUNT ファイル"
echo ""
echo "⚠️  注意事項:"
echo "  1. コメント・文字列内の参照は検出できません。"
echo "  2. 動的インポートやルーター文字列パス指定は検出できません。"
echo "  3. barrel ファイル(index/exports.dart) 経由の間接参照は追跡します。"
echo "  4. 削除前に必ず手動でコードを確認してください。"
echo ""
echo "💡 ヒント: 詳細表示は VERBOSE=1 ./find_unused_files.sh"
echo "           参照元表示は SHOW_IMPORTS=1 ./find_unused_files.sh"