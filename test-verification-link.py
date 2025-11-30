#!/usr/bin/env python3
"""
KYC 验证链接生成测试
演示从订单到验证链接的完整流程
"""

import os
import sys
import json
import hmac
import hashlib
import time
from datetime import datetime

print("\n" + "="*80)
print("   🔗 KYC 验证链接生成和测试")
print("="*80 + "\n")

# 加载环境变量
os.environ['SUMSUB_APP_TOKEN'] = 'prd:1b15gKkFtPh440hQSOXIvjR3.OSJVLkmtJfnWVPS7IpuKCI2Tas4giOCO'
os.environ['SUMSUB_SECRET_KEY'] = 'CTHMPDlqphQmvB2fqBC7b6wF5v9iyqoK'
os.environ['SUMSUB_API_URL'] = 'https://api.sumsub.com'
os.environ['APP_DOMAIN'] = 'http://localhost:5000'

# ============================================================================
# 第 1 步: 模拟订单数据
# ============================================================================
print("📋 第 1 步: 模拟订单")
print("-" * 80)

mock_order = {
    "order_id": "taobao_20251125_001",
    "buyer_id": "buyer_12345",
    "buyer_name": "张三",
    "buyer_email": "zhangsan@example.com",
    "buyer_phone": "+86 13800138000",
    "platform": "taobao",
    "order_amount": 299.99,
    "timestamp": int(time.time())
}

print(f"✓ 订单号: {mock_order['order_id']}")
print(f"✓ 买家: {mock_order['buyer_name']} ({mock_order['buyer_email']})")
print(f"✓ 电话: {mock_order['buyer_phone']}")
print(f"✓ 金额: ¥{mock_order['order_amount']}")
print(f"✓ 平台: {mock_order['platform']}")

# ============================================================================
# 第 2 步: 生成验证令牌 (本地)
# ============================================================================
print("\n📋 第 2 步: 生成验证令牌")
print("-" * 80)

import secrets
verification_token = secrets.token_hex(16)  # 32个字符的令牌

print(f"✓ 验证令牌: {verification_token}")
print(f"✓ 令牌长度: {len(verification_token)} 字符")
print(f"✓ 生成时间: {datetime.now().isoformat()}")

# ============================================================================
# 第 3 步: 生成买家验证页面链接
# ============================================================================
print("\n📋 第 3 步: 买家验证页面链接")
print("-" * 80)

app_domain = os.getenv('APP_DOMAIN', 'http://localhost:5000')
verification_page_url = f"{app_domain}/verify/{verification_token}"

print(f"✓ 验证页面 URL:")
print(f"  {verification_page_url}")
print(f"\n✓ 这是买家需要访问的链接")
print(f"✓ 在这个页面上，买家会看到:")
print(f"  - 订单信息")
print(f"  - Sumsub KYC 验证按钮")
print(f"  - 验证状态")

# ============================================================================
# 第 4 步: 生成 Sumsub Web SDK 链接 (用于演示)
# ============================================================================
print("\n📋 第 4 步: Sumsub Web SDK 链接 (后端生成)")
print("-" * 80)

# 模拟 Sumsub Access Token 生成
# 在真实场景中，这会通过 Sumsub API 生成
mock_access_token = secrets.token_hex(32)  # 模拟访问令牌

sumsub_api_url = os.getenv('SUMSUB_API_URL', 'https://api.sumsub.com')
sumsub_sdk_url = f"{sumsub_api_url}/sdk/applicant?token={mock_access_token}"

print(f"✓ Sumsub Web SDK URL:")
print(f"  {sumsub_sdk_url}")
print(f"\n✓ 说明:")
print(f"  - 这个 URL 是在后端生成的")
print(f"  - Access Token 由 Sumsub API 返回")
print(f"  - Token 有有效期 (默认 30 分钟)")
print(f"  - 买家通过验证页面点击按钮访问此 URL")

# ============================================================================
# 第 5 步: 生成 Webhook 签名 (用于测试)
# ============================================================================
print("\n📋 第 5 步: 生成 Webhook 签名 (用于测试)")
print("-" * 80)

webhook_secret = os.getenv('WEBHOOK_SECRET', 'test-secret')
payload = json.dumps(mock_order)
timestamp_str = str(int(time.time()))

signature = hmac.new(
    webhook_secret.encode(),
    f"{payload}{timestamp_str}".encode(),
    hashlib.sha256
).hexdigest()

print(f"✓ Webhook 签名: {signature}")
print(f"✓ 时间戳: {timestamp_str}")

# ============================================================================
# 第 6 步: 验证流程演示
# ============================================================================
print("\n📋 第 6 步: 验证流程演示")
print("-" * 80)

