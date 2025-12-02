#!/bin/bash

# VPS 快速更新脚本

echo "========================================"
echo "  更新 Flask 应用"
echo "========================================"
echo ""

# Step 1: 拉取最新代码
echo "Step 1: 拉取最新代码..."
git pull origin main
echo "✓ 代码已更新"
echo ""

# Step 2: 重启 Web 容器
echo "Step 2: 重启 Flask 容器..."
docker-compose restart web
sleep 5
echo "✓ 容器已重启"
echo ""

# Step 3: 测试健康检查
echo "Step 3: 测试健康检查端点..."
echo ""
if curl -s http://localhost:5000/health; then
    echo ""
    echo "✅ 健康检查端点正常"
else
    echo "⚠️  健康检查端点未响应"
fi
echo ""
