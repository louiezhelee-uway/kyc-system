#!/bin/bash

###############################################################################
# VPS webhook 测试脚本 - 完整重启和测试
###############################################################################

cd /opt/kyc-app

echo "╔════════════════════════════════════════════════════════╗"
echo "║  KYC Webhook 完整测试                                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

echo "1️⃣  停止并清理容器..."
docker-compose down
echo "✅ 清理完成"
echo ""

echo "2️⃣  拉取最新代码..."
git pull origin main
echo "✅ 代码已更新"
echo ""

echo "3️⃣  启动容器..."
docker-compose up -d
echo "✅ 容器启动中..."
echo ""

echo "4️⃣  等待 Flask 完全启动 (20秒)..."
sleep 20
echo "✅ 启动完成"
echo ""

echo "5️⃣  检查容器状态..."
docker ps | grep kyc
echo ""

echo "6️⃣  查看 Flask 日志 (最后 50 行)..."
echo "════════════════════════════════════════════════════════"
docker logs kyc_web 2>&1 | tail -50
echo "════════════════════════════════════════════════════════"
echo ""

echo "7️⃣  检查 FLASK_ENV 环境变量..."
FLASK_ENV=$(docker exec kyc_web env | grep FLASK_ENV | cut -d= -f2)
echo "FLASK_ENV=$FLASK_ENV"
echo ""

echo "8️⃣  测试 /health 端点..."
echo "════════════════════════════════════════════════════════"
curl -s -w "\nHTTP 状态码: %{http_code}\n" http://localhost:5000/health | head -20
echo ""

echo "9️⃣  测试 /webhook/taobao/order 端点..."
echo "════════════════════════════════════════════════════════"
TEST_ORDER_ID="test_$(date +%s)"
echo "订单 ID: $TEST_ORDER_ID"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:5000/webhook/taobao/order \
  -H 'Content-Type: application/json' \
  -d "{
    \"order_id\":\"$TEST_ORDER_ID\",
    \"buyer_name\":\"测试用户\",
    \"buyer_email\":\"test@test.com\",
    \"buyer_phone\":\"13800138000\",
    \"order_amount\":1000
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

echo "HTTP 状态码: $HTTP_CODE"
echo "响应内容:"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Webhook 测试成功！"
    echo ""
    echo "查询数据库中的订单..."
    docker exec kyc_postgres psql -U kyc_user -d kyc_db -c \
      "SELECT taobao_order_id, buyer_name, created_at FROM orders ORDER BY created_at DESC LIMIT 1;"
else
    echo "❌ Webhook 测试失败 (状态码: $HTTP_CODE)"
    echo ""
    echo "可能原因:"
    echo "  - Flask 还在启动"
    echo "  - 代码还没有更新"
    echo "  - 还有其他问题"
    echo ""
    echo "请重新运行此脚本"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 测试完成"
