#!/usr/bin/env python3
"""
Sumsub API Ultimate Diagnostic Tool
Comprehensive testing of credentials, signatures, and API connectivity
"""

import requests
import hmac
import hashlib
import time
import json
import sys

# Credentials
SUMSUB_APP_TOKEN = "prd:5egHoatccEUC4LTnBZvBDlGH.jZLquVQyveNPaQzEYMBCshQtv2WpLsoR"
SUMSUB_SECRET_KEY = "X2EytNeEicET8jno0Vr6iHbKhOE0cpKQ"
API_BASE = "https://api.sumsub.com"

def print_header(text):
    print(f"\n{'='*70}")
    print(f"  {text}")
    print(f"{'='*70}")

def print_section(text):
    print(f"\n➜ {text}")
    print("  " + "─" * 66)

def test_credential_format():
    """Test if credentials are properly formatted"""
    print_section("1️⃣  凭证格式检查")
    
    # Check token format
    if SUMSUB_APP_TOKEN.startswith('prd:') or SUMSUB_APP_TOKEN.startswith('tst:'):
        print(f"✅ Token 前缀正确: {SUMSUB_APP_TOKEN[:15]}...")
    else:
        print(f"⚠️  Token 前缀异常: {SUMSUB_APP_TOKEN[:15]}...")
    
    # Check token length
    if len(SUMSUB_APP_TOKEN) > 50:
        print(f"✅ Token 长度合理: {len(SUMSUB_APP_TOKEN)} 字符")
    else:
        print(f"❌ Token 长度异常: {len(SUMSUB_APP_TOKEN)} 字符（应该 >50）")
    
    # Check secret format
    if len(SUMSUB_SECRET_KEY) > 20:
        print(f"✅ Secret 长度合理: {len(SUMSUB_SECRET_KEY)} 字符")
    else:
        print(f"❌ Secret 长度异常: {len(SUMSUB_SECRET_KEY)} 字符（应该 >20）")
    
    return True

def test_signature_generation():
    """Test signature generation"""
    print_section("2️⃣  签名生成测试")
    
    path = "/resources/applicants"
    body = '{"externalUserId":"test_12345"}'
    
    ts_seconds = int(time.time())
    ts_millis = int(time.time() * 1000)
    
    # Try signature with seconds
    sig_raw_sec = f"POST{path}{body}{ts_seconds}"
    sig_sec = hmac.new(SUMSUB_SECRET_KEY.encode(), sig_raw_sec.encode(), hashlib.sha256).hexdigest()
    
    # Try signature with milliseconds
    sig_raw_ms = f"POST{path}{body}{ts_millis}"
    sig_ms = hmac.new(SUMSUB_SECRET_KEY.encode(), sig_raw_ms.encode(), hashlib.sha256).hexdigest()
    
    print(f"时间戳（秒）: {ts_seconds}")
    print(f"  签名原文: POST{path}{body}{ts_seconds}")
    print(f"  签名结果: {sig_sec[:20]}...")
    
    print(f"\n时间戳（毫秒）: {ts_millis}")
    print(f"  签名原文: POST{path}{body}{ts_millis}")
    print(f"  签名结果: {sig_ms[:20]}...")
    
    return sig_ms, ts_millis

def test_raw_http_request(signature, ts):
    """Test raw HTTP request with curl-like approach"""
    print_section("3️⃣  原始 HTTP 请求测试")
    
    path = "/resources/applicants"
    url = f"{API_BASE}{path}"
    
    payload = {
        "externalUserId": f"test_{int(time.time())}",
        "email": "test@example.com"
    }
    
    headers = {
        'Authorization': f'Bearer {SUMSUB_APP_TOKEN}',
        'X-App-Access-Sig': signature,
        'X-App-Access-Ts': str(ts),  # 必须是字符串!
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Python-Diagnostic-Tool/1.0'
    }
    
    print(f"URL: {url}")
    print(f"\n请求头:")
    for k, v in headers.items():
        if k == 'Authorization':
            print(f"  {k}: Bearer ****...****")
        elif k == 'X-App-Access-Sig':
            print(f"  {k}: {v[:20]}...")
        else:
            print(f"  {k}: {v}")
    
    print(f"\n请求体:")
    print(f"  {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(
            url,
            json=payload,
            headers=headers,
            timeout=10,
            allow_redirects=False,
            verify=True  # 验证 SSL 证书
        )
        
        print(f"\n📥 响应状态码: {response.status_code}")
        print(f"   响应大小: {len(response.text)} 字节")
        
        # Check response headers
        print(f"\n响应关键头:")
        important_headers = [
            'Server',
            'Content-Type',
            'X-Request-Id',
            'cf-mitigated',
            'cf-ray',
            'Set-Cookie'
        ]
        
        for header in important_headers:
            if header in response.headers:
                value = response.headers[header]
                if len(value) > 50:
                    print(f"  {header}: {value[:47]}...")
                else:
                    print(f"  {header}: {value}")
        
        # Check response body
        print(f"\n响应内容 (前 300 字符):")
        print(f"  {response.text[:300]}")
        
        # Try to parse as JSON
        try:
            data = response.json()
            print(f"\n✅ 成功解析为 JSON:")
            print(f"  {json.dumps(data, indent=2)[:200]}...")
            return True, None
        except:
            print(f"\n❌ 无法解析为 JSON")
            
            # Check if it's Cloudflare challenge
            if 'cf-mitigated' in response.headers:
                print(f"   ⚠️  Cloudflare 挑战被触发")
                return False, "Cloudflare challenge detected"
            elif response.status_code == 401:
                print(f"   ❌ 认证失败 (401)")
                return False, "Authentication failed"
            elif response.status_code == 403:
                print(f"   ❌ 禁止访问 (403)")
                return False, "Access forbidden"
            else:
                return False, f"HTTP {response.status_code}"
    
    except Exception as e:
        print(f"\n❌ 请求异常: {e}")
        return False, str(e)

