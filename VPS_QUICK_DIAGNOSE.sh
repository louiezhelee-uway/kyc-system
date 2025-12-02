#!/bin/bash

###############################################################################
# VPS 快速诊断脚本
###############################################################################

cd /opt/kyc-app

echo "╔════════════════════════════════════════════════════════╗"
echo "║  KYC 系统快速诊断                                      ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 检查容器
echo "1️⃣  检查 Docker 容器状态..."
echo "════════════════════════════════════════════════════════"
docker ps -a | grep kyc || echo "未找到任何 kyc 容器"
echo ""

# 获取 Flask 容器名
FLASK_CONTAINER=$(docker ps -a --format '{{.Names}}' | grep -E 'kyc_web|kyc-app.web.1' | head -1)

if [ -z "$FLASK_CONTAINER" ]; then
    echo "❌ 找不到 Flask 容器！"
    echo "尝试重启容器..."
    docker-compose down
    sleep 2
    docker-compose up -d
    sleep 5
    FLASK_CONTAINER=$(docker ps -a --format '{{.Names}}' | grep -E 'kyc_web|kyc-app.web' | head -1)
fi

if [ -z "$FLASK_CONTAINER" ]; then
    echo "❌ 仍然找不到容器"
    docker ps -a
    exit 1
fi

echo "✅ Flask 容器: $FLASK_CONTAINER"
echo ""

# 查看 Flask 日志
echo "2️⃣  Flask 容器日志 (最后 30 行)..."
echo "════════════════════════════════════════════════════════"
docker logs --tail=30 "$FLASK_CONTAINER" 2>&1 | tail -30
echo ""

# 检查应用是否能启动
echo "3️⃣  检查 Flask 应用..."
echo "════════════════════════════════════════════════════════"
docker exec "$FLASK_CONTAINER" python3 -c "
from app import create_app
app = create_app()
routes = [str(r.rule) for r in app.url_map.iter_rules()]
print(f'✅ Flask 应用启动成功')
print(f'📊 注册的路由数: {len(routes)}')
if '/health' in routes:
    print('✅ /health 路由已注册')
else:
    print('❌ /health 路由未找到')
if '/webhook/taobao/order' in routes:
    print('✅ /webhook/taobao/order 路由已注册')
else:
    print('❌ /webhook/taobao/order 路由未找到')
" 2>&1

echo ""

# 测试 HTTP 请求
echo "4️⃣  测试 HTTP 请求..."
echo "════════════════════════════════════════════════════════"

echo "测试 /health 端点..."
curl -s -w '\nHTTP 状态码: %{http_code}\n' http://localhost:5000/health | head -20
echo ""

echo "测试 /webhook/taobao/order 端点..."
curl -s -w '\nHTTP 状态码: %{http_code}\n' -X POST http://localhost:5000/webhook/taobao/order \
  -H 'Content-Type: application/json' \
  -d '{"order_id":"test_123","buyer_name":"测试","buyer_email":"test@test.com","buyer_phone":"13800138000","order_amount":1000}' | head -20

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 诊断完成"
