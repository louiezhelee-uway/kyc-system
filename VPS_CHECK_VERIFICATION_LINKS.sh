#!/bin/bash

# VPS 查询验证链接脚本

echo "========================================"
echo "  KYC 验证链接查询"
echo "========================================"
echo ""

# 方式 1: 直接查询数据库
echo "方式 1: 查询数据库中的所有订单和验证"
echo "========================================"
echo ""

docker exec kyc_postgres psql -U kyc_user -d kyc_db << EOPSQL
\echo '========== 所有订单信息 =========='
SELECT id, taobao_order_id, buyer_name, buyer_email, created_at FROM orders;

\echo ''
\echo '========== 所有验证记录 =========='
SELECT id, order_id, status, verification_token, created_at FROM verifications;

\echo ''
\echo '========== 验证链接详情 =========='
SELECT 
    v.id as 验证ID,
    o.taobao_order_id as 订单ID,
    o.buyer_name as 买家,
    v.status as 状态,
    v.verification_link as 验证链接,
    v.created_at as 创建时间
FROM verifications v
JOIN orders o ON v.order_id = o.id
ORDER BY v.created_at DESC;
EOPSQL

echo ""
echo "========================================"
echo "  方式 2: 测试 Webhook 创建订单和验证"
echo "========================================"
echo ""

# 模拟 Taobao webhook 创建订单和验证链接
ORDER_ID="test_order_$(date +%s)"

echo "创建测试订单: $ORDER_ID"
echo ""

WEBHOOK_RESPONSE=$(curl -s -X POST http://localhost:5000/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d "{
    \"order_id\": \"$ORDER_ID\",
    \"buyer_id\": \"buyer123\",
    \"buyer_name\": \"测试买家\",
    \"buyer_email\": \"test@example.com\",
    \"buyer_phone\": \"13800138000\",
    \"platform\": \"taobao\",
    \"order_amount\": 1000
  }")

echo "Webhook 响应:"
echo "$WEBHOOK_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$WEBHOOK_RESPONSE"

echo ""
echo "========================================"
echo "  方式 3: 查看最新的验证链接"
echo "========================================"
echo ""

docker exec kyc_postgres psql -U kyc_user -d kyc_db -c "
SELECT 
    v.verification_link as 验证链接,
    o.buyer_name as 买家,
    v.status as 状态,
    v.created_at as 创建时间
FROM verifications v
JOIN orders o ON v.order_id = o.id
ORDER BY v.created_at DESC
LIMIT 1;
"

echo ""
