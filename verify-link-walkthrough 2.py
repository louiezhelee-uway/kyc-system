#!/usr/bin/env python3
"""
KYC 验证链接生成完整演示
==========================

这个脚本展示了从订单接收到买家验证链接的完整流程。
不需要数据库或服务器，可以独立运行查看整个流程的演示。
"""

import hmac
import hashlib
import json
import secrets
from datetime import datetime
from typing import Dict, Any

# ═══════════════════════════════════════════════════════════════════════════════
# 配置
# ═══════════════════════════════════════════════════════════════════════════════

WEBHOOK_SECRET = "your-webhook-secret-key"  # 生产环境应该使用环境变量
BASE_URL = "http://localhost:5000"
SUMSUB_API_URL = "https://api.sumsub.com"


# ═══════════════════════════════════════════════════════════════════════════════
# 核心函数
# ═══════════════════════════════════════════════════════════════════════════════

def print_section(title: str, level: int = 1) -> None:
    """打印章节标题"""
    if level == 1:
        print("\n" + "═" * 80)
        print(f"  {title}")
        print("═" * 80 + "\n")
    elif level == 2:
        print("\n" + "─" * 80)
        print(f"  {title}")
        print("─" * 80 + "\n")
    else:
        print(f"\n  {title}\n")


def print_info(label: str, value: Any, indent: int = 0) -> None:
    """打印信息行"""
    prefix = "  " * indent
    if isinstance(value, dict):
        print(f"{prefix}📦 {label}:")
        for k, v in value.items():
            print(f"{prefix}    {k}: {v}")
    elif isinstance(value, (list, tuple)):
        print(f"{prefix}📋 {label}:")
        for i, item in enumerate(value, 1):
            print(f"{prefix}    {i}. {item}")
    else:
        print(f"{prefix}✓ {label}: {value}")


def print_code(code: str, indent: int = 0) -> None:
    """打印代码块"""
    prefix = "  " * indent
    for line in code.split("\n"):
        print(f"{prefix}    {line}")


def generate_verification_token() -> str:
    """
    生成验证令牌（32字符唯一令牌）
    
    源代码位置: app/utils/token_generator.py
    """
    return secrets.token_hex(16)  # 32 个字符


def calculate_webhook_signature(data: str, secret: str) -> str:
    """
    计算 Webhook HMAC 签名
    
    源代码位置: app/routes/webhook.py > verify_webhook_signature()
    """
    return hmac.new(
        secret.encode(),
        data.encode(),
        hashlib.sha256
    ).hexdigest()


def simulate_sumsub_api_call(order_id: str) -> Dict[str, str]:
    """
    模拟 Sumsub API 调用
    
    源代码位置: app/services/sumsub_service.py > create_verification()
    """
    return {
        "applicantId": f"sumsub_applicant_{secrets.token_hex(8)}",
        "accessToken": secrets.token_hex(32)  # 64 字符 token
    }


def generate_buyer_verification_link(verification_token: str) -> str:
    """
    生成买家验证链接
    
    这是发送给买家的链接
    源代码位置: app/routes/webhook.py
    """
    return f"{BASE_URL}/verify/{verification_token}"


def generate_sumsub_sdk_link(access_token: str) -> str:
    """
    生成 Sumsub Web SDK 链接
    
    这是在验证页面上显示的链接，买家点击它打开 Sumsub 的身份验证表单
    源代码位置: app/services/sumsub_service.py (第 82 行)
    """
    return f"{SUMSUB_API_URL}/sdk/applicant?token={access_token}"


