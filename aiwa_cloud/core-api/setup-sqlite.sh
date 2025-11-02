#!/bin/bash

# =============================================================================
# AIWA Auth API - SQLite 快速设置脚本 (Linux/Mac)
# =============================================================================
# 用途：一键设置 SQLite 开发环境
# 使用：chmod +x setup-sqlite.sh && ./setup-sqlite.sh
# =============================================================================

set -e  # 遇到错误立即退出

echo "🚀 AIWA Auth API - SQLite 快速设置"
echo "================================"
echo ""

# 检查是否在正确的目录
if [ ! -f "package.json" ]; then
    echo "❌ 错误：请在 core-api 目录下运行此脚本"
    exit 1
fi

# 步骤1: 复制环境变量文件
echo "📋 步骤 1/5: 配置环境变量..."

if [ ! -f ".env" ]; then
    if [ -f "env.sqlite.example" ]; then
        cp env.sqlite.example .env
        echo "✅ 已从模板创建 .env 文件"
    else
        echo "⚠️  未找到 env.sqlite.example，请手动创建 .env 文件"
    fi
else
    echo "ℹ️  .env 文件已存在，跳过创建"
fi

# 步骤2: 复制 SQLite schema
echo ""
echo "📋 步骤 2/5: 配置 SQLite schema..."

if [ -f "prisma/schema.sqlite.prisma" ]; then
    cp prisma/schema.sqlite.prisma prisma/schema.prisma
    echo "✅ 已使用 SQLite schema"
else
    echo "❌ 未找到 prisma/schema.sqlite.prisma"
    exit 1
fi

# 步骤3: 生成 JWT 密钥
echo ""
echo "📋 步骤 3/5: 生成 JWT 密钥..."

ACCESS_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
REFRESH_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")

echo "✅ JWT 密钥已生成"
echo ""
echo "❗ 请将以下密钥填入 .env 文件："
echo "   JWT_ACCESS_SECRET=$ACCESS_SECRET"
echo "   JWT_REFRESH_SECRET=$REFRESH_SECRET"
echo ""

# 尝试自动更新 .env（如果存在且是默认值）
if [ -f ".env" ]; then
    if grep -q "JWT_ACCESS_SECRET=your_access_secret_here" .env; then
        sed -i.bak "s/JWT_ACCESS_SECRET=your_access_secret_here.*/JWT_ACCESS_SECRET=$ACCESS_SECRET/" .env
        sed -i.bak "s/JWT_REFRESH_SECRET=your_refresh_secret_here.*/JWT_REFRESH_SECRET=$REFRESH_SECRET/" .env
        rm -f .env.bak
        echo "✅ 已自动更新 .env 文件中的 JWT 密钥"
    fi
fi

# 步骤4: 安装依赖
echo ""
echo "📋 步骤 4/5: 安装依赖..."
echo "⏳ 这可能需要几分钟..."

if npm install; then
    echo "✅ 依赖安装完成"
else
    echo "❌ 依赖安装失败"
    exit 1
fi

# 步骤5: 创建数据库
echo ""
echo "📋 步骤 5/5: 创建数据库..."

if npx prisma db push; then
    echo "✅ 数据库创建成功"
else
    echo "❌ 数据库创建失败"
    echo "   请检查 .env 文件中的 DATABASE_URL 配置"
    exit 1
fi

# 完成
echo ""
echo "================================"
echo "✅ 设置完成！"
echo "================================"
echo ""
echo "🚀 启动开发服务器："
echo "   npm run dev"
echo ""
echo "📊 查看数据库："
echo "   npx prisma studio"
echo ""
echo "🌐 API 地址："
echo "   http://localhost:3001"
echo ""
echo "🎉 祝你开发顺利！"

