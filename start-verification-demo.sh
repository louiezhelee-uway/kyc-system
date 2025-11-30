#!/bin/bash

# KYC 验证系统演示服务器启动脚本

set -e

PROJECT_DIR="/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"
SERVER_SCRIPT="/tmp/verification_server.py"

echo "=========================================================="
echo "🚀 KYC 验证系统 - 演示服务器启动脚本"
echo "=========================================================="

# 检查 Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: 找不到 python3"
    exit 1
fi

echo "✅ Python 版本: $(python3 --version)"

# 检查 Flask
if ! python3 -c "import flask" 2>/dev/null; then
    echo "❌ 错误: 找不到 Flask"
    echo "请运行: pip install flask"
    exit 1
fi

echo "✅ Flask 已安装"

# 检查端口是否被占用
if lsof -i :5000 &> /dev/null; then
    echo ""
    echo "⚠️  警告: 端口 5000 已被占用"
    echo ""
    echo "当前占用进程:"
    lsof -i :5000 | tail -n +2
    echo ""
    echo "选项:"
    echo "  1. 使用 'kill -9 <PID>' 杀死进程"
    echo "  2. 修改脚本中的端口号"
    echo "  3. 等待占用进程释放端口"
    echo ""
    read -p "是否继续? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 1
    fi
fi

# 启动服务器
echo ""
echo "=========================================================="
echo "🚀 启动服务器..."
echo "=========================================================="
echo ""

cd "$PROJECT_DIR"
python3 "$SERVER_SCRIPT"
