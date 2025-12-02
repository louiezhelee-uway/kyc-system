# 🔗 KYC 验证链接查询指南

## 📍 快速回答：KYC 验证链接在哪里？

### 答案汇总

| 位置 | 说明 |
|------|------|
| **数据库** | PostgreSQL `verifications` 表的 `verification_link` 字段 |
| **生成时刻** | 发送 Webhook `/webhook/taobao/order` 时 |
| **生成函数** | `app/services/sumsub_service.py` 中的 `create_verification()` |
| **返回给用户** | Webhook 响应中的 `verification_link` 字段 |
| **给买家的链接** | `http://localhost:5000/verify/{verification_token}` |

---

## 🚀 三种查询方式（推荐顺序）

### 方式 1️⃣：快速查询（最简单，30 秒）

```bash
bash QUICK_CHECK_LINKS.sh
```

**输出示例**：
```
订单ID    | 买家    | 状态    | 验证链接                                    | 创建时间
----------|---------|---------|---------------------------------------------|----------------
test_001  | 张三    | pending | https://api.sumsub.com/sdk/applicant?... | 2025-12-03...
test_002  | 李四    | pending | https://api.sumsub.com/sdk/applicant?... | 2025-12-03...
```

---

### 方式 2️⃣：交互式查询（功能齐全，推荐）

```bash
bash CHECK_VERIFICATION_LINKS.sh
```

菜单功能：
```
1) 查询所有订单和验证记录
2) 查询最新 5 条验证链接         ← 最常用
3) 创建测试订单（生成新的验证链接）← 用于测试
4) 查询特定订单的验证链接
5) 查看验证状态统计
6) 导出所有验证链接              ← 用于导入 Excel
7) 检查 Sumsub API 连接
0) 退出
```

---

### 方式 3️⃣：直接数据库查询（高级用户）

#### 3.1 登录 PostgreSQL

```bash
docker exec -it kyc_postgres psql -U kyc_user -d kyc_db
```

#### 3.2 查看所有验证链接

```sql
SELECT 
    o.taobao_order_id as 订单ID,
    o.buyer_name as 买家,
    v.verification_link as 验证链接,
    v.status as 状态,
    v.created_at as 创建时间
FROM verifications v
JOIN orders o ON v.order_id = o.id
ORDER BY v.created_at DESC;
```

#### 3.3 查看最新 1 条

```sql
SELECT verification_link FROM verifications 
ORDER BY created_at DESC LIMIT 1 \gx
```

#### 3.4 查看特定订单

```sql
SELECT 
    v.verification_link,
    v.verification_token,
    v.status
FROM verifications v
JOIN orders o ON v.order_id = o.id
WHERE o.taobao_order_id = 'your_order_id';
```

#### 3.5 退出 PostgreSQL

```sql
\q
```

---

## 📊 数据库结构速查

### `orders` 表（订单表）

```
id                  - UUID 主键
taobao_order_id     - 淘宝订单 ID（唯一）
buyer_id            - 买家 ID
buyer_name          - 买家名称
buyer_email         - 买家邮箱
buyer_phone         - 买家电话
platform            - 平台（taobao/xianyu）
order_amount        - 订单金额
status              - 订单状态（pending/completed/rejected）
created_at          - 创建时间
updated_at          - 更新时间
```

### `verifications` 表（验证表）⭐ 重点

```
id                      - UUID 主键
order_id                - 外键 → orders.id
sumsub_applicant_id     - Sumsub 申请人 ID
verification_link       - ⭐ KYC 验证链接（这就是你要找的！）
verification_token      - 内部验证令牌（32 字符）
status                  - 验证状态（pending/approved/rejected/expired）
started_at              - 开始时间
completed_at            - 完成时间
created_at              - 创建时间
updated_at              - 更新时间
```

---

## 🔄 验证链接的完整生命周期

