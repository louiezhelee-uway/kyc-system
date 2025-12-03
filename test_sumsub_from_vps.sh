#!/bin/bash

# Test Sumsub API directly from VPS container

echo "════════════════════════════════════════════════════"
echo "🧪 从 VPS 容器测试 Sumsub API"
echo "════════════════════════════════════════════════════"

cd /opt/kyc-app || exit 1

# Test using docker-compose exec
docker-compose exec -T web python3 << 'PYTHON_SCRIPT'
import requests
import hmac
import hashlib
import time
import json
import os

SUMSUB_APP_TOKEN = os.getenv('SUMSUB_APP_TOKEN')
SUMSUB_SECRET_KEY = os.getenv('SUMSUB_SECRET_KEY')
SUMSUB_API_URL = os.getenv('SUMSUB_API_URL', 'https://api.sumsub.com')

print("📝 环境变量凭证:")
print(f"  Token: {SUMSUB_APP_TOKEN[:30] if SUMSUB_APP_TOKEN else 'NOT SET'}...")
print(f"  Secret: {SUMSUB_SECRET_KEY[:20] if SUMSUB_SECRET_KEY else 'NOT SET'}...")
print(f"  API URL: {SUMSUB_API_URL}")

if not SUMSUB_APP_TOKEN or not SUMSUB_SECRET_KEY:
    print("\n❌ 错误: 缺少必要的环境变量")
    exit(1)

# Generate signature
path = "/resources/applicants"
ts = str(int(time.time() * 1000))

payload = {
    "externalUserId": f"test_{int(time.time())}",
    "email": "test@example.com",
    "firstName": "Test",
    "country": "CN"
}

body = json.dumps(payload)
sig_raw = f"POST{path}{body}{ts}"
signature = hmac.new(
    SUMSUB_SECRET_KEY.encode(),
    sig_raw.encode(),
    hashlib.sha256
).hexdigest()

headers = {
    'Authorization': f'Bearer {SUMSUB_APP_TOKEN}',
    'X-App-Access-Sig': signature,
    'X-App-Access-Ts': str(ts),
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'KYC-System/1.0'
}

print(f"\n🔐 签名信息:")
print(f"  时间戳: {ts}")
print(f"  签名: {signature[:30]}...")

print(f"\n🚀 发送请求...")
print(f"  方法: POST")
print(f"  URL: {SUMSUB_API_URL}{path}")
print(f"  超时: 10 秒\n")

try:
    response = requests.post(
        f'{SUMSUB_API_URL}{path}',
        json=payload,
        headers=headers,
        timeout=10,
        allow_redirects=False,
        verify=True
    )
    
    print(f"📥 响应状态码: {response.status_code}")
    print(f"   响应大小: {len(response.text)} 字节")
    
    if response.status_code in [200, 201]:
        print(f"\n✅ 成功！")
        data = response.json()
        print(f"\n📊 Applicant ID: {data.get('id')}")
        print(f"   External ID: {data.get('externalUserId')}")
        print(f"   Status: {data.get('status')}")
    else:
        print(f"\n❌ 请求失败")
        
        # Check for Cloudflare
        if 'cf-mitigated' in response.headers:
            print(f"   Cloudflare 挑战: {response.headers.get('cf-mitigated')}")
            print(f"   CF Ray: {response.headers.get('cf-ray')}")
        
        if response.status_code == 401:
            print(f"   错误类型: 认证失败 (401)")
        elif response.status_code == 403:
            print(f"   错误类型: 禁止访问 (403)")
        
        # Try to parse error response
        try:
            error_data = response.json()
            print(f"\n   API 错误信息:")
            print(json.dumps(error_data, indent=2))
        except:
            print(f"\n   响应内容 (前 200 字符):")
            print(f"   {response.text[:200]}")

except requests.exceptions.Timeout:
    print(f"❌ 请求超时 (10秒)")
except requests.exceptions.ConnectionError as e:
    print(f"❌ 连接错误: {e}")
except Exception as e:
    print(f"❌ 异常: {e}")

PYTHON_SCRIPT

echo ""
echo "════════════════════════════════════════════════════"
echo "✅ 测试完成"
echo "════════════════════════════════════════════════════"
