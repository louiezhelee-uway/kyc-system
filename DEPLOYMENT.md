# 🚀 完整部署指南

## 📦 已创建的脚本

| 脚本 | 大小 | 说明 |
|------|------|------|
| `quick-start.sh` | 1.9K | 快速启动（1 条命令启动所有服务） |
| `start-docker.sh` | 8.2K | 完整的 Docker 管理工具 |
| `docker-entrypoint.sh` | 1.0K | 容器启动脚本 |
| `deploy-vps.sh` | 6.2K | VPS 一键部署脚本 |
| `Makefile` | - | Make 命令快捷方式 |

---

## 🎯 三种使用方式

### 方式 1️⃣ : 最快开始 (30 秒)

```bash
cd Project_KYC
./quick-start.sh
```

就这么简单！打开 http://localhost 即可访问。

---

### 方式 2️⃣ : 高级管理 (推荐)

使用完整的管理脚本：

```bash
./start-docker.sh help          # 查看所有命令
./start-docker.sh start         # 启动
./start-docker.sh logs          # 查看日志
./start-docker.sh shell         # 进入容器
./start-docker.sh db backup     # 备份数据库
./start-docker.sh stop          # 停止
```

---

### 方式 3️⃣ : Make 命令

```bash
make help                # 查看所有命令
make start              # 启动
make logs               # 查看日志
make shell              # 进入容器
make db-backup          # 备份
make stop               # 停止
```

---

## 🌍 本地开发 vs 生产部署

### 本地开发环境

```bash
# 1. 配置环境
cp .env.docker .env
# 编辑 .env，填入测试值

# 2. 启动
./quick-start.sh

# 3. 访问
# 本地: http://localhost
# 数据库: localhost:5432
# 容器: docker-compose ps
```

### VPS 生产环境

```bash
# 在 VPS 上执行
sudo bash deploy-vps.sh

# 这将:
# ✅ 更新系统
# ✅ 安装 Docker
# ✅ 克隆代码
# ✅ 配置 SSL
# ✅ 启动服务
# ✅ 配置备份
```

---

## 📝 快速参考

### 启动服务

```bash
# 快速启动
./quick-start.sh

# 或
./start-docker.sh start

# 或
make start

# 或
docker-compose up -d
```

### 查看状态

```bash
# 查看运行中的容器
docker-compose ps

# 查看详细信息
./start-docker.sh test

# 查看日志
./start-docker.sh logs
make logs
```

### 停止服务

```bash
./start-docker.sh stop
make stop
docker-compose down
```

### 进入容器

```bash
# Flask 容器
./start-docker.sh shell
make shell

# 数据库
./start-docker.sh db shell
make db-shell
```

### 备份数据

```bash
# 备份
./start-docker.sh db backup
make db-backup

# 恢复
./start-docker.sh db restore backups/backup_20251125_120000.sql
```

---

## 🔧 环境配置

### 本地开发 (.env 示例)

```env
FLASK_ENV=development
DATABASE_URL=postgresql://kyc_user:kyc_password@localhost:5432/kyc_db
SUMSUB_API_KEY=test-key
WEBHOOK_SECRET=test-secret
SECRET_KEY=dev-key
```

### VPS 生产 (.env 示例)

```env
FLASK_ENV=production
DATABASE_URL=postgresql://kyc_user:secure_password@postgres:5432/kyc_db
SUMSUB_API_KEY=your-real-api-key
WEBHOOK_SECRET=your-real-webhook-secret
SECRET_KEY=your-real-secret-key
```

---

## 📊 容器架构

```
┌─────────────────────────────────────┐
│         Nginx (80/443)              │
│      反向代理 + HTTPS               │
├─────────────────────────────────────┤
│      Flask Application              │
│  • Webhook 接收                     │
│  • KYC 链接生成                     │
│  • 报告生成                         │
├─────────────────────────────────────┤
│      PostgreSQL Database            │
│  • 订单存储                         │
│  • 验证记录                         │
│  • 报告数据                         │
└─────────────────────────────────────┘
```

---

## 🚨 常见问题

### Q: 如何更改端口？

编辑 `docker-compose.yml`:
```yaml
nginx:
  ports:
    - "8080:80"    # 改为 8080
```

### Q: 如何启用 HTTPS？

1. 获取 SSL 证书（Let's Encrypt）
2. 编辑 `nginx.conf` 启用 HTTPS 部分
3. 重启 Nginx

### Q: 数据库连接失败？

```bash
# 查看数据库日志
docker-compose logs postgres

# 重启数据库
docker-compose restart postgres

# 进入数据库
./start-docker.sh db shell
```

### Q: 如何备份数据？

```bash
# 备份到 backups/ 目录
./start-docker.sh db backup

# 或使用 Make
make db-backup
```

---

## 🔐 安全建议

### 生产环境必做

- [ ] 更改 `SECRET_KEY` 为强随机密钥
- [ ] 更改数据库密码
- [ ] 启用 HTTPS（Let's Encrypt）
- [ ] 配置防火墙
- [ ] 定期备份数据
- [ ] 监控日志
- [ ] 配置 Webhook 秘密

### 备份计划

```bash
# 自动每天凌晨 2 点备份
0 2 * * * /opt/kyc-app/backup.sh

# 保留 7 天的备份
find backups -name "backup_*.sql" -mtime +7 -delete
```

---

## 📱 访问地址

| 服务 | 本地 | VPS |
|------|------|-----|
| 网页 | http://localhost | https://your-domain.com |
| API | http://localhost/api | https://your-domain.com/api |
| 数据库 | localhost:5432 | 容器内部:5432 |

---

## 🎓 学习资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Flask 文档](https://flask.palletsprojects.com/)
- [PostgreSQL 文档](https://www.postgresql.org/docs/)
- [Nginx 文档](https://nginx.org/en/docs/)

---

## 💡 最佳实践

1. **使用脚本管理**
   - 所有操作都通过脚本完成
   - 避免手动修改配置

2. **定期备份**
   - 每天自动备份
   - 保留 7-30 天的历史备份

3. **监控日志**
   - 定期检查应用日志
   - 设置告警

4. **更新依赖**
   - 定期更新 Docker 镜像
   - 检查安全补丁

5. **文档维护**
   - 记录所有配置变更
   - 保存部署文档

---

## 🎯 下一步

### 本地开发
```bash
./quick-start.sh              # 启动
./start-docker.sh logs        # 查看日志
# 开发...
./start-docker.sh stop        # 停止
```

### 部署到 VPS
```bash
# 在 VPS 上
sudo bash deploy-vps.sh       # 一键部署
# 完成！
```

---

**创建时间**: 2025-11-25
**更新时间**: 2025-11-25
**维护者**: KYC Team
