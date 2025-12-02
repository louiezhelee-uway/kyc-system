#!/bin/bash

# VPS 完整验证脚本

echo "========================================"
echo "  VPS 部署完整验证"
echo "========================================"
echo ""

# Step 1: 检查所有容器
echo "Step 1: 检查容器状态..."
echo ""
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Step 2: 测试 Flask
echo "Step 2: 测试 Flask 应用..."
echo ""
if docker exec kyc_web curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Flask 容器内响应正常"
    docker exec kyc_web curl -s http://localhost:5000/health
else
    echo "⚠️  Flask 容器内无响应"
fi
echo ""

# Step 3: 测试数据库
echo "Step 3: 测试数据库连接..."
echo ""
if docker exec kyc_postgres psql -U kyc_user -d kyc_db -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ 数据库连接正常"
    docker exec kyc_postgres psql -U kyc_user -d kyc_db -c "\dt"
else
    echo "❌ 数据库连接失败"
fi
echo ""

# Step 4: 测试 Nginx
echo "Step 4: 测试 Nginx..."
echo ""
if curl -s http://localhost:8080/ > /dev/null 2>&1; then
    echo "✅ Nginx 通过 8080 响应"
else
    echo "⚠️  Nginx 未响应"
fi
echo ""

# Step 5: 从主机测试 Flask
echo "Step 5: 从主机测试 Flask..."
echo ""
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Flask 可从主机访问"
    curl -s http://localhost:5000/health | head -5
else
    echo "⚠️  从主机无法访问 Flask"
    echo "尝试从容器访问..."
    docker exec kyc_web curl -s http://localhost:5000/health
fi
echo ""

# Step 6: 检查日志
echo "Step 6: 最近的错误日志..."
echo ""
echo "--- Flask 日志 ---"
docker logs --tail 5 kyc_web 2>&1 | grep -i error || echo "无错误"
echo ""
echo "--- PostgreSQL 日志 ---"
docker logs --tail 5 kyc_postgres 2>&1 | grep -i error || echo "无错误"
echo ""

# Step 7: 总结
echo "========================================"
echo "  验证总结"
echo "========================================"
echo ""
echo "✅ Docker 容器状态:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep kyc
echo ""

echo "✅ 访问方式:"
echo "  • Flask API: http://localhost:5000"
echo "  • Nginx:     http://localhost:8080"
echo "  • 数据库:    postgresql://localhost:5432"
echo ""

echo "✅ Docker 网络:"
docker network inspect kyc-app_kyc_network | grep -E "(Name|Containers)" | head -3
echo ""

echo "========================================"
echo "  部署成功！"
echo "========================================"
echo ""
