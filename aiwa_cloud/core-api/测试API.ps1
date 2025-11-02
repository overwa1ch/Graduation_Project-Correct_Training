# =============================================================================
# API 测试脚本
# =============================================================================
# 用途：快速测试 API 是否正常工作
# =============================================================================

Write-Host "🧪 测试 AIWA Auth API" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080"

# 测试 1: 健康检查
Write-Host "📋 测试 1/3: 健康检查..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ 健康检查通过" -ForegroundColor Green
        $health = $response.Content | ConvertFrom-Json
        Write-Host "   状态: $($health.status)" -ForegroundColor White
        Write-Host "   服务: $($health.service)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ 健康检查失败: $_" -ForegroundColor Red
    Write-Host "   请确保服务器正在运行 (npm run dev)" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 测试 2: 注册用户
Write-Host "📋 测试 2/3: 用户注册..." -ForegroundColor Yellow
$testEmail = "test_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
$testPassword = "test123456"

try {
    $body = @{
        email = $testEmail
        password = $testPassword
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/register" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body `
        -UseBasicParsing `
        -TimeoutSec 10

    if ($response.StatusCode -eq 201) {
        Write-Host "✅ 注册成功" -ForegroundColor Green
        $result = $response.Content | ConvertFrom-Json
        Write-Host "   测试邮箱: $testEmail" -ForegroundColor White
        Write-Host "   Token: $($result.token.Substring(0, 20))..." -ForegroundColor Gray
        Write-Host "   Refresh Token: $($result.refresh_token.Substring(0, 20))..." -ForegroundColor Gray
        
        # 保存 token 供登录测试使用
        $global:refreshToken = $result.refresh_token
    }
} catch {
    $errorDetails = $_.ErrorDetails.Message
    if ($errorDetails -like "*already exists*") {
        Write-Host "⚠️  用户已存在（这是正常的，可以继续测试登录）" -ForegroundColor Yellow
    } else {
        Write-Host "❌ 注册失败: $errorDetails" -ForegroundColor Red
    }
}

Write-Host ""

# 测试 3: 用户登录
Write-Host "📋 测试 3/3: 用户登录..." -ForegroundColor Yellow
try {
    $body = @{
        email = $testEmail
        password = $testPassword
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body `
        -UseBasicParsing `
        -TimeoutSec 10

    if ($response.StatusCode -eq 200) {
        Write-Host "✅ 登录成功" -ForegroundColor Green
        $result = $response.Content | ConvertFrom-Json
        Write-Host "   Token: $($result.token.Substring(0, 20))..." -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ 登录失败: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ API 测试完成！" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📚 接下来：" -ForegroundColor Cyan
Write-Host "   1. 使用 Postman 或 curl 测试更多功能" -ForegroundColor White
Write-Host "   2. 查看数据库: npx prisma studio" -ForegroundColor White
Write-Host "   3. 集成到 Flutter 应用" -ForegroundColor White
Write-Host ""

