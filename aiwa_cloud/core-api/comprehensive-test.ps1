# =============================================================================
# 全面 API 测试脚本
# =============================================================================
# 测试内容：
# 1. 健康检查
# 2. Token 刷新
# 3. 多次注册/登录测试
# 4. 错误场景测试（错误密码、重复注册等）
# =============================================================================

Write-Host "🧪 全面测试 AIWA Auth API" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080"
$testResults = @{
    Passed = 0
    Failed = 0
    Total = 0
}

function Test-Step {
    param(
        [string]$Name,
        [scriptblock]$TestScript
    )
    
    $testResults.Total++
    Write-Host "📋 测试 $($testResults.Total): $Name" -ForegroundColor Yellow
    
    try {
        $result = & $TestScript
        if ($result -eq $true -or $result -eq $null) {
            Write-Host "   ✅ 通过" -ForegroundColor Green
            $testResults.Passed++
            return $true
        } else {
            Write-Host "   ❌ 失败: $result" -ForegroundColor Red
            $testResults.Failed++
            return $false
        }
    } catch {
        Write-Host "   ❌ 异常: $_" -ForegroundColor Red
        $testResults.Failed++
        return $false
    }
}

# =============================================================================
# 测试 1: 健康检查
# =============================================================================
Test-Step "健康检查" {
    $response = Invoke-WebRequest -Uri "$baseUrl/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        $health = $response.Content | ConvertFrom-Json
        Write-Host "   状态: $($health.status)" -ForegroundColor Gray
        Write-Host "   服务: $($health.service)" -ForegroundColor Gray
        return $true
    }
    return $false
}

Write-Host ""

# =============================================================================
# 测试 2: 正常注册
# =============================================================================
$testEmail = "comprehensive_test_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
$testPassword = "test123456"
$global:savedRefreshToken = $null
$global:savedAccessToken = $null

Test-Step "正常用户注册" {
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
        $result = $response.Content | ConvertFrom-Json
        $global:savedRefreshToken = $result.refresh_token
        $global:savedAccessToken = $result.token
        Write-Host "   测试邮箱: $testEmail" -ForegroundColor Gray
        Write-Host "   Token 已保存" -ForegroundColor Gray
        return $true
    }
    return $false
}

Write-Host ""

# =============================================================================
# 测试 3: 重复注册（应该失败）
# =============================================================================
Test-Step "重复注册相同邮箱（应该失败）" {
    $body = @{
        email = $testEmail
        password = "differentpassword"
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/register" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -UseBasicParsing `
            -TimeoutSec 10
        
        # 如果成功（不应该），测试失败
        Write-Host "   警告: 重复注册被允许（不应该）" -ForegroundColor Yellow
        return $false
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorContent = $_.ErrorDetails.Message
        if ($statusCode -eq 409) {
            Write-Host "   正确拒绝了重复注册" -ForegroundColor Gray
            return $true
        }
        if ($errorContent) {
            try {
                $errorResponse = $errorContent | ConvertFrom-Json
                if ($errorResponse.error.code -eq "USER_EXISTS") {
                    Write-Host "   正确拒绝了重复注册" -ForegroundColor Gray
                    return $true
                }
            } catch {
                # 忽略 JSON 解析错误
            }
        }
        return $false
    }
}

Write-Host ""

# =============================================================================
# 测试 4: 密码太短（应该失败）
# =============================================================================
Test-Step "注册密码太短（应该失败）" {
    $body = @{
        email = "shortpass_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
        password = "1234567"  # 少于8位
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/register" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -UseBasicParsing `
            -TimeoutSec 10
        
        # 如果成功（不应该），测试失败
        Write-Host "   警告: 短密码被接受（不应该）" -ForegroundColor Yellow
        return $false
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorContent = $_.ErrorDetails.Message
        if ($statusCode -eq 400) {
            Write-Host "   正确拒绝了短密码" -ForegroundColor Gray
            return $true
        }
        if ($errorContent) {
            try {
                $errorResponse = $errorContent | ConvertFrom-Json
                if ($errorResponse.error.code -eq "VALIDATION_ERROR") {
                    Write-Host "   正确拒绝了短密码" -ForegroundColor Gray
                    return $true
                }
            } catch {
                # 忽略 JSON 解析错误
            }
        }
        return $false
    }
}

Write-Host ""