print("""
流程:

1️⃣  用户在淘宝下单
    └─> 触发订单 Webhook

2️⃣  系统接收 Webhook
    ├─ 验证签名
    └─ 创建订单记录

3️⃣  系统调用 Sumsub API
    ├─ 创建 Applicant
    ├─ 生成 Access Token
    └─ 创建验证链接

4️⃣  系统生成买家链接
    └─ http://localhost:5000/verify/{verification_token}

5️⃣  发送链接给买家
    └─ 通过邮件/短信/店铺公告

6️⃣  买家访问验证页面
    ├─ 看到订单信息
    └─ 点击验证按钮

7️⃣  打开 Sumsub Web SDK
    ├─ 完成 KYC 验证
    └─ 提交身份信息

8️⃣  Sumsub 发送回调 Webhook
    └─ 系统更新验证状态

9️⃣  系统生成 PDF 报告
    └─ 验证完成

10️⃣ 显示验证结果
    └─ 买家可下载报告
""")

# ============================================================================
# 第 7 步: 测试 curl 命令
# ============================================================================
print("\n📋 第 7 步: 完整测试命令")
print("-" * 80)

print("\n1️⃣  启动应用 (需要 PostgreSQL):")
print("   ./local-dev.sh")
print("   或")
print("   python3 run.py")

print("\n2️⃣  测试 Webhook 端点:")
print(f"""   curl -X POST http://localhost:5000/webhook/taobao/order \\
     -H "Content-Type: application/json" \\
     -H "X-Webhook-Signature: {signature}" \\
     -H "X-Webhook-Timestamp: {timestamp_str}" \\
     -d '{json.dumps(mock_order, ensure_ascii=False)}'""")

print("\n3️⃣  响应示例:")
print("""   {
     "status": "success",
     "order_id": "uuid-here",
     "verification_token": "...",
     "verification_link": "http://localhost:5000/verify/..."
   }""")

print("\n4️⃣  访问验证页面:")
print(f"   {verification_page_url}")

print("\n5️⃣  查看验证状态:")
print(f"   curl http://localhost:5000/verify/status/{verification_token}")

# ============================================================================
# 第 8 步: 关键 URL 总结
# ============================================================================
print("\n" + "="*80)
print("   🔗 关键 URL 总结")
print("="*80)

print(f"""
📌 买家需要访问的链接 (验证页面):
   {verification_page_url}

📌 Sumsub Web SDK 链接 (后端使用):
   {sumsub_sdk_url}

📌 Webhook 端点 (淘宝/系统回调):
   POST http://localhost:5000/webhook/taobao/order
   POST http://localhost:5000/webhook/sumsub/verification

📌 API 端点:
   GET /verify/<token>              - 显示验证页面
   GET /verify/status/<token>       - 获取验证状态
   GET /report/<order_id>           - 显示报告
   GET /report/<order_id>/download  - 下载 PDF
""")

# ============================================================================
# 第 9 步: 实现细节
# ============================================================================
print("\n" + "="*80)
print("   📋 实现细节")
print("="*80)

print("""
验证链接组成部分:

1. 应用域名
   BASE_URL = http://localhost:5000

2. 验证路由
   ROUTE = /verify

3. 验证令牌 (唯一标识)
   TOKEN = 生成的 32 字符令牌

4. 完整 URL
   FULL_URL = BASE_URL + ROUTE + TOKEN
            = http://localhost:5000/verify/abc123...

数据流:
   订单 → Webhook → 数据库 → 验证记录 → 验证令牌 → 买家链接 → Sumsub 验证

安全机制:
   ✅ 验证令牌唯一性
   ✅ Webhook 签名验证 (HMAC-SHA256)
   ✅ Token 有效期限制
   ✅ 一次性使用 (完成后过期)
""")

# ============================================================================
# 第 10 步: 本地测试指南
# ============================================================================
print("\n" + "="*80)
print("   ✅ 下一步: 本地测试")
print("="*80)

print("""
方式 1: 完整测试 (需要 PostgreSQL)
   1. 安装 PostgreSQL:
      brew install postgresql@15
      brew services start postgresql@15
   
   2. 启动应用:
      ./local-dev.sh
   
   3. 发送 Webhook:
      curl -X POST http://localhost:5000/webhook/taobao/order \\
        -H "Content-Type: application/json" \\
        -d '{"order_id":"test","buyer_name":"Test","buyer_email":"test@example.com","buyer_phone":"13800138000","order_amount":99.99}'
   
   4. 访问链接:
      http://localhost:5000/verify/<verification_token>

方式 2: Docker 测试 (需要 Docker)
   1. 安装 Docker:
      brew install docker docker-compose
   
   2. 启动服务:
      ./quick-start.sh
   
   3. 发送 Webhook:
      curl -X POST http://localhost/webhook/taobao/order \\
        -H "Content-Type: application/json" \\
        -d '{"order_id":"test","buyer_name":"Test","buyer_email":"test@example.com","buyer_phone":"13800138000","order_amount":99.99}'
   
   4. 访问链接:
      http://localhost/verify/<verification_token>

方式 3: 查看代码
   验证链接生成逻辑:
   - app/services/sumsub_service.py (第 82 行)
   
   验证页面路由:
   - app/routes/verification.py
   
   验证页面 HTML:
   - app/templates/verification.html
""")

print("\n" + "="*80)
print("   ✨ 系统已就绪！")
print("="*80 + "\n")
