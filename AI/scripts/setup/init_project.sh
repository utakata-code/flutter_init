#!/usr/bin/env bash
set -Eeuo pipefail

# init_project.sh
# Flutter プロジェクト初期化用スクリプト
# - `flutter create .` を実行
# - プラットフォーム選択（--platforms）と org ドメイン指定（--org）に対応


SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# プロジェクトのルートは scripts ディレクトリから3階層上（リポジトリ直下）を想定
# 例: <repo_root>/AI/scripts/bash -> <repo_root>
ROOT_DIR=$(cd "${SCRIPT_DIR}/../../.." && pwd)

ORG="com.example"
# ルートディレクトリ名から Dart パッケージ名に適した形へ正規化
# - 小文字化
# - 非 [a-z0-9_] の文字はアンダースコアに置換
# - 先頭が数字の場合は先頭にアンダースコアを付与
_BASENAME="$(basename "${ROOT_DIR}")"
_NORMALIZED="$(echo "${_BASENAME}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_]+/_/g')"
if [[ "${_NORMALIZED}" =~ ^[0-9] ]]; then
  PROJECT_NAME="_${_NORMALIZED}"
else
  PROJECT_NAME="${_NORMALIZED}"
fi
DESCRIPTION="Flutter Clean Architecture app"
PLATFORMS="android,ios,web,macos"
OVERWRITE=false
YES=false
EMPTY=true

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --org <domain>             パッケージ org ドメイン（例: com.example）
  --platforms <list>         生成するプラットフォーム（例: android,ios,web,macos,windows,linux）
  --project-name <name>      プロジェクト名（省略時はフォルダ名）
  --description <text>       プロジェクト説明
  --overwrite                既存ファイルを上書き（flutter create の --overwrite）
  --keep-comments            `--empty` を無効化しコメントありテンプレートを生成
  --yes                      確認なしで実行（非対話）
  -h, --help                 このヘルプを表示

Note:
  このスクリプトはプロジェクト作成のみを行います。
  依存関係の追加は AI/scripts/bash/add_dependencies.sh を、
  共通例外ファイルの生成は AI/scripts/bash/init_core_exceptions.sh を使用してください。

Examples:
  $0 --org com.acme --platforms android,ios,web --description "ACME App" --yes
  $0 --org jp.co.example --platforms android,ios,macos,web --overwrite
USAGE
}

# 引数パース（ロングオプション対応）
while [[ $# -gt 0 ]]; do
  case "$1" in
    --org)
      ORG="$2"; shift 2;;
    --org=*)
      ORG="${1#*=}"; shift 1;;
    --platforms)
      PLATFORMS="$2"; shift 2;;
    --platforms=*)
      PLATFORMS="${1#*=}"; shift 1;;
    --project-name)
      PROJECT_NAME="$2"; shift 2;;
    --project-name=*)
      PROJECT_NAME="${1#*=}"; shift 1;;
    --description)
      DESCRIPTION="$2"; shift 2;;
    --description=*)
      DESCRIPTION="${1#*=}"; shift 1;;
    --overwrite)
      OVERWRITE=true; shift 1;;
    --keep-comments)
      EMPTY=false; shift 1;;
    --yes)
      YES=true; shift 1;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown option: $1" >&2
      usage; exit 1;;
  esac
done

cd "${ROOT_DIR}"

echo "[init] Working directory: ${ROOT_DIR}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter が見つかりません。Flutter SDK をインストールし、PATH を設定してください。" >&2
  exit 1
fi

echo "[init] flutter: $(flutter --version | head -n 1)"

if [[ "${YES}" == false ]]; then
  echo "\n設定確認:" 
  echo "  org:          ${ORG}"
  echo "  platforms:    ${PLATFORMS}"
  echo "  project-name: ${PROJECT_NAME}"
  echo "  description:  ${DESCRIPTION}"
  echo "  overwrite:    ${OVERWRITE}"
  echo "  empty:        ${EMPTY}"
  read -r -p "続行しますか？ [y/N] " resp
  if [[ ! "${resp}" =~ ^[yY]$ ]]; then
    echo "中止しました"; exit 1
  fi
fi

CREATE_FLAGS=("--platforms=${PLATFORMS}" "--org=${ORG}" "-t" "app")
if [[ -n "${PROJECT_NAME}" ]]; then
  CREATE_FLAGS+=("--project-name" "${PROJECT_NAME}")
fi
if [[ "${OVERWRITE}" == true ]]; then
  CREATE_FLAGS+=("--overwrite")
fi
if [[ "${EMPTY}" == true ]]; then
  CREATE_FLAGS+=("--empty")
fi

echo "\n[init] Running: flutter create ${CREATE_FLAGS[*]} ."
flutter create "${CREATE_FLAGS[@]}" .

 



echo "\n[done] Initialization complete."
echo "- Add dependencies: AI/scripts/bash/add_dependencies.sh --yes"
echo "- Init core exceptions: AI/scripts/bash/init_core_exceptions.sh --yes"
echo "- Run feature generator: AI/scripts/bash/generate_feature.sh"
echo "- Build codegen: flutter pub run build_runner build --delete-conflicting-outputs"