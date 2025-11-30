#!/bin/bash

# 本地开发快速启动脚本
# 无需 Docker，直接运行 Flask 应用

set -e

echo "╔════════════════════════════════════════╗"
echo "║   KYC 系统 - 本地开发快速启动          ║"
echo "║   (不需要 Docker)                      ║"
echo "╚════════════════════════════════════════╝"
echo ""

# 1. 检查 Python
echo "📍 步骤 1/5: 检查 Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 未安装"
    echo "请运行: brew install python3"
    exit 1
fi
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
echo "✅ Python $PYTHON_VERSION"

# 2. 检查/创建虚拟环境
echo ""
echo "📍 步骤 2/5: 设置虚拟环境..."
if [ ! -d "venv" ]; then
    echo "创建虚拟环境..."
    python3 -m venv venv
fi
source venv/bin/activate
echo "✅ 虚拟环境已激活"

# 3. 检查 PostgreSQL
echo ""
echo "📍 步骤 3/5: 检查 PostgreSQL..."
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL 未安装"
    echo "安装 PostgreSQL:"
    echo "  brew install postgresql@15"
    echo ""
    echo "然后启动 PostgreSQL:"
    echo "  brew services start postgresql@15"
    exit 1
fi

# 创建数据库
if psql -lqt | cut -d \| -f 1 | grep -qw kyc_db; then
    echo "✅ 数据库 kyc_db 已存在"
else
    echo "创建数据库 kyc_db..."
    createdb kyc_db
    echo "✅ 数据库已创建"
fi

# 4. 安装 Python 依赖
echo ""
echo "📍 步骤 4/5: 安装 Python 依赖..."
pip install -q -r requirements.txt
echo "✅ 依赖已安装"

# 5. 运行应用
echo ""
echo "📍 步骤 5/5: 启动 Flask 应用..."
echo ""
echo "════════════════════════════════════════"
echo "✅ 应用启动成功!"
echo "════════════════════════════════════════"
echo ""
echo "🌐 访问地址: http://localhost:5000"
echo ""
echo "📖 文档:"
echo "  - API 测试: http://localhost:5000/"
echo "  - Webhook: POST http://localhost:5000/webhook/taobao/order"
echo ""
echo "⏹️  停止应用: Ctrl+C"
echo ""

# 设置环境变量
export FLASK_ENV=development
export FLASK_APP=run.py
export DATABASE_URL="postgresql://$(whoami)@localhost:5432/kyc_db"

# 运行应用
python3 run.py
