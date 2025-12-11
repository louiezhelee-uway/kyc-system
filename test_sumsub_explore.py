#!/usr/bin/env python3
"""
Test Sumsub API - 获取现有 applicant 列表
"""

import os
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

def test_list_applicants():
    """List applicants"""
    print("\n获取 Applicant 列表...")
    
    path = '/resources/applicants'
    ts, sig = get_signature('GET', path)
    
    headers = {
        'X-App-Token': SUMSUB_APP_TOKEN,
        'X-App-Access-Sig': sig,
        'X-App-Access-Ts': ts,
    }
    
    url = f'{SUMSUB_API_URL}{path}'
    
    try:
        response = requests.get(url, headers=headers, timeout=15)
        print(f"状态: {response.status_code}")
        print("内容:")
        print(json.dumps(response.json(), indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"错误: {str(e)}")

def test_verification_level():
    """Get verification level"""
    print("\n获取验证等级...")
    
    path = '/resources/levels'
    ts, sig = get_signature('GET', path)
    
    headers = {
        'X-App-Token': SUMSUB_APP_TOKEN,
        'X-App-Access-Sig': sig,
        'X-App-Access-Ts': ts,
    }
    
    url = f'{SUMSUB_API_URL}{path}'
    
    try:
        response = requests.get(url, headers=headers, timeout=15)
        print(f"状态: {response.status_code}")
        print("内容:")
        print(json.dumps(response.json(), indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"错误: {str(e)}")

if __name__ == '__main__':
    test_list_applicants()
    test_verification_level()
