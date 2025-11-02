# Advanced API Test Script
# Tests: Token refresh, multiple registrations, error scenarios

Write-Host "Advanced AIWA Auth API Testing" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080"
$testEmail = "adv_test_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
$testPassword = "test123456"
$global:refreshToken = $null

# Test 1: Health Check
Write-Host "Test 1: Health Check" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "  PASS: Service is running" -ForegroundColor Green
} catch {
    Write-Host "  FAIL: Service is not running" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Register user
Write-Host "Test 2: Register User" -ForegroundColor Yellow
try {
    $body = @{ email = $testEmail; password = $testPassword } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/register" `
        -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
    $result = $response.Content | ConvertFrom-Json
    $global:refreshToken = $result.refresh_token
    Write-Host "  PASS: User registered" -ForegroundColor Green
    Write-Host "  Email: $testEmail" -ForegroundColor Gray
} catch {
    Write-Host "  FAIL: Registration failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 3: Duplicate Registration (should fail)
Write-Host "Test 3: Duplicate Registration (should fail)" -ForegroundColor Yellow
try {
    $body = @{ email = $testEmail; password = "different" } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/register" `
        -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
    Write-Host "  FAIL: Duplicate registration was allowed" -ForegroundColor Red
} catch {
    $statusCode = 0
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode.value__
    }
    if ($statusCode -eq 409) {
        Write-Host "  PASS: Correctly rejected duplicate registration" -ForegroundColor Green
    } else {
        Write-Host "  WARN: Got status $statusCode instead of 409" -ForegroundColor Yellow
    }
}

Write-Host ""

# Test 4: Short Password (should fail)
Write-Host "Test 4: Short Password (should fail)" -ForegroundColor Yellow
try {
    $body = @{ email = "short_$(Get-Date -Format 'yyyyMMddHHmmss')@test.com"; password = "1234567" } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/register" `
        -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
    Write-Host "  FAIL: Short password was accepted" -ForegroundColor Red
} catch {
    $statusCode = 0
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode.value__
    }
    if ($statusCode -eq 400) {
        Write-Host "  PASS: Correctly rejected short password" -ForegroundColor Green
    } else {
        Write-Host "  WARN: Got status $statusCode instead of 400" -ForegroundColor Yellow
    }
}

Write-Host ""

# Test 5: Invalid Email (should fail)
Write-Host "Test 5: Invalid Email Format (should fail)" -ForegroundColor Yellow
try {
    $body = @{ email = "notanemail"; password = "validpass123" } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/register" `
        -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
    Write-Host "  FAIL: Invalid email was accepted" -ForegroundColor Red
} catch {
    $statusCode = 0
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode.value__
    }
    if ($statusCode -eq 400) {
        Write-Host "  PASS: Correctly rejected invalid email" -ForegroundColor Green
    } else {
        Write-Host "  WARN: Got status $statusCode instead of 400" -ForegroundColor Yellow
    }
}

Write-Host ""

# Test 6: Login
Write-Host "Test 6: Login" -ForegroundColor Yellow
try {
    $body = @{ email = $testEmail; password = $testPassword } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/login" `
        -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
    $result = $response.Content | ConvertFrom-Json
    $global:refreshToken = $result.refresh_token
    Write-Host "  PASS: Login successful" -ForegroundColor Green
} catch {
    Write-Host "  FAIL: Login failed" -ForegroundColor Red
}

Write-Host ""

# Test 7: Wrong Password (should fail)
Write-Host "Test 7: Wrong Password (should fail)" -ForegroundColor Yellow
try {
    $body = @{ email = $testEmail; password = "wrongpassword" } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/login" `
        -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
    Write-Host "  FAIL: Wrong password was accepted" -ForegroundColor Red
} catch {
    $statusCode = 0
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode.value__
    }
    if ($statusCode -eq 401) {
        Write-Host "  PASS: Correctly rejected wrong password" -ForegroundColor Green
    } else {
        Write-Host "  WARN: Got status $statusCode instead of 401" -ForegroundColor Yellow
    }
}

