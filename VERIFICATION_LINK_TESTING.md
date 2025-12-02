# KYC 验证链接测试指南

## 🎯 快速检查

### 方法 1：直接在 VPS 上测试

在虚拟机上执行这些命令来检查应用是否正常运行：

```bash
# 1. 检查 Flask 应用日志
docker-compose logs web | grep -i "verify\|kyc\|sumsub"

# 2. 测试 Flask API 端点
curl -v https://kyc.317073.xyz/api/health

# 3. 查看最近的 Nginx 日志
tail -f /var/log/nginx/access.log
```

---

## 📋 完整的验证链接生成流程

KYC 验证链接是通过以下流程生成的：

```
淘宝/闲鱼 订单事件
    ↓
POST /webhook/taobao/order (接收订单)
    ↓
调用 Sumsub API 创建验证
    ↓
生成唯一的验证 token
    ↓
生成验证链接：https://kyc.317073.xyz/verify/{token}
    ↓
存储到 PostgreSQL 数据库
    ↓
返回验证链接给买家
```

---

## 🧪 测试方式

### 测试 1：查看 Flask 应用是否正确初始化

在 VPS 上检查应用日志：

```bash
# 查看完整的应用启动日志
docker-compose logs web

# 应该看到类似的输出：
# * Running on http://0.0.0.0:5000
# WARNING in app.logger: ...
```

### 测试 2：直接调用 API 创建验证

创建一个测试脚本来模拟订单 Webhook：

```bash
# 在 VPS 上创建测试脚本
cat > /tmp/test_kyc.sh << 'EOF'
#!/bin/bash

# 测试参数
ORDER_ID="test-order-$(date +%s)"
BUYER_EMAIL="test@example.com"
BUYER_PHONE="13800138000"

echo "🧪 测试 KYC 验证链接生成..."
echo "订单 ID: $ORDER_ID"

# 调用 Webhook 端点（模拟淘宝订单）
curl -v -X POST https://kyc.317073.xyz/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d "{
    \"order_id\": \"$ORDER_ID\",
    \"buyer_email\": \"$BUYER_EMAIL\",
    \"buyer_phone\": \"$BUYER_PHONE\",
    \"buyer_name\": \"Test User\",
    \"shop_id\": \"test-shop\",
    \"timestamp\": $(date +%s)
  }"

echo ""
echo "✅ 请求已发送"
EOF

chmod +x /tmp/test_kyc.sh
bash /tmp/test_kyc.sh
```

### 测试 3：查看数据库中的验证记录

```bash
# 连接到 PostgreSQL 数据库
docker-compose exec postgres psql -U kyc_user -d kyc_db

# 在 PostgreSQL 提示符下执行：
# 查看所有订单
SELECT * FROM kyc_order LIMIT 5;

# 查看所有验证记录
SELECT id, order_id, verification_token, status, created_at FROM kyc_verification LIMIT 5;

# 查看最新的验证链接
SELECT 
    o.id as order_id,
    o.buyer_email,
    v.verification_token,
    v.status,
    'https://kyc.317073.xyz/verify/' || v.verification_token as verification_url
FROM kyc_order o
LEFT JOIN kyc_verification v ON o.id = v.order_id
ORDER BY o.created_at DESC
LIMIT 10;

# 退出数据库
\q
```

---

## 🔍 常见问题排查

### 问题 1：Flask 应用无法启动

```bash
# 查看应用错误日志
docker-compose logs web | tail -50

# 可能的原因：
# - PostgreSQL 连接失败
# - 环境变量配置错误
# - 依赖包缺失
```

### 问题 2：Webhook 端点返回 404

```bash
# 检查 Flask 路由是否正确
docker-compose exec web python -c "from app import app; print(app.url_map)"

# 应该看到 /webhook/taobao/order 路由
```

### 问题 3：Sumsub API 集成失败

```bash
# 检查环境变量是否设置
docker-compose exec web env | grep SUMSUB

# 应该看到：
# SUMSUB_API_KEY=your-api-key
# SUMSUB_API_URL=https://api.sumsub.com

# 如果为空，需要编辑 .env 文件
sudo nano /opt/kyc-app/.env
```

---

## 📊 查看现有的验证链接

如果系统已经收到了订单，可以这样查看：

```bash
# SSH 到 VPS
gcloud compute ssh kyc-app --zone=asia-east1-a

# 查看数据库
cd /opt/kyc-app
docker-compose exec postgres psql -U kyc_user -d kyc_db << SQL
SELECT 
    o.id,
    o.buyer_email,
    v.verification_token,
    v.status,
    o.created_at
FROM kyc_order o
LEFT JOIN kyc_verification v ON o.id = v.order_id
ORDER BY o.created_at DESC
LIMIT 20;
SQL
```

---

## 🔗 验证链接的访问

生成的验证链接格式是：

```
https://kyc.317073.xyz/verify/{verification_token}
```

例如：
```
https://kyc.317073.xyz/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
```

