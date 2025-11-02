#!/bin/bash

# =============================================================================
# AIWA Auth API - 阿里云部署脚本
# =============================================================================
# 用途：在阿里云 ECS 上一键部署应用
# 使用：chmod +x deploy.sh && ./deploy.sh
# =============================================================================

set -e  # 遇到错误立即退出

echo "🚀 AIWA Auth API - 阿里云部署脚本"
echo "================================"
echo ""

# 检查是否在正确的目录
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 错误：请在 aiwa_cloud 目录下运行此脚本"
    exit 1
fi

# 1. 检查环境
echo "📋 步骤 1/6: 检查环境..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

echo "✅ Docker 和 Docker Compose 已安装"

# 2. 检查环境变量
echo ""
echo "📋 步骤 2/6: 检查环境变量..."
if [ ! -f "core-api/.env" ]; then
    echo "⚠️  未找到 core-api/.env 文件"
    echo "📝 正在从模板创建..."
    cp core-api/env.example core-api/.env
    echo ""
    echo "❗ 重要：请编辑 core-api/.env 文件并填写以下配置："
    echo "   - DATABASE_URL（阿里云 RDS 连接字符串）"
    echo "   - JWT_ACCESS_SECRET（随机生成的密钥）"
    echo "   - JWT_REFRESH_SECRET（随机生成的密钥）"
    echo ""
    echo "生成密钥的方法："
    echo "   node -e \"console.log(require('crypto').randomBytes(32).toString('hex'))\""
    echo ""
    read -p "配置完成后按 Enter 继续..."
fi

# 检查必需的环境变量
if ! grep -q "DATABASE_URL=postgresql://" core-api/.env; then
    echo "❌ DATABASE_URL 未配置，请编辑 core-api/.env"
    exit 1
fi

echo "✅ 环境变量配置完成"

# 3. 停止旧容器
echo ""
echo "📋 步骤 3/6: 停止旧容器..."
docker-compose down || true
echo "✅ 旧容器已停止"

# 4. 拉取最新代码（如果使用 Git）
echo ""
echo "📋 步骤 4/6: 更新代码..."
if [ -d ".git" ]; then
    echo "🔄 从 Git 拉取最新代码..."
    git pull || echo "⚠️  Git pull 失败，使用本地代码"
else
    echo "ℹ️  未检测到 Git 仓库，使用本地代码"
fi

# 5. 构建并启动容器
echo ""
echo "📋 步骤 5/6: 构建并启动服务..."
echo "⏳ 这可能需要几分钟..."
docker-compose up -d --build

# 等待服务启动
echo ""
echo "⏳ 等待服务启动..."
sleep 10

# 6. 健康检查
echo ""
echo "📋 步骤 6/6: 健康检查..."
max_retries=30
retry_count=0

while [ $retry_count -lt $max_retries ]; do
    if curl -s http://localhost:3000/health > /dev/null; then
        echo "✅ 服务启动成功！"
        echo ""
        curl -s http://localhost:3000/health | python3 -m json.tool || curl -s http://localhost:3000/health
        break
    else
        retry_count=$((retry_count + 1))
        echo "⏳ 等待服务就绪... ($retry_count/$max_retries)"
        sleep 2
    fi
done

if [ $retry_count -eq $max_retries ]; then
    echo "❌ 服务启动失败，请查看日志："
    echo "   docker-compose logs auth-api"
    exit 1
fi

# 完成
echo ""
echo "================================"
echo "✅ 部署完成！"
echo "================================"
echo ""
echo "📊 服务信息："
echo "   - API 地址: http://localhost:3000"
echo "   - 健康检查: http://localhost:3000/health"
echo ""
echo "📝 常用命令："
echo "   - 查看日志: docker-compose logs -f auth-api"
echo "   - 重启服务: docker-compose restart auth-api"
echo "   - 停止服务: docker-compose down"
echo "   - 进入容器: docker exec -it aiwa-auth-api sh"
echo ""
echo "🎉 祝你使用愉快！"

