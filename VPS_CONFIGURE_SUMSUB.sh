#!/bin/bash

###############################################################################
# 配置 Sumsub API 凭证
# 使用: bash VPS_CONFIGURE_SUMSUB.sh
###############################################################################

cd /opt/kyc-app

echo "╔════════════════════════════════════════════════════════╗"
echo "║  配置 Sumsub API 凭证                                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 读取或提示输入
read -p "请输入 SUMSUB_APP_TOKEN: " SUMSUB_APP_TOKEN
read -p "请输入 SUMSUB_SECRET_KEY: " SUMSUB_SECRET_KEY
read -p "请输入 Sumsub API URL (默认: https://api.sumsub.com): " SUMSUB_API_URL
SUMSUB_API_URL=${SUMSUB_API_URL:-https://api.sumsub.com}

echo ""
echo "准备更新环境变量..."
echo "  SUMSUB_APP_TOKEN: ${SUMSUB_APP_TOKEN:0:20}..."
echo "  SUMSUB_SECRET_KEY: ${SUMSUB_SECRET_KEY:0:20}..."
echo "  SUMSUB_API_URL: $SUMSUB_API_URL"
echo ""

read -p "确认更新? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 1
fi

echo ""
echo "更新 docker-compose.yml 环境变量..."

# 更新 docker-compose.yml
sed -i.bak \
  -e "s|SUMSUB_APP_TOKEN:.*|SUMSUB_APP_TOKEN: $SUMSUB_APP_TOKEN|" \
  -e "s|SUMSUB_SECRET_KEY:.*|SUMSUB_SECRET_KEY: $SUMSUB_SECRET_KEY|" \
  -e "s|SUMSUB_API_URL:.*|SUMSUB_API_URL: $SUMSUB_API_URL|" \
  docker-compose.yml

echo "✅ 环境变量已更新"
echo ""

echo "重启容器..."
docker-compose restart kyc_web
sleep 5

echo ""
echo "测试 Sumsub API 连接..."
docker exec kyc_web python3 << 'EOF'
import os
import requests
import hmac
import hashlib
import time

print("\n检查 Sumsub 配置:")
token = os.getenv('SUMSUB_APP_TOKEN', '')
secret = os.getenv('SUMSUB_SECRET_KEY', '')
api_url = os.getenv('SUMSUB_API_URL', 'https://api.sumsub.com')

print(f"  Token 长度: {len(token)} 字符")
print(f"  Secret 长度: {len(secret)} 字符")
print(f"  API URL: {api_url}")

if not token or not secret:
    print("\n❌ 凭证不完整!")
    exit(1)

# 尝试调用 API
print("\n测试 API 连接...")

path = '/resources/applicants'
ts = str(int(time.time()))
signature_raw = f"GET{path}{ts}"
signature = hmac.new(
    secret.encode(),
    signature_raw.encode(),
    hashlib.sha256
).hexdigest()

headers = {
    'Authorization': f'Bearer {token}',
    'X-App-Access-Sig': signature,
    'X-App-Access-Ts': ts,
    'Content-Type': 'application/json'
}

try:
    response = requests.get(
        f'{api_url}{path}',
        headers=headers,
        timeout=10
    )
    
    print(f"  HTTP 状态码: {response.status_code}")
    
    if response.status_code == 200:
        print("  ✅ API 连接成功!")
        data = response.json()
        print(f"  响应: {data}")
    else:
        print(f"  ❌ 请求失败")
        print(f"  响应 (前300字): {response.text[:300]}")
        
except Exception as e:
    print(f"  ❌ 连接错误: {e}")

EOF

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 配置完成"
echo ""
echo "下次测试 webhook 时运行:"
echo "  bash VPS_WEBHOOK_TEST.sh"
