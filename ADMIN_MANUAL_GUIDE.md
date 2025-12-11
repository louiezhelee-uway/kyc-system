# 🔐 隐秘管理后台 - 快速指南

## 概述

这是一个只有你能访问的隐秘管理后台，用于：
- 📝 **手动生成验证链接** - 输入用户号和订单号，快速生成 KYC 验证链接
- 🔍 **查询验证状态** - 随时查看验证进度和下载报告
- 📥 **获取报告链接** - 验证完成后直接获取买家的报告下载链接

---

## 🚀 快速开始

### 1️⃣ 访问管理后台

```
https://kyc.317073.xyz/admin-manual/
```

你会看到一个登录界面，需要输入密钥。

### 2️⃣ 管理员密钥

密钥在环境变量中配置（`.env` 文件）：

```bash
ADMIN_SECRET_KEY=your-secret-key-here
```

**默认密钥：** `your-secret-key-change-this`

⚠️ **强烈建议更改！** 这个密钥应该是只有你知道的。

### 3️⃣ 登录

输入正确的密钥后，系统会创建一个 session（浏览器 cookie），有效期为你的 Flask session 设置（默认 31 天）。

---

## 📝 功能详解

### 功能 1：生成验证链接

#### 使用场景
> 你从闲鱼获取了一个订单，现在需要为这个买家生成一个 KYC 验证链接。

#### 操作步骤

1. **登录管理后台**
2. **在左侧"生成验证链接"表单中填入:**
   
   | 字段 | 例子 | 说明 |
   |------|------|------|
   | **用户号** ⭐ | `alipay_user_12345` | 闲鱼/淘宝用户ID，**必填** |
   | **订单号** ⭐ | `order_20251208_001` | 订单编号，**必填** |
   | 买家名称 | 小王 | 可选，用于记录 |
   | 买家电话 | 13800138000 | 可选 |
   | 买家邮箱 | buyer@example.com | 可选 |

3. **点击"生成链接"按钮**

#### 获得的结果

系统会返回：

```json
{
  "verification_link": "https://kyc.317073.xyz/verify/token_abc123xyz",
  "verification_token": "token_abc123xyz",
  "applicant_id": "123456789",
  "created_at": "2025-12-08 10:30:00"
}
```

#### 接下来做什么

1. **复制验证链接** - 点击"复制"按钮，或手动复制
2. **发送给买家** - 通过聊天、邮件或短信发送链接
3. **买家访问链接** - 买家点击链接进行 KYC 认证
4. **系统自动处理** - 验证完成后，系统自动下载报告

---

### 功能 2：查询验证状态

#### 使用场景
> 你已经给买家发送了验证链接，现在想查看进度，看看是否已经完成认证。

#### 操作步骤

1. **在右侧"查询验证状态"表单中输入订单号**
   - 例如：`order_20251208_001`

2. **点击"查询状态"按钮**

#### 获得的信息

```json
{
  "order_id": "order_20251208_001",
  "user_id": "alipay_user_12345",
  "verification_status": "approved",  // pending, approved, rejected, expired
  "verified_at": "2025-12-08 10:30:00",
  "buyer_info": {
    "name": "小王",
    "phone": "13800138000",
    "email": "buyer@example.com"
  },
  "report_urls": {
    "en": {
      "pdf": "https://kyc.317073.xyz/report/sumsub/download/...",
      "json": "https://kyc.317073.xyz/report/sumsub/download/..."
    },
    "zh": {
      "pdf": "https://kyc.317073.xyz/report/sumsub/download/..."
    }
  }
}
```

#### 状态说明

| 状态 | 含义 | 操作 |
|------|------|------|
| ⏳ `pending` | 等待中 | 买家还未完成认证，继续等待 |
| ✅ `approved` | 已通过 | 认证成功，可下载报告发给买家 |
| ❌ `rejected` | 已拒绝 | 认证失败，可能需要重新认证 |
| ⏰ `expired` | 已过期 | 链接过期，需要生成新链接 |

#### 获取报告链接

当状态为 `approved` 时，会显示报告链接。

**支持的格式和语言：**
- 英文 PDF：`en/pdf`
- 中文 PDF：`zh/pdf`
- JSON 格式：`json`（用于集成）

**发送给买家：**
直接复制报告链接，买家可以打开查看或下载 PDF。

---

## 🔒 安全性说明

### 密钥管理

1. **更改默认密钥** ⭐
   ```bash
   # 在 .env 文件中
   ADMIN_SECRET_KEY=your-super-secret-key-that-only-you-know
   ```

