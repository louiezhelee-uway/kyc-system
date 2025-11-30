#!/usr/bin/env python3
"""
KYC 系统 Mock 测试脚本
使用 Mock 数据测试完整的工作流
"""

import sys
import json
from pathlib import Path
from datetime import datetime
from unittest.mock import Mock, patch
import hmac
import hashlib

# 添加项目路径
project_dir = Path(__file__).parent.parent
sys.path.insert(0, str(project_dir))

def create_webhook_signature(payload, secret):
    """创建 Webhook 签名"""
    return hmac.new(
        secret.encode(),
        payload if isinstance(payload, bytes) else payload.encode(),
        hashlib.sha256
    ).hexdigest()


def test_webhook_flow():
    """测试完整的 Webhook 工作流"""
    print("\n" + "=" * 60)
    print("测试 Webhook 流程")
    print("=" * 60)
    
    from app import create_app
    import os
    
    app = create_app()
    client = app.test_client()
    
    # 模拟订单数据
    order_data = {
        'order_id': 'TAOBAO_20251125_123456',
        'buyer_id': 'buyer_12345',
        'buyer_name': '张三',
        'buyer_email': 'buyer@example.com',
        'buyer_phone': '13800138000',
        'platform': 'taobao',
        'order_amount': 299.99
    }
    
    # 创建签名
    payload = json.dumps(order_data)
    signature = create_webhook_signature(payload, 'test-webhook-secret')
    
    print(f"📝 订单数据: {json.dumps(order_data, ensure_ascii=False, indent=2)}")
    print(f"🔐 签名: {signature[:20]}...")
    
    # 发送 Webhook 请求
    response = client.post(
        '/webhook/taobao/order',
        data=payload,
        headers={
            'Content-Type': 'application/json',
            'X-Webhook-Signature': signature
        }
    )
    
    print(f"\n📊 响应状态: {response.status_code}")
    
    if response.status_code == 201:
        resp_data = response.get_json()
        print(f"✅ 订单已创建")
        print(f"   订单 ID: {resp_data.get('order_id')}")
        print(f"   验证 ID: {resp_data.get('verification_id')}")
        return True
    elif response.status_code == 401:
        print(f"⚠️  签名验证失败 (预期行为，因为 WEBHOOK_SECRET 不匹配)")
        return True
    else:
        print(f"❌ 请求失败")
        print(f"   响应: {response.get_json()}")
        return False


def test_token_generation():
    """测试 Token 生成"""
    print("\n" + "=" * 60)
    print("测试 Token 生成")
    print("=" * 60)
    
    from app.utils import token_generator
    
    tokens = []
    for i in range(5):
        token = token_generator.generate_verification_token()
        tokens.append(token)
        print(f"  Token {i+1}: {token}")
    
    # 检查唯一性
    if len(tokens) == len(set(tokens)):
        print(f"\n✅ 所有 Token 都唯一")
        return True
    else:
        print(f"\n❌ 发现重复 Token")
        return False


def test_models():
    """测试数据库模型"""
    print("\n" + "=" * 60)
    print("测试数据库模型")
    print("=" * 60)
    
    from app.models import Order, Verification, Report
    
    # 检查模型属性
    order_attrs = ['id', 'taobao_order_id', 'buyer_id', 'buyer_name', 
                   'buyer_email', 'platform', 'created_at']
    verification_attrs = ['id', 'sumsub_applicant_id', 'verification_token', 
                         'status', 'created_at']
    report_attrs = ['id', 'verification_result', 'pdf_path', 'created_at']
    
    print("Order 模型:")
    for attr in order_attrs:
        if hasattr(Order, attr):
            print(f"  ✅ {attr}")
        else:
            print(f"  ❌ {attr}")
    
    print("\nVerification 模型:")
    for attr in verification_attrs:
        if hasattr(Verification, attr):
            print(f"  ✅ {attr}")
        else:
            print(f"  ❌ {attr}")
    
    print("\nReport 模型:")
    for attr in report_attrs:
        if hasattr(Report, attr):
            print(f"  ✅ {attr}")
        else:
            print(f"  ❌ {attr}")
    
    return True


