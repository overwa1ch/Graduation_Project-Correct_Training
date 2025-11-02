# API Test Script
# Usage: .\test-api.ps1

Write-Host "Testing AIWA Auth API" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080"

# Test 1: Health Check
Write-Host "Test 1/3: Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "Health check passed" -ForegroundColor Green
        $health = $response.Content | ConvertFrom-Json
        Write-Host "   Status: $($health.status)" -ForegroundColor White
        Write-Host "   Service: $($health.service)" -ForegroundColor White
    }
} catch {
    Write-Host "Health check failed: $_" -ForegroundColor Red
    Write-Host "   Please ensure server is running (npm run dev)" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Test 2: Register User
Write-Host "Test 2/3: User Registration..." -ForegroundColor Yellow
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
        Write-Host "Registration successful" -ForegroundColor Green
        $result = $response.Content | ConvertFrom-Json
        Write-Host "   Test email: $testEmail" -ForegroundColor White
        if ($result.token) {
            Write-Host "   Token: $($result.token.Substring(0, [Math]::Min(20, $result.token.Length)))..." -ForegroundColor Gray
        }
        if ($result.refresh_token) {
            Write-Host "   Refresh Token: $($result.refresh_token.Substring(0, [Math]::Min(20, $result.refresh_token.Length)))..." -ForegroundColor Gray
        }
        $global:testEmail = $testEmail
        $global:testPassword = $testPassword
    }
} catch {
    $errorMessage = $_.Exception.Message
    if ($_.ErrorDetails) {
        $errorMessage = $_.ErrorDetails.Message
    }
    
    if ($errorMessage -like "*already exists*" -or $errorMessage -like "*User already exists*") {
        Write-Host "User already exists (this is normal, continuing with login test)" -ForegroundColor Yellow
        $global:testEmail = $testEmail
        $global:testPassword = $testPassword
    } else {
        Write-Host "Registration failed: $errorMessage" -ForegroundColor Red
    }
}

Write-Host ""

# Test 3: User Login
Write-Host "Test 3/3: User Login..." -ForegroundColor Yellow

if (-not $global:testEmail) {
    Write-Host "Skipping login test (registration failed or user exists)" -ForegroundColor Yellow
} else {
    try {
        $body = @{
            email = $global:testEmail
            password = $global:testPassword
        } | ConvertTo-Json

        $response = Invoke-WebRequest -Uri "$baseUrl/v1/auth/login" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -UseBasicParsing `
            -TimeoutSec 10

        if ($response.StatusCode -eq 200) {
            Write-Host "Login successful" -ForegroundColor Green
            $result = $response.Content | ConvertFrom-Json
            if ($result.token) {
                Write-Host "   Token: $($result.token.Substring(0, [Math]::Min(20, $result.token.Length)))..." -ForegroundColor Gray
            }
        }
    } catch {
        $errorMessage = $_.Exception.Message
        if ($_.ErrorDetails) {
            $errorMessage = $_.ErrorDetails.Message
        }
        Write-Host "Login failed: $errorMessage" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "API Test Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "   1. Use Postman or curl to test more features" -ForegroundColor White
Write-Host "   2. View database: npx prisma studio" -ForegroundColor White
Write-Host "   3. Integrate with Flutter app" -ForegroundColor White
Write-Host ""