```
1. 订单创建
   ↓
2. 发送 Webhook: POST /webhook/taobao/order
   {
     "order_id": "taobao_001",
     "buyer_name": "张三",
     "buyer_email": "zhangsan@example.com",
     "buyer_phone": "13800138000",
     "order_amount": 1000
   }
   ↓
3. 系统创建 Order 记录
   ↓
4. 系统调用 Sumsub API 创建 Applicant
   请求: POST https://api.sumsub.com/resources/applicants
   响应: { "id": "applicant_xyz", ... }
   ↓
5. 系统生成 Access Token（临时令牌）
   ↓
6. 系统生成 Verification 链接
   https://api.sumsub.com/sdk/applicant?token=<ACCESS_TOKEN>
   ↓
7. 系统保存到数据库
   INSERT INTO verifications (verification_link, ...)
   ↓
8. 系统返回给调用者
   {
     "status": "success",
     "verification_link": "https://api.sumsub.com/sdk/applicant?token=...",
     "order_id": "uuid-123"
   }
   ↓
9. 买家点击链接进行 KYC 验证
   ↓
10. 上传身份证件、进行人脸识别
   ↓
11. 提交验证
   ↓
12. Sumsub 进行审核
   ↓
13. Sumsub 回调结果
    POST /webhook/sumsub/verification
    {
      "applicantId": "applicant_xyz",
      "reviewStatus": "approved"
    }
   ↓
14. 系统更新验证状态
    UPDATE verifications SET status = 'approved'
   ↓
15. 系统生成 PDF 报告
```

---

## 🧪 测试：创建第一个验证链接

### 步骤 1: 发送测试订单

```bash
curl -X POST http://35.212.217.145:5000/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "test_'$(date +%s)'",
    "buyer_id": "test_buyer",
    "buyer_name": "测试用户",
    "buyer_email": "test@example.com",
    "buyer_phone": "13800138000",
    "platform": "taobao",
    "order_amount": 1000
  }' | python3 -m json.tool
```

### 步骤 2: 响应示例

```json
{
  "status": "success",
  "order_id": "9f87d8c7-6a5b-4c3d-2e1f-0a9b8c7d6e5f",
  "verification_id": "7c6b5a49-38d2-1e0f-9c8b-7a6d5e4f3a2b",
  "verification_link": "https://api.sumsub.com/sdk/applicant?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "buyer_link": "http://35.212.217.145:5000/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a"
}
```

### 步骤 3: 查询数据库验证

```bash
bash QUICK_CHECK_LINKS.sh
```

### 步骤 4: 访问验证链接（买家页面）

```
http://35.212.217.145:5000/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
```

这会显示：
- 订单信息
- 买家信息
- "开始验证"按钮
- 点击后跳转到 Sumsub Web SDK

---

## 📱 在生产中使用验证链接

### 流程 1: 发送给买家

```
1. 系统收到淘宝订单 Webhook
   ↓
2. 自动生成 KYC 验证链接
   ↓
3. 通过邮件/短信/消息发送给买家
   
   "请点击以下链接完成身份验证:"
   http://35.212.217.145:5000/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
   
   ↓
4. 买家点击链接
   ↓
5. 进入验证页面（显示订单信息）
   ↓
6. 点击"开始验证"按钮
   ↓
7. 跳转到 Sumsub Web SDK（身份验证表单）
   ↓
8. 完成 KYC（上传证件、人脸识别等）
```

### 流程 2: 追踪验证状态

```bash
# 查询特定买家的验证状态
docker exec kyc_postgres psql -U kyc_user -d kyc_db -c "
SELECT 
    o.buyer_name,
    o.buyer_email,
    v.status,
    v.completed_at
FROM orders o
JOIN verifications v ON o.id = v.order_id
WHERE o.buyer_email = 'test@example.com';"
```

---

## 🔗 两种链接对比

| 特性 | 买家链接 | Sumsub 链接 |
|------|--------|-----------|
| 用途 | 中间页面 | 实际验证表单 |
| 格式 | `http://localhost:5000/verify/{token}` | `https://api.sumsub.com/sdk/applicant?token=...` |
| 由谁生成 | 我们的系统 | Sumsub API |
| 显示什么 | 订单信息 + 开始验证按钮 | KYC 验证表单（身份证、人脸识别等） |
| 是否需要网络 | 需要 | 需要（连接 Sumsub API） |
| 过期时间 | 可配置（默认 24h） | 由 Sumsub 决定（通常 24h） |
| 可重复使用 | 否 | 否 |
| 保存位置 | `verifications` 表 | `verifications.verification_link` |

