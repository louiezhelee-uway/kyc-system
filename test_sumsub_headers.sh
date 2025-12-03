#!/bin/bash

# test_sumsub_headers.sh - 测试不同的请求头组合

cd /opt/kyc-app || exit 1

echo "════════════════════════════════════════════════════════"
echo "🧪 测试不同的 Sumsub API 请求头组合"
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
print(f"  签名结果: {signature[:20]}...")

# 尝试不同的请求头组合
test_configs = [
    {
        "name": "标准配置 (带 User-Agent)",
        "headers": {
            'Authorization': f'Bearer {SUMSUB_APP_TOKEN}',
            'X-App-Access-Sig': signature,
            'X-App-Access-Ts': ts,
            'Content-Type': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'application/json'
        }
    },
    {
        "name": "简化配置 (仅必需头)",
        "headers": {
            'Authorization': f'Bearer {SUMSUB_APP_TOKEN}',
            'X-App-Access-Sig': signature,
            'X-App-Access-Ts': ts,
            'Content-Type': 'application/json'
        }
    },
    {
        "name": "使用 Token 作为签名 (尝试不同签名方式)",
        "headers": {
            'Authorization': f'Bearer {SUMSUB_APP_TOKEN}',
            'X-App-Access-Sig': signature,
            'X-App-Access-Ts': ts,
            'Content-Type': 'application/json',
            'Accept': '*/*'
        }
    }
]

for config in test_configs:
    print(f"\n{'='*60}")
    print(f"测试: {config['name']}")
    print(f"{'='*60}")
    
    try:
        response = requests.post(
            f'{API_URL}{path}',
            json=json.loads(body),
            headers=config['headers'],
            timeout=10,
            allow_redirects=False
        )
        
        print(f"📥 状态码: {response.status_code}")
        
        if response.status_code in [200, 201]:
            print(f"✅ 成功！")
            data = response.json()
            print(f"   Applicant ID: {data.get('id')}")
            break
        elif response.status_code == 403:
            print(f"❌ 403 Forbidden - 可能是凭证问题或 Cloudflare 挑战")
            # 检查响应头
            if 'cf-mitigated' in response.headers:
                print(f"   Cloudflare 检测: {response.headers.get('cf-mitigated')}")
        elif response.status_code == 401:
            print(f"❌ 401 Unauthorized - 凭证无效")
            if response.text:
                print(f"   响应: {response.text[:200]}")
        else:
            print(f"⚠️ 其他错误")
            print(f"   响应体: {response.text[:300]}")
            
    except Exception as e:
        print(f"❌ 请求异常: {e}")

PYTHON_SCRIPT

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 测试完成"
echo "════════════════════════════════════════════════════════"
