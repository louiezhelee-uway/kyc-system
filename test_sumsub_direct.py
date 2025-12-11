#!/usr/bin/env python3
"""
直接测试 Sumsub API - 创建 applicant（不使用 Flask）
"""

import os
import sys
import json
import hmac
import hashlib
import time
import requests

# Configuration
SUMSUB_APP_TOKEN = os.getenv('SUMSUB_APP_TOKEN', 'prd:BUWAA7ogVIJZ7W9h7A4BaSRx.xm4V4Zef52mLLYJl0oJ1X4v878Ibo2ie')
SUMSUB_SECRET_KEY = os.getenv('SUMSUB_SECRET_KEY', 'ypDDepVCvib3Oq3P6tfML91huztzOMuY')
SUMSUB_API_URL = os.getenv('SUMSUB_API_URL', 'https://api.sumsub.com')

def get_signature(method: str, path: str, body: str = ''):
    """Generate HMAC-SHA256 signature"""
    ts = str(int(time.time()))  # Seconds
    sig_raw = f"{ts}{method}{path}{body}"
    signature = hmac.new(
        SUMSUB_SECRET_KEY.encode(),
        sig_raw.encode(),
        hashlib.sha256
    ).hexdigest()
    return ts, signature

def test_create_applicant():
    """Test creating an applicant"""
    print("\n" + "="*60)
    print("🧪 直接测试 Sumsub API - 创建 Applicant")
    print("="*60)
    
    path = '/resources/applicants'
    
    payload = {
        'externalUserId': 'test_' + str(int(time.time())),
        'email': 'test@example.com',
        'phone': '+86 13800138000',
        'firstName': '张三',
        'lastName': '',
        'country': 'CN',
        'levelName': 'id-and-liveness',  # Add level name
    }
    
    print(f"\n📝 请求数据:")
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    
    body = json.dumps(payload)
    ts, sig = get_signature('POST', path, body)
    
    headers = {
        'X-App-Token': SUMSUB_APP_TOKEN,
        'X-App-Access-Sig': sig,
        'X-App-Access-Ts': ts,
        'Content-Type': 'application/json',
    }
    
    print(f"\n🔐 请求头:")
    print(f"  X-App-Token: {SUMSUB_APP_TOKEN[:30]}...")
    print(f"  X-App-Access-Sig: {sig[:30]}...")
    print(f"  X-App-Access-Ts: {ts}")
    
    url = f'{SUMSUB_API_URL}{path}'
    print(f"\n🌐 请求 URL: {url}")
    
    try:
        response = requests.post(
            url,
            json=payload,
            headers=headers,
            timeout=15
        )
        
        print(f"\n📥 响应状态: {response.status_code}")
        print(f"📝 响应内容:")
        print(json.dumps(response.json(), indent=2, ensure_ascii=False))
        
        if response.status_code in [200, 201]:
            data = response.json()
            applicant_id = data.get('id')
            print(f"\n✅ Applicant 已创建!")
            print(f"   Applicant ID: {applicant_id}")
            return applicant_id
        else:
            print(f"\n❌ 创建失败!")
            return None
            
    except Exception as e:
        print(f"\n❌ 错误: {str(e)}")
        return None

if __name__ == '__main__':
    test_create_applicant()
