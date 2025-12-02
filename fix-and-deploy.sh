#!/bin/bash

# 快速修复 git 冲突并部署的脚本

set -e

echo "🔧 开始修复 git 冲突..."

# 检查是否在正确的目录
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 错误：请在 /opt/kyc-app 目录运行此脚本"
    echo "   cd /opt/kyc-app"
    exit 1
fi

echo ""
echo "📊 当前状态："
git status

echo ""
echo "🔄 保存本地修改..."
git stash

echo ""
echo "⬇️  拉取最新代码..."
git pull origin main

echo ""
echo "✅ 检查脚本文件..."
if [ ! -f "deploy-kyc-nginx.sh" ]; then
    echo "❌ deploy-kyc-nginx.sh 不存在！"
    exit 1
fi

echo "✅ deploy-kyc-nginx.sh 已找到"

echo ""
echo "🔐 赋予脚本执行权限..."
chmod +x deploy-kyc-nginx.sh

echo ""
echo "🚀 运行部署脚本..."
bash deploy-kyc-nginx.sh

echo ""
echo "✨ 完成！"
