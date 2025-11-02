# AIWA Auth API - SQLite Setup Script
# Usage: .\setup-sqlite.ps1

$ErrorActionPreference = "Continue"

Write-Host "AIWA Auth API - SQLite Setup" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Check directory
if (-not (Test-Path "package.json")) {
    Write-Host "Error: Please run this script in core-api directory" -ForegroundColor Red
    exit 1
}

# Step 1: Copy env file
Write-Host "Step 1/5: Configuring environment..." -ForegroundColor Cyan

if (-not (Test-Path ".env")) {
    if (Test-Path "env.sqlite.example") {
        Copy-Item "env.sqlite.example" ".env"
        Write-Host "Created .env file from template" -ForegroundColor Green
    } else {
        Write-Host "Warning: env.sqlite.example not found" -ForegroundColor Yellow
    }
} else {
    Write-Host ".env file already exists, skipping" -ForegroundColor Cyan
}

# Step 2: Copy SQLite schema
Write-Host ""
Write-Host "Step 2/5: Configuring SQLite schema..." -ForegroundColor Cyan

if (Test-Path "prisma\schema.sqlite.prisma") {
    Copy-Item "prisma\schema.sqlite.prisma" "prisma\schema.prisma" -Force
    Write-Host "Using SQLite schema" -ForegroundColor Green
} else {
    Write-Host "Error: prisma\schema.sqlite.prisma not found" -ForegroundColor Red
    exit 1
}

# Step 3: Generate JWT secrets
Write-Host ""
Write-Host "Step 3/5: Generating JWT secrets..." -ForegroundColor Cyan

$accessSecret = ""
$refreshSecret = ""

$nodeCmd = 'console.log(require("crypto").randomBytes(32).toString("hex"))'

try {
    $accessSecret = node -e $nodeCmd 2>&1 | Out-String
    $refreshSecret = node -e $nodeCmd 2>&1 | Out-String
    
    $accessSecret = $accessSecret.Trim()
    $refreshSecret = $refreshSecret.Trim()
    
    if ($accessSecret.Length -gt 0 -and $refreshSecret.Length -gt 0) {
        Write-Host "JWT secrets generated" -ForegroundColor Green
        Write-Host ""
        Write-Host "Please add these secrets to .env file:" -ForegroundColor Yellow
        Write-Host "   JWT_ACCESS_SECRET=$accessSecret" -ForegroundColor Cyan
        Write-Host "   JWT_REFRESH_SECRET=$refreshSecret" -ForegroundColor Cyan
        Write-Host ""
        
        # Auto-update .env if exists
        if (Test-Path ".env") {
            $envContent = Get-Content ".env" -Raw
            
            if ($envContent -match "JWT_ACCESS_SECRET=your_access_secret_here") {
                $envContent = $envContent -replace "JWT_ACCESS_SECRET=your_access_secret_here[^\r\n]*", "JWT_ACCESS_SECRET=$accessSecret"
                $envContent = $envContent -replace "JWT_REFRESH_SECRET=your_refresh_secret_here[^\r\n]*", "JWT_REFRESH_SECRET=$refreshSecret"
                [System.IO.File]::WriteAllText((Join-Path $PWD ".env"), $envContent, [System.Text.Encoding]::UTF8)
                Write-Host "Auto-updated JWT secrets in .env file" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Warning: Could not generate secrets automatically" -ForegroundColor Yellow
        Write-Host "Command: node -e 'console.log(require(\"crypto\").randomBytes(32).toString(\"hex\"))'" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Warning: Could not generate secrets automatically" -ForegroundColor Yellow
    Write-Host "Command: node -e 'console.log(require(\"crypto\").randomBytes(32).toString(\"hex\"))'" -ForegroundColor Cyan
}

# Step 4: Install dependencies
Write-Host ""
Write-Host "Step 4/5: Installing dependencies..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Yellow

npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to install dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "Dependencies installed" -ForegroundColor Green

# Step 5: Create database
Write-Host ""
Write-Host "Step 5/5: Creating database..." -ForegroundColor Cyan

npx prisma db push
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to create database" -ForegroundColor Red
    Write-Host "Please check DATABASE_URL in .env file" -ForegroundColor Yellow
    exit 1
}
Write-Host "Database created" -ForegroundColor Green

# Done
Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "Start development server:" -ForegroundColor Cyan
Write-Host "   npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "View database:" -ForegroundColor Cyan
Write-Host "   npx prisma studio" -ForegroundColor White
Write-Host ""
Write-Host "API URL:" -ForegroundColor Cyan
Write-Host "   http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "Good luck with development!" -ForegroundColor Green
