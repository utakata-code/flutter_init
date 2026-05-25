#!/usr/bin/env bash
set -Eeuo pipefail

# add_dependencies.sh
# YAMLファイルから依存関係を読み取り pubspec.yaml に追加するユーティリティ
#
# ワークフロー:
#   1. AI/architecture/guides/dependencies/core_stack.yaml を編集
#   2. このスクリプトを実行
#   3. pubspec.yaml に依存関係が追加されます

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/../../.." && pwd)
DEPS_DIR="${ROOT_DIR}/AI/architecture/guides/dependencies"

YAML_FILE="${DEPS_DIR}/core_stack.yaml"
YES=false

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --file <path>  依存関係YAMLファイルのパス
                 (デフォルト: AI/architecture/guides/dependencies/core_stack.yaml)
  --yes          確認なしで実行（非対話）
  -h, --help     このヘルプを表示

Workflow:
  1. AI/architecture/guides/dependencies/core_stack.yaml を編集
  2. このスクリプトを実行
  3. pubspec.yaml に依存関係が追加されます
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      YAML_FILE="$2"; shift 2;;
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
echo "[deps] YAML file: ${YAML_FILE}"

# ── 前提チェック ──────────────────────────────────

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter が見つかりません。Flutter SDK をインストールし、PATH を設定してください。" >&2
  exit 1
fi

if [[ ! -f "pubspec.yaml" ]]; then
  echo "Error: pubspec.yaml が見つかりません。プロジェクトルートで実行してください。" >&2
  exit 1
fi

if [[ ! -f "${YAML_FILE}" ]]; then
  echo "Error: ${YAML_FILE} が見つかりません。" >&2
  exit 1
fi

# ── YAMLパーサー ──────────────────────────────────
# dependencies: / dev_dependencies: セクションからパッケージ:バージョンを抽出
# コメント行・空行・sdk依存はスキップ

parse_packages() {
  local file="$1"
  local target_section="$2"
  local in_section=false
  local skip_nested=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    # 空行はスキップ
    [[ -z "${line}" ]] && continue

    # トップレベルのセクション検出（インデントなし、コメントでない）
    if [[ "${line}" =~ ^[a-z_]+: ]]; then
      if [[ "${line}" == "${target_section}:" ]]; then
        in_section=true
      else
        in_section=false
      fi
      skip_nested=false
      continue
    fi

    # 対象セクション外はスキップ
    [[ "${in_section}" == false ]] && continue

    # コメント行はスキップ
    stripped="${line#"${line%%[![:space:]]*}"}"
    [[ "${stripped}" =~ ^# ]] && continue

    # ネストされたマップ（sdk: flutter 等）の値行はスキップ
    if [[ "${skip_nested}" == true ]]; then
      if [[ "${line}" =~ ^[[:space:]]{4,} ]]; then
        continue
      else
        skip_nested=false
      fi
    fi

    # パッケージ行: "  package_name: version" を抽出
    if [[ "${stripped}" =~ ^([a-z_][a-z0-9_]*):(.+)$ ]]; then
      local pkg="${BASH_REMATCH[1]}"
      local ver="${BASH_REMATCH[2]}"

      # バージョン文字列をトリム・クォート除去
      ver="${ver#"${ver%%[![:space:]]*}"}"
      ver="${ver%"${ver##*[![:space:]]}"}"
      ver="${ver#\"}"
      ver="${ver%\"}"

      # sdk 依存（flutter_localizations 等）は flutter pub add で扱えないためスキップ
      if [[ "${ver}" == "" ]]; then
        skip_nested=true
        continue
      fi

      echo "${pkg}:${ver}"
    fi
  done < "${file}"
}

# ── パッケージ抽出 ──────────────────────────────────

RUNTIME_PKGS=()
while IFS= read -r pkg; do
  [[ -n "${pkg}" ]] && RUNTIME_PKGS+=("${pkg}")
done < <(parse_packages "${YAML_FILE}" "dependencies")

DEV_PKGS=()
while IFS= read -r pkg; do
  [[ -n "${pkg}" ]] && DEV_PKGS+=("${pkg}")
done < <(parse_packages "${YAML_FILE}" "dev_dependencies")

if [[ ${#RUNTIME_PKGS[@]} -eq 0 && ${#DEV_PKGS[@]} -eq 0 ]]; then
  echo "[deps] 追加するパッケージが見つかりませんでした。"
  exit 0
fi

# ── 確認表示 ──────────────────────────────────

echo ""
echo "追加予定の依存関係 (from $(basename "${YAML_FILE}")):"

if [[ ${#RUNTIME_PKGS[@]} -gt 0 ]]; then
  echo "  [runtime]"
  for pkg in "${RUNTIME_PKGS[@]}"; do
    echo "    ${pkg}"
  done
fi

if [[ ${#DEV_PKGS[@]} -gt 0 ]]; then
  echo "  [dev]"
  for pkg in "${DEV_PKGS[@]}"; do
    echo "    ${pkg}"
  done
fi

if [[ "${YES}" == false ]]; then
  echo ""
  read -r -p "続行しますか？ [y/N] " resp
  if [[ ! "${resp}" =~ ^[yY]$ ]]; then
    echo "中止しました"; exit 1
  fi
fi

# ── 依存関係の追加 ──────────────────────────────────

if [[ ${#RUNTIME_PKGS[@]} -gt 0 ]]; then
  echo ""
  echo "[deps] Adding runtime dependencies..."
  flutter pub add "${RUNTIME_PKGS[@]}"
fi

if [[ ${#DEV_PKGS[@]} -gt 0 ]]; then
  echo ""
  echo "[deps] Adding dev dependencies..."
  flutter pub add --dev "${DEV_PKGS[@]}"
fi

echo ""
echo "[deps] Done."
