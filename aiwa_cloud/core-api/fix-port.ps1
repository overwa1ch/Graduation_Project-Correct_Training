# =============================================================================
# 修复端口问题脚本
# =============================================================================
# Windows 系统在端口 3000-3012 范围内有保留端口
# 此脚本会检查并建议可用端口
# =============================================================================

Write-Host "🔍 检查端口配置..." -ForegroundColor Cyan
Write-Host ""

# 检查当前 .env 配置
if (Test-Path ".env") {
    $envContent = Get-Content .env
    $portLine = $envContent | Select-String "PORT="
    
    if ($portLine) {
        $currentPort = ($portLine -split "=")[1].Trim()
        Write-Host "当前配置端口: $currentPort" -ForegroundColor Yellow
        
        # 检查是否在保留范围内
        $reservedRanges = @(
            @{Start=3000; End=3012},
            @{Start=5000; End=5059}
        )
        
        $inReserved = $false
        foreach ($range in $reservedRanges) {
            if ([int]$currentPort -ge $range.Start -and [int]$currentPort -le $range.End) {
                $inReserved = $true
                Write-Host "❌ 端口 $currentPort 在 Windows 保留范围内 ($($range.Start)-$($range.End))" -ForegroundColor Red
                break
            }
        }
        
        if ($inReserved) {
            Write-Host ""
            Write-Host "💡 建议使用以下端口：" -ForegroundColor Cyan
            Write-Host "   - 8080 (推荐)" -ForegroundColor Green
            Write-Host "   - 8081" -ForegroundColor Green
            Write-Host "   - 4000" -ForegroundColor Green
            Write-Host "   - 5000 (需确保不被占用)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "修复方法：" -ForegroundColor Cyan
            Write-Host "   1. 编辑 .env 文件" -ForegroundColor White
            Write-Host "   2. 将 PORT=$currentPort 改为 PORT=8080" -ForegroundColor White
        } else {
            # 检查端口是否被占用
            $checkPort = Test-NetConnection -ComputerName localhost -Port $currentPort -InformationLevel Quiet -WarningAction SilentlyContinue
            if (-not $checkPort) {
                Write-Host "✅ 端口 $currentPort 可用" -ForegroundColor Green
            } else {
                Write-Host "⚠️  端口 $currentPort 可能被占用" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "⚠️  .env 文件中未找到 PORT 配置" -ForegroundColor Yellow
        Write-Host "   建议添加: PORT=8080" -ForegroundColor Cyan
    }
} else {
    Write-Host "❌ 未找到 .env 文件" -ForegroundColor Red
    Write-Host "   请先运行: Copy-Item env.sqlite.example .env" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Windows 保留端口范围：" -ForegroundColor Gray
Write-Host "  3000-3012 (可能影响 3000, 3001 等端口)" -ForegroundColor Gray
Write-Host "  50000-50059" -ForegroundColor Gray

