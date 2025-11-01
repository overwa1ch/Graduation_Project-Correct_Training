# AIWA App - 本地 CI 测试脚本 (PowerShell)
# 在提交代码前运行此脚本，确保能通过 CI 检查

$ErrorActionPreference = "Stop"

Write-Host "============================================================"
Write-Host "           AIWA APP - 本地 CI 测试"
Write-Host "============================================================"
Write-Host ""

# 切换到 aiwa_app 目录
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptPath "..")

# 测试结果统计
$script:Passed = 0
$script:Failed = 0

# 运行测试函数
function Run-Test {
    param(
        [string]$Name,
        [scriptblock]$Command
    )
    
    Write-Host ""
    Write-Host "------------------------------------------------------------"
    Write-Host "Running: $Name"
    Write-Host "------------------------------------------------------------"
    
    try {
        & $Command
        Write-Host "✅ $Name passed" -ForegroundColor Green
        $script:Passed++
        return $true
    }
    catch {
        Write-Host "❌ $Name failed" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $script:Failed++
        return $false
    }
}

# 1. 检查 Flutter 环境
Write-Host "🔍 Checking Flutter environment..."
try {
    flutter --version
}
catch {
    Write-Host "❌ Flutter not found. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# 2. 获取依赖
Write-Host ""
Write-Host "📦 Getting dependencies..."
flutter pub get

# 3. 静态代码分析
Run-Test "📊 Static Analysis" {
    flutter analyze --no-pub --no-fatal-infos
    if ($LASTEXITCODE -ne 0) { throw "Analysis failed" }
}

# 4. 所有测试
Run-Test "🧪 All Tests" {
    flutter test --no-pub --reporter expanded --coverage
    if ($LASTEXITCODE -ne 0) { throw "Tests failed" }
}

# 5. 覆盖率检查
Run-Test "📊 Coverage Check (>85%)" {
    dart tool/check_coverage.dart --threshold=85
    if ($LASTEXITCODE -ne 0) { throw "Coverage below threshold" }
}

# 6. 主题测试
Run-Test "🎨 Theme Tests" {
    flutter test test/theme_test.dart --no-pub --reporter expanded
    if ($LASTEXITCODE -ne 0) { throw "Theme tests failed" }
}

# 7. Tokens Schema 测试
Run-Test "📝 Tokens Schema Tests" {
    flutter test test/tokens_schema_test.dart --no-pub --reporter expanded
    if ($LASTEXITCODE -ne 0) { throw "Schema tests failed" }
}

# 8. Widget 测试
Run-Test "🖼️  Widget Tests" {
    flutter test test/widget_test.dart --no-pub --reporter expanded
    if ($LASTEXITCODE -ne 0) { throw "Widget tests failed" }
}

# 9. Tokens 同步验证
if ((Test-Path "tool") -and (Test-Path "tool/sync_tokens.dart")) {
    Write-Host ""
    Write-Host "------------------------------------------------------------"
    Write-Host "Running: 🔄 Tokens Sync Validation"
    Write-Host "------------------------------------------------------------"
    
    Push-Location tool
    dart pub get | Out-Null
    Pop-Location
    
    try {
        dart tool/sync_tokens.dart --tokens-dir=lib/theme/tokens --dry-run
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Tokens Sync Validation passed" -ForegroundColor Green
            $script:Passed++
        }
        else {
            throw "Sync validation failed"
        }
    }
    catch {
        Write-Host "❌ Tokens Sync Validation failed" -ForegroundColor Red
        $script:Failed++
    }
}

# 10. 构建验证（可选，耗时较长）
if ($args -contains "--with-build") {
    Run-Test "🏗️  Build Validation" {
        flutter build apk --debug --no-pub
        if ($LASTEXITCODE -ne 0) { throw "Build failed" }
    }
}

# 最终报告
Write-Host ""
Write-Host "============================================================"
Write-Host "                    FINAL REPORT"
Write-Host "============================================================"
Write-Host ""
Write-Host "Passed: $script:Passed"
Write-Host "Failed: $script:Failed"
Write-Host ""

if ($script:Failed -eq 0) {
    Write-Host "🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉" -ForegroundColor Green
    Write-Host "                                                    " -ForegroundColor Green
    Write-Host "   ✅ All checks passed!                           " -ForegroundColor Green
    Write-Host "                                                    " -ForegroundColor Green
    Write-Host "   Ready to commit and push! 🚀                    " -ForegroundColor Green
    Write-Host "                                                    " -ForegroundColor Green
    Write-Host "🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉" -ForegroundColor Green
    Write-Host ""
    exit 0
}
else {
    Write-Host "❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌" -ForegroundColor Red
    Write-Host "                                                    " -ForegroundColor Red
    Write-Host "   ❌ Some checks failed!                           " -ForegroundColor Red
    Write-Host "                                                    " -ForegroundColor Red
    Write-Host "   Please fix the issues before committing.        " -ForegroundColor Red
    Write-Host "                                                    " -ForegroundColor Red
    Write-Host "❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌" -ForegroundColor Red
    Write-Host ""
    exit 1
}

