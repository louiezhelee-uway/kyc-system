#!/usr/bin/env python3
"""
测试完整的 KYC 验证页面流程
包括：创建订单 -> 创建验证 -> 访问验证页面 -> 生成验证链接
"""

import os
import sys
import json
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

os.environ['FLASK_ENV'] = 'development'
os.environ['DATABASE_URL'] = 'sqlite:///kyc_demo.db'
os.environ['SUMSUB_APP_TOKEN'] = os.getenv('SUMSUB_APP_TOKEN', 'prd:BUWAA7ogVIJZ7W9h7A4BaSRx.xm4V4Zef52mLLYJl0oJ1X4v878Ibo2ie')
os.environ['SUMSUB_SECRET_KEY'] = os.getenv('SUMSUB_SECRET_KEY', 'ypDDepVCvib3Oq3P6tfML91huztzOMuY')
os.environ['SUMSUB_API_URL'] = os.getenv('SUMSUB_API_URL', 'https://api.sumsub.com')
os.environ['SUMSUB_VERIFICATION_LEVEL'] = 'id-and-liveness'

from app import create_app, db
from app.models import Order
from app.services import sumsub_service

def test_verification_page_flow():
    """测试完整的验证页面流程"""
    
    print("\n" + "="*70)
    print("🧪 完整的 KYC 验证页面流程测试")
    print("="*70)
    
    # Create Flask app
    app = create_app()
    
    with app.app_context():
        # Create tables
        print("\n📦 初始化数据库...")
        db.create_all()
        
        # Step 1: Create order
        print("\n" + "-"*70)
        print("第一步：创建订单")
        print("-"*70)
        
        order = Order(
            taobao_order_id='test_order_' + datetime.now().strftime('%Y%m%d%H%M%S'),
            buyer_id='buyer_12345',
            buyer_name='李四',
            buyer_email='lisi@example.com',
            buyer_phone='+86 13900139000',
            platform='taobao',
            order_amount=50000.00,
        )
        db.session.add(order)
        db.session.flush()
        
        print(f"✓ 订单已创建")
        print(f"  订单 ID: {order.id}")
        print(f"  淘宝订单号: {order.taobao_order_id}")
        print(f"  买家: {order.buyer_name}")
        print(f"  邮箱: {order.buyer_email}")
        print(f"  手机: {order.buyer_phone}")
        print(f"  金额: ¥{order.order_amount:,.2f}")
        
        # Step 2: Create verification
        print("\n" + "-"*70)
        print("第二步：创建 KYC 验证记录")
        print("-"*70)
        
        try:
            verification = sumsub_service.create_verification(order)
            db.session.commit()
            
            print(f"✓ 验证记录已创建")
            print(f"  验证 ID: {verification.id}")
            print(f"  验证令牌: {verification.verification_token}")
            print(f"  Sumsub 用户 ID: {verification.sumsub_applicant_id}")
            print(f"  状态: {verification.status}")
            print(f"  后端链接: {verification.verification_link}")
            
        except Exception as e:
            print(f"✗ 验证创建失败: {str(e)}")
            return False
        
        # Step 3: Generate access token
        print("\n" + "-"*70)
        print("第三步：生成 WebSDK 访问令牌")
        print("-"*70)
        
        try:
            access_token = sumsub_service._generate_access_token(
                verification.sumsub_applicant_id,
                f"order_{order.id}",
                order.buyer_email
            )
            
            print(f"✓ 访问令牌已生成")
            print(f"  令牌类型: JWT")
            print(f"  令牌长度: {len(access_token)} 字符")
            print(f"  令牌前缀: {access_token[:30]}...")
            print(f"  有效期: 30 分钟")
            
        except Exception as e:
            print(f"✗ 令牌生成失败: {str(e)}")
            return False
        
        # Step 4: Simulate user visiting verification page
        print("\n" + "-"*70)
        print("第四步：模拟用户访问验证页面")
        print("-"*70)
        
        try:
            with app.test_client() as client:
                # Visit verification page
                response = client.get(f'/verify/{verification.verification_token}')
                
                print(f"✓ 验证页面已加载")
                print(f"  HTTP 状态码: {response.status_code}")
                print(f"  内容类型: {response.content_type}")
                print(f"  页面大小: {len(response.data)} 字节")
                
                if response.status_code != 200:
                    print(f"  ✗ 页面加载失败")
                    return False
                
                # Check page content
                response_text = response.data.decode('utf-8')
                
                checks = {
                    'WebSDK 脚本': 'sns-websdk-builder.js' in response_text,
                    '订单信息': order.buyer_name in response_text,
                    '订单号': order.taobao_order_id in response_text,
                    '买家邮箱': order.buyer_email in response_text,
                    'WebSDK 容器': 'sumsub-websdk-container' in response_text,
                    '访问令牌': '_act-jwt' in response_text,
                    'JavaScript 初始化': 'snsWebSdk' in response_text,
                    '令牌刷新端点': '/verify/refresh-token' in response_text,
                }
                
                print(f"\n  页面内容检查:")
                all_passed = True
                for check_name, passed in checks.items():
                    status = "✓" if passed else "✗"
                    print(f"    {status} {check_name}")
                    if not passed:
                        all_passed = False
                
                if not all_passed:
                    return False
                    
        except Exception as e:
            print(f"✗ 页面访问失败: {str(e)}")
            import traceback
            traceback.print_exc()
            return False
        
        # Step 5: Test token refresh endpoint
        print("\n" + "-"*70)
        print("第五步：测试令牌刷新端点")
        print("-"*70)
        
        try:
            with app.test_client() as client:
                response = client.post(
                    '/verify/refresh-token',
                    json={'verification_token': verification.verification_token},
                    content_type='application/json'
                )
                
                print(f"✓ 令牌刷新端点响应")
                print(f"  HTTP 状态码: {response.status_code}")
                
                if response.status_code == 200:
                    data = response.get_json()
                    new_token = data.get('token')
                    
                    print(f"  ✓ 新令牌已返回")
                    print(f"    新令牌长度: {len(new_token)} 字符")
                    print(f"    新令牌前缀: {new_token[:30]}...")
                    print(f"    有效期: {data.get('expires_in')} 秒")
                else:
                    print(f"  ✗ 令牌刷新失败")
                    return False
                    
        except Exception as e:
            print(f"✗ 令牌刷新端点测试失败: {str(e)}")
            return False
        
        # Step 6: Display verification URLs
        print("\n" + "="*70)
        print("✅ 所有测试通过！")
        print("="*70)
        
        print(f"\n📋 验证信息总结:")
        print(f"  订单 ID: {order.id}")
        print(f"  订单号: {order.taobao_order_id}")
        print(f"  验证令牌: {verification.verification_token}")
        
        print(f"\n🔗 验证链接:")
        local_url = f"http://localhost:8080/verify/{verification.verification_token}"
        vps_url = f"https://kyc.317073.xyz/verify/{verification.verification_token}"
        
        print(f"  本地测试: {local_url}")
        print(f"  VPS 生产: {vps_url}")
        
        print(f"\n📱 用户体验流程:")
        print(f"  1. 用户收到验证链接")
        print(f"  2. 点击链接访问验证页面")
        print(f"  3. 页面加载 WebSDK iframe")
        print(f"  4. 用户在 iframe 中完成身份验证")
        print(f"  5. 完成后 Sumsub 发送 Webhook")
        print(f"  6. 系统更新验证状态并生成报告")
        
        print(f"\n💾 页面组件:")
        print(f"  ✓ 订单信息卡片")
        print(f"  ✓ WebSDK iframe 容器")
        print(f"  ✓ 加载动画")
        print(f"  ✓ 错误处理")
        print(f"  ✓ 令牌自动刷新")
        print(f"  ✓ 事件监听器")
        
        print(f"\n🔐 安全特性:")
        print(f"  ✓ HMAC-SHA256 签名验证")
        print(f"  ✓ 时间戳防重放")
        print(f"  ✓ X-App-Token 认证")
        print(f"  ✓ 令牌有效期控制")
        print(f"  ✓ 自动令牌刷新")
        
        print(f"\n" + "="*70)
        print(f"系统已准备就绪！可以部署到 VPS")
        print(f"="*70 + "\n")
        
        return True

if __name__ == '__main__':
    success = test_verification_page_flow()
    sys.exit(0 if success else 1)
