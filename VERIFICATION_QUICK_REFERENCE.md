# ✅ 验证链接系统 - 快速参考卡片

## 🎯 核心答案

### Q: 生成给买家的验证链接在哪里？

**A: 验证链接在多个地方生成和处理：**

| 位置 | 文件 | 功能 |
|------|------|------|
| **生成** | `app/routes/webhook.py` | 接收订单，触发生成 |
| **令牌生成** | `app/utils/token_generator.py` | 生成 32 位十六进制令牌 |
| **API 调用** | `app/services/sumsub_service.py` (第 82 行) | 生成 Sumsub SDK 链接 |
| **页面显示** | `app/routes/verification.py` | 验证页面路由 |
| **HTML 模板** | `app/templates/verification.html` | 前端显示 |

---

## 📊 验证链接结构

```
验证链接 (买家链接)
├── 格式: http://domain/verify/{32字符令牌}
├── 例: http://localhost:5000/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
├── 作用: 买家访问入口
└── 生成位置: webhook.py

      ↓ (买家点击)

验证页面显示 (verification.py)
├── 显示订单信息
├── 显示验证状态
├── 提供验证按钮
└── 链接到 Sumsub SDK

      ↓ (买家点击"开始验证")

Sumsub SDK 链接
├── 格式: https://api.sumsub.com/sdk/applicant?token={access_token}
├── 生成位置: sumsub_service.py 第 82 行
├── 作用: 真实身份验证
└── 结果: KYC 完成
```

---

## 🔑 关键代码位置

### 1️⃣ Webhook 处理 (`app/routes/webhook.py`)

```python
# 核心逻辑位置
@app.route('/webhook/taobao/order', methods=['POST'])
def taobao_webhook_handler():
    # 1. 验证 Webhook 签名
    # 2. 解析订单数据
    # 3. 调用 create_verification()
    # 4. 返回链接
    pass
```

**关键步骤**:
- 接收订单事件
- 验证 HMAC-SHA256 签名
- 启动 KYC 验证流程
- 返回买家验证链接

### 2️⃣ 令牌生成 (`app/utils/token_generator.py`)

```python
def generate_verification_token():
    """生成 32 位十六进制验证令牌"""
    return secrets.token_hex(16)  # 返回: a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
```

**特点**:
- 使用 `secrets` 模块（密码学安全）
- 32 字符十六进制字符串
- 唯一、不可预测

### 3️⃣ Sumsub 集成 (`app/services/sumsub_service.py` 第 82 行)

```python
# 第 82 行：生成 Sumsub Web SDK 链接
verification_link = f"{SUMSUB_API_URL.replace('/api', '')}/sdk/applicant?token={access_token}"

# 示例:
# https://api.sumsub.com/sdk/applicant?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**逻辑**:
1. 调用 Sumsub API 创建 Applicant
2. 获取 Access Token
3. 拼接 SDK 链接
4. 返回给前端

### 4️⃣ 验证页面 (`app/routes/verification.py`)

```python
@app.route('/verify/<verification_token>')
def verification_page(verification_token):
    # 1. 查询验证记录
    # 2. 查询订单信息
    # 3. 检查有效期
    # 4. 渲染 HTML 模板
    pass
```

**流程**:
- 接收令牌参数
- 数据库查询
- 权限验证
- 模板渲染

### 5️⃣ HTML 模板 (`app/templates/verification.html`)

```html
<!-- 订单信息显示 -->
<div>订单号: {{ order.id }}</div>
<div>买家: {{ order.buyer_name }}</div>

<!-- 验证按钮 -->
<a href="{{ verification_link }}">开始验证</a>
```

---

## 🚀 现在就可以访问

### 启动服务器

```bash
cd "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"
python3 /tmp/verification_server.py
```

### 访问链接

- **首页**: http://localhost:5000/
- **验证页面**: http://localhost:5000/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
- **API 测试**: http://localhost:5000/api/test

---

## 📋 完整工作流程

```
┌─ 第 1 步 ──────────────────────────────────┐
│ 买家在淘宝/闲鱼下单                         │
└──────────────────┬────────────────────────┘
                   ↓
┌─ 第 2 步 ──────────────────────────────────┐
│ 订单 Webhook 事件                           │
│ → app/routes/webhook.py                   │
└──────────────────┬────────────────────────┘
                   ↓
┌─ 第 3 步 ──────────────────────────────────┐
│ 生成验证令牌 (32 位十六进制)               │
│ → app/utils/token_generator.py             │
│ → a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a        │
└──────────────────┬────────────────────────┘
                   ↓
┌─ 第 4 步 ──────────────────────────────────┐
│ 调用 Sumsub API                             │
│ → app/services/sumsub_service.py (第 82 行)│
│ → 生成 Sumsub SDK 链接                     │
└──────────────────┬────────────────────────┘
                   ↓
┌─ 第 5 步 ──────────────────────────────────┐
│ 生成买家验证链接                           │
│ → http://domain/verify/{token}             │
└──────────────────┬────────────────────────┘
                   ↓
