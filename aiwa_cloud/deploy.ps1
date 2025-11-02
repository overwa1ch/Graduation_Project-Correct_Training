# =============================================================================
# AIWA Auth API - Windows 部署脚本 (PowerShell)
# =============================================================================
# 用途：在 Windows 开发环境一键部署应用
# 使用：.\deploy.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

Write-Host "🚀 AIWA Auth API - Windows 部署脚本" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# 检查是否在正确的目录
if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "❌ 错误：请在 aiwa_cloud 目录下运行此脚本" -ForegroundColor Red
    exit 1
}

# 1. 检查环境
Write-Host "📋 步骤 1/6: 检查环境..." -ForegroundColor Cyan

# 检查 Docker
$dockerInstalled = $false
try {
    docker --version | Out-Null
    $dockerInstalled = $true
} catch {
    Write-Host "❌ Docker 未安装，请先安装 Docker Desktop" -ForegroundColor Red
    exit 1
}

# 检查 Docker Compose
$dockerComposeInstalled = $false
try {
    docker-compose --version | Out-Null
    $dockerComposeInstalled = $true
} catch {
    Write-Host "❌ Docker Compose 未安装" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker 和 Docker Compose 已安装" -ForegroundColor Green

# 2. 检查环境变量
Write-Host ""
Write-Host "📋 步骤 2/6: 检查环境变量..." -ForegroundColor Cyan

if (-not (Test-Path "core-api\.env")) {
    Write-Host "⚠️  未找到 core-api\.env 文件" -ForegroundColor Yellow
    Write-Host "📝 正在从模板创建..." -ForegroundColor Yellow
    Copy-Item "core-api\env.example" "core-api\.env"
    Write-Host ""
    Write-Host "❗ 重要：请编辑 core-api\.env 文件并填写以下配置：" -ForegroundColor Yellow
    Write-Host "   - DATABASE_URL（PostgreSQL 连接字符串）" -ForegroundColor Yellow
    Write-Host "   - JWT_ACCESS_SECRET（随机生成的密钥）" -ForegroundColor Yellow
    Write-Host "   - JWT_REFRESH_SECRET（随机生成的密钥）" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "生成密钥的方法：" -ForegroundColor Cyan
    Write-Host '   node -e "console.log(require(''crypto'').randomBytes(32).toString(''hex''))"' -ForegroundColor Cyan
    Write-Host ""
    Read-Host "配置完成后按 Enter 继续"
}

# 检查 DATABASE_URL
$envContent = Get-Content "core-api\.env" -Raw
if ($envContent -notmatch "DATABASE_URL=postgresql://") {
    Write-Host "❌ DATABASE_URL 未配置，请编辑 core-api\.env" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 环境变量配置完成" -ForegroundColor Green

# 3. 停止旧容器
Write-Host ""
Write-Host "📋 步骤 3/6: 停止旧容器..." -ForegroundColor Cyan
try {
    docker-compose down 2>&1 | Out-Null
} catch {
    # 忽略错误
}
Write-Host "✅ 旧容器已停止" -ForegroundColor Green

# 4. 更新代码
Write-Host ""
Write-Host "📋 步骤 4/6: 检查代码更新..." -ForegroundColor Cyan
if (Test-Path ".git") {
    Write-Host "🔄 从 Git 拉取最新代码..." -ForegroundColor Cyan
    try {
        git pull 2>&1 | Out-Null
    } catch {
        Write-Host "⚠️  Git pull 失败，使用本地代码" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  未检测到 Git 仓库，使用本地代码" -ForegroundColor Cyan
}

# 5. 构建并启动容器
Write-Host ""
Write-Host "📋 步骤 5/6: 构建并启动服务..." -ForegroundColor Cyan
Write-Host "⏳ 这可能需要几分钟..." -ForegroundColor Yellow
docker-compose up -d --build

# 等待服务启动
Write-Host ""
Write-Host "⏳ 等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 6. 健康检查
Write-Host ""
Write-Host "📋 步骤 6/6: 健康检查..." -ForegroundColor Cyan

$maxRetries = 30
$retryCount = 0
$serviceReady = $false

while ($retryCount -lt $maxRetries) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ 服务启动成功！" -ForegroundColor Green
            Write-Host ""
            $response.Content
            $serviceReady = $true
            break
        }
    } catch {
        $retryCount++
        Write-Host "⏳ 等待服务就绪... ($retryCount/$maxRetries)" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
}

if (-not $serviceReady) {
    Write-Host "❌ 服务启动失败，请查看日志：" -ForegroundColor Red
    Write-Host "   docker-compose logs auth-api" -ForegroundColor Yellow
    exit 1
}

# 完成
Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "✅ 部署完成！" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 服务信息：" -ForegroundColor Cyan
Write-Host "   - API 地址: http://localhost:3000" -ForegroundColor White
Write-Host "   - 健康检查: http://localhost:3000/health" -ForegroundColor White
Write-Host ""
Write-Host "📝 常用命令：" -ForegroundColor Cyan
Write-Host "   - 查看日志: docker-compose logs -f auth-api" -ForegroundColor White
Write-Host "   - 重启服务: docker-compose restart auth-api" -ForegroundColor White
Write-Host "   - 停止服务: docker-compose down" -ForegroundColor White
Write-Host "   - 进入容器: docker exec -it aiwa-auth-api sh" -ForegroundColor White
Write-Host ""
Write-Host "🎉 祝你使用愉快！" -ForegroundColor Green

