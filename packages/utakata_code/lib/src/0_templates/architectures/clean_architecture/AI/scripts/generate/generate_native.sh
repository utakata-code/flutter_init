#!/bin/bash

# ==========================================
# Flutter + JUCE Native Environment Setup (Complete)
# Target: JUCE 8.0.12 (Stable as of Jan 2026)
# Includes: Directory Setup, CMake, C++ Source, CocoaPods Integration
# ==========================================

JUCE_REPO="https://github.com/juce-framework/JUCE.git"
JUCE_TAG="8.0.12" 
NATIVE_DIR="native"
PODSPEC_NAME="native_audio"

echo "🚀 Setting up native environment for Flutter + JUCE..."

# -------------------------------------------
# 1. ディレクトリ作成
# -------------------------------------------
if [ -d "$NATIVE_DIR" ]; then
    echo "⚠️  Directory '$NATIVE_DIR' already exists. Skipping creation."
else
    mkdir -p "$NATIVE_DIR"/{src,include}
    echo "✅ Created directory structure: $NATIVE_DIR/{src,include}"
fi

# -------------------------------------------
# 2. JUCEのインストール
# -------------------------------------------
JUCE_DIR="$NATIVE_DIR/juce"
if [ -d "$JUCE_DIR" ]; then
    echo "ℹ️  JUCE directory already exists."
else
    echo "📥 Installing JUCE ($JUCE_TAG)..."
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git submodule add --depth 1 --branch $JUCE_TAG $JUCE_REPO $JUCE_DIR
    else
        echo "⚠️  Not a git repository. Cloning JUCE directly..."
        git clone --depth 1 --branch $JUCE_TAG $JUCE_REPO $JUCE_DIR
    fi
fi

# -------------------------------------------
# 3. CMakeLists.txt の生成
# -------------------------------------------
CMAKE_FILE="$NATIVE_DIR/CMakeLists.txt"
if [ ! -f "$CMAKE_FILE" ]; then
    cat <<EOF > "$CMAKE_FILE"
cmake_minimum_required(VERSION 3.15)
project($PODSPEC_NAME VERSION 0.0.1 LANGUAGES C CXX)

add_subdirectory(juce)

add_library($PODSPEC_NAME SHARED
    src/audio_engine.cpp
)

target_include_directories($PODSPEC_NAME PUBLIC
    include
    juce/modules
)

target_link_libraries($PODSPEC_NAME PRIVATE
    juce::juce_core
    juce::juce_events
    juce::juce_audio_basics
    juce::juce_audio_devices
    juce::juce_audio_formats
    juce::juce_audio_processors
    juce::juce_dsp
)

target_compile_features($PODSPEC_NAME PUBLIC cxx_std_20)

if (MSVC)
    target_compile_definitions($PODSPEC_NAME PRIVATE JUCE_MSVC=1)
elseif (APPLE)
    target_link_options($PODSPEC_NAME PRIVATE "-undefined" "dynamic_lookup")
endif()
EOF
    echo "✅ Created $CMAKE_FILE"
else
    echo "ℹ️  $CMAKE_FILE already exists. Skipping."
fi

# -------------------------------------------
# 4. ヘッダーファイル (Bridge API) の生成
# -------------------------------------------
HEADER_FILE="$NATIVE_DIR/include/bridge_api.h"
if [ ! -f "$HEADER_FILE" ]; then
    cat <<EOF > "$HEADER_FILE"
#pragma once
#include <stdint.h>

#if _WIN32
    #define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
    #define FFI_PLUGIN_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

extern "C" {
    FFI_PLUGIN_EXPORT void native_audio_init();
    FFI_PLUGIN_EXPORT float native_audio_get_input_level();
    FFI_PLUGIN_EXPORT void native_audio_cleanup();
}
EOF
    echo "✅ Created $HEADER_FILE"
else
    echo "ℹ️  $HEADER_FILE already exists. Skipping."
fi

# -------------------------------------------
# 5. 実装ファイル (Source) の生成
# -------------------------------------------
SRC_FILE="$NATIVE_DIR/src/audio_engine.cpp"
if [ ! -f "$SRC_FILE" ]; then
    cat <<EOF > "$SRC_FILE"
#include "bridge_api.h"
#include <juce_audio_devices/juce_audio_devices.h>

namespace {
    std::unique_ptr<juce::AudioDeviceManager> deviceManager;
}

extern "C" {
    void native_audio_init() {
        juce::MessageManager::getInstance();
        deviceManager = std::make_unique<juce::AudioDeviceManager>();
        deviceManager->initialiseWithDefaultDevices(1, 2);
    }

    float native_audio_get_input_level() {
        return 0.5f; 
    }

    void native_audio_cleanup() {
        deviceManager = nullptr;
        juce::MessageManager::deleteInstance();
    }
}
EOF
    echo "✅ Created $SRC_FILE"
else
    echo "ℹ️  $SRC_FILE already exists. Skipping."
fi

# -------------------------------------------
# 6. .podspec の作成 (iOS連携用)
# -------------------------------------------
PODSPEC_FILE="$NATIVE_DIR/$PODSPEC_NAME.podspec"
if [ ! -f "$PODSPEC_FILE" ]; then
    cat <<EOF > "$PODSPEC_FILE"
Pod::Spec.new do |s|
  s.name             = '$PODSPEC_NAME'
  s.version          = '0.0.1'
  s.summary          = 'A standard C++ audio engine using JUCE.'
  s.homepage         = 'http://example.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '14.0'
  
  # build_native_ios.sh で生成されるFrameworkを参照
  s.vendored_frameworks = '../ios/Frameworks/$PODSPEC_NAME.framework'
  s.library = 'c++'
end
EOF
    echo "✅ Created $PODSPEC_FILE"
else
    echo "ℹ️  $PODSPEC_FILE already exists. Skipping."
fi

# -------------------------------------------
# 7. ios/Podfile の編集
# -------------------------------------------
PODFILE="ios/Podfile"
POD_LINE="  pod '$PODSPEC_NAME', :path => '../$NATIVE_DIR'"

if [ -f "$PODFILE" ]; then
    if grep -q "$PODSPEC_NAME" "$PODFILE"; then
        echo "ℹ️  $PODSPEC_NAME is already in $PODFILE."
    else
        echo "✏️  Adding $PODSPEC_NAME to $PODFILE..."
        # MacOS/Linux互換のためperlを使用 ("target 'Runner' do" の次の行に挿入)
        perl -i -pe "s/target 'Runner' do/target 'Runner' do\n$POD_LINE/" "$PODFILE"
        echo "✅ Updated $PODFILE"
    fi
else
    echo "⚠️  $PODFILE not found. Skipping Podfile update."
fi

# -------------------------------------------
# 8. pod install の実行
# -------------------------------------------
if [ -d "ios" ]; then
    echo "🍎 Running pod install..."
    
    # Framework置き場がないとpod installが警告を出す場合があるため空作成
    mkdir -p ios/Frameworks
    
    (cd ios && pod install)
    
    if [ $? -eq 0 ]; then
        echo "✅ pod install completed successfully."
    else
        echo "⚠️  pod install finished with errors (Likely because framework is not built yet)."
        echo "   This is normal! Please run 'AI/scripts/build/build_native_ios.sh' next."
    fi
else
    echo "⚠️  'ios' directory not found. Skipping pod install."
fi

echo "🎉 Setup complete!"
echo "---------------------------------------------------"
echo "NEXT STEPS:"
echo "1. Run Build Script: ./AI/scripts/build/build_native_ios.sh"
echo "2. Run Flutter:      flutter run"
echo "---------------------------------------------------"
