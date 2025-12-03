#!/bin/bash

# VPS_SIMPLE_TEST.sh - 简单的 webhook 测试

cd /opt/kyc-app || exit 1

echo "════════════════════════════════════════════════════════"
echo "🧪 简单 Webhook 测试"
echo "════════════════════════════════════════════════════════"

# 生成测试订单 ID
TEST_ORDER_ID="test_$(date +%s)"

echo ""
echo "📝 发送 webhook 请求..."
echo "URL: http://localhost:5000/webhook/taobao/order"
echo "订单 ID: $TEST_ORDER_ID"

# 发送请求
RESPONSE=$(curl -s -X POST http://localhost:5000/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d "{
    \"taobao_order_id\": \"$TEST_ORDER_ID\",
    \"buyer_name\": \"Test User\",
    \"buyer_email\": \"test@example.com\",
    \"buyer_phone\": \"+86-13800000000\",
    \"order_amount\": \"99.99\"
  }")

echo ""
echo "📥 响应:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"

# 查看最新日志
echo ""
echo "📋 最新容器日志 (最后 30 行):"
docker-compose logs web 2>/dev/null | tail -30

echo ""
echo "════════════════════════════════════════════════════════"
