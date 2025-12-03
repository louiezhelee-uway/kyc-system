#!/bin/bash

# VPS_TEST_KYC_FLOW.sh - 模拟完整的 KYC 验证流程

set -e

cd /opt/kyc-app || exit 1

echo "════════════════════════════════════════════════════════"
echo "🧪 模拟完整 KYC 验证流程"
echo "════════════════════════════════════════════════════════"

# 1. 生成测试订单 ID
TEST_ORDER_ID="taobao_$(date +%s)"
echo ""
echo "📝 测试订单信息:"
echo "  订单 ID: $TEST_ORDER_ID"
echo "  买家: 张三 (Test Buyer)"
echo "  邮箱: test@example.com"
echo "  电话: +86-13800000000"
echo "  金额: 99.99 元"

# 2. 发送 webhook 请求（模拟淘宝订单事件）
echo ""
echo "🚀 1️⃣  模拟淘宝订单 webhook..."
WEBHOOK_RESPONSE=$(curl -s -X POST http://localhost:5000/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d "{
    \"taobao_order_id\": \"$TEST_ORDER_ID\",
    \"buyer_name\": \"张三\",
    \"buyer_email\": \"test@example.com\",
    \"buyer_phone\": \"+86-13800000000\",
    \"order_amount\": \"99.99\",
    \"platform\": \"taobao\"
  }")

echo "响应:"
echo "$WEBHOOK_RESPONSE" | jq '.' 2>/dev/null || echo "$WEBHOOK_RESPONSE"

# 3. 解析响应
if echo "$WEBHOOK_RESPONSE" | grep -q "verification_link\|verification_token"; then
    echo "✅ Webhook 成功！生成了验证链接"
    
    # 提取关键信息
    VERIFICATION_TOKEN=$(echo "$WEBHOOK_RESPONSE" | jq -r '.verification_token' 2>/dev/null || echo "")
    ORDER_ID=$(echo "$WEBHOOK_RESPONSE" | jq -r '.order_id' 2>/dev/null || echo "")
    VERIFICATION_ID=$(echo "$WEBHOOK_RESPONSE" | jq -r '.verification_id' 2>/dev/null || echo "")
    
    if [ ! -z "$VERIFICATION_TOKEN" ]; then
        echo ""
        echo "📌 生成的验证信息:"
        echo "  订单 ID: $ORDER_ID"
        echo "  验证 ID: $VERIFICATION_ID"
        echo "  验证 Token: $VERIFICATION_TOKEN"
        
        # 4. 访问验证页面
        echo ""
        echo "🧑‍💼 2️⃣  访问 KYC 验证页面..."
        VERIFY_URL="http://localhost:5000/verify/$VERIFICATION_TOKEN"
        echo "  URL: $VERIFY_URL"
        
        VERIFY_RESPONSE=$(curl -s -I "$VERIFY_URL" | head -1)
        echo "  状态: $VERIFY_RESPONSE"
        
        if echo "$VERIFY_RESPONSE" | grep -q "200\|301\|302"; then
            echo "✅ 验证页面可访问"
        else
            echo "❌ 验证页面访问失败"
        fi
        
        # 5. 查询数据库验证数据
        echo ""
        echo "📊 3️⃣  查询数据库记录..."
        docker-compose exec -T postgres psql -U kyc_user -d kyc_db -c "
        SELECT 
            id,
            taobao_order_id,
            buyer_name,
            buyer_email,
            order_amount,
            created_at
        FROM orders 
        WHERE id = '$ORDER_ID'
        LIMIT 1;
        " 2>/dev/null || echo "⚠️  查询失败"
        
        # 6. 查询验证记录
        echo ""
        echo "📋 验证记录:"
        docker-compose exec -T postgres psql -U kyc_user -d kyc_db -c "
        SELECT 
            id,
            sumsub_applicant_id,
            verification_token,
            status,
            created_at
        FROM verifications 
        WHERE order_id = '$ORDER_ID'
        LIMIT 1;
        " 2>/dev/null || echo "⚠️  查询失败"
        
    else
        echo "⚠️  未能从响应中提取 verification_token"
    fi
    
elif echo "$WEBHOOK_RESPONSE" | grep -q "error"; then
    echo "❌ Webhook 返回错误"
    echo "$WEBHOOK_RESPONSE" | jq '.' 2>/dev/null || echo "$WEBHOOK_RESPONSE"
    
    # 显示容器日志
    echo ""
    echo "📋 容器日志:"
    docker-compose logs web | tail -30
else
    echo "⚠️  响应不清晰"
    echo "$WEBHOOK_RESPONSE"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 测试完成"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📚 下一步:"
echo "1. 如果测试成功，访问上面生成的验证链接"
echo "2. 点击 'Start KYC' 进入 Sumsub WebSDK"
echo "3. 完成身份验证流程"
echo "4. Sumsub 会回调 webhook 更新验证状态"
echo "5. 系统自动生成 PDF 报告"
