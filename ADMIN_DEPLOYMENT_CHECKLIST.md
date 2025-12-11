# ✅ 管理后台部署检查清单

## 📋 部署前清单

在将代码部署到 VPS 前，请确保完成以下步骤：

### 1️⃣ 代码更新

- [ ] `app/routes/admin_manual.py` 已创建
- [ ] `app/templates/admin_manual.html` 已创建
- [ ] `app/templates/admin_login.html` 已创建
- [ ] `app/__init__.py` 已修改（注册 admin_manual 蓝图）
- [ ] `.env.admin` 示例文件已查看

### 2️⃣ 环境变量配置

在 VPS 上的 `.env` 文件中添加：

```bash
# 编辑 .env 文件
nano /opt/kyc-app/.env

# 添加以下行
ADMIN_SECRET_KEY=your-super-secret-key-only-you-know
```

**选择一个强密钥的建议：**

```bash
# 使用 Python 生成随机密钥
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# 或使用 OpenSSL
openssl rand -base64 32
```

**示例强密钥：**
```
ADMIN_SECRET_KEY=7bF4kL9mN2pQr5wXyZa3cB6dE8fG1hI0jK2lM4nO6p
```

### 3️⃣ VPS 部署

```bash
# 登录 VPS
ssh user@kyc.317073.xyz

# 进入项目目录
cd /opt/kyc-app

# 拉取最新代码
git pull origin main

# 停止现有容器
docker-compose down

# 启动新容器
docker-compose up -d

# 检查日志
docker-compose logs -f web | head -20
```

**预期输出：**
```
✅ admin_manual 蓝图已注册 (隐秘管理后台)
```

### 4️⃣ 功能测试

#### 测试 1：访问管理后台

```bash
# 打开浏览器访问
https://kyc.317073.xyz/admin-manual/

# 预期：看到登录界面
# 输入你设置的 ADMIN_SECRET_KEY
# 预期：进入管理后台（如果密钥正确）
```

#### 测试 2：生成验证链接

```bash
# 在管理后台中：
# 1. 填入测试用户号和订单号
# 2. 点击"生成链接"
# 3. 应该收到验证链接和令牌

# 或用 curl 测试：
curl -X POST https://kyc.317073.xyz/admin-manual/generate-link \
  -H "Content-Type: application/json" \
  -H "X-Admin-Key: your-secret-key" \
  -d '{
    "user_id": "test_user_001",
    "order_id": "test_order_001"
  }'

# 预期：HTTP 201，返回验证链接
```

#### 测试 3：查询状态

```bash
curl -X POST https://kyc.317073.xyz/admin-manual/check-status \
  -H "Content-Type: application/json" \
  -H "X-Admin-Key: your-secret-key" \
  -d '{"order_id": "test_order_001"}'

# 预期：HTTP 200，返回验证状态
```

#### 测试 4：完整流程

1. 生成链接 → 获得验证链接和令牌
2. 用令牌访问验证页面：`https://kyc.317073.xyz/verify/{token}`
3. 完成模拟认证（或在 Sumsub 控制台手动批准）
4. 回到管理后台，查询订单状态
5. 应该看到状态为 "已通过"，并有报告下载链接

---

## 🔒 安全检查

- [ ] `ADMIN_SECRET_KEY` 已设置为强密钥
- [ ] `.env` 文件已添加到 `.gitignore`
- [ ] 密钥没有保存在代码中
- [ ] HTTPS 已启用（kyc.317073.xyz）
- [ ] 只有你知道管理后台密钥

---

## 📊 监控和维护

### 查看日志

```bash
# 查看最近 50 行日志
docker-compose logs -n 50 web

# 实时查看日志
docker-compose logs -f web

# 搜索特定日志
docker-compose logs web | grep -i "admin"
```

### 查看已生成的订单

```bash
# 连接数据库
docker-compose exec db psql -U kyc_user -d kyc_db

# 查询手动创建的订单
SELECT * FROM orders WHERE source = 'manual_admin' ORDER BY created_at DESC LIMIT 10;

# 查询对应的验证记录
SELECT * FROM verifications WHERE order_id = {order_id};
```

### 重启应用

```bash
docker-compose restart web
```

---

## 🆘 故障排除

### 问题 1：无法访问管理后台

**症状：** 403 或 401 错误

**解决：**
```bash
# 检查环境变量是否设置
docker-compose exec web env | grep ADMIN_SECRET_KEY

# 重启容器
docker-compose restart web

# 检查日志
docker-compose logs -f web
```

### 问题 2：密钥错误

**症状：** "密钥错误" 提示

**解决：**
1. 确认 `.env` 中的 `ADMIN_SECRET_KEY` 值
2. 确保没有多余的空格或换行
3. 重新启动容器后重试

### 问题 3：无法生成验证链接

**症状：** "生成验证链接失败" 错误

**解决：**
```bash
# 检查 Sumsub 凭证是否正确
docker-compose exec web python3
>>> from app import create_app
>>> app = create_app()
>>> from app.services.sumsub_service import SumsubService
>>> svc = SumsubService()
>>> print("✅ Sumsub 服务初始化成功")

# 检查数据库连接
>>> from app import db
>>> db.session.execute("SELECT 1")
>>> print("✅ 数据库连接成功")
```

### 问题 4：报告无法下载

**症状：** "报告生成中" 或 404 错误

**解决：**
```bash
# 检查报告存储目录
docker-compose exec web ls -lah /opt/kyc-app/reports/sumsub/

# 检查文件权限
docker-compose exec web chmod -R 755 /opt/kyc-app/reports/sumsub/

# 重新查询状态
# 等待 1-5 秒后再查询一次
```

---

## 📈 性能监控

### 监控容器资源

```bash
docker stats kyc-web
```

### 查看数据库大小

```bash
docker-compose exec db psql -U kyc_user -d kyc_db -c \
  "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema') ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
```

### 清理报告文件（定期）

```bash
# 删除超过 30 天的报告
find /opt/kyc-app/reports/sumsub/ -mtime +30 -delete

# 创建 cron 定时任务
(crontab -l 2>/dev/null; echo "0 2 * * * find /opt/kyc-app/reports/sumsub/ -mtime +30 -delete") | crontab -
```

---

## ✅ 部署完成检查表

部署完成后，确认以下所有项都能工作：

- [ ] 管理后台能成功登录
- [ ] 能生成验证链接
- [ ] 生成的链接能在验证页面打开
- [ ] 能查询验证状态
- [ ] 验证完成后能看到报告链接
- [ ] 报告链接能下载
- [ ] 日志中没有错误
- [ ] 性能正常（无内存泄漏）

---

## 📞 获取支持

如遇到问题，检查以下内容：

1. **查看日志**：`docker-compose logs web | grep -i error`
2. **检查配置**：`docker-compose exec web env | grep ADMIN`
3. **测试连接**：使用 curl 命令测试 API
4. **重启应用**：`docker-compose restart`

---

**版本：** 1.0  
**最后更新：** 2025-12-10
