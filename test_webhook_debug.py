#!/usr/bin/env python3
"""
Debug script to test webhook endpoint and identify the exact error
"""

import requests
import json
import sys
import traceback

# Configuration
HOST = "http://localhost:5000"
ENDPOINT = f"{HOST}/webhook/taobao/order"

def test_webhook():
    """Test webhook endpoint with detailed error reporting"""
    
    print("=" * 70)
    print("KYC Webhook Endpoint Test")
    print("=" * 70)
    print()
    
    payload = {
        "order_id": "test_" + str(int(__import__('time').time())),
        "buyer_id": "test_buyer",
        "buyer_name": "测试用户",
        "buyer_email": "test@test.com",
        "buyer_phone": "13800138000",
        "platform": "taobao",
        "order_amount": 1000
    }
    
    print("📤 Request Details:")
    print(f"  URL: {ENDPOINT}")
    print(f"  Method: POST")
    print(f"  Headers:")
    print(f"    Content-Type: application/json")
    print(f"  Payload:")
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    print()
    
    try:
        print("🔄 Sending request...")
        response = requests.post(
            ENDPOINT,
            json=payload,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        
        print(f"✅ Response Status: {response.status_code}")
        print(f"📦 Response Body:")
        
        try:
            response_json = response.json()
            print(json.dumps(response_json, indent=2, ensure_ascii=False))
        except:
            print(response.text)
        
        print()
        
        if response.status_code == 201:
            print("✅ SUCCESS! Order created successfully")
            return True
        else:
            print(f"⚠️  Unexpected status code: {response.status_code}")
            return False
            
    except requests.exceptions.ConnectionError as e:
        print(f"❌ Connection Error: Cannot connect to {HOST}")
        print(f"   Make sure Flask app is running: python run.py")
        print(f"   Error: {e}")
        return False
        
    except requests.exceptions.Timeout:
        print(f"❌ Timeout: Request took too long")
        return False
        
    except Exception as e:
        print(f"❌ Error: {e}")
        traceback.print_exc()
        return False

def check_flask_health():
    """Check if Flask app is running"""
    
    print("=" * 70)
    print("Checking Flask Health")
    print("=" * 70)
    print()
    
    try:
        response = requests.get(f"{HOST}/health", timeout=5)
        print(f"✅ Flask is running!")
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}")
        return True
    except Exception as e:
        print(f"❌ Flask is NOT running: {e}")
        print(f"   Start Flask with: python run.py")
        return False

def check_environment():
    """Check if environment variables are set"""
    
    print()
    print("=" * 70)
    print("Checking Environment Variables")
    print("=" * 70)
    print()
    
    import os
    
    vars_to_check = [
        'SUMSUB_APP_TOKEN',
        'SUMSUB_SECRET_KEY',
        'DATABASE_URL',
        'FLASK_ENV'
    ]
    
    for var in vars_to_check:
        value = os.getenv(var)
        if value:
            # Show only first 10 and last 10 chars for secrets
            if 'SECRET' in var or 'TOKEN' in var or 'KEY' in var:
                display = value[:10] + '...' + value[-10:] if len(value) > 20 else '***'
            else:
                display = value
            print(f"✅ {var}: {display}")
        else:
            print(f"⚠️  {var}: NOT SET")
    
    print()

if __name__ == '__main__':
    check_flask_health()
    check_environment()
    success = test_webhook()
    
    sys.exit(0 if success else 1)
