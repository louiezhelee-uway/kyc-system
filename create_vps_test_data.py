#!/usr/bin/env python3
"""
在 VPS 上创建测试订单和验证链接
"""

import os
import sys
import json
from datetime import datetime

# 添加项目路径
sys.path.insert(0, '/app')

os.environ['FLASK_ENV'] = 'production'

from app import create_app, db
from app.models import Order
from app.services import sumsub_service

def create_test_order_on_vps():
    """在 VPS 上创建测试订单"""
    
    print("\n" + "="*70)
    print("在 VPS 上创建测试订单")
    print("="*70)
    
    app = create_app()
    
    with app.app_context():
        try:
            # Create order
            print("\n📋 创建订单...")
            order = Order(
                taobao_order_id='vps_test_' + datetime.now().strftime('%Y%m%d%H%M%S'),
                buyer_id='vps_buyer_001',
                buyer_name='王五',
                buyer_email='wangwu@example.com',
                buyer_phone='+86 13700137000',
                platform='taobao',
                order_amount=99999.99,
            )
            db.session.add(order)
            db.session.flush()
            
            print(f"✓ 订单已创建")
            print(f"  订单 ID: {order.id}")
            print(f"  淘宝订单号: {order.taobao_order_id}")
            print(f"  买家: {order.buyer_name}")
            
            # Create verification
            print("\n🔐 创建验证记录...")
            verification = sumsub_service.create_verification(order)
            db.session.commit()
            
            print(f"✓ 验证记录已创建")
            print(f"  验证令牌: {verification.verification_token}")
            
            # Generate access token
            print("\n🎟️  生成访问令牌...")
            access_token = sumsub_service._generate_access_token(
                verification.sumsub_applicant_id,
                f"order_{order.id}",
                order.buyer_email
            )
            
            print(f"✓ 访问令牌已生成")
            print(f"  令牌: {access_token[:50]}...")
            
            # Display links
            print("\n" + "="*70)
            print("✅ 测试数据已创建在 VPS")
            print("="*70)
            
            verification_link = f"https://kyc.317073.xyz/verify/{verification.verification_token}"
            
            print(f"\n📋 订单信息:")
            print(f"  订单号: {order.taobao_order_id}")
            print(f"  买家: {order.buyer_name}")
            print(f"  邮箱: {order.buyer_email}")
            print(f"  金额: ¥{order.order_amount:,.2f}")
            
            print(f"\n🔗 验证链接:")
            print(f"  {verification_link}")
            
            print(f"\n💾 数据库信息:")
            print(f"  订单 ID: {order.id}")
            print(f"  验证 ID: {verification.id}")
            print(f"  Verification Token: {verification.verification_token}")
            
            print(f"\n现在可以访问上面的链接测试 WebSDK 了！")
            print("="*70 + "\n")
            
            return verification_link
            
        except Exception as e:
            print(f"\n❌ 错误: {str(e)}")
            import traceback
            traceback.print_exc()
            return None

if __name__ == '__main__':
    link = create_test_order_on_vps()
    if link:
        sys.exit(0)
    else:
        sys.exit(1)