2. **保管好密钥**
   - 不要告诉任何人
   - 不要提交到 Git
   - 定期更换

3. **Session 管理**
   - 自动登出：关闭浏览器或清除 Cookie
   - 手动登出：点击"退出登录"按钮

### 请求认证

所有 API 都需要有效的 session 或 `X-Admin-Key` 请求头：

```bash
curl https://kyc.317073.xyz/admin-manual/generate-link \
  -H "X-Admin-Key: your-secret-key" \
  -H "Content-Type: application/json" \
  -d '{"user_id": "...", "order_id": "..."}'
```

---

## 🔄 完整工作流

```
1. 从闲鱼获取订单信息
   ↓
2. 登录管理后台（输入密钥）
   ↓
3. 填入用户号和订单号，点击"生成链接"
   ↓
4. 复制验证链接，发送给买家
   ↓
5. 买家点击链接，进行 KYC 认证（自拍、身份证等）
   ↓
6. 系统自动处理验证和下载报告
   ↓
7. 回到管理后台，查询订单状态
   ↓
8. 看到状态为"已通过"，复制报告链接
   ↓
9. 发送报告链接给买家（或自己保存）
   ↓
10. ✅ 流程完成，后续通过淘宝或其他渠道处理发货
```

---

## 📊 管理员 API 端点

如果你想用 curl 或脚本自动化，可以直接调用这些 API。

### POST /admin-manual/login
**登录并创建 session**

```bash
curl -X POST https://kyc.317073.xyz/admin-manual/login \
  -H "Content-Type: application/json" \
  -d '{"secret_key": "your-key"}' \
  -c cookies.txt
```

### POST /admin-manual/generate-link
**生成验证链接**

```bash
curl -X POST https://kyc.317073.xyz/admin-manual/generate-link \
  -H "Content-Type: application/json" \
  -H "X-Admin-Key: your-key" \
  -d '{
    "user_id": "user_12345",
    "order_id": "order_001",
    "buyer_name": "小王",
    "buyer_phone": "13800138000",
    "buyer_email": "buyer@example.com"
  }'
```

### POST /admin-manual/check-status
**查询验证状态**

```bash
curl -X POST https://kyc.317073.xyz/admin-manual/check-status \
  -H "Content-Type: application/json" \
  -H "X-Admin-Key: your-key" \
  -d '{"order_id": "order_001"}'
```

### GET /admin-manual/list-orders
**列出所有手动订单**

```bash
curl -X GET 'https://kyc.317073.xyz/admin-manual/list-orders?status=approved' \
  -H "X-Admin-Key: your-key"
```

---

## 🐛 常见问题

### Q: 忘记了密钥怎么办？
**A:** 检查 `.env` 文件中的 `ADMIN_SECRET_KEY` 值。如果没有该文件，创建一个：
```bash
echo "ADMIN_SECRET_KEY=your-new-key" >> .env
```

### Q: 买家无法访问验证链接？
**A:** 
1. 检查链接是否正确复制
2. 确保 URL 是 `https://` 不是 `http://`
3. 如果显示"已过期"，重新生成新链接

### Q: 验证状态查不到？
**A:**
1. 确认订单号输入正确
2. 订单号是否与生成链接时输入的一致？
3. 检查管理后台的日志

### Q: 报告还在生成中？
**A:** 系统会在验证完成后自动下载报告。通常需要 1-5 秒。稍后再查询一次。

### Q: 我想批量生成多个链接？
**A:** 可以直接调用 API 脚本，或者逐个在前端生成。

---

## 📝 最佳实践

1. **记录订单** - 在你的系统中记录生成的验证令牌，方便后续查询
2. **定期更换密钥** - 建议每月更换一次
3. **备份密钥** - 把密钥保存在安全的地方（密码管理器）
4. **避免共享** - 不要与他人分享管理后台的访问方式
5. **监测日志** - 定期检查服务器日志，看是否有异常访问

---

## 🚀 部署上线

### 本地测试

```bash
# 启动 Flask
python run.py

# 访问
http://localhost:5000/admin-manual/
```

### VPS 部署

```bash
# 更新代码
cd /opt/kyc-app
git pull origin main

# 重新启动容器
docker-compose down
docker-compose up -d

# 访问
https://kyc.317073.xyz/admin-manual/
```

---

## 📚 相关文档

- [KYC 系统完整指南](./00_START_HERE.md)
- [验证报告功能](./SUMSUB_REPORT_INTEGRATION.md)
- [部署指南](./PRODUCTION_DEPLOYMENT.md)

---

**版本：** 1.0  
**创建日期：** 2025-12-08  
**更新日期：** 2025-12-10