访问这个链接会显示 KYC 验证页面。

### 测试访问验证页面

```bash
# 在 VPS 上获取一个真实的 token
TOKEN=$(docker-compose exec postgres psql -U kyc_user -d kyc_db -t -c "SELECT verification_token FROM kyc_verification LIMIT 1;")

# 访问验证页面
curl -v "https://kyc.317073.xyz/verify/$TOKEN"
```

---

## ✅ 完整的测试清单

在 VPS 上逐一检查：

- [ ] Docker 容器都在运行：`docker-compose ps`
- [ ] Flask 应用已启动：`docker-compose logs web | grep "Running on"`
- [ ] PostgreSQL 可以连接：`docker-compose exec postgres psql -U kyc_user -d kyc_db -c "SELECT 1;"`
- [ ] Nginx 反向代理正常：`curl -v https://kyc.317073.xyz/api/health`
- [ ] 数据库有验证表：`docker-compose exec postgres psql -U kyc_user -d kyc_db -c "\dt"`
- [ ] 至少有一条验证记录：`docker-compose exec postgres psql -U kyc_user -d kyc_db -c "SELECT COUNT(*) FROM kyc_verification;"`
- [ ] 可以访问验证页面：`curl -v "https://kyc.317073.xyz/verify/test-token"`

---

## 📈 监控生成的链接

### 实时查看新的验证链接

创建一个监控脚本：

```bash
cat > /tmp/watch_kyc.sh << 'EOF'
#!/bin/bash

echo "📊 KYC 验证链接监控面板"
echo "=================================="
echo ""

while true; do
  clear
  echo "📊 KYC 验证链接监控面板 - 更新时间: $(date)"
  echo "=================================="
  echo ""
  
  # 显示最近的验证链接
  docker-compose exec postgres psql -U kyc_user -d kyc_db << SQL
SELECT 
    o.id as 订单ID,
    o.buyer_email as 买家邮箱,
    v.verification_token as 验证Token,
    v.status as 状态,
    o.created_at as 创建时间,
    'https://kyc.317073.xyz/verify/' || v.verification_token as 验证链接
FROM kyc_order o
LEFT JOIN kyc_verification v ON o.id = v.order_id
ORDER BY o.created_at DESC
LIMIT 10;
SQL

  echo ""
  echo "（每 10 秒刷新一次，按 Ctrl+C 停止）"
  sleep 10
done
EOF

chmod +x /tmp/watch_kyc.sh
bash /tmp/watch_kyc.sh
```

---

## 🛠️ 手动创建测试验证

如果没有收到订单，可以手动创建测试数据：

```bash
# 连接到数据库
docker-compose exec postgres psql -U kyc_user -d kyc_db

# 创建测试订单
INSERT INTO kyc_order (
    id, order_id, buyer_name, buyer_email, 
    buyer_phone, shop_id, status
) VALUES (
    uuid_generate_v4(),
    'test-order-' || to_char(now(), 'YYYYMMDD-HH24MI'),
    'Test User',
    'test@example.com',
    '13800138000',
    'test-shop',
    'pending'
);

# 创建验证记录
INSERT INTO kyc_verification (
    id, order_id, verification_token, status
) VALUES (
    uuid_generate_v4(),
    (SELECT id FROM kyc_order ORDER BY created_at DESC LIMIT 1),
    'test-token-' || substr(md5(random()::text), 1, 32),
    'pending'
);

# 查看刚创建的数据
SELECT 
    o.id,
    o.order_id,
    o.buyer_email,
    v.verification_token,
    'https://kyc.317073.xyz/verify/' || v.verification_token as url
FROM kyc_order o
LEFT JOIN kyc_verification v ON o.id = v.order_id
ORDER BY o.created_at DESC
LIMIT 1;

\q
```

---

## 📝 验证成功的标志

如果看到以下情况，说明系统正常工作：

✅ **数据库有数据**
```
订单数量 > 0
验证记录 > 0
Token 不为空
```

✅ **可以访问验证页面**
```
curl https://kyc.317073.xyz/verify/{token}
返回 200 OK 和 HTML 内容
```

✅ **日志中有请求记录**
```
tail -f /var/log/nginx/access.log
看到 GET /verify/ 请求
```

✅ **Flask 应用正在处理请求**
```
docker-compose logs web
看到请求处理的日志
```

---

## 🎯 总结

验证 KYC 链接生成的步骤：

1. **检查容器运行状态** → `docker-compose ps`
2. **查看应用日志** → `docker-compose logs web`
3. **连接数据库** → `docker-compose exec postgres psql ...`
4. **查看数据库记录** → `SELECT * FROM kyc_verification`
5. **访问验证页面** → `curl https://kyc.317073.xyz/verify/{token}`
6. **查看 Nginx 日志** → `tail -f /var/log/nginx/access.log`

如果这些都正常，说明 KYC 验证链接生成系统已经完全工作了！ 🚀
