#!/usr/bin/env bash
set -Eeuo pipefail

# add_dependencies.sh
# 推奨依存関係を pubspec.yaml に追加するユーティリティ

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# リポジトリ直下（Flutter プロジェクトルート）を指すように 3 階層上に設定
# 例: <repo_root>/AI/scripts/bash -> <repo_root>
ROOT_DIR=$(cd "${SCRIPT_DIR}/../../.." && pwd)

YES=false

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --yes          確認なしで実行（非対話）
  -h, --help     このヘルプを表示

Note:
  ランタイム依存と開発依存をまとめて追加します。
  必要に応じて pubspec.yaml を編集して調整してください。
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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

echo "[deps] Working directory: ${ROOT_DIR}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter が見つかりません。Flutter SDK をインストールし、PATH を設定してください。" >&2
  exit 1
fi

if [[ ! -f "pubspec.yaml" ]]; then
  echo "Error: pubspec.yaml が見つかりません。プロジェクトルートで実行してください。" >&2
  exit 1
fi

if [[ "${YES}" == false ]]; then
  cat <<CONF

追加予定の依存関係:
  [runtime]
    hooks_riverpod, riverpod_annotation, flutter_hooks,
    freezed_annotation, json_annotation, go_router,
    drift, sqlite3_flutter_libs, path_provider, path, logger
  [dev]
    build_runner, freezed, json_serializable, riverpod_generator,
    drift_dev, flutter_lints
CONF
  read -r -p "続行しますか？ [y/N] " resp
  if [[ ! "${resp}" =~ ^[yY]$ ]]; then
    echo "中止しました"; exit 1
  fi
fi

echo "\n[deps] Adding runtime dependencies"
flutter pub add \
  hooks_riverpod \
  riverpod_annotation \
  flutter_hooks \
  freezed_annotation \
  json_annotation \
  go_router \
  drift \
  sqlite3_flutter_libs \
  path_provider \
  path \
  logger

echo "\n[deps] Adding dev dependencies"
flutter pub add --dev \
  build_runner \
  freezed \
  json_serializable \
  riverpod_generator \
  drift_dev \
  flutter_lints

echo "\n[deps] Done."
