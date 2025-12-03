#!/bin/bash

# Test different Sumsub API approaches

python3 << 'EOF'
import requests
import hmac
import hashlib
import time
import json

TOKEN = "prd:BUWAA7ogVIJZ7W9h7A4BaSRx.xm4V4Zef52mLLYJl0oJ1X4v878Ibo2ie"
SECRET = "ypDDepVCvib3Oq3P6tfML91huztzOMuY"

print("=" * 70)
print("🔍 尝试不同的 Sumsub API 端点和方法")
print("=" * 70)

# Try different API versions/endpoints
endpoints = [
    ("https://api.sumsub.com/resources/applicants", "生产环境 API"),
    ("https://test-api.sumsub.com/resources/applicants", "测试环境 API (如果存在)"),
    ("https://api.sumsub.com/v5/resources/applicants", "V5 API"),
]

payload = {
    "externalUserId": f"test_{int(time.time())}",
    "email": "test@kyc.317073.xyz",
    "firstName": "Test",
    "country": "CN"
}

for url, desc in endpoints:
    print(f"\n➜ {desc}")
    print(f"  URL: {url}")
    print("  " + "─" * 64)
    
    # Generate signature for this URL
    path = url.replace("https://api.sumsub.com", "").replace("https://test-api.sumsub.com", "")
    if not path:
        path = "/resources/applicants"
    
    ts = str(int(time.time() * 1000))
    body = json.dumps(payload)
    sig_raw = f"POST{path}{body}{ts}"
    sig = hmac.new(SECRET.encode(), sig_raw.encode(), hashlib.sha256).hexdigest()
    
    headers = {
        'Authorization': f'Bearer {TOKEN}',
        'X-App-Access-Sig': sig,
        'X-App-Access-Ts': str(ts),
        'Content-Type': 'application/json',
    }
    
    try:
        response = requests.post(
            url,
            json=payload,
            headers=headers,
            timeout=10,
            allow_redirects=False
        )
        
        if response.status_code in [200, 201]:
            print(f"  ✅ 成功! (状态: {response.status_code})")
            data = response.json()
            print(f"     Applicant ID: {data.get('id')}")
        else:
            status_icon = "⚠️" if response.status_code not in [403, 404] else "❌"
            print(f"  {status_icon} 状态码: {response.status_code}")
            
            if 'cf-mitigated' in response.headers:
                print(f"     Cloudflare 挑战")
            elif response.status_code == 404:
                print(f"     端点不存在")
            
    except requests.exceptions.ConnectionError:
        print(f"  ❌ 连接错误")
    except Exception as e:
        print(f"  ❌ 异常: {str(e)[:50]}")

EOF
