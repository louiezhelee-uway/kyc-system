# VPS 环境配置错误诊断报告

## 🔴 发现的问题

### 1. **关键问题: DATABASE_URL 配置错误**

**当前配置（❌ 错误）：**
```bash
DATABASE_URL=postgresql://kyc_user:kyc_password@localhost:5432/kyc_db
```

**正确配置（✅）：**
```bash
DATABASE_URL=postgresql://kyc_user:kyc_password@postgres:5432/kyc_db
```

**原因：**
- Flask 应用运行在 Docker 容器内
- 容器内的 `localhost` 指向容器自己，而不是另一个容器
- 应该使用 Docker Compose 中定义的服务名 `postgres`

---

### 2. **FLASK_ENV 生产配置**

**当前配置（⚠️ 开发模式）：**
```bash
FLASK_ENV=development
FLASK_DEBUG=1
```

**正确配置（✅ 生产模式）：**
```bash
FLASK_ENV=production
FLASK_DEBUG=0
```

**原因：**
- VPS 是生产环境，不应该启用 Debug 模式
- Debug 模式会暴露敏感信息

---

### 3. **APP_DOMAIN 配置**

**当前配置（❌ localhost）：**
```bash
APP_DOMAIN=http://localhost:5000
```

**正确配置（✅ 实际域名）：**
```bash
APP_DOMAIN=https://kyc.317073.xyz
```

**原因：**
- 某些地方会使用 APP_DOMAIN 生成链接
- 应该使用实际的生产域名和 HTTPS

---

### 4. **容器命名不一致**

**发现的问题：**
```
CONTAINER ID   NAMES             STATUS
825f59e5503e   bold_goldwasser   Exited (1)
cff6bc541795   zealous_carson    Exited (1)
```

**预期容器名：**
```
kyc_postgres
kyc_web
kyc_nginx
```

**原因：**
- Docker 给了随机名称，说明不是通过 docker-compose.yml 定义的
- 可能是手动运行 `docker run` 创建的，或者之前的部署遗留
- 这些容器会干扰当前的 docker-compose 部署

---

### 5. **旧部署的卷（Volume）**

**发现的问题：**
```
local     kyc-app_postgres_data        # 旧部署
local     kyc-system_postgres_data     # 另一个旧部署
```

**影响：**
- 可能有旧数据库数据
- 可能导致冲突

**解决方案：**
- 删除旧的孤立卷
- 让 docker-compose 创建新的、命名正确的卷

---

## ✅ 修复方案

### 自动修复（推荐）
```bash
bash VPS_COMPLETE_FIX.sh
```

这个脚本会自动：
1. 备份现有的 .env
2. 停止所有容器
3. 清理 orphaned 容器和卷
4. 生成正确的 .env 文件
5. 拉取最新代码
6. 构建并启动容器
7. 初始化数据库

### 手动修复

如果你想手动修复：

#### Step 1: 停止容器
```bash
docker-compose down
docker ps -a | grep -E "(bold_|zealous_)" | awk '{print $1}' | xargs docker rm -f
```

#### Step 2: 修复 .env
```bash
cat > .env << 'EOF'
FLASK_ENV=production
FLASK_APP=run.py
FLASK_DEBUG=0
DATABASE_URL=postgresql://kyc_user:kyc_password@postgres:5432/kyc_db
SUMSUB_APP_TOKEN=prd:1b15gKkFtPh440hQSOXIvjR3.OSJVLkmtJfnWVPS7IpuKCI2Tas4giOCO
SUMSUB_SECRET_KEY=CTHMPDlqphQmvB2fqBC7b6wF5v9iyqoK
SUMSUB_API_URL=https://api.sumsub.com
WEBHOOK_SECRET=your-webhook-secret-key-here
TAOBAO_WEBHOOK_SECRET=your-taobao-webhook-secret-here
APP_DOMAIN=https://kyc.317073.xyz
PYTHONUNBUFFERED=1
EOF
```

#### Step 3: 启动容器
```bash
git pull origin main
docker-compose build --no-cache web
docker-compose up -d
```

#### Step 4: 初始化数据库
```bash
sleep 10  # 等待数据库就绪
docker exec kyc_web python -c "from app import create_app, db; \
with create_app().app_context(): db.create_all()"
```

---

## 🧪 验证修复

修复后运行：

```bash
# 检查容器
docker ps -a

# 预期输出：
# NAMES                  STATUS
# kyc_postgres          Up 2 minutes (healthy)
# kyc_web               Up 1 minute
# kyc_nginx             Up 1 minute

# 测试数据库连接
docker exec kyc_postgres psql -U kyc_user -d kyc_db -c "SELECT 1;"

# 测试 Flask 应用
curl http://localhost:5000/health

# 完整验证
bash VPS_VERIFICATION_CHECK.sh
```

---

## 📋 修复前后对比

| 项目 | 修复前 | 修复后 |
|------|--------|--------|
| DATABASE_URL | `localhost:5432` ❌ | `postgres:5432` ✅ |
| FLASK_ENV | `development` ⚠️ | `production` ✅ |
| FLASK_DEBUG | `1` ⚠️ | `0` ✅ |
| APP_DOMAIN | `localhost:5000` ❌ | `kyc.317073.xyz` ✅ |
| 容器名称 | `bold_goldwasser` ❌ | `kyc_web` ✅ |
| 容器状态 | `Exited (1)` ❌ | `Up` ✅ |

---

## 💡 为什么容器启动失败

容器失败的原因是 `DATABASE_URL` 指向 `localhost`，但 Flask 应用无法连接到同一个容器的 localhost（它是一个单独的进程）。

**Docker 网络架构：**
```
┌────────────────────────────────────┐
│       Docker 网络 (kyc_network)    │
├────────────────────────────────────┤
│                                    │
│  ┌─────────────────┐   ┌────────┐ │
│  │   kyc_postgres  │   │kyc_web │ │
│  │   :5432         │   │:5000   │ │
│  └─────────────────┘   └────────┘ │
│                                    │
│  kyc_web 要连接 kyc_postgres：    │
│  ❌ localhost:5432 → 连不上        │
│  ✅ postgres:5432 → 连接成功       │
│                                    │
└────────────────────────────────────┘
```

---

## 🚀 推荐操作顺序

```bash
# 1. 进入项目目录
cd /path/to/kyc-system

# 2. 运行修复脚本
bash VPS_COMPLETE_FIX.sh

# 3. 等待 30 秒让容器完全启动
sleep 30

# 4. 验证部署
bash VPS_VERIFICATION_CHECK.sh

# 5. 查看日志
docker-compose logs -f
```

---

**诊断日期**: 2025-12-02  
**VPS IP**: 35.212.217.145  
**域名**: kyc.317073.xyz  
**Docker Compose 版本**: 1.29.2
