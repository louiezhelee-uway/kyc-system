#!/bin/bash

# KYC 系统 - 本地无数据库快速测试
# 用于演示和测试，不需要 Docker 或 PostgreSQL

set -e

echo "╔════════════════════════════════════════╗"
echo "║   KYC 系统 - 本地快速演示测试          ║"
echo "║   (无需 Docker/PostgreSQL)             ║"
echo "╚════════════════════════════════════════╝"
echo ""

# 检查 Python
echo "📍 步骤 1/3: 检查 Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 未安装"
    exit 1
fi
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
echo "✅ Python $PYTHON_VERSION"

# 检查/创建虚拟环境
echo ""
echo "📍 步骤 2/3: 设置虚拟环境..."
if [ ! -d "venv" ]; then
    echo "创建虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
echo "安装依赖包..."
pip install -q --upgrade pip
pip install -q -r requirements.txt

echo "✅ 虚拟环境已准备"

# 运行测试
echo ""
echo "📍 步骤 3/3: 运行系统测试..."
echo ""

# 运行 Sumsub 集成测试
echo "════════════════════════════════════════"
echo "运行 Sumsub 集成测试..."
echo "════════════════════════════════════════"
echo ""

python3 tests/test_sumsub_integration.py

echo ""
echo "════════════════════════════════════════"
echo "✅ 所有测试完成！"
echo "════════════════════════════════════════"
echo ""

echo "🎯 下一步:"
echo ""
echo "1️⃣  查看系统演示:"
echo "    python3 demo.py"
echo ""
echo "2️⃣  启动完整应用 (需要 PostgreSQL):"
echo "    brew install postgresql@15"
echo "    brew services start postgresql@15"
echo "    ./local-dev.sh"
echo ""
echo "3️⃣  启动 Docker 应用 (需要 Docker):"
echo "    ./quick-start.sh"
echo ""
echo "📚 查看文档:"
echo "    cat SUMSUB_INTEGRATION.md"
echo "    cat README.md"
echo ""
