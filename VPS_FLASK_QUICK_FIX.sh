#!/bin/bash

# VPS Flask 快速修复脚本

echo "========================================"
echo "  VPS Flask 快速修复"
echo "========================================"
echo ""

# Step 1: 检查 Flask 容器状态
echo "Step 1: 检查容器状态..."
docker ps -a | grep kyc_web
echo ""

# Step 2: 查看最近的错误日志
echo "Step 2: 最近 30 行日志..."
docker logs --tail 30 kyc_web 2>&1 | tail -20
echo ""

# Step 3: 重启容器
echo "Step 3: 重启 Flask 容器..."
docker-compose restart web
sleep 10
echo "✓ 容器已重启，等待 10 秒启动..."
echo ""

# Step 4: 再次检查状态
echo "Step 4: 检查容器状态..."
docker ps -a | grep kyc_web
echo ""

# Step 5: 测试连接
echo "Step 5: 测试 Flask 连接..."
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Flask 应用已启动并响应"
    echo ""
    echo "响应内容:"
    curl -s http://localhost:5000/health
else
    echo "⚠️  Flask 应用仍未响应"
    echo ""
    echo "故障排查:"
    echo "  1. 查看详细日志: docker logs kyc_web"
    echo "  2. 检查数据库: docker logs kyc_postgres"
    echo "  3. 检查网络: docker network ls"
fi
echo ""