# =============================================================================
# 测试 5: 无效邮箱格式（应该失败）
# =============================================================================
Test-Step "无效邮箱格式（应该失败）" {
    $body = @{
        email = "notanemail"
        password = "validpassword123"
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/register" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -UseBasicParsing `
            -TimeoutSec 10
        
        # 如果成功（不应该），测试失败
        Write-Host "   警告: 无效邮箱被接受（不应该）" -ForegroundColor Yellow
        return $false
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorContent = $_.ErrorDetails.Message
        if ($statusCode -eq 400) {
            Write-Host "   正确拒绝了无效邮箱" -ForegroundColor Gray
            return $true
        }
        if ($errorContent) {
            try {
                $errorResponse = $errorContent | ConvertFrom-Json
                if ($errorResponse.error.code -eq "VALIDATION_ERROR") {
                    Write-Host "   正确拒绝了无效邮箱" -ForegroundColor Gray
                    return $true
                }
            } catch {
                # 忽略 JSON 解析错误
            }
        }
        return $false
    }
}

Write-Host ""

# =============================================================================
# 测试 6: 正常登录
# =============================================================================
Test-Step "正常用户登录" {
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
        $result = $response.Content | ConvertFrom-Json
        $global:savedRefreshToken = $result.refresh_token
        $global:savedAccessToken = $result.token
        Write-Host "   登录成功，Token 已更新" -ForegroundColor Gray
        return $true
    }
    return $false
}

Write-Host ""

# =============================================================================
# 测试 7: 错误密码登录（应该失败）
# =============================================================================
Test-Step "错误密码登录（应该失败）" {
    $body = @{
        email = $testEmail
        password = "wrongpassword"
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/login" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -UseBasicParsing `
            -TimeoutSec 10
        
        # 如果成功（不应该），测试失败
        Write-Host "   警告: 错误密码被接受（不应该）" -ForegroundColor Yellow
        return $false
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorContent = $_.ErrorDetails.Message
        if ($statusCode -eq 401) {
            Write-Host "   正确拒绝了错误密码" -ForegroundColor Gray
            return $true
        }
        if ($errorContent) {
            try {
                $errorResponse = $errorContent | ConvertFrom-Json
                if ($errorResponse.error.code -eq "AUTH_INVALID") {
                    Write-Host "   正确拒绝了错误密码" -ForegroundColor Gray
                    return $true
                }
            } catch {
                # 忽略 JSON 解析错误
            }
        }
        return $false
    }
}

Write-Host ""

# =============================================================================
# 测试 8: 不存在的用户登录（应该失败）
# =============================================================================
Test-Step "不存在的用户登录（应该失败）" {
    $body = @{
        email = "nonexistent_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
        password = "anypassword"
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/login" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -UseBasicParsing `
            -TimeoutSec 10
        
        # 如果成功（不应该），测试失败
        Write-Host "   警告: 不存在用户被接受（不应该）" -ForegroundColor Yellow
        return $false
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorContent = $_.ErrorDetails.Message
        if ($statusCode -eq 401) {
            Write-Host "   正确拒绝了不存在用户" -ForegroundColor Gray
            return $true
        }
        if ($errorContent) {
            try {
                $errorResponse = $errorContent | ConvertFrom-Json
                if ($errorResponse.error.code -eq "AUTH_INVALID") {
                    Write-Host "   正确拒绝了不存在用户" -ForegroundColor Gray
                    return $true
                }
            } catch {
                # 忽略 JSON 解析错误
            }
        }
        return $false
    }
}

Write-Host ""

