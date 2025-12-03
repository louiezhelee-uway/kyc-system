#!/bin/bash

# Complete KYC flow test with corrected Sumsub integration

echo "════════════════════════════════════════════════════════"
echo "🧪 完整 KYC 流程测试"
echo "════════════════════════════════════════════════════════"

python3 << 'EOF'
import requests
import hmac
import hashlib
import time
import json
import os

# 使用环境变量或固定值
TOKEN = os.getenv('SUMSUB_TOKEN', 'prd:BUWAA7ogVIJZ7W9h7A4BaSRx.xm4V4Zef52mLLYJl0oJ1X4v878Ibo2ie')
SECRET = os.getenv('SUMSUB_SECRET', 'ypDDepVCvib3Oq3P6tfML91huztzOMuY')
API_BASE = "https://api.sumsub.com"
LEVEL_NAME = os.getenv('SUMSUB_VERIFICATION_LEVEL', 'id-and-liveness')

def sign_request(method: str, path: str, body: str = ''):
    """根据 Sumsub 官方文档生成签名"""
    ts = str(int(time.time()))
    sig_raw = f"{ts}{method}{path}{body}"
    sig = hmac.new(SECRET.encode(), sig_raw.encode(), hashlib.sha256).hexdigest()
    return ts, sig

def get_headers(ts: str, sig: str):
    """构建请求头"""
    return {
        'X-App-Token': TOKEN,
        'X-App-Access-Sig': sig,
        'X-App-Access-Ts': ts,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    }

print("\n" + "═" * 70)
print("📌 第一步: 生成 SDK 访问令牌")
print("═" * 70)

# Step 1: Generate SDK access token
path = "/resources/accessTokens/sdk"
user_id = f"kyc_user_{int(time.time())}"

payload = {
    "userId": user_id,
    "levelName": LEVEL_NAME,
    "ttlInSecs": 1800,
    "applicantIdentifiers": {
        "email": f"{user_id}@kyc.317073.xyz"
    }
}

body = json.dumps(payload)
ts, sig = sign_request("POST", path, body)

print(f"\n📋 请求参数:")
print(f"  用户ID: {user_id}")
print(f"  验证等级: {LEVEL_NAME}")
print(f"  时间戳: {ts}")
print(f"  签名: {sig[:20]}...")

response = requests.post(
    f'{API_BASE}{path}',
    json=payload,
    headers=get_headers(ts, sig),
    timeout=15
)

print(f"\n📥 响应状态码: {response.status_code}")

if response.status_code in [200, 201]:
    data = response.json()
    access_token = data.get('token')
    
    print(f"✅ 成功生成访问令牌!")
    print(f"\n📊 令牌信息:")
    print(f"  令牌前缀: {access_token[:40]}...")
    print(f"  用户ID: {data.get('userId')}")
    
    print(f"\n🔗 KYC 验证链接:")
    verification_url = f"https://api.sumsub.com/sdk/applicant?token={access_token}"
    print(f"  {verification_url}")
    
    print(f"\n📱 这个链接可以:")
    print(f"  1. 由用户直接打开进行身份验证")
    print(f"  2. 嵌入到 iframe 中集成到您的应用")
    print(f"  3. 通过 WebSDK 加载")
    
    print(f"\n" + "═" * 70)
    print("✅ KYC 流程已完全就绪！")
    print("═" * 70)
    
    print(f"\n📌 后续步骤:")
    print(f"  1. 用户通过上述链接完成身份验证")
    print(f"  2. Sumsub 会通过 webhook 通知验证结果")
    print(f"  3. 您的系统接收 webhook 并更新用户状态")
    print(f"  4. 生成 KYC 报告")
    
else:
    print(f"❌ 生成令牌失败")
    print(f"\n📊 错误信息:")
    try:
        error_data = response.json()
        print(json.dumps(error_data, indent=2))
    except:
        print(f"  {response.text[:500]}")

print(f"\n" + "═" * 70)

EOF
