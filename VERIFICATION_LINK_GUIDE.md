# 🔗 KYC 验证链接快速参考

## 📍 验证链接在哪里生成？

### 关键文件位置

| 功能 | 文件 | 行号 | 函数 |
|------|------|------|------|
| 🎲 生成令牌 | `app/utils/token_generator.py` | 10 | `generate_verification_token()` |
| 🔗 生成验证链接 | `app/services/sumsub_service.py` | 82 | `create_verification()` |
| 🌐 验证页面路由 | `app/routes/verification.py` | 5 | `verification_page()` |
| 📄 验证页面模板 | `app/templates/verification.html` | - | HTML 模板 |
| 💾 数据库模型 | `app/models/verification.py` | - | `Verification` 类 |
| 🪝 Webhook 处理 | `app/routes/webhook.py` | 15 | `taobao_webhook_handler()` |

---

## 🔗 两种链接说明

### 1️⃣ 买家验证链接（发送给买家）

**格式**: `http://localhost:5000/verify/{verification_token}`

**例子**: 
```
http://localhost:5000/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
```

**特点**:
- ✅ 简单易记
- ✅ 本地应用链接
- ✅ 显示买家验证页面
- ✅ 包含订单信息
- ✅ 32 字符令牌（唯一标识）

**生成位置**: `app/routes/webhook.py` (webhook 处理函数)

---

### 2️⃣ Sumsub Web SDK 链接（在验证页面上）

**格式**: `https://api.sumsub.com/sdk/applicant?token={access_token}`

**例子**: 
```
https://api.sumsub.com/sdk/applicant?token=eyJhbGcjQ2FsbFByb3ZpZGVyIjp...
```

**特点**:
- ✅ Sumsub 官方链接
- ✅ 64+ 字符 access token
- ✅ 身份验证表单
- ✅ 需要上传证件、人脸识别
- ✅ 由 Sumsub API 返回

**生成位置**: `app/services/sumsub_service.py` 第 82 行

---

## 🔄 完整流程（12 步）

```
1️⃣ 淘宝/闲鱼订单创建
   ↓
2️⃣ 系统接收 Webhook 通知
   POST /webhook/taobao/order
   ↓
3️⃣ 验证 HMAC-SHA256 签名
   ├─ 秘钥: WEBHOOK_SECRET
   └─ 签名验证成功
   ↓
4️⃣ 创建 Order 数据库记录
   ├─ 表: orders
   └─ 字段: order_id, buyer_name, buyer_email, ...
   ↓
5️⃣ 生成验证令牌 ⭐
   ├─ 函数: generate_verification_token()
   ├─ 长度: 32 字符
   └─ 例: a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
   ↓
6️⃣ 调用 Sumsub API 创建 Applicant
   ├─ API: POST /resources/applicants
   ├─ 返回: applicantId, accessToken
   └─ 文件: app/services/sumsub_service.py
   ↓
7️⃣ 生成 Sumsub Web SDK 链接 ⭐
   ├─ 链接: https://api.sumsub.com/sdk/applicant?token={accessToken}
   └─ 位置: 第 82 行
   ↓
8️⃣ 创建 Verification 数据库记录
   ├─ 表: verifications
   ├─ 字段: verification_token, verification_link, sumsub_applicant_id
   └─ 状态: pending
   ↓
9️⃣ 生成买家验证链接 ⭐
   ├─ 链接: http://localhost:5000/verify/{verification_token}
   └─ 例: http://localhost:5000/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
   ↓
🔟 发送链接给买家
   ├─ 邮件、短信、消息等
   └─ 显示: 点击链接进行身份验证
   ↓
1️⃣1️⃣ 买家点击链接访问验证页面
   ├─ GET /verify/{verification_token}
   ├─ 路由: app/routes/verification.py
   └─ 显示: 订单信息 + 开始验证按钮
   ↓
1️⃣2️⃣ 买家点击"开始验证"
   ├─ 点击按钮链接到 Sumsub Web SDK
   ├─ 跳转: https://api.sumsub.com/sdk/applicant?token={accessToken}
   └─ 进入 Sumsub 身份验证流程
   ↓
1️⃣3️⃣ 买家完成 KYC 验证
   ├─ 上传身份证件
   ├─ 完成人脸识别
   ├─ 填写个人信息
   └─ 提交验证
   ↓
1️⃣4️⃣ Sumsub 回调验证结果
   ├─ Webhook: POST /webhook/sumsub/verification
   ├─ 数据: applicantId, reviewStatus
   └─ 状态: approved / rejected
   ↓
1️⃣5️⃣ 系统更新验证状态
   ├─ 更新: UPDATE verifications SET status = 'approved'
   └─ 文件: app/routes/webhook.py
   ↓
1️⃣6️⃣ 生成 PDF 报告
   ├─ 文件: app/services/report_service.py
   └─ 链接: http://localhost:5000/report/{order_id}
```