# =============================================================================
# 测试 9: Token 刷新
# =============================================================================
Test-Step "使用 Refresh Token 刷新 Access Token" {
    if (-not $global:savedRefreshToken) {
        Write-Host "   跳过: 没有可用的 refresh token" -ForegroundColor Yellow
        return $false
    }

    $body = @{
        refresh_token = $global:savedRefreshToken
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/refresh" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body `
        -UseBasicParsing `
        -TimeoutSec 10

    if ($response.StatusCode -eq 200) {
        $result = $response.Content | ConvertFrom-Json
        Write-Host "   新的 Access Token: $($result.token.Substring(0, [Math]::Min(30, $result.token.Length)))..." -ForegroundColor Gray
        return $true
    }
    return $false
}

Write-Host ""

# =============================================================================
# 测试 10: 无效 Refresh Token（应该失败）
# =============================================================================
Test-Step "使用无效 Refresh Token（应该失败）" {
    $body = @{
        refresh_token = "invalid_refresh_token_12345"
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/refresh" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -UseBasicParsing `
            -TimeoutSec 10
        
        # 如果成功（不应该），测试失败
        Write-Host "   警告: 无效 token 被接受（不应该）" -ForegroundColor Yellow
        return $false
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorContent = $_.ErrorDetails.Message
        if ($statusCode -eq 401) {
            Write-Host "   正确拒绝了无效 token" -ForegroundColor Gray
            return $true
        }
        if ($errorContent) {
            try {
                $errorResponse = $errorContent | ConvertFrom-Json
                if ($errorResponse.error.code -eq "AUTH_EXPIRED" -or $errorResponse.error.code -eq "AUTH_INVALID") {
                    Write-Host "   正确拒绝了无效 token" -ForegroundColor Gray
                    return $true
                }
            } catch {
                # 忽略 JSON 解析错误
            }
        }
        return $false
    }
}

Write-Host ""

# =============================================================================
# 测试 11: 多次注册不同用户
# =============================================================================
Test-Step "多次注册不同用户" {
    $successCount = 0
    for ($i = 1; $i -le 3; $i++) {
        $multiEmail = "multi_test_$i_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
        $body = @{
            email = $multiEmail
            password = "password123"
        } | ConvertTo-Json

        try {
            $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/register" `
                -Method POST `
                -ContentType "application/json" `
                -Body $body `
                -UseBasicParsing `
                -TimeoutSec 10
            
            if ($response.StatusCode -eq 201) {
                $successCount++
            }
        } catch {
            # 忽略错误，继续下一个
        }
    }
    
    if ($successCount -eq 3) {
        Write-Host "   成功注册了 3 个用户" -ForegroundColor Gray
        return $true
    } else {
        Write-Host "   只成功注册了 $successCount/3 个用户" -ForegroundColor Yellow
        return $false
    }
}

Write-Host ""

# =============================================================================
# 测试 12: 多次登录同一用户
# =============================================================================
Test-Step "多次登录同一用户（应生成不同的 Refresh Token）" {
    $tokens = @()
    for ($i = 1; $i -le 3; $i++) {
        $body = @{
            email = $testEmail
            password = $testPassword
        } | ConvertTo-Json

        try {
            $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/login" `
                -Method POST `
                -ContentType "application/json" `
                -Body $body `
                -UseBasicParsing `
                -TimeoutSec 10
            
            if ($response.StatusCode -eq 200) {
                $result = $response.Content | ConvertFrom-Json
                $tokens += $result.refresh_token
            }
        } catch {
            # 忽略错误
        }
    }
    
    # 检查是否有不同的 token
    $uniqueTokens = $tokens | Select-Object -Unique
    if ($uniqueTokens.Count -eq 3) {
        Write-Host "   每次登录都生成了不同的 Refresh Token（正确）" -ForegroundColor Gray
        return $true
    } else {
        Write-Host "   生成了 $($uniqueTokens.Count)/3 个不同的 Token" -ForegroundColor Yellow
        return $false
    }
}

Write-Host ""

# =============================================================================
# 测试结果总结
# =============================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📊 测试结果总结" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "总测试数: $($testResults.Total)" -ForegroundColor White
Write-Host "通过: $($testResults.Passed)" -ForegroundColor Green
Write-Host "失败: $($testResults.Failed)" -ForegroundColor Red
Write-Host ""

$successRate = [math]::Round(($testResults.Passed / $testResults.Total) * 100, 2)
Write-Host "成功率: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } else { "Yellow" })
Write-Host ""

if ($testResults.Failed -eq 0) {
    Write-Host "🎉 所有测试通过！" -ForegroundColor Green
} else {
    Write-Host "⚠️  有 $($testResults.Failed) 个测试失败，请检查上面的详细信息" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📚 提示：" -ForegroundColor Cyan
Write-Host "   - 刷新 Prisma Studio 查看数据库中的用户和 token" -ForegroundColor White
Write-Host "   - 使用 Postman 进行更详细的 API 测试" -ForegroundColor White
Write-Host "   - 查看服务器日志了解详细错误信息" -ForegroundColor White
Write-Host ""