Write-Host ""

# Test 8: Non-existent User (should fail)
Write-Host "Test 8: Non-existent User (should fail)" -ForegroundColor Yellow
try {
    $body = @{ email = "nonexistent_$(Get-Date -Format 'yyyyMMddHHmmss')@test.com"; password = "any" } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/login" `
        -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
    Write-Host "  FAIL: Non-existent user was accepted" -ForegroundColor Red
} catch {
    $statusCode = 0
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode.value__
    }
    if ($statusCode -eq 401) {
        Write-Host "  PASS: Correctly rejected non-existent user" -ForegroundColor Green
    } else {
        Write-Host "  WARN: Got status $statusCode instead of 401" -ForegroundColor Yellow
    }
}

Write-Host ""

# Test 9: Token Refresh
Write-Host "Test 9: Refresh Token" -ForegroundColor Yellow
if ($global:refreshToken) {
    try {
        $body = @{ refresh_token = $global:refreshToken } | ConvertTo-Json
        $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/refresh" `
            -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
        $result = $response.Content | ConvertFrom-Json
        Write-Host "  PASS: Token refreshed successfully" -ForegroundColor Green
        Write-Host "  New token: $($result.token.Substring(0, [Math]::Min(30, $result.token.Length)))..." -ForegroundColor Gray
    } catch {
        Write-Host "  FAIL: Token refresh failed" -ForegroundColor Red
    }
} else {
    Write-Host "  SKIP: No refresh token available" -ForegroundColor Yellow
}

Write-Host ""

# Test 10: Invalid Refresh Token (should fail)
Write-Host "Test 10: Invalid Refresh Token (should fail)" -ForegroundColor Yellow
try {
    $body = @{ refresh_token = "invalid_token_12345" } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/refresh" `
        -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
    Write-Host "  FAIL: Invalid token was accepted" -ForegroundColor Red
} catch {
    $statusCode = 0
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode.value__
    }
    if ($statusCode -eq 401) {
        Write-Host "  PASS: Correctly rejected invalid token" -ForegroundColor Green
    } else {
        Write-Host "  WARN: Got status $statusCode instead of 401" -ForegroundColor Yellow
    }
}

Write-Host ""

# Test 11: Multiple Registrations
Write-Host "Test 11: Multiple User Registrations" -ForegroundColor Yellow
$successCount = 0
for ($i = 1; $i -le 3; $i++) {
    $multiEmail = "multi_$i_$(Get-Date -Format 'yyyyMMddHHmmss')@test.com"
    $body = @{ email = $multiEmail; password = "password123" } | ConvertTo-Json
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/register" `
            -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
        $successCount++
    } catch {
        # Ignore errors
    }
}
if ($successCount -eq 3) {
    Write-Host "  PASS: Successfully registered 3 users" -ForegroundColor Green
} else {
    Write-Host "  WARN: Only $successCount/3 users registered" -ForegroundColor Yellow
}

Write-Host ""

# Test 12: Multiple Logins (should generate different tokens)
Write-Host "Test 12: Multiple Logins" -ForegroundColor Yellow
$tokens = @()
for ($i = 1; $i -le 3; $i++) {
    $body = @{ email = $testEmail; password = $testPassword } | ConvertTo-Json
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/login" `
            -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
        $result = $response.Content | ConvertFrom-Json
        $tokens += $result.refresh_token
    } catch {
        # Ignore errors
    }
}
$uniqueTokens = $tokens | Select-Object -Unique
if ($uniqueTokens.Count -eq 3) {
    Write-Host "  PASS: Each login generated different token" -ForegroundColor Green
} else {
    Write-Host "  WARN: Generated $($uniqueTokens.Count)/3 unique tokens" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Complete!" -ForegroundColor Green
Write-Host "Refresh Prisma Studio to see the data" -ForegroundColor Cyan
Write-Host ""

