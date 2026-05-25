#!/usr/bin/env bash
set -Eeuo pipefail

# init_core_exceptions.sh
# lib/core/exceptions の共通例外ファイルを生成するユーティリティ

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# リポジトリ直下をプロジェクトルートとして扱う
ROOT_DIR=$(cd "${SCRIPT_DIR}/../../.." && pwd)

OVERWRITE=false
YES=false

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --overwrite    既存ファイルを上書き
  --yes          確認なしで実行（非対話）
  -h, --help     このヘルプを表示

Note:
  lib/core/exceptions/ に Base/Network/Storage の例外を生成します。
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --overwrite)
      OVERWRITE=true; shift 1;;
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

echo "[core] Working directory: ${ROOT_DIR}"

if [[ ! -d "lib" ]]; then
  echo "Error: lib ディレクトリが見つかりません。Flutter プロジェクトのルートで実行してください。" >&2
  exit 1
fi

TARGET_DIR="lib/core/exceptions"
mkdir -p "${TARGET_DIR}"

files=(
  "${TARGET_DIR}/base_exception.dart"
  "${TARGET_DIR}/network_exception.dart"
  "${TARGET_DIR}/storage_exception.dart"
)

if [[ "${OVERWRITE}" == false ]]; then
  for f in "${files[@]}"; do
    if [[ -f "$f" ]]; then
      echo "Error: $f は既に存在します。--overwrite を指定してください。" >&2
      exit 1
    fi
  done
fi

if [[ "${YES}" == false ]]; then
  echo "\n生成先: ${TARGET_DIR}"
  read -r -p "続行しますか？ [y/N] " resp
  if [[ ! "${resp}" =~ ^[yY]$ ]]; then
    echo "中止しました"; exit 1
  fi
fi

cat > "${TARGET_DIR}/base_exception.dart" <<'EOF'
abstract class BaseException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const BaseException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'BaseException(message: ' + message + (code != null ? ', code: ' + code! : '') + ')';
}
EOF

cat > "${TARGET_DIR}/network_exception.dart" <<'EOF'
import 'base_exception.dart';

class NetworkException extends BaseException {
  const NetworkException(super.message, {super.code, super.originalError});

  factory NetworkException.connectionTimeout() =>
      const NetworkException('接続がタイムアウトしました', code: 'CONNECTION_TIMEOUT');

  factory NetworkException.noInternet() =>
      const NetworkException('インターネット接続がありません', code: 'NO_INTERNET');
}
EOF

cat > "${TARGET_DIR}/storage_exception.dart" <<'EOF'
import 'base_exception.dart';

class StorageException extends BaseException {
  const StorageException(super.message, {super.code, super.originalError});

  factory StorageException.databaseError(String details) =>
      StorageException('データベースエラー: ' + details, code: 'DATABASE_ERROR');

  factory StorageException.fileNotFound(String path) =>
      StorageException('ファイルが見つかりません: ' + path, code: 'FILE_NOT_FOUND');
}
EOF

echo "\n[core] Generated:"
printf "  - %s\n" "${files[@]}"