# 🐳 Docker 快速启动指南

## 快速开始 (30 秒)

### 最简单的方式

```bash
chmod +x quick-start.sh
./quick-start.sh
```

完成！系统已在 http://localhost 上运行。

---

## 详细步骤

### 1️⃣ 准备环境

```bash
# 确保已安装 Docker 和 Docker Compose
docker --version
docker-compose --version
```

### 2️⃣ 配置环境变量

```bash
# 复制配置文件
cp .env.docker .env

# 编辑 .env，填入实际值
nano .env  # 或用你喜欢的编辑器
```

**必须配置的项:**
```env
SUMSUB_API_KEY=your-actual-key
WEBHOOK_SECRET=your-webhook-secret
SECRET_KEY=your-secret-key
```

### 3️⃣ 启动服务

**方式 A: 使用脚本（推荐）**
```bash
./start-docker.sh start
```

**方式 B: 使用 Makefile**
```bash
make start
```

**方式 C: 直接使用 Docker Compose**
```bash
docker-compose up -d
```

### 4️⃣ 验证服务

```bash
# 查看运行中的容器
docker-compose ps

# 查看日志
docker-compose logs -f web

# 测试应用
curl http://localhost/health
```

---

## 📋 常用命令

### 启动/停止

```bash
# 启动
./start-docker.sh start
# 或
make start

# 停止
./start-docker.sh stop
# 或
make stop

# 重启
./start-docker.sh restart
# 或
make restart
```

### 查看日志

```bash
# 所有服务日志
./start-docker.sh logs

# 仅 Flask 日志
./start-docker.sh logs web
./start-docker.sh logs web

# 仅数据库日志
./start-docker.sh logs postgres

# 仅 Nginx 日志
./start-docker.sh logs nginx

# 实时监控
make logs
```

### 进入容器

```bash
# 进入 Flask 容器
./start-docker.sh shell
# 或
make shell
# 或
docker-compose exec web bash

# 进入数据库容器
./start-docker.sh db shell
# 或
make db-shell
# 或
docker-compose exec postgres psql -U kyc_user -d kyc_db
```

### 数据库操作

```bash
# 备份数据库
./start-docker.sh db backup
# 或
make db-backup

# 恢复数据库
./start-docker.sh db restore backups/backup_20251125_120000.sql

# 访问数据库 CLI
./start-docker.sh db shell
```

### 系统信息

```bash
# 查看容器状态
./start-docker.sh test
# 或
make ps

# 查看系统资源使用
docker stats

# 查看网络
docker network ls
docker network inspect kyc_project_kyc_network
```

---

## 🔧 高级用法

### 构建自己的镜像

```bash
# 构建所有镜像
docker-compose build

# 构建特定服务
docker-compose build web

# 不使用缓存构建
docker-compose build --no-cache
```

### 清理资源

```bash
# 删除容器（保留数据）
docker-compose down

# 删除容器、卷和镜像
./start-docker.sh clean
# 或
make clean

# 删除所有 Docker 资源
docker system prune -a --volumes
```

### 更改端口

如果 80 或 443 端口被占用，编辑 `docker-compose.yml`：

```yaml
services:
  nginx:
    ports:
      - "8080:80"      # 改为 8080
      - "8443:443"     # 改为 8443
```

然后访问 http://localhost:8080

### 环境变量

所有环境变量都在 `.env` 文件中配置。常用变量：

```env
# Flask
FLASK_ENV=production          # 或 development
SECRET_KEY=your-secret-key

# 数据库
DATABASE_URL=postgresql://...

# Sumsub
SUMSUB_API_KEY=your-key
SUMSUB_API_URL=https://api.sumsub.com

# Webhook
WEBHOOK_SECRET=your-secret

# 服务
HOST=0.0.0.0
PORT=5000
```

---

## 🚀 访问地址

- **Web 应用**: http://localhost
- **API 接口**: http://localhost/api
- **数据库**: localhost:5432
- **日志**: 查看 `docker-compose logs`

---

## 🐛 常见问题

### 端口被占用

```bash
# 查看占用的端口
lsof -i :5000    # Flask
lsof -i :5432    # PostgreSQL
lsof -i :80      # Nginx

# 杀死进程
kill -9 <PID>
```

### 数据库连接失败

```bash
# 检查 PostgreSQL 状态
docker-compose exec postgres pg_isready -U kyc_user

# 查看数据库日志
docker-compose logs postgres

# 重启数据库
docker-compose restart postgres
```

### 应用崩溃

```bash
# 查看完整错误
docker-compose logs web --tail=100

# 重启应用
docker-compose restart web

# 进入容器调试
docker-compose exec web bash
```

### 权限问题

```bash
# 确保脚本可执行
chmod +x *.sh

# 以 sudo 运行 Docker（如果需要）
sudo docker-compose up -d
```

---

## 📊 Docker 文件说明

| 文件 | 说明 |
|------|------|
| `docker-compose.yml` | 容器编排配置 |
| `Dockerfile` | 应用镜像定义 |
| `docker-entrypoint.sh` | 容器启动脚本 |
| `start-docker.sh` | 完整的 Docker 管理脚本 |
| `quick-start.sh` | 快速启动脚本 |
| `Makefile` | Make 命令快捷方式 |
| `nginx.conf` | Nginx 配置 |
| `.env.docker` | Docker 环境变量示例 |

---

## 🔒 生产部署

对于 VPS 部署，请遵循以下步骤：

1. **购买域名** 并配置 DNS
2. **生成 SSL 证书** (Let's Encrypt)
   ```bash
   certbot certonly --standalone -d your-domain.com
   ```
3. **编辑 nginx.conf** 启用 HTTPS
4. **更新 docker-compose.yml** 证书路径
5. **部署到 VPS**
   ```bash
   git clone <repo>
   cd Project_KYC
   cp .env.docker .env
   # 编辑 .env
   ./quick-start.sh
   ```

---

## 📞 获取帮助

```bash
# 查看所有可用命令
./start-docker.sh help
# 或
make help

# 查看 Docker Compose 文档
docker-compose help

# 查看项目文档
cat DOCKER.md
```

---

**开发时间**: 2025-11-25
**最后更新**: 2025-11-25