---

## 🔐 数据库表结构

### orders 表

```sql
CREATE TABLE orders (
    id VARCHAR(255) PRIMARY KEY,
    buyer_name VARCHAR(255) NOT NULL,
    buyer_email VARCHAR(255) NOT NULL,
    buyer_phone VARCHAR(20) NOT NULL,
    order_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50),  -- pending, completed, rejected
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### verifications 表

```sql
CREATE TABLE verifications (
    id SERIAL PRIMARY KEY,
    order_id VARCHAR(255) FOREIGN KEY REFERENCES orders(id),
    sumsub_applicant_id VARCHAR(255) NOT NULL,
    verification_token VARCHAR(32) NOT NULL UNIQUE,  -- ⭐ 关键字段
    verification_link TEXT NOT NULL,  -- ⭐ Sumsub SDK 链接
    status VARCHAR(50),  -- pending, approved, rejected
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL
);
```

---

## 🧪 测试命令

### 1. 启动开发服务器

```bash
./local-dev.sh
```

### 2. 发送测试订单 Webhook

```bash
curl -X POST http://localhost:5000/webhook/taobao/order \
  -H 'Content-Type: application/json' \
  -H 'X-Signature: YOUR_SIGNATURE_HERE' \
  -d '{
    "order_id": "taobao_001",
    "buyer_name": "张三",
    "buyer_email": "zhangsan@example.com",
    "buyer_phone": "13800138000",
    "order_amount": 299.99,
    "timestamp": 1234567890
  }'
```

**响应示例**:
```json
{
  "success": true,
  "verification_token": "a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a",
  "verification_link": "http://localhost:5000/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a"
}
```

### 3. 访问验证页面

```bash
# 在浏览器中打开
open 'http://localhost:5000/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a'
```

### 4. 查询验证状态

```bash
curl -X GET http://localhost:5000/verify/status/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
```

**响应示例**:
```json
{
  "status": "pending",
  "order_id": "taobao_001",
  "created_at": "2025-11-25T19:06:24",
  "completed_at": null
}
```

### 5. 查看报告

```bash
curl -X GET http://localhost:5000/report/taobao_001
```

### 6. 下载 PDF 报告

```bash
curl -X GET http://localhost:5000/report/taobao_001/download -o report.pdf
```

---

## 📋 验证页面 HTML

**文件**: `app/templates/verification.html`

**关键元素**:

```html
<!-- 显示订单信息 -->
<div class="order-info">
  <p>订单号: {{ order.order_id }}</p>
  <p>买家: {{ order.buyer_name }}</p>
  <p>邮箱: {{ order.buyer_email }}</p>
</div>

<!-- 验证说明 -->
<div class="verification-info">
  <p>为了完成您的订单，请进行身份验证</p>
  <p>验证过程需要 5-10 分钟</p>
  <p>需要上传身份证件并进行人脸识别</p>
</div>

<!-- 验证按钮 - 链接到 Sumsub Web SDK -->
<a href="{{ verification_link }}" class="button">
  开始验证
</a>
```

---

## 🔧 代码示例

### 生成验证令牌

```python
# app/utils/token_generator.py
import secrets

