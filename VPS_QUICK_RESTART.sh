#!/bin/bash

# VPS_QUICK_RESTART.sh - 快速重启容器并处理端口冲突

set -e

cd /opt/kyc-app || exit 1

echo "════════════════════════════════════════════════════════"
echo "🔧 快速重启容器并处理端口冲突"
echo "════════════════════════════════════════════════════════"

# 1. 停止所有容器
echo "🛑 停止容器..."
docker-compose down --remove-orphans 2>/dev/null || true

# 2. 检查端口占用
echo "🔍 检查端口占用..."
if sudo lsof -i :80 >/dev/null 2>&1; then
    echo "⚠️  端口 80 被占用，正在释放..."
    sudo fuser -k 80/tcp 2>/dev/null || true
    sleep 2
fi

if sudo lsof -i :443 >/dev/null 2>&1; then
    echo "⚠️  端口 443 被占用，正在释放..."
    sudo fuser -k 443/tcp 2>/dev/null || true
    sleep 2
fi

# 3. 启动容器
echo "🚀 启动容器..."
docker-compose up -d

# 4. 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 5. 检查状态
echo "📊 检查容器状态:"
docker-compose ps

# 6. 测试健康状态
echo ""
echo "🏥 测试服务..."
HEALTH=$(curl -s http://localhost:5000/health || echo "fail")
if echo "$HEALTH" | grep -q "healthy"; then
    echo "✅ Flask 服务正常"
else
    echo "⚠️  Flask 服务状态: $HEALTH"
fi

# 7. 查看环境变量
echo ""
echo "📋 Sumsub 配置检查:"
docker-compose exec -T web env | grep SUMSUB || echo "⚠️  环境变量未设置"

# 8. 测试 webhook
echo ""
echo "🧪 测试 /webhook/taobao/order 端点..."
TEST_ORDER_ID="test_$(date +%s)"
RESPONSE=$(curl -s -X POST http://localhost:5000/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d "{
    \"taobao_order_id\": \"$TEST_ORDER_ID\",
    \"buyer_name\": \"Test Buyer\",
    \"buyer_email\": \"test@example.com\",
    \"buyer_phone\": \"+86-13800000000\",
    \"order_amount\": \"100.00\"
  }" 2>&1)

echo "响应状态码检查..."
STATUS=$(echo "$RESPONSE" | head -1)
echo "返回: $STATUS"

if echo "$RESPONSE" | grep -q "verification_token\|verification_link"; then
    echo "✅ Webhook 测试成功！生成了验证链接"
    
    # 提取 verification_token
    TOKEN=$(echo "$RESPONSE" | grep -o '"verification_token":"[^"]*"' | cut -d'"' -f4)
    if [ ! -z "$TOKEN" ]; then
        echo ""
        echo "📌 验证链接地址:"
        echo "http://35.212.217.145:5000/verify/$TOKEN"
    fi
elif echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Webhook 返回错误"
    # 检查是否是 Sumsub API 错误
    if echo "$RESPONSE" | grep -q "Sumsub API error"; then
        echo "⚠️  Sumsub API 认证问题"
        echo "检查日志:"
        docker-compose logs web | tail -15
    fi
else
    echo "⚠️  响应不清晰:"
    echo "$RESPONSE" | head -10
    echo ""
    echo "完整日志:"
    docker-compose logs web | tail -20
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 重启完成"
echo "════════════════════════════════════════════════════════"
