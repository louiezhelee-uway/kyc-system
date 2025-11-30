# 生产部署指南

## 📋 前置要求

### 本地环境
- Python 3.11+
- Docker & Docker Compose
- Git
- Sumsub API 凭证 ✅ (已获得)

### 服务器要求
- Linux (Ubuntu 20.04+ 推荐)
- 2GB RAM 最少
- 10GB 存储空间
- 开放端口: 80, 443
- 互联网连接

---

## 🚀 本地测试 (5分钟)

### 1. 启动应用
```bash
cd /Users/louie/Library/Mobile\ Documents/com~apple~CloudDocs/Documents/project\ X/Project_KYC

./quick-start.sh
```

### 2. 验证运行
```bash
# 检查容器状态
docker-compose ps

# 应该显示:
# web        - running
# db         - running
# nginx      - running
```

### 3. 测试 API
```bash
# 测试主页
curl http://localhost:5000

# 测试 Webhook
curl -X POST http://localhost:5000/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "test_001",
    "buyer_name": "Test",
    "buyer_email": "test@example.com",
    "buyer_phone": "13800138000",
    "order_amount": 99.99
  }'
```

### 4. 运行测试
```bash
python3 tests/test_full_integration.py
```

---

## 🌐 部署到 VPS (10分钟)

### 方法 1: 自动化部署 (推荐)

```bash
# 使用部署脚本
./deploy-vps.sh <你的VPS_IP地址>

# 例如:
./deploy-vps.sh 192.168.1.100
```

