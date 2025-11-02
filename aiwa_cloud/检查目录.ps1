# =============================================================================
# 目录检查脚本
# =============================================================================
# 用途：检查你是否在正确的目录下
# 使用：.\检查目录.ps1
# =============================================================================

Write-Host "📁 目录检查" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$currentPath = Get-Location
Write-Host "当前位置: $currentPath" -ForegroundColor Yellow

# 检查是否在 core-api 目录
$isInCoreApi = $currentPath.Path -like "*core-api*"
$hasEnvFile = Test-Path "env.sqlite.example"
$hasSchemaFile = Test-Path "prisma\schema.sqlite.prisma"

Write-Host ""
if ($isInCoreApi -and $hasEnvFile -and $hasSchemaFile) {
    Write-Host "✅ 位置正确！" -ForegroundColor Green
    Write-Host "   你可以在当前目录运行所有命令" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步：" -ForegroundColor Cyan
    Write-Host "   .\setup-sqlite.ps1  # 运行自动设置脚本" -ForegroundColor White
    Write-Host "   或" -ForegroundColor Gray
    Write-Host "   Copy-Item env.sqlite.example .env" -ForegroundColor White
} else {
    Write-Host "❌ 位置不正确！" -ForegroundColor Red
    Write-Host ""
    
    if (-not $isInCoreApi) {
        Write-Host "   问题：不在 core-api 目录下" -ForegroundColor Yellow
    }
    if (-not $hasEnvFile) {
        Write-Host "   问题：找不到 env.sqlite.example 文件" -ForegroundColor Yellow
    }
    if (-not $hasSchemaFile) {
        Write-Host "   问题：找不到 prisma\schema.sqlite.prisma 文件" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "解决：" -ForegroundColor Cyan
    Write-Host "   cd aiwa_cloud\core-api" -ForegroundColor White
    Write-Host "   然后再次运行此脚本检查" -ForegroundColor Gray
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan

