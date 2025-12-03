#!/bin/bash

# test_sumsub_via_python.sh - 通过 Python 测试 Sumsub API

cd /opt/kyc-app || exit 1

echo "════════════════════════════════════════════════════════"
echo "🧪 通过 Python 测试 Sumsub API 凭证"
echo "════════════════════════════════════════════════════════"

docker-compose exec -T web python3 << 'PYTHON_SCRIPT'
import requests
import hmac
import hashlib
import time
import json

SUMSUB_APP_TOKEN = "prd:5egHoatccEUC4LTnBZvBDlGH.jZLquVQyveNPaQzEYMBCshQtv2WpLsoR"
SUMSUB_SECRET_KEY = "X2EytNeEicET8jno0Vr6iHbKhOE0cpKQ"
API_URL = "https://api.sumsub.com"

print("\n📝 凭证信息:")
print(f"  Token: {SUMSUB_APP_TOKEN[:30]}...")
print(f"  Secret: {SUMSUB_SECRET_KEY[:20]}...")

# 生成签名
ts = str(int(time.time() * 1000))
path = '/resources/applicants'
body = json.dumps({
    "externalUserId": f"test_{int(time.time())}",
    "email": "test@example.com",
    "phone": "+86-13800000000",
    "firstName": "Test",
    "lastName": "",
    "country": "CN"
})

sig_raw = f"POST{path}{body}{ts}"
signature = hmac.new(
    SUMSUB_SECRET_KEY.encode(),
    sig_raw.encode(),
    hashlib.sha256
).hexdigest()

print(f"\n🔐 签名信息:")
print(f"  时间戳: {ts}")
print(f"  签名原文长度: {len(sig_raw)}")
print(f"  签名结果: {signature[:20]}...")

# 发送请求
headers = {
    'Authorization': f'Bearer {SUMSUB_APP_TOKEN}',
    'X-App-Access-Sig': signature,
    'X-App-Access-Ts': ts,
    'Content-Type': 'application/json'
}

print(f"\n🚀 发送请求到: {API_URL}{path}")
print(f"  请求头: Authorization=Bearer ******, X-App-Access-Sig={signature[:10]}..., X-App-Access-Ts={ts}")

try:
    response = requests.post(
        f'{API_URL}{path}',
        json=json.loads(body),
        headers=headers,
        timeout=10
    )
    
    print(f"\n📥 响应状态码: {response.status_code}")
    print(f"  响应头: {dict(response.headers)}")
    print(f"  响应体 (前 500 字):")
    print(response.text[:500])
    
    if response.status_code in [200, 201]:
        print("\n✅ API 凭证有效！")
        data = response.json()
        print(f"  Applicant ID: {data.get('id')}")
    else:
        print(f"\n❌ API 返回错误状态码: {response.status_code}")
        
except Exception as e:
    print(f"\n❌ 请求失败: {e}")
    import traceback
    traceback.print_exc()

PYTHON_SCRIPT

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 测试完成"
echo "════════════════════════════════════════════════════════"