脚本会自动:
- ✅ 更新系统包
- ✅ 安装 Docker 和 Docker Compose
- ✅ 克隆项目
- ✅ 生成 SSL 证书 (Let's Encrypt)
- ✅ 启动服务
- ✅ 配置自动备份

### 方法 2: 手动部署

#### 1. 连接到 VPS
```bash
ssh root@<你的VPS_IP>
```

#### 2. 更新系统
```bash
apt update && apt upgrade -y
apt install -y git curl docker.io docker-compose
systemctl start docker
systemctl enable docker
```

#### 3. 克隆项目
```bash
cd /opt
git clone https://github.com/你的账户/Project_KYC.git
cd Project_KYC
```

#### 4. 配置环境
```bash
# 复制环境配置
cp .env.docker .env

# 编辑 .env 文件
nano .env

# 需要修改的部分:
# DATABASE_URL=postgresql://kyc_user:kyc_password@db:5432/kyc_db
# APP_DOMAIN=https://你的域名.com
```

#### 5. 配置 SSL 证书 (Let's Encrypt)
```bash
# 安装 Certbot
apt install -y certbot python3-certbot-nginx

# 生成证书
certbot certonly --standalone -d 你的域名.com

# 证书路径:
# /etc/letsencrypt/live/你的域名.com/fullchain.pem
# /etc/letsencrypt/live/你的域名.com/privkey.pem
```

#### 6. 更新 Nginx 配置
```bash
# 编辑 nginx.conf
nano app/nginx.conf

# 取消注释 HTTPS 部分，添加证书路径:
# ssl_certificate /etc/letsencrypt/live/你的域名.com/fullchain.pem;
# ssl_certificate_key /etc/letsencrypt/live/你的域名.com/privkey.pem;
```

#### 7. 启动应用
```bash
docker-compose up -d

# 查看日志
docker-compose logs -f web
```

#### 8. 配置自动更新证书
```bash
# 添加到 crontab
crontab -e

# 添加以下行 (每月初 1 号凌晨 2 点)
0 2 1 * * certbot renew --quiet
```

---

## 📊 配置淘宝/闲鱼 Webhook

### 1. 获取 Webhook URL
部署完成后，你的 Webhook URL 是:
```
https://你的域名.com/webhook/taobao/order
```

### 2. 在淘宝后台配置
1. 登录淘宝开放平台
2. 进入应用管理
3. 配置 Webhook
4. 设置回调 URL
5. 配置 Secret Key (与 WEBHOOK_SECRET 相同)
6. 订阅事件: 订单成交

### 3. 验证配置
```bash
# 测试 Webhook
curl -X POST https://你的域名.com/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d '{"order_id":"test","buyer_name":"Test","buyer_email":"test@example.com","buyer_phone":"13800138000","order_amount":99.99}'
```

---

## 🔒 安全配置

### 1. 防火墙规则
```bash
# 允许 HTTP
ufw allow 80/tcp

# 允许 HTTPS
ufw allow 443/tcp

# 允许 SSH (可选)
ufw allow 22/tcp

# 启用防火墙
ufw enable
```

### 2. 环境变量保护
```bash
# 修改权限
chmod 600 .env
chmod 600 .env.docker

# 从版本控制中排除
echo ".env" >> .gitignore
echo ".env.docker" >> .gitignore
```

### 3. 数据库备份
```bash
# 创建备份目录
mkdir -p /backups

# 添加备份脚本到 crontab (每天凌晨 3 点)
0 3 * * * docker-compose exec db pg_dump -U kyc_user kyc_db > /backups/kyc_db_$(date +\%Y\%m\%d).sql
```

### 4. 日志轮转
```bash
# 配置 logrotate
cat > /etc/logrotate.d/kyc-system <<EOF
/var/log/kyc-system/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
}
EOF
```

---

## 📈 监控和维护

### 1. 查看容器状态
```bash
# 实时监控
docker stats

# 查看日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f web
```

### 2. 性能监控
```bash
# 检查磁盘空间
df -h

# 检查内存使用
free -h

# 检查 CPU 使用
top
```

### 3. 数据库维护
```bash
# 连接到数据库
docker-compose exec db psql -U kyc_user -d kyc_db

# 查看表
\dt

# 查看行数
SELECT COUNT(*) FROM orders;

# 优化表
VACUUM ANALYZE;
```

### 4. 自动健康检查
```bash
# 创建健康检查脚本
cat > /usr/local/bin/check-kyc.sh <<EOF
#!/bin/bash
curl -f http://localhost:5000 || exit 1
EOF

# 添加到 crontab (每 5 分钟检查一次)
*/5 * * * * /usr/local/bin/check-kyc.sh || systemctl restart docker
```

---

## 🔄 持续部署

### 1. 自动更新
```bash
# 创建更新脚本
cat > /usr/local/bin/update-kyc.sh <<EOF
#!/bin/bash
cd /opt/Project_KYC
git pull origin main
docker-compose down
docker-compose up -d
EOF

# 设置定时任务 (每周日凌晨 1 点)
0 1 * * 0 /usr/local/bin/update-kyc.sh
```

### 2. 版本管理
```bash
# 标记版本
git tag -a v1.0.0 -m "Production release"
git push origin v1.0.0

# 检查版本
git describe --tags
```

---

## ⚠️ 故障排除

### 问题 1: 容器无法启动
```bash
# 查看错误日志
docker-compose logs web

# 检查端口占用
lsof -i :5000
lsof -i :5432
lsof -i :80

# 重启服务
docker-compose restart
```

### 问题 2: 数据库连接失败
```bash
# 检查 PostgreSQL 容器
docker-compose ps db

# 查看数据库日志
docker-compose logs db

# 重建数据库
docker-compose down
docker volume rm project_kyc_db_data
docker-compose up -d
```

### 问题 3: Webhook 不触发
```bash
# 查看 Nginx 日志
docker-compose exec nginx cat /var/log/nginx/access.log

# 查看应用日志
docker-compose logs web

# 测试 Webhook 端点
curl -v -X POST https://你的域名.com/webhook/taobao/order
```

### 问题 4: SSL 证书过期
```bash
# 检查证书
certbot certificates

# 手动更新
certbot renew --force-renewal

# 重启 Nginx
docker-compose restart nginx
```

---

## 📊 性能优化

### 1. 数据库优化
```sql
-- 创建索引
CREATE INDEX idx_order_taobao_id ON orders(taobao_order_id);
CREATE INDEX idx_verification_applicant ON verifications(sumsub_applicant_id);
CREATE INDEX idx_verification_status ON verifications(status);
```

### 2. 缓存配置 (可选)
```bash
# 安装 Redis
apt install -y redis-server

# 在应用中启用缓存
export REDIS_URL=redis://localhost:6379
```

### 3. Gunicorn 优化
```bash
# 修改 gunicorn 配置
# workers = CPU核数 * 2 + 1
workers = 5

# 修改 docker-entrypoint.sh
gunicorn --workers 5 --worker-class sync --bind 0.0.0.0:5000 run:app
```

---

## 🎯 生产检查清单

部署前请确认:

- [ ] 环境变量已配置 (.env 文件)
- [ ] Sumsub API 凭证正确
- [ ] SSL 证书已安装
- [ ] 防火墙规则已配置
- [ ] 数据库备份已配置
- [ ] Webhook URL 已配置到淘宝后台
- [ ] 日志轮转已配置
- [ ] 监控告警已设置
- [ ] 域名 DNS 已指向 VPS IP
- [ ] 应用测试通过
- [ ] 数据库备份可恢复
- [ ] 所有敏感信息已隐藏

---

## 📞 支持信息

### 快速命令参考
```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 查看日志
docker-compose logs -f web

# 进入容器
docker-compose exec web bash

# 备份数据库
docker-compose exec db pg_dump -U kyc_user kyc_db > backup.sql

# 恢复数据库
docker-compose exec db psql -U kyc_user kyc_db < backup.sql
```

### 常用 URL
```
应用访问: https://你的域名.com
Webhook URL: https://你的域名.com/webhook/taobao/order
API 文档: https://你的域名.com/docs (如果启用)
管理面板: https://你的域名.com/admin (如果启用)
```

### 日志位置
```
应用日志: docker-compose logs web
数据库日志: docker-compose logs db
Nginx 日志: docker-compose exec nginx cat /var/log/nginx/access.log
系统日志: docker logs <container_id>
```

---

## 📖 相关文档

- [快速启动](QUICK_START.md)
- [Sumsub 集成](SUMSUB_INTEGRATION.md)
- [Docker 使用](DOCKER.md)
- [集成完成清单](CHECKLIST.md)

---

**最后更新**: 2025-11-25  
**部署版本**: v1.0.0 生产就绪
