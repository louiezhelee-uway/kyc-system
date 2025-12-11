# 🔐 隐秘管理后台 - 快速参考卡

## 🎯 30 秒了解

你现在拥有一个**只有你能访问的隐秘管理后台**：
- 输入用户号和订单号 → **1秒** 生成验证链接
- 输入订单号 → **1秒** 查询状态和报告链接
- 3 种方式访问：网页、脚本、API

---

## 📖 文档速查表

| 需要... | 看这个文档 |
|--------|----------|
| 立即开始使用 | `COMPLETE_WORKFLOW.md` |
| 详细的 API 说明 | `ADMIN_MANUAL_GUIDE.md` |
| 部署到 VPS | `ADMIN_DEPLOYMENT_CHECKLIST.md` |
| 了解项目情况 | `ADMIN_BACKEND_SUMMARY.md` |

---

## 🚀 3 分钟快速开始

### 1. 配置密钥（1 分钟）

```bash
# VPS 上编辑 .env
ssh user@kyc.317073.xyz
nano /opt/kyc-app/.env

# 添加这一行：
ADMIN_SECRET_KEY=your-super-secret-key-here

# 生成强密钥：
openssl rand -base64 32
```

### 2. 部署（1 分钟）

```bash
cd /opt/kyc-app
bash deploy-admin.sh
```

### 3. 访问（1 分钟）

```
https://kyc.317073.xyz/admin-manual/
输入你的密钥 → 开始使用！
```

---

## 💻 3 种使用方式

### 方式 1️⃣：网页（推荐，最简单）
```
https://kyc.317073.xyz/admin-manual/
输入密钥 → 完成！
```

### 方式 2️⃣：Shell 脚本（快速）
```bash
# 生成链接（5 秒）
bash kyc-admin.sh generate alipay_user_123 order_001 "小王"

# 查询状态（1 秒）
bash kyc-admin.sh check order_001
```

### 方式 3️⃣：cURL（集成）
```bash
# 生成链接
curl -X POST https://kyc.317073.xyz/admin-manual/generate-link \
  -H "X-Admin-Key: your-key" \
  -d '{"user_id":"user_123","order_id":"order_001"}'

# 查询状态
curl -X POST https://kyc.317073.xyz/admin-manual/check-status \
  -H "X-Admin-Key: your-key" \
  -d '{"order_id":"order_001"}'
```

---

## 📋 核心 API 速查

### POST /admin-manual/generate-link
生成验证链接

**请求：**
```json
{
  "user_id": "user_123",        // 必填
  "order_id": "order_001",      // 必填
  "buyer_name": "小王",         // 可选
  "buyer_phone": "13800138000", // 可选
  "buyer_email": "buyer@example.com" // 可选
}
```

**响应：**
```json
{
  "verification_link": "https://kyc.317073.xyz/verify/token_xxx",
  "verification_token": "token_xxx",
  "applicant_id": "123456789"
}
```

### POST /admin-manual/check-status
查询验证状态

**请求：**
```json
{
  "order_id": "order_001"
}
```

**响应（已完成）：**
```json
{
  "verification_status": "approved",
  "report_urls": {
    "en": {"pdf": "https://..."},
    "zh": {"pdf": "https://..."}
  }
}
```

---

## ⏱️ 完整流程时间

```
用户号 + 订单号
    ↓ < 1 秒
验证链接 → 发送给买家
    ↓ 5 分钟
买家完成验证 → Sumsub 批准
    ↓ 5 秒
报告自动下载
    ↓ < 1 秒
查询状态 → 获取报告链接
    ↓ 2 分钟
发送报告给买家
    ↓
✅ 完成！（总计 15 分钟）
```

---

## 🔒 重要安全提醒

⚠️  **密钥安全**
- 使用强密钥（16+ 字符）
- 定期更换（每月）
- 不要分享给任何人
- 不要提交到 Git

⚠️  **访问安全**
- 总是用 HTTPS（不要 HTTP）
- 定期检查日志
- 不要在公开环境暴露密钥

---

## 🐛 快速故障排除

| 问题 | 解决 |
|------|------|
| 无法登录 | 检查密钥是否正确；清除 Cookie；重启容器 |
| 无法生成链接 | 检查 Sumsub 凭证；检查数据库；查看日志 |
| 报告无法下载 | 等待 1-5 秒；重新查询一次 |
| 忘记密钥 | `cat /opt/kyc-app/.env \| grep ADMIN` |

---

## 📞 有用的命令

```bash
# 查看日志
docker-compose logs -f web

# 查看特定日志
docker-compose logs web | grep -i admin

# 重启应用
docker-compose restart web

# 生成强密钥
openssl rand -base64 32

# 查询数据库
docker-compose exec db psql -U kyc_user -d kyc_db

# 列出所有订单
SELECT * FROM orders WHERE source = 'manual_admin';
```

---

## 📊 状态代码速查

| 状态 | 含义 | 下一步 |
|------|------|-------|
| `pending` | ⏳ 等待验证 | 等待买家完成 |
| `approved` | ✅ 已通过 | 下载报告，发送给买家 |
| `rejected` | ❌ 已拒绝 | 重新生成链接 |
| `expired` | ⏰ 已过期 | 重新生成链接 |

---

## 🎯 典型场景快速应对

### 场景 1：新订单进来

```bash
# 方式 1：网页
https://kyc.317073.xyz/admin-manual/ → 登录 → 填表单 → 生成链接

# 方式 2：脚本
bash kyc-admin.sh generate user_id order_id
```

### 场景 2：买家完成验证了？

```bash
# 查询状态
bash kyc-admin.sh check order_id

# 或网页查询
https://kyc.317073.xyz/admin-manual/ → 右侧输入订单号 → 查询
```

### 场景 3：批量处理订单

```bash
# 写个简单脚本
while read user_id order_id name; do
  bash kyc-admin.sh generate "$user_id" "$order_id" "$name"
done < orders.csv
```

---

## 📱 记住这个 URL

```
https://kyc.317073.xyz/admin-manual/
```

登录密钥：保存在你的密码管理器中 🔐

---

## 🔗 所有链接汇总

| 链接 | 说明 |
|------|------|
| `https://kyc.317073.xyz/admin-manual/` | 管理后台登录 |
| `https://kyc.317073.xyz/verify/{token}` | 买家验证页面 |
| `/admin-manual/generate-link` | API: 生成链接 |
| `/admin-manual/check-status` | API: 查询状态 |

---

## 💾 本地参考

保存这些文件到本地：
- `ADMIN_MANUAL_GUIDE.md` - 详细指南
- `COMPLETE_WORKFLOW.md` - 完整流程
- `kyc-admin.sh` - 快速脚本

---

**版本：** 1.0  
**最后更新：** 2025-12-10  
**状态：** ✅ 可立即使用
