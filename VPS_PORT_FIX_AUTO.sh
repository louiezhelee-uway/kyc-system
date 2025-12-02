#!/bin/bash

# VPS 自动修复端口冲突脚本
# 将 nginx 端口从 80/443 改为 8080/8443

echo "========================================"
echo "  VPS 自动修复端口冲突"
echo "========================================"
echo ""

# Step 1: 停止 nginx 容器
echo "Step 1: 停止 nginx 容器..."
docker-compose down 2>&1 | grep -v "^$" || true
sleep 2
echo "✓ 容器已停止"
echo ""

# Step 2: 清空孤立容器
echo "Step 2: 清空孤立容器..."
docker container prune -f > /dev/null 2>&1 || true
echo "✓ 清空完成"
echo ""

# Step 3: 修改 docker-compose.yml 的 nginx 端口
echo "Step 3: 修改 nginx 端口映射..."
echo "将 80:80 改为 8080:80"
echo "将 443:443 改为 8443:443"
echo ""

# 备份原文件
cp docker-compose.yml docker-compose.yml.backup

# 修改端口映射
sed -i.bak 's/- "80:80"/- "8080:80"/' docker-compose.yml
sed -i.bak 's/- "443:443"/- "8443:443"/' docker-compose.yml

echo "✓ 端口映射已修改"
echo ""

# Step 4: 验证修改
echo "Step 4: 验证修改..."
echo ""
grep -A 2 "ports:" docker-compose.yml | grep -E "(80|443)"
echo ""

# Step 5: 重新启动 nginx
echo "Step 5: 重新启动容器..."
docker-compose up -d nginx
sleep 3
echo "✓ nginx 容器已启动"
echo ""

# Step 6: 检查容器状态
echo "Step 6: 检查容器状态..."
echo ""
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Step 7: 验证连接
echo "Step 7: 测试连接..."
echo ""
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Nginx 通过 8080 端口响应正常"
else
    echo "⚠️  无法通过 8080 端口访问"
fi

if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Flask 应用响应正常"
else
    echo "⚠️  Flask 应用暂未响应"
fi

echo ""
echo "========================================"
echo "  完成！"
echo "========================================"
echo ""
echo "📝 重要信息:"
echo "  • Nginx 现在使用 8080 端口而不是 80"
echo "  • HTTP 访问: http://kyc.317073.xyz:8080"
echo "  • HTTPS 访问: https://kyc.317073.xyz:8443"
echo ""
echo "💡 如果需要使用标准 80/443 端口:"
echo "  1. 停止占用这些端口的其他服务"
echo "  2. 修改 docker-compose.yml 改回 80:80 和 443:443"
echo "  3. 运行 docker-compose restart nginx"
echo ""