---

## 📈 实用 SQL 查询

### 今天创建的所有验证

```sql
SELECT COUNT(*) as 今天的验证数
FROM verifications
WHERE DATE(created_at) = CURRENT_DATE;
```

### 已批准的验证

```sql
SELECT COUNT(*) as 已批准
FROM verifications
WHERE status = 'approved';
```

### 待处理的验证

```sql
SELECT COUNT(*) as 待处理
FROM verifications
WHERE status = 'pending';
```

### 验证耗时统计

```sql
SELECT 
    ROUND(AVG(EXTRACT(EPOCH FROM (completed_at - created_at))/3600)::numeric, 2) as 平均耗时小时,
    MAX(EXTRACT(EPOCH FROM (completed_at - created_at))/3600) as 最长耗时小时,
    MIN(EXTRACT(EPOCH FROM (completed_at - created_at))/3600) as 最短耗时小时
FROM verifications
WHERE completed_at IS NOT NULL;
```

---

## 🐛 故障排查

### 问题 1：数据库中没有验证链接

**检查清单**：

```bash
# 1. 检查 Flask 容器状态
docker ps | grep kyc_web

# 2. 检查 PostgreSQL 容器状态
docker ps | grep kyc_postgres

# 3. 查看 Flask 日志
docker logs -f kyc_web

# 4. 测试 Webhook 端点
curl http://localhost:5000/health

# 5. 检查数据库连接
docker exec kyc_web python3 -c "
from app import create_app, db
with create_app().app_context():
    print('数据库连接成功' if db.session.execute('SELECT 1') else '连接失败')
"
```

### 问题 2：Webhook 失败

**检查**：

```bash
# 查看完整日志
docker logs kyc_web --tail=50

# 检查 Sumsub API 凭证
docker exec kyc_web env | grep SUMSUB

# 测试 Sumsub API 连接
docker exec kyc_web python3 -c "
import requests
import hmac
import hashlib
from datetime import datetime

# 测试认证
print('测试 Sumsub API 连接...')
"
```

### 问题 3：无法访问验证链接

**原因可能**：
1. Sumsub API Token 过期
2. 网络连接问题
3. APP_DOMAIN 配置错误

**解决**：
```bash
# 重新启动 Flask
docker-compose restart kyc_web

# 查看配置
docker exec kyc_web env | grep APP_DOMAIN
```

---

## 💾 导出和备份

### 导出为 CSV

```bash
docker exec kyc_postgres psql -U kyc_user -d kyc_db \
  -c "COPY (
    SELECT 
      taobao_order_id,
      buyer_name,
      buyer_email,
      verification_link,
      status,
      created_at
    FROM orders o
    LEFT JOIN verifications v ON o.id = v.order_id
  ) TO STDOUT WITH CSV HEADER;" > links_backup.csv
```

### 导出为 JSON

```bash
docker exec kyc_postgres psql -U kyc_user -d kyc_db \
  --json \
  -c "SELECT * FROM verifications;" > verifications_backup.json
```

---

## 📞 快速参考

### 查看最新链接
```bash
bash QUICK_CHECK_LINKS.sh
```

### 创建测试订单
```bash
bash CHECK_VERIFICATION_LINKS.sh
# 选择选项 3
```

### 查询特定订单
```bash
bash CHECK_VERIFICATION_LINKS.sh
# 选择选项 4
```

### 查看统计信息
```bash
bash CHECK_VERIFICATION_LINKS.sh
# 选择选项 5
```

### 导出所有链接
```bash
bash CHECK_VERIFICATION_LINKS.sh
# 选择选项 6
```

---

## ✅ 验证清单

- [ ] 能够使用 `QUICK_CHECK_LINKS.sh` 快速查询
- [ ] 能够使用 `CHECK_VERIFICATION_LINKS.sh` 创建测试订单
- [ ] 理解验证链接的生成流程
- [ ] 能够查询数据库中的验证记录
- [ ] 已成功创建至少一个验证链接
- [ ] 理解两种链接的区别（买家链接 vs Sumsub 链接）
- [ ] 知道如何追踪验证状态
- [ ] 能够导出验证链接用于分析

---

**最后更新**: 2025-12-03  
**文档版本**: 1.0
