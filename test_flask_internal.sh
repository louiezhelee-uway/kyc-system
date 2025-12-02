#!/bin/bash

###############################################################################
# 在 VPS 容器内测试 Flask 应用
###############################################################################

echo "运行 Flask 应用内部测试..."
echo ""

docker exec kyc_web python3 << 'EOF'
import sys
import os

# 设置日志
print("\n" + "="*70)
print("Flask 应用内部测试")
print("="*70 + "\n")

try:
    print("1️⃣  导入 Flask 应用...")
    from app import create_app, db
    app = create_app()
    print("✅ Flask 应用创建成功\n")
    
    print("2️⃣  列出已注册的路由...")
    routes = []
    for rule in sorted(app.url_map.iter_rules(), key=lambda r: str(r)):
        routes.append(str(rule.rule))
        print(f"  ✓ {rule.rule:50} -> {rule.endpoint:30} {list(rule.methods)}")
    
    if '/health' not in routes:
        print("\n❌ 警告: /health 路由未找到!")
    else:
        print("\n✅ /health 路由已注册")
    
    if '/webhook/taobao/order' not in routes:
        print("❌ 警告: /webhook/taobao/order 路由未找到!")
    else:
        print("✅ /webhook/taobao/order 路由已注册")
    
    print("\n3️⃣  测试 /health 端点...")
    with app.test_client() as client:
        try:
            response = client.get('/health')
            print(f"  状态码: {response.status_code}")
            if response.status_code == 200:
                print(f"  ✅ 成功: {response.get_json()}")
            else:
                print(f"  ⚠️  状态: {response.data.decode()}")
        except Exception as e:
            print(f"  ❌ 错误: {e}")
            import traceback
            traceback.print_exc()
    
    print("\n4️⃣  测试 /webhook/taobao/order 端点...")
    with app.test_client() as client:
        try:
            response = client.post('/webhook/taobao/order',
                json={
                    'order_id': 'test_123',
                    'buyer_name': '张三',
                    'buyer_email': 'test@test.com',
                    'buyer_phone': '13800138000',
                    'order_amount': 1000
                },
                content_type='application/json'
            )
            print(f"  状态码: {response.status_code}")
            print(f"  响应: {response.get_json()}")
            if response.status_code in [200, 201]:
                print("  ✅ 成功!")
            else:
                print(f"  ⚠️  可能有错误")
        except Exception as e:
            print(f"  ❌ 错误: {e}")
            import traceback
            traceback.print_exc()
    
    print("\n5️⃣  检查数据库连接...")
    with app.app_context():
        try:
            from sqlalchemy import text
            result = db.session.execute(text("SELECT 1"))
            print("  ✅ 数据库连接成功")
            
            # 检查表
            from app.models import Order, Verification
            order_count = Order.query.count()
            verification_count = Verification.query.count()
            print(f"  📊 订单表: {order_count} 条记录")
            print(f"  📊 验证表: {verification_count} 条记录")
        except Exception as e:
            print(f"  ❌ 数据库错误: {e}")
            import traceback
            traceback.print_exc()
    
    print("\n" + "="*70)
    print("测试完成")
    print("="*70 + "\n")

except Exception as e:
    print(f"\n❌ 致命错误: {e}\n")
    import traceback
    traceback.print_exc()
    sys.exit(1)

EOF