def test_different_endpoints(signature, ts):
    """Test different Sumsub API endpoints"""
    print_section("4️⃣  不同端点测试")
    
    endpoints = [
        ("/resources/applicants", "POST", "创建申请人"),
        ("/resources/applicants", "GET", "列表申请人"),
        ("/v5/resources/applicants", "POST", "V5 API - 创建申请人"),
    ]
    
    for path, method, desc in endpoints:
        print(f"\n测试: {desc}")
        print(f"  端点: {method} {path}")
        
        # Re-generate signature for this path
        body = '{"externalUserId":"test"}' if method == "POST" else ""
        ts_new = str(int(time.time() * 1000))
        sig_raw = f"{method}{path}{body}{ts_new}"
        sig = hmac.new(SUMSUB_SECRET_KEY.encode(), sig_raw.encode(), hashlib.sha256).hexdigest()
        
        headers = {
            'Authorization': f'Bearer {SUMSUB_APP_TOKEN}',
            'X-App-Access-Sig': sig,
            'X-App-Access-Ts': ts_new,
            'Content-Type': 'application/json',
        }
        
        try:
            if method == "POST":
                response = requests.post(f"{API_BASE}{path}", json={"test": True}, headers=headers, timeout=5, allow_redirects=False)
            else:
                response = requests.get(f"{API_BASE}{path}", headers=headers, timeout=5, allow_redirects=False)
            
            status_icon = "✅" if response.status_code in [200, 201] else "❌"
            print(f"  {status_icon} 状态: {response.status_code}")
            
            if response.status_code in [200, 201]:
                print(f"     💚 成功！")
        except Exception as e:
            print(f"  ❌ 异常: {str(e)[:50]}")

def test_api_health():
    """Test if API is reachable"""
    print_section("5️⃣  API 健康检查")
    
    try:
        response = requests.get(f"{API_BASE}/healthz", timeout=5, allow_redirects=False)
        if response.status_code == 200:
            print(f"✅ API 可访问 (状态: {response.status_code})")
        else:
            print(f"⚠️  API 响应异常 (状态: {response.status_code})")
    except Exception as e:
        print(f"❌ 无法连接到 API: {e}")

def main():
    print_header("🔧 Sumsub API 终极诊断工具")
    
    # Step 1: Check credentials
    test_credential_format()
    
    # Step 2: Check API reachability
    test_api_health()
    
    # Step 3: Test signature generation
    sig, ts = test_signature_generation()
    
    # Step 4: Test raw HTTP request
    success, error = test_raw_http_request(sig, ts)
    
    # Step 5: Test different endpoints
    if not success:
        test_different_endpoints(sig, ts)
    
    # Final summary
    print_header("📊 诊断总结")
    
    if success:
        print("\n✅ 所有测试通过！Sumsub API 集成已准备好")
        sys.exit(0)
    else:
        print(f"\n❌ API 测试失败: {error}")
        print("\n可能的解决方案:")
        print("  1. 检查凭证是否过期或无效")
        print("  2. 检查网络连接和防火墙规则")
        print("  3. 确认使用的是 API 密钥而非普通凭证")
        print("  4. 查看 Sumsub 控制面板中的 API 使用情况日志")
        print("  5. 联系 Sumsub 支持检查账户状态")
        sys.exit(1)

if __name__ == '__main__':
    main()
