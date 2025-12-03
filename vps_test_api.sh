#!/bin/bash

# Quick test script to run on VPS

cat > /tmp/test_api.py << 'EOF'
import requests
import hmac
import hashlib
import time
import json
import os
import sys

TOKEN = os.getenv('SUMSUB_APP_TOKEN', 'prd:BUWAA7ogVIJZ7W9h7A4BaSRx.xm4V4Zef52mLLYJl0oJ1X4v878Ibo2ie')
SECRET = os.getenv('SUMSUB_SECRET_KEY', 'ypDDepVCvib3Oq3P6tfML91huztzOMuY')
API_URL = 'https://api.sumsub.com'

print("🧪 从 VPS 测试 Sumsub API")
print("=" * 60)

path = "/resources/applicants"
ts = str(int(time.time() * 1000))

payload = {
    "externalUserId": f"vps_test_{int(time.time())}",
    "email": "test@kyc.317073.xyz",
    "firstName": "Test",
    "country": "CN"
}

body = json.dumps(payload)
sig_raw = f"POST{path}{body}{ts}"
sig = hmac.new(SECRET.encode(), sig_raw.encode(), hashlib.sha256).hexdigest()

headers = {
    'Authorization': f'Bearer {TOKEN}',
    'X-App-Access-Sig': sig,
    'X-App-Access-Ts': str(ts),
    'Content-Type': 'application/json',
}

print(f"📍 VPS 测试开始")
print(f"🔗 API: {API_URL}{path}")
print(f"⏰ 时间戳: {ts}")
print(f"🔐 签名: {sig[:20]}...\n")

try:
    r = requests.post(f'{API_URL}{path}', json=payload, headers=headers, timeout=10, allow_redirects=False)
    
    print(f"📥 状态码: {r.status_code}")
    
    if r.status_code in [200, 201]:
        print(f"✅ 成功!")
        print(json.dumps(r.json(), indent=2))
        sys.exit(0)
    else:
        print(f"❌ 失败")
        if 'cf-mitigated' in r.headers:
            print(f"   Cloudflare: {r.headers.get('cf-mitigated')}")
        print(f"   响应: {r.text[:200]}")
        sys.exit(1)
except Exception as e:
    print(f"❌ 异常: {e}")
    sys.exit(1)
EOF

echo "📦 脚本已创建: /tmp/test_api.py"
echo ""
echo "在 VPS 上运行此命令:"
echo "python3 /tmp/test_api.py"
