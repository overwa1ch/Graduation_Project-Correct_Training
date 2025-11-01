#!/bin/bash

# AIWA App - 本地 CI 测试脚本
# 在提交代码前运行此脚本，确保能通过 CI 检查

set -e  # 遇到错误立即退出

echo "============================================================"
echo "           AIWA APP - 本地 CI 测试"
echo "============================================================"
echo ""

# 切换到 aiwa_app 目录
cd "$(dirname "$0")/.."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试结果统计
PASSED=0
FAILED=0

# 运行测试函数
run_test() {
    local name="$1"
    local command="$2"
    
    echo ""
    echo "------------------------------------------------------------"
    echo "Running: $name"
    echo "------------------------------------------------------------"
    
    if eval "$command"; then
        echo -e "${GREEN}✅ $name passed${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ $name failed${NC}"
        ((FAILED++))
        return 1
    fi
}

# 1. 检查 Flutter 环境
echo "🔍 Checking Flutter environment..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi
flutter --version

# 2. 获取依赖
echo ""
echo "📦 Getting dependencies..."
flutter pub get

# 3. 静态代码分析
run_test "📊 Static Analysis" "flutter analyze --no-pub --no-fatal-infos"

# 4. 所有测试
run_test "🧪 All Tests" "flutter test --no-pub --reporter expanded --coverage"

# 5. 覆盖率检查
run_test "📊 Coverage Check (>85%)" "dart tool/check_coverage.dart --threshold=85"

# 6. 主题测试
run_test "🎨 Theme Tests" "flutter test test/theme_test.dart --no-pub --reporter expanded"

# 7. Tokens Schema 测试
run_test "📝 Tokens Schema Tests" "flutter test test/tokens_schema_test.dart --no-pub --reporter expanded"

# 8. Widget 测试
run_test "🖼️  Widget Tests" "flutter test test/widget_test.dart --no-pub --reporter expanded"

# 9. Tokens 同步验证
if [ -d "tool" ] && [ -f "tool/sync_tokens.dart" ]; then
    echo ""
    echo "------------------------------------------------------------"
    echo "Running: 🔄 Tokens Sync Validation"
    echo "------------------------------------------------------------"
    
    cd tool
    dart pub get > /dev/null 2>&1
    cd ..
    
    if dart tool/sync_tokens.dart --tokens-dir=lib/theme/tokens --dry-run; then
        echo -e "${GREEN}✅ Tokens Sync Validation passed${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ Tokens Sync Validation failed${NC}"
        ((FAILED++))
    fi
fi

# 10. 构建验证（可选，耗时较长）
if [ "$1" == "--with-build" ]; then
    run_test "🏗️  Build Validation" "flutter build apk --debug --no-pub"
fi

# 最终报告
echo ""
echo "============================================================"
echo "                    FINAL REPORT"
echo "============================================================"
echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉${NC}"
    echo -e "${GREEN}                                                    ${NC}"
    echo -e "${GREEN}   ✅ All checks passed!                           ${NC}"
    echo -e "${GREEN}                                                    ${NC}"
    echo -e "${GREEN}   Ready to commit and push! 🚀                    ${NC}"
    echo -e "${GREEN}                                                    ${NC}"
    echo -e "${GREEN}🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌${NC}"
    echo -e "${RED}                                                    ${NC}"
    echo -e "${RED}   ❌ Some checks failed!                           ${NC}"
    echo -e "${RED}                                                    ${NC}"
    echo -e "${RED}   Please fix the issues before committing.        ${NC}"
    echo -e "${RED}                                                    ${NC}"
    echo -e "${RED}❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌${NC}"
    echo ""
    exit 1
fi