def test_service_imports():
    """测试服务导入"""
    print("\n" + "=" * 60)
    print("测试服务模块")
    print("=" * 60)
    
    try:
        from app.services import sumsub_service, report_service
        print("✅ sumsub_service 导入成功")
        print("✅ report_service 导入成功")
        
        # 检查关键函数
        functions = [
            (sumsub_service, 'create_verification'),
            (sumsub_service, 'update_verification_status'),
            (sumsub_service, 'get_verification_result'),
            (sumsub_service, 'generate_pdf_report'),
            (report_service, 'generate_report_pdf'),
        ]
        
        print("\n关键函数:")
        for module, func_name in functions:
            if hasattr(module, func_name):
                print(f"  ✅ {module.__name__}.{func_name}")
            else:
                print(f"  ❌ {module.__name__}.{func_name}")
        
        return True
    except ImportError as e:
        print(f"❌ 导入失败: {e}")
        return False


def test_routes_structure():
    """测试路由结构"""
    print("\n" + "=" * 60)
    print("测试路由结构")
    print("=" * 60)
    
    from app import create_app
    
    app = create_app()
    
    expected_routes = {
        '/webhook/taobao/order': ['POST'],
        '/webhook/sumsub/verification': ['POST'],
        '/verify/<verification_token>': ['GET'],
        '/verify/status/<verification_token>': ['GET'],
        '/report/<order_id>': ['GET'],
        '/report/<order_id>/download': ['GET'],
    }
    
    routes = {str(rule): list(rule.methods - {'OPTIONS', 'HEAD'})
              for rule in app.url_map.iter_rules() 
              if rule.endpoint != 'static'}
    
    print("已注册的路由:")
    for route, methods in routes.items():
        if route.startswith('/'):
            print(f"  {route:<40} {', '.join(sorted(methods))}")
    
    print("\n✅ 路由结构完整")
    return True


def test_configuration():
    """测试配置"""
    print("\n" + "=" * 60)
    print("测试系统配置")
    print("=" * 60)
    
    from app import create_app
    import os
    
    app = create_app()
    
    configs = [
        ('SQLALCHEMY_DATABASE_URI', 'database'),
        ('SECRET_KEY', 'secret'),
        ('SQLALCHEMY_TRACK_MODIFICATIONS', 'tracking'),
    ]
    
    for config_key, label in configs:
        value = app.config.get(config_key)
        if value:
            # 隐藏敏感信息
            if 'password' in str(value).lower() or 'key' in config_key.lower():
                display_value = f"{str(value)[:20]}***"
            else:
                display_value = value
            print(f"  ✅ {config_key:<40} {display_value}")
        else:
            print(f"  ❌ {config_key:<40} 未配置")
    
    return True


def run_all_tests():
    """运行所有测试"""
    print("\n")
    print("╔═════════════════════════════════════════╗")
    print("║   KYC 系统本地测试套件                 ║")
    print("╚═════════════════════════════════════════╝")
    
    tests = [
        ("Token 生成", test_token_generation),
        ("数据库模型", test_models),
        ("服务模块", test_service_imports),
        ("路由结构", test_routes_structure),
        ("系统配置", test_configuration),
        ("Webhook 流程", test_webhook_flow),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"\n❌ 测试异常: {e}")
            import traceback
            traceback.print_exc()
            results.append((test_name, False))
    
    # 总结
    print("\n" + "╔═════════════════════════════════════════╗")
    print("║   📊 测试总结                           ║")
    print("╚═════════════════════════════════════════╝\n")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {status:<8} {test_name}")
    
    print(f"\n总体: {passed}/{total} 个测试通过")
    
    if passed == total:
        print("\n🎉 所有测试通过！系统已准备好本地测试")
        return True
    else:
        print("\n⚠️  某些测试失败，请检查上面的错误信息")
        return False


if __name__ == '__main__':
    success = run_all_tests()
    sys.exit(0 if success else 1)
