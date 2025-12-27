#!/bin/bash
set -e # 에러 발생 시 즉시 중단

# --- 설정 ---
# 현재 스크립트 위치의 상위 폴더(SentencePieceKit 루트)로 이동
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)
# sentencepiece C++ 원본 소스 위치
SP_SOURCE_DIR="$PROJECT_ROOT/../sentencepiece"
OUTPUT_FRAMEWORK="$PROJECT_ROOT/sentencepiece.xcframework"
TOOLCHAIN_URL="https://raw.githubusercontent.com/leetal/ios-cmake/master/ios.toolchain.cmake"

# 색상 설정
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting SentencePieceKit Build Process...${NC}"

# 0. 필수 도구 점검
for cmd in cmake lipo xcodebuild wget; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ Error: '$cmd' is not installed. Please install it first."
        exit 1
    fi
done

if [ ! -d "$SP_SOURCE_DIR" ]; then
    echo "❌ Error: Cannot find sentencepiece directory at $SP_SOURCE_DIR"
    echo "Please clone google/sentencepiece next to SentencePieceKit directory."
    exit 1
fi

cd "$SP_SOURCE_DIR"

# 1. Clean previous builds
echo -e "${GREEN}[1/8] Cleaning previous builds...${NC}"
rm -rf build_* staged_*

# 2. iOS Toolchain 준비 (자동 다운로드)
echo -e "${GREEN}[2/8] Checking for iOS Toolchain...${NC}"
if [ ! -f "cmake/ios.toolchain.cmake" ]; then
    echo -e "${YELLOW}  - Toolchain missing. Downloading from leetal/ios-cmake...${NC}"
    mkdir -p cmake
    wget -q -O cmake/ios.toolchain.cmake "$TOOLCHAIN_URL"
    echo -e "  - Downloaded ios.toolchain.cmake"
else
    echo -e "  - Toolchain already exists."
fi

# 3. CMakeLists.txt 패치 (watchOS Bundle 에러 방지 - 안전하게)
echo -e "${GREEN}[3/8] Patching CMakeLists.txt for watchOS...${NC}"
# 이미 패치되었는지 확인 후 적용
if grep -q "BUNDLE DESTINATION bin" src/CMakeLists.txt; then
    echo -e "  - Already patched."
else
    sed -i '' 's/RUNTIME DESTINATION/BUNDLE DESTINATION bin RUNTIME DESTINATION/g' src/CMakeLists.txt
    echo -e "  - Patch applied."
fi

# 4. Build iOS (Device & Simulator)
echo -e "${GREEN}[4/8] Building for iOS...${NC}"

# 4-1. iOS Device (arm64)
cmake -B build_ios_device -DCMAKE_TOOLCHAIN_FILE=cmake/ios.toolchain.cmake -DPLATFORM=OS64 -DENABLE_BITCODE=OFF -DENABLE_ARC=ON -DSPM_ENABLE_SHARED=OFF
cmake --build build_ios_device --config Release -j8
cmake --install build_ios_device --config Release --prefix staged_ios_device

# 4-2. iOS Simulator (arm64)
cmake -B build_ios_sim_arm64 -DCMAKE_TOOLCHAIN_FILE=cmake/ios.toolchain.cmake -DPLATFORM=SIMULATORARM64 -DENABLE_BITCODE=OFF -DENABLE_ARC=ON -DSPM_ENABLE_SHARED=OFF
cmake --build build_ios_sim_arm64 --config Release -j8
cmake --install build_ios_sim_arm64 --config Release --prefix staged_ios_sim_arm64

# 4-3. iOS Simulator (x86_64)
cmake -B build_ios_sim_x86 -DCMAKE_TOOLCHAIN_FILE=cmake/ios.toolchain.cmake -DPLATFORM=SIMULATOR64 -DENABLE_BITCODE=OFF -DENABLE_ARC=ON -DSPM_ENABLE_SHARED=OFF
cmake --build build_ios_sim_x86 --config Release -j8
cmake --install build_ios_sim_x86 --config Release --prefix staged_ios_sim_x86

# 4-4. Merge iOS Simulator Libs (Universal)
mkdir -p staged_ios_sim_combined/lib
mkdir -p staged_ios_sim_combined/include
lipo -create staged_ios_sim_arm64/lib/libsentencepiece.a staged_ios_sim_x86/lib/libsentencepiece.a -output staged_ios_sim_combined/lib/libsentencepiece.a
cp staged_ios_sim_arm64/include/*.h staged_ios_sim_combined/include/

# 5. Build macOS (Universal: arm64 + x86_64)
echo -e "${GREEN}[5/8] Building for macOS...${NC}"
cmake -B build_macos -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" -DCMAKE_BUILD_TYPE=Release -DENABLE_BITCODE=OFF -DENABLE_ARC=ON -DSPM_ENABLE_SHARED=OFF
cmake --build build_macos --config Release -j8
cmake --install build_macos --config Release --prefix staged_macos

# 6. Build watchOS (Device)
echo -e "${GREEN}[6/8] Building for watchOS Device...${NC}"
cmake -B build_watchos_device -DCMAKE_TOOLCHAIN_FILE=cmake/ios.toolchain.cmake -DPLATFORM=WATCHOS -DENABLE_BITCODE=OFF -DSPM_ENABLE_SHARED=OFF -DCMAKE_MACOSX_BUNDLE=OFF
cmake --build build_watchos_device --config Release -j8
cmake --install build_watchos_device --config Release --prefix staged_watchos_device

# 7. Build watchOS Simulator (arm64 + x86_64)
echo -e "${GREEN}[7/8] Building for watchOS Simulator...${NC}"
cmake -B build_watchos_sim -DCMAKE_TOOLCHAIN_FILE=cmake/ios.toolchain.cmake -DPLATFORM=SIMULATOR_WATCHOS -DENABLE_BITCODE=OFF -DSPM_ENABLE_SHARED=OFF -DCMAKE_MACOSX_BUNDLE=OFF -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
cmake --build build_watchos_sim --config Release -j8
cmake --install build_watchos_sim --config Release --prefix staged_watchos_sim

# 8. Generate & Copy Modulemap & Create XCFramework
echo -e "${GREEN}[8/8] Configuring Modulemaps & Creating XCFramework...${NC}"
echo 'module sentencepiece {
    header "sentencepiece_processor.h"
    export *
}' > module.modulemap

cp module.modulemap staged_ios_device/include/
cp module.modulemap staged_ios_sim_combined/include/
cp module.modulemap staged_macos/include/
cp module.modulemap staged_watchos_device/include/
cp module.modulemap staged_watchos_sim/include/

rm -rf sentencepiece.xcframework

xcodebuild -create-xcframework \
  -library staged_ios_device/lib/libsentencepiece.a \
  -headers staged_ios_device/include \
  -library staged_ios_sim_combined/lib/libsentencepiece.a \
  -headers staged_ios_sim_combined/include \
  -library staged_macos/lib/libsentencepiece.a \
  -headers staged_macos/include \
  -library staged_watchos_device/lib/libsentencepiece.a \
  -headers staged_watchos_device/include \
  -library staged_watchos_sim/lib/libsentencepiece.a \
  -headers staged_watchos_sim/include \
  -output sentencepiece.xcframework

# 결과물을 프로젝트 폴더로 이동
echo -e "${BLUE}📦 Copying framework to project...${NC}"
rm -rf "$OUTPUT_FRAMEWORK"
cp -r sentencepiece.xcframework "$PROJECT_ROOT/"

echo -e "${GREEN}✅ Build Success! Framework is located at: $OUTPUT_FRAMEWORK${NC}"
