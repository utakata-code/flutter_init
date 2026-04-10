#!/bin/bash

# ==========================================
# iOS Framework Build Script
# Location: AI/scripts/build/build_native_ios.sh
# ==========================================

# 1. パス定義の自動解決
# このスクリプトがあるディレクトリ (AI/scripts/bash)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# プロジェクトルートへのパス (3階層上: bash -> scripts -> AI -> root)
PROJECT_ROOT="$SCRIPT_DIR/../../.."

# 各種ディレクトリ設定
NATIVE_DIR="$PROJECT_ROOT/native"
BUILD_DIR="$NATIVE_DIR/build_ios"
OUTPUT_DIR="$PROJECT_ROOT/ios/Frameworks"

# CMakeLists.txt の project() または add_library() で指定した名前
PROJECT_NAME="native_audio"

# エラーハンドリング設定（エラーが出たら即停止）
set -e

echo "🍎 Building iOS Framework..."
echo "   Target: $PROJECT_NAME"
echo "   Source: $NATIVE_DIR"
echo "   Output: $OUTPUT_DIR"

# 2. ディレクトリの準備
if [ -d "$BUILD_DIR" ]; then
    echo "🧹 Cleaning previous build artifacts..."
    rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# 3. CMakeの生成 (Generator)
echo "⚙️  Generating Xcode project..."
cd "$BUILD_DIR"

cmake "$NATIVE_DIR" \
    -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
    -DCMAKE_IOS_INSTALL_COMBINED=YES

# 4. ビルド実行 (Releaseモード)
echo "🔨 Compiling framework..."
cmake --build . --config Release --target "$PROJECT_NAME"

# 5. 成果物の移動
echo "📦 Locating and copying framework..."
# Release-iphoneos などのサブフォルダから framework を探す
FRAMEWORK_PATH=$(find . -name "$PROJECT_NAME.framework" -type d | head -n 1)

if [ -z "$FRAMEWORK_PATH" ]; then
    echo "❌ Error: Framework build failed or output not found."
    exit 1
fi

# 既存のものを削除して上書きコピー
rm -rf "$OUTPUT_DIR/$PROJECT_NAME.framework"
cp -R "$FRAMEWORK_PATH" "$OUTPUT_DIR/"

echo "✅ Build Success!"
echo "   Framework is ready at: $OUTPUT_DIR/$PROJECT_NAME.framework"