# ═══════════════════════════════════════════════════════════════════════════════
# 完整流程演示
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    """主流程演示"""
    
    print("\n" + "█" * 80)
    print("█" + " " * 78 + "█")
    print("█" + "  🔗 KYC 验证链接生成完整演示".center(78) + "█")
    print("█" + " " * 78 + "█")
    print("█" * 80)
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 1: 淘宝/闲鱼订单
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 1️⃣ : 淘宝/闲鱼订单创建", 1)
    print("""
当买家在淘宝或闲鱼平台完成支付后，会生成一个订单。
系统通过 Webhook 接收到订单通知。
    """)
    
    order_data = {
        "order_id": f"taobao_{datetime.now().strftime('%Y%m%d%H%M%S')}",
        "buyer_name": "张三",
        "buyer_email": "zhangsan@example.com",
        "buyer_phone": "13800138000",
        "order_amount": 299.99,
        "timestamp": int(datetime.now().timestamp())
    }
    
    print_info("订单数据", order_data)
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 2: 验证 Webhook 签名
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 2️⃣ : 验证 Webhook 签名 (HMAC-SHA256)", 2)
    print("""
当系统接收到 Webhook 请求时，需要验证请求的真实性。
使用 HMAC-SHA256 算法和共享密钥来验证。

源代码位置: app/routes/webhook.py > verify_webhook_signature()
    """)
    
    # 序列化订单数据为 JSON 字符串
    order_json = json.dumps(order_data, separators=(",", ":"), sort_keys=True)
    print_info("订单 JSON 字符串", order_json)
    print()
    
    # 计算签名
    webhook_signature = calculate_webhook_signature(order_json, WEBHOOK_SECRET)
    print_info("Webhook 秘钥", WEBHOOK_SECRET)
    print_info("计算的 HMAC 签名", webhook_signature)
    print()
    
    print("验证过程代码示例:")
    print_code("""
import hmac
import hashlib

def verify_webhook_signature(data, signature, secret):
    calculated_signature = hmac.new(
        secret.encode(),
        data.encode(),
        hashlib.sha256
    ).hexdigest()
    return signature == calculated_signature

# 验证
is_valid = verify_webhook_signature(order_json, webhook_signature, WEBHOOK_SECRET)
print(f"签名有效: {is_valid}")
    """, indent=1)
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 3: 数据库存储
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 3️⃣ : 创建 Order 数据库记录", 2)
    print("""
验证签名通过后，系统创建订单记录在数据库中。

表: orders
源代码位置: app/models/order.py
    """)
    
    order_record = {
        "id": order_data["order_id"],
        "buyer_name": order_data["buyer_name"],
        "buyer_email": order_data["buyer_email"],
        "buyer_phone": order_data["buyer_phone"],
        "order_amount": order_data["order_amount"],
        "status": "pending",
        "created_at": datetime.now().isoformat()
    }
    
    print_info("Order 记录", order_record)
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 4: 生成验证令牌
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 4️⃣ : 生成验证令牌 ⭐ 关键步骤", 2)
    print("""
系统生成一个唯一的 32 字符验证令牌。
这个令牌用于标识这个验证会话。

源代码位置: app/utils/token_generator.py
    """)
    
    verification_token = generate_verification_token()
    print_info("生成的验证令牌", verification_token)
    print_info("令牌长度", len(verification_token))
    print()
    
    print("生成代码示例:")
    print_code("""
import secrets

def generate_verification_token():
    return secrets.token_hex(16)  # 32 字符令牌

verification_token = generate_verification_token()
# 输出: a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
    """, indent=1)
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 5: 调用 Sumsub API
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 5️⃣ : 调用 Sumsub API 创建 Applicant", 2)
    print("""
系统调用 Sumsub API 为这个买家创建一个 Applicant（申请人）记录。
这是 KYC 验证的核心。

API 调用:
  POST https://api.sumsub.com/resources/applicants
  
返回:
  - applicantId: 唯一的申请人 ID
  - accessToken: 用于生成 Web SDK 链接的令牌

源代码位置: app/services/sumsub_service.py > create_verification()
    """)
    
    sumsub_response = simulate_sumsub_api_call(order_data["order_id"])
    print_info("Sumsub API 响应", sumsub_response)
    
    sumsub_applicant_id = sumsub_response["applicantId"]
    sumsub_access_token = sumsub_response["accessToken"]
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 6: 生成 Sumsub Web SDK 链接
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 6️⃣ : 生成 Sumsub Web SDK 链接", 2)
    print("""
使用 Sumsub 返回的 accessToken，生成 Web SDK 链接。
这是实际的身份验证页面链接，会在买家访问时显示。

源代码位置: app/services/sumsub_service.py (第 82 行)
    """)
    
    sumsub_sdk_link = generate_sumsub_sdk_link(sumsub_access_token)
    print_info("Sumsub Web SDK 链接", sumsub_sdk_link)
    print()
    
    print("生成代码示例:")
    print_code("""
def generate_sumsub_sdk_link(access_token):
    SUMSUB_API_URL = "https://api.sumsub.com"
    return f"{SUMSUB_API_URL}/sdk/applicant?token={access_token}"

sumsub_sdk_link = generate_sumsub_sdk_link(access_token)
# 输出: https://api.sumsub.com/sdk/applicant?token=...
    """, indent=1)
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 7: 创建验证记录
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 7️⃣ : 创建 Verification 数据库记录", 2)
    print("""
系统在数据库中创建验证记录，关联订单和 Sumsub 信息。

表: verifications
源代码位置: app/models/verification.py
    """)
    
    verification_record = {
        "id": 1,
        "order_id": order_data["order_id"],
        "sumsub_applicant_id": sumsub_applicant_id,
        "verification_token": verification_token,
        "verification_link": f"{SUMSUB_API_URL}/sdk/applicant?token={sumsub_access_token}",
        "status": "pending",
        "created_at": datetime.now().isoformat(),
        "completed_at": None
    }
    
    print_info("Verification 记录", verification_record)
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 8: 生成买家验证链接 ⭐ 最终链接
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 8️⃣ : 生成买家验证链接 ⭐ 最终链接", 2)
    print("""
这是发送给买家的链接。
买家访问这个链接后，会看到一个中间页面，显示订单信息和验证按钮。

源代码位置: app/routes/webhook.py
    """)
    
    buyer_verification_link = generate_buyer_verification_link(verification_token)
    print_info("买家验证链接", buyer_verification_link)
    print()
    print("这个链接的结构:")
    print_code("""
BASE_URL = http://localhost:5000
ROUTE = /verify
TOKEN = verification_token (唯一标识)

完整链接:
http://localhost:5000/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
    """, indent=1)
    
    print("\n✅ 这是发送给买家的链接！")
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 9: 买家访问验证页面
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 9️⃣ : 买家访问验证页面", 2)
    print("""
买家收到链接后（通过邮件、短信等），点击链接。
系统渲染验证页面。

路由: app/routes/verification.py > verification_page()
模板: app/templates/verification.html
    """)
    
    print("验证页面流程:")
    print_code("""
1. 买家访问: GET http://localhost:5000/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a

2. 系统查询验证记录:
   SELECT * FROM verifications 
   WHERE verification_token = 'a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a'

3. 获取关联的订单信息

4. 渲染 HTML 模板，传入数据:
   - order: {order_id, buyer_name, buyer_email, ...}
   - verification: {status, verification_link, ...}

5. 返回 HTML 页面给买家
    """, indent=1)
    
    print("\n验证页面显示:")
    print_code("""
┌─────────────────────────────────────────┐
│  身份验证                              │
├─────────────────────────────────────────┤
│                                         │
│  订单号: taobao_20251125_123456         │
│  买家: 张三                             │
│  邮箱: zhangsan@example.com             │
│                                         │
│  为了完成您的订单，请进行身份验证      │
│  验证过程需要 5-10 分钟                 │
│  需要上传身份证件并进行人脸识别        │
│                                         │
│  ┌───────────────────────────────┐     │
│  │     🔘 开始验证               │     │
│  └───────────────────────────────┘     │
│                                         │
│  (点击此按钮打开 Sumsub Web SDK)       │
│                                         │
└─────────────────────────────────────────┘
    """, indent=1)
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 10: 买家点击验证按钮
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 🔟 : 买家点击\"开始验证\"按钮", 2)
    print("""
买家在验证页面上点击\"开始验证\"按钮。
这个按钮链接到 Sumsub Web SDK。

HTML 代码:
    """)
    
    print_code("""
<!-- app/templates/verification.html -->
<a href="{{ verification_link }}" class="button">
  开始验证
</a>

<!-- 实际渲染为 -->
<a href="https://api.sumsub.com/sdk/applicant?token=..." class="button">
  开始验证
</a>
    """, indent=1)
    
    print("\n买家跳转到 Sumsub Web SDK 页面:")
    print_info("Sumsub Web SDK URL", sumsub_sdk_link)
    print()
    print("在 Sumsub SDK 页面，买家需要:")
    print_info("所需步骤", [
        "上传身份证件（护照、驾照等）",
        "完成人脸识别",
        "填写个人信息",
        "提交验证"
    ])
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 11: Sumsub 回调
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 1️⃣1️⃣ : Sumsub 验证完成回调", 2)
    print("""
验证完成后，Sumsub 会向系统发送回调通知。

Webhook 端点: POST /webhook/sumsub/verification
源代码位置: app/routes/webhook.py > sumsub_webhook()
    """)
    
    sumsub_callback = {
        "applicantId": sumsub_applicant_id,
        "reviewStatus": "approved",
        "timestamp": int(datetime.now().timestamp())
    }
    
    print_info("Sumsub 回调数据", sumsub_callback)
    print()
    print("系统更新验证记录:")
    print_code("""
UPDATE verifications 
SET status = 'approved', 
    completed_at = NOW()
WHERE sumsub_applicant_id = 'sumsub_applicant_...'
    """, indent=1)
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 步骤 12: 生成 PDF 报告
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("步骤 1️⃣2️⃣ : 生成 PDF 报告", 2)
    print("""
验证批准后，系统自动生成 PDF 报告。

源代码位置: app/services/report_service.py > generate_report_pdf()
    """)
    
    report_info = {
        "order_id": order_data["order_id"],
        "buyer_name": order_data["buyer_name"],
        "verification_status": "approved",
        "report_url": f"{BASE_URL}/report/{order_data['order_id']}",
        "download_url": f"{BASE_URL}/report/{order_data['order_id']}/download",
        "generated_at": datetime.now().isoformat()
    }
    
    print_info("生成的报告信息", report_info)
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 完整流程总结
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("✅ 完整流程总结", 1)
    
    print("流程图:")
    print_code("""
1️⃣  淘宝/闲鱼订单创建
    ↓
2️⃣  系统接收 Webhook 通知
    ↓
3️⃣  验证 HMAC-SHA256 签名
    ↓
4️⃣  创建 Order 数据库记录
    ↓
5️⃣  生成验证令牌 (32 字符)
    ↓
6️⃣  调用 Sumsub API 创建 Applicant
    ↓
7️⃣  生成 Sumsub Web SDK 链接
    ↓
8️⃣  创建 Verification 数据库记录
    ↓
9️⃣  生成买家验证链接
    ↓
🔟 发送链接给买家 (邮件/短信/消息)
    ↓
1️⃣1️⃣ 买家点击链接访问验证页面
    ↓
1️⃣2️⃣ 买家点击\"开始验证\"进入 Sumsub SDK
    ↓
1️⃣3️⃣ 买家完成 KYC 验证
    ↓
1️⃣4️⃣ Sumsub 回调验证结果
    ↓
1️⃣5️⃣ 系统生成 PDF 报告
    ↓
1️⃣6️⃣ 验证完成，订单可以继续处理
    """, indent=1)
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 核心 API 端点
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("🔗 核心 API 端点", 2)
    
    endpoints = [
        ("订单 Webhook", "POST", "/webhook/taobao/order"),
        ("验证页面", "GET", f"/verify/{verification_token}"),
        ("验证状态", "GET", f"/verify/status/{verification_token}"),
        ("Sumsub 回调", "POST", "/webhook/sumsub/verification"),
        ("查看报告", "GET", f"/report/{order_data['order_id']}"),
        ("下载报告", "GET", f"/report/{order_data['order_id']}/download")
    ]
    
    for name, method, path in endpoints:
        print(f"  {method:6} {BASE_URL}{path}")
        print(f"          {name}\n")
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 关键文件位置
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("📁 关键代码文件位置", 2)
    
    files = [
        ("令牌生成", "app/utils/token_generator.py", "generate_verification_token()"),
        ("验证链接生成", "app/services/sumsub_service.py", "create_verification() 第 82 行"),
        ("验证页面路由", "app/routes/verification.py", "verification_page()"),
        ("验证页面模板", "app/templates/verification.html", "HTML 模板"),
        ("数据库模型", "app/models/verification.py", "Verification 类"),
        ("Webhook 处理", "app/routes/webhook.py", "taobao_webhook_handler()"),
    ]
    
    for name, file, location in files:
        print(f"  {name:20} → {file}")
        print(f"  {' ' * 20}   位置: {location}\n")
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 测试命令
    # ═══════════════════════════════════════════════════════════════════════════
    
    print_section("🧪 本地测试命令", 1)
    
    print("1. 启动开发服务器:")
    print_code("./local-dev.sh", indent=1)
    
    print("\n2. 发送测试订单 Webhook:")
    print_code(f"""
curl -X POST {BASE_URL}/webhook/taobao/order \\
  -H 'Content-Type: application/json' \\
  -H 'X-Signature: {webhook_signature}' \\
  -d '{json.dumps(order_data)}'
    """, indent=1)
    
    print("\n3. 访问验证页面:")
    print_code(f"open '{buyer_verification_link}'", indent=1)
    
    print("\n4. 查询验证状态:")
    print_code(f"""
curl -X GET {BASE_URL}/verify/status/{verification_token}
    """, indent=1)
    
    print("\n5. 查看报告:")
    print_code(f"""
curl -X GET {BASE_URL}/report/{order_data['order_id']}
    """, indent=1)
    
    print("\n" + "═" * 80)
    print("✅ 演示完成！所有验证链接已生成".center(80))
    print("═" * 80 + "\n")


if __name__ == "__main__":
    main()
