#!/bin/bash

# VPS_FIX_SUMSUB_CONFIG.sh - 修复 Sumsub API 凭证配置
# 用途: 纠正 docker-compose.yml 中的环境变量名称

set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 修复 Sumsub API 凭证配置"
echo "════════════════════════════════════════════════════════"

cd /opt/kyc-app || exit 1

# 1. 拉取最新代码
echo "📥 拉取最新代码..."
git pull origin main || echo "⚠️  Git pull 失败，继续使用本地版本"

# 2. 停止容器
echo "🛑 停止容器..."
docker-compose down --remove-orphans 2>/dev/null || true

# 3. 提示用户输入凭证
echo ""
echo "请输入 Sumsub API 凭证："
read -p "SUMSUB_APP_TOKEN (prd:...): " SUMSUB_APP_TOKEN
read -p "SUMSUB_SECRET_KEY: " SUMSUB_SECRET_KEY

if [[ -z "$SUMSUB_APP_TOKEN" || -z "$SUMSUB_SECRET_KEY" ]]; then
    echo "❌ 凭证不能为空"
    exit 1
fi

# 4. 更新 .env 文件
echo "📝 更新 .env 文件..."
cat > .env <<EOF
SUMSUB_APP_TOKEN=$SUMSUB_APP_TOKEN
SUMSUB_SECRET_KEY=$SUMSUB_SECRET_KEY
WEBHOOK_SECRET=test-webhook-secret
SECRET_KEY=test-secret-key
FLASK_ENV=production
EOF

# 5. 启动容器
echo "🚀 启动容器..."
docker-compose up -d

# 6. 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 7. 检查健康状态
echo "🏥 检查健康状态..."
HEALTH=$(curl -s http://localhost:5000/health || echo "fail")
if echo "$HEALTH" | grep -q "healthy"; then
    echo "✅ Flask 服务健康"
else
    echo "❌ Flask 服务不健康"
    echo "响应: $HEALTH"
    docker-compose logs web | tail -20
fi

# 8. 查看环境变量
echo ""
echo "📋 验证环境变量:"
docker-compose exec -T web env | grep SUMSUB || echo "⚠️  Sumsub 变量未找到"

# 9. 测试 webhook
echo ""
echo "🧪 测试 /webhook/taobao/order 端点..."
RESPONSE=$(curl -s -X POST http://localhost:5000/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d '{
    "taobao_order_id": "test_'"$(date +%s)"'",
    "buyer_name": "Test Buyer",
    "buyer_email": "test@example.com",
    "buyer_phone": "+86-13800000000",
    "order_amount": "100.00"
  }')

echo "响应: $RESPONSE"

if echo "$RESPONSE" | grep -q "verification_token"; then
    echo "✅ Webhook 测试成功！"
elif echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Webhook 返回错误"
    echo "完整响应:"
    echo "$RESPONSE" | head -5
else
    echo "⚠️  响应不清晰，检查日志:"
    docker-compose logs web | tail -20
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 配置完成"
echo "════════════════════════════════════════════════════════"
