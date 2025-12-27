#!/bin/bash

# --- 설정 ---
XCFRAMEWORK_PATH="./sentencepiece.xcframework"
SCHEME_NAME="SentencePieceKit"

# --- 색상 ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- 상태 변수 ---
ARCH_IOS_DEVICE="❌"
ARCH_IOS_SIM="❌"
ARCH_MACOS="❌"
ARCH_WATCH_DEVICE="❌"
ARCH_WATCH_SIM="❌"
MODULEMAP_CHECK="❌"
BUILD_MACOS="❌"
BUILD_IOS_SIM="❌"
BUILD_WATCH_SIM="❌"

echo -e "${BLUE}==============================================${NC}"
echo -e "${BLUE}       SentencePieceKit 통합 검증 시작       ${NC}"
echo -e "${BLUE}==============================================${NC}"

# 1. 프레임워크 존재 확인
if [ ! -d "$XCFRAMEWORK_PATH" ]; then
    echo -e "${RED}[Critical] sentencepiece.xcframework를 찾을 수 없습니다!${NC}"
    exit 1
fi

echo -e "\n${YELLOW}[1/4] 아키텍처(Architecture) 검증 중...${NC}"

# 함수: 아키텍처 확인
check_arch() {
    local platform_path=$1
    local expected_archs=$2
    local label=$3
    
    # 경로 패턴 매칭을 위해 find 사용
    local lib_path=$(find "$XCFRAMEWORK_PATH" -path "*$platform_path*" -name "libsentencepiece.a" | head -n 1)
    
    if [ -z "$lib_path" ]; then
        echo -e "  - $label: ${RED}라이브러리 파일 없음${NC}"
        return 1
    fi

    local info=$(lipo -info "$lib_path")
    local pass=true
    
    for arch in $expected_archs; do
        if [[ "$info" != *"$arch"* ]]; then
            pass=false
        fi
    done

    if [ "$pass" = true ]; then
        echo -e "  - $label: ${GREEN}PASS${NC} (Detected: $(echo $info | awk -F: '{print $NF}'))"
        return 0
    else
        echo -e "  - $label: ${RED}FAIL${NC} (Expected: $expected_archs / Got: $(echo $info | awk -F: '{print $NF}'))"
        return 1
    fi
}

check_arch "ios-arm64" "arm64" "iOS Device" && ARCH_IOS_DEVICE="✅"
check_arch "ios-arm64_x86_64-simulator" "arm64 x86_64" "iOS Simulator" && ARCH_IOS_SIM="✅"
check_arch "macos-" "arm64 x86_64" "macOS (Universal)" && ARCH_MACOS="✅"
check_arch "watchos-arm64_32_armv7k" "arm64_32 armv7k" "watchOS Device" && ARCH_WATCH_DEVICE="✅"
check_arch "watchos-arm64_x86_64-simulator" "arm64" "watchOS Simulator" && ARCH_WATCH_SIM="✅"


echo -e "\n${YELLOW}[2/4] Modulemap 검증 중...${NC}"
# 모든 헤더 폴더에 module.modulemap이 있는지 확인
MISSING_MAPS=$(find "$XCFRAMEWORK_PATH" -name "Headers" | while read header_dir; do
    if [ ! -f "$header_dir/module.modulemap" ]; then
        echo "$header_dir"
    fi
done)

if [ -z "$MISSING_MAPS" ]; then
    echo -e "  - 모든 플랫폼에 module.modulemap 존재: ${GREEN}PASS${NC}"
    MODULEMAP_CHECK="✅"
else
    echo -e "  - ${RED}FAIL${NC}: 다음 경로에 module.modulemap이 없습니다."
    echo "$MISSING_MAPS"
fi


echo -e "\n${YELLOW}[3/4] macOS 빌드 테스트 (swift build)...${NC}"
rm -rf .build
if swift build > /dev/null 2>&1; then
    echo -e "  - macOS Build: ${GREEN}PASS${NC}"
    BUILD_MACOS="✅"
else
    echo -e "  - macOS Build: ${RED}FAIL${NC}"
    # 에러 로그 확인을 위해 다시 실행해서 보여줌 (선택)
    # swift build
fi


echo -e "\n${YELLOW}[4/4] 시뮬레이터 빌드 테스트 (xcodebuild)...${NC}"

# iOS Simulator
echo -n "  - iOS Simulator Build: "
if xcodebuild -scheme "$SCHEME_NAME" -destination 'generic/platform=iOS Simulator' build -quiet > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    BUILD_IOS_SIM="✅"
else
    echo -e "${RED}FAIL${NC}"
fi

# watchOS Simulator
echo -n "  - watchOS Simulator Build: "
if xcodebuild -scheme "$SCHEME_NAME" -destination 'generic/platform=watchOS Simulator' build -quiet > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    BUILD_WATCH_SIM="✅"
else
    echo -e "${RED}FAIL${NC} (런타임 미설치시 실패할 수 있음)"
fi


echo -e "\n${BLUE}==============================================${NC}"
echo -e "${BLUE}             최종 검증 리포트                ${NC}"
echo -e "${BLUE}==============================================${NC}"
echo -e "1. Architecture Check:"
echo -e "   - iOS Device:       $ARCH_IOS_DEVICE"
echo -e "   - iOS Simulator:    $ARCH_IOS_SIM"
echo -e "   - macOS:            $ARCH_MACOS"
echo -e "   - watchOS Device:   $ARCH_WATCH_DEVICE"
echo -e "   - watchOS Simulator:$ARCH_WATCH_SIM"
echo -e "2. Modulemap Check:    $MODULEMAP_CHECK"
echo -e "3. Build Tests:"
echo -e "   - macOS (SwiftPM):  $BUILD_MACOS"
echo -e "   - iOS Simulator:    $BUILD_IOS_SIM"
echo -e "   - watchOS Simulator:$BUILD_WATCH_SIM"
echo -e "${BLUE}==============================================${NC}"

if [[ "$ARCH_IOS_SIM" == "✅" && "$ARCH_MACOS" == "✅" && "$ARCH_WATCH_SIM" == "✅" && "$BUILD_MACOS" == "✅" && "$BUILD_IOS_SIM" == "✅" ]]; then
    echo -e "\n🎉 ${GREEN}모든 중요 테스트 통과! 깃허브에 올려도 좋습니다!${NC} 🎉\n"
else
    echo -e "\n⚠️ ${RED}일부 테스트 실패. 위 로그를 확인하세요.${NC}\n"
fi