┌─ 第 6 步 ──────────────────────────────────┐
│ 保存到数据库                                │
│ → INSERT INTO verifications                │
└──────────────────┬────────────────────────┘
                   ↓
┌─ 第 7 步 ──────────────────────────────────┐
│ 返回链接给前端                              │
│ → JSON 响应包含验证链接                    │
└──────────────────┬────────────────────────┘
                   ↓
┌─ 第 8 步 ──────────────────────────────────┐
│ 发送给买家 (邮件/短信)                     │
│ → 买家收到链接                             │
└──────────────────┬────────────────────────┘
                   ↓
        ┌──────────────────┐
        │ 买家点击链接     │
        └────────┬─────────┘
                 ↓
┌─ 第 9 步 ──────────────────────────────────┐
│ 访问验证页面                                │
│ → GET /verify/{token}                      │
│ → app/routes/verification.py               │
└──────────────────┬────────────────────────┘
                   ↓
┌─ 第 10 步 ─────────────────────────────────┐
│ 显示订单信息和验证页面                     │
│ → app/templates/verification.html          │
└──────────────────┬────────────────────────┘
                   ↓
┌─ 第 11 步 ─────────────────────────────────┐
│ 买家点击"开始验证"                         │
│ → 转向 Sumsub Web SDK                      │
└──────────────────┬────────────────────────┘
                   ↓
┌─ 第 12 步 ─────────────────────────────────┐
│ 进行真实 KYC 验证                           │
│ → Sumsub 处理                              │
│ → 5-10 分钟完成                            │
└──────────────────┬────────────────────────┘
                   ↓
                 完成 ✓
```

---

## 📁 相关文件导航

| 文件 | 类型 | 功能 |
|------|------|------|
| `app/routes/webhook.py` | Python | 接收订单、生成链接 |
| `app/routes/verification.py` | Python | 验证页面路由 |
| `app/services/sumsub_service.py` | Python | Sumsub API 集成 |
| `app/utils/token_generator.py` | Python | 令牌生成 |
| `app/templates/verification.html` | HTML/Jinja2 | 前端模板 |
| `app/models/order.py` | Python | 订单数据模型 |
| `app/models/verification.py` | Python | 验证数据模型 |
| `/tmp/verification_server.py` | Python | 演示服务器 |
| `VERIFICATION_LINKS_WORKING.md` | 文档 | 访问指南 |
| `VERIFICATION_LINKS_TECHNICAL_DOC.md` | 文档 | 技术文档 |

---

## 🎓 学习路径

### 快速理解（5 分钟）
1. 阅读本文档
2. 查看工作流程图
3. 访问演示链接

### 深入学习（30 分钟）
1. 阅读 `VERIFICATION_LINKS_WORKING.md`
2. 查看相关代码文件
3. 追踪完整数据流

### 完全掌握（1 小时）
1. 阅读 `VERIFICATION_LINKS_TECHNICAL_DOC.md`
2. 分析所有代码实现
3. 理解 Sumsub 集成
4. 理解数据库操作

---

## ✨ 关键特点

| 特性 | 说明 |
|------|------|
| **唯一性** | 每个订单一个唯一令牌 |
| **安全性** | HMAC-SHA256 + JWT 加密 |
| **可追踪** | 完整的审计日志 |
| **可扩展** | 支持多个平台集成 |
| **用户友好** | 简洁的验证页面 |
| **集成完整** | Sumsub Web SDK 集成 |

---

## 🔧 故障排查

### 链接无法访问？
```bash
# 检查服务器状态
lsof -i :5000

# 重启服务器
python3 /tmp/verification_server.py
```

### 页面显示错误？
```bash
# 检查 Flask 错误日志
tail -f /tmp/verification_server.log

# 查看模板文件
cat app/templates/verification.html
```

### Sumsub 链接失效？
```bash
# 检查 API 密钥
echo $SUMSUB_API_KEY

# 验证 Access Token 生成
grep "verification_link" app/services/sumsub_service.py
```

---

## 📞 需要帮助？

- 📖 **文档**: 查看 `VERIFICATION_LINKS_TECHNICAL_DOC.md`
- 🚀 **快速启动**: 查看 `VERIFICATION_LINKS_WORKING.md`
- 🔧 **代码**: 查看相关 Python 文件
- 💻 **演示**: 访问 http://localhost:5000/

---

## 📌 总结

**验证链接生成的关键文件**:

```
webhook.py (接收订单)
    ↓
token_generator.py (生成令牌)
    ↓
sumsub_service.py (Sumsub API)
    ↓
verification.py (页面路由)
    ↓
verification.html (前端显示)
```

**现在可以做的事**:
- ✅ 访问演示验证页面
- ✅ 查看完整代码实现
- ✅ 理解工作流程
- ✅ 集成到自己的系统

---

*最后更新: 2025-11-26*  
*系统状态: ✅ 完全就绪*  
*演示服务器: 🟢 运行中*
