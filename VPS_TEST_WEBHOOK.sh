#!/bin/bash

###############################################################################
# VPS 上快速修复和测试 webhook
# 使用: bash VPS_TEST_WEBHOOK.sh
###############################################################################

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  VPS Webhook 修复和测试                               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 步骤 1: 拉取最新代码
echo "📥 第 1 步: 拉取最新代码..."
git pull origin main || echo "⚠️  git pull 失败，继续..."
echo ""

# 步骤 2: 重启 Flask 容器
echo "🔄 第 2 步: 重启 Flask 容器..."
docker-compose restart kyc_web
sleep 3
echo "✅ Flask 容器已重启"
echo ""

# 步骤 3: 检查容器状态
echo "📊 第 3 步: 检查容器状态..."
docker ps | grep kyc
echo ""

# 步骤 4: 检查 Flask 日志
echo "📋 第 4 步: 检查 Flask 启动日志..."
docker logs --tail=20 kyc_web
echo ""

# 步骤 5: 测试 /health 端点
echo "🔍 第 5 步: 测试 /health 端点..."
curl -s http://localhost:5000/health | python3 -m json.tool || echo "❌ /health 端点失败"
echo ""
echo ""

# 步骤 6: 发送测试 webhook
echo "🧪 第 6 步: 发送测试 webhook..."
echo ""

order_id="test_$(date +%s)"
echo "📤 正在发送订单: $order_id"
echo ""

response=$(curl -s -X POST http://localhost:5000/webhook/taobao/order \
  -H 'Content-Type: application/json' \
  -d "{
    \"order_id\": \"$order_id\",
    \"buyer_id\": \"test_buyer\",
    \"buyer_name\": \"测试用户\",
    \"buyer_email\": \"test@test.com\",
    \"buyer_phone\": \"13800138000\",
    \"platform\": \"taobao\",
    \"order_amount\": 1000
  }")

echo "📦 响应:"
echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
echo ""

# 检查响应
if echo "$response" | grep -q '"status":"success"'; then
    echo "✅ SUCCESS! 订单创建成功"
    echo ""
    
    # 查询验证链接
    echo "🔗 查询验证链接..."
    docker exec kyc_postgres psql -U kyc_user -d kyc_db -c \
      "SELECT taobao_order_id, verification_link, status FROM orders o 
       LEFT JOIN verifications v ON o.id = v.order_id 
       ORDER BY o.created_at DESC LIMIT 5;"
else
    echo "❌ 创建订单失败!"
    echo ""
    echo "📋 完整 Flask 日志:"
    docker logs kyc_web
fi