def generate_verification_token():
    """生成 32 字符唯一令牌"""
    return secrets.token_hex(16)

# 使用
token = generate_verification_token()
# 输出: a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
```

### 生成验证链接

```python
# app/services/sumsub_service.py
def create_verification(order):
    # ... 生成 Sumsub Applicant ...
    
    # 生成验证链接（第 82 行）
    verification_link = f"{SUMSUB_API_URL.replace('/api', '')}/sdk/applicant?token={access_token}"
    
    # 生成买家链接
    buyer_link = f"{BASE_URL}/verify/{verification_token}"
    
    # 创建验证记录
    verification = Verification(
        order_id=order.id,
        sumsub_applicant_id=applicant_id,
        verification_token=verification_token,
        verification_link=verification_link
    )
    
    return verification
```

### 验证页面路由

```python
# app/routes/verification.py
@bp.route('/<verification_token>', methods=['GET'])
def verification_page(verification_token):
    # 查询验证记录
    verification = Verification.query.filter_by(
        verification_token=verification_token
    ).first()
    
    if not verification:
        return render_template('error.html', 
                             message='验证链接不存在'), 404
    
    # 获取订单信息
    order = verification.order
    
    # 渲染模板
    return render_template('verification.html',
                         order=order,
                         verification=verification,
                         verification_link=verification.verification_link)
```

---

## ✅ 验证清单

- [ ] 验证链接生成位置理解正确
- [ ] 知道两种链接的区别
- [ ] 理解完整的 12 步流程
- [ ] 能够读懂数据库记录
- [ ] 能够运行测试命令
- [ ] 已启动本地开发服务器
- [ ] 已发送测试订单 Webhook
- [ ] 已访问验证页面
- [ ] 已查询验证状态
- [ ] 准备进行端到端测试

---

## 🎯 下一步行动

### 快速验证（5 分钟）

```bash
# 1. 启动服务器
./local-dev.sh

# 2. 在另一个终端，运行演示脚本
python3 verify-link-walkthrough.py

# 3. 或者运行快速测试
python3 test-verification-link.py
```

### 完整测试（15 分钟）

```bash
# 1. 启动服务器
./local-dev.sh

# 2. 发送测试订单
curl -X POST http://localhost:5000/webhook/taobao/order \
  -H 'Content-Type: application/json' \
  -d '{"order_id":"test_001",...}'

# 3. 从响应中复制验证链接

# 4. 在浏览器中打开验证链接
# http://localhost:5000/verify/{token}

# 5. 观察验证页面显示
# 6. 点击"开始验证"按钮
# 7. 进入 Sumsub Web SDK
```

### 生产部署

```bash
# 查看部署指南
cat PRODUCTION_DEPLOYMENT.md

# 或者使用 VPS 部署脚本
./deploy-vps.sh
```

---

## 📞 常见问题

**Q: 验证链接过期了怎么办？**

A: 系统可以配置验证链接的过期时间。默认设置为 24 小时。过期后，需要重新生成新的验证链接。

**Q: 可以重复使用同一个验证链接吗？**

A: 不可以。每个订单生成唯一的验证链接。验证完成后，链接自动失效。

**Q: 如何测试 Sumsub 集成？**

A: 使用 Sumsub 测试账户和测试链接。详见 `SUMSUB_INTEGRATION.md`。

**Q: 验证链接在数据库中存储吗？**

A: 是的。验证链接和验证令牌都存储在 `verifications` 表中，用于追踪和查询。

---

## 📚 相关文档

- 📖 [Sumsub 集成指南](SUMSUB_INTEGRATION.md)
- 📖 [完整项目清单](CHECKLIST.md)
- 📖 [完成报告](COMPLETION_REPORT.md)
- 📖 [开始指南](GETTING_STARTED.md)
- 📖 [生产部署](PRODUCTION_DEPLOYMENT.md)

---

**最后更新**: 2025-11-25  
**验证链接系统**: ✅ 完全就绪
