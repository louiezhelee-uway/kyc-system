# VPS 部署验证清单

## 快速验证步骤

在 VPS 上执行：

```bash
# 1. 进入项目目录
cd /path/to/kyc-system

# 2. 更新代码（如果有更新）
git pull origin main

# 3. 重启容器
docker-compose down
docker-compose up -d

# 4. 运行验证脚本
bash VPS_VERIFICATION_CHECK.sh
```

---

## 检查清单

### ✅ Docker 容器
- [ ] kyc_postgres 运行中（状态: Up）
- [ ] kyc_web 运行中（状态: Up）
- [ ] kyc_nginx 运行中（状态: Up）

### ✅ 数据库
- [ ] PostgreSQL 可连接（`docker exec kyc_postgres psql ...`）
- [ ] kyc_db 数据库存在
- [ ] 表已创建：order, verification, report

### ✅ Flask 应用
- [ ] 容器运行无错误（`docker logs kyc_web`）
- [ ] 端口 5000 监听中（`lsof -i :5000`）
- [ ] 健康检查通过：`curl http://localhost:5000/health`

### ✅ Nginx 反向代理
- [ ] 配置有效（`docker exec kyc_nginx nginx -t`）
- [ ] 端口 80 和 443 开放
- [ ] HTTPS 重定向工作（`curl -L http://kyc.317073.xyz`）

### ✅ SSL 证书
- [ ] 证书文件存在：`/etc/nginx/certs/`
- [ ] 证书有效期未过期（`openssl x509 -in cert.crt -noout -dates`）

### ✅ 环境变量
- [ ] SUMSUB_API_KEY 已设置
- [ ] DATABASE_URL 正确
- [ ] WEBHOOK_SECRET 已设置

---

## 问题排查

### 1. Flask 容器无法启动

**症状**: `docker ps` 中 kyc_web 显示 "Exited"

**检查日志**:
```bash
docker logs kyc_web
```

**常见原因**:
- `python run.py` 命令失败 → 检查 run.py 是否存在
- 数据库连接失败 → 检查 DATABASE_URL
- 依赖缺失 → 检查 requirements.txt

**修复**:
```bash
# 重新构建镜像
docker-compose build web --no-cache
docker-compose up -d web
```

### 2. PostgreSQL 无法连接

**症状**: Flask 日志显示 "could not connect to server"

**检查**:
```bash
# 进入 postgres 容器
docker exec -it kyc_postgres psql -U kyc_user -d kyc_db

# 或直接测试连接
docker exec kyc_postgres pg_isready -U kyc_user -h localhost
```

**修复**:
```bash
# 删除并重建数据库
docker-compose down -v
docker-compose up -d postgres
```

### 3. HTTPS 不工作

**症状**: 浏览器显示证书错误或无法连接 HTTPS

**检查证书**:
```bash
ls -la /path/to/certs/
openssl x509 -in cert.crt -noout -text
```

**修复**:
```bash
# 重新生成 Let's Encrypt 证书
sudo certbot renew --force-renewal
# 或手动续期
sudo certbot certonly --standalone -d kyc.317073.xyz
```

### 4. Nginx 配置错误

**症状**: Nginx 容器启动失败

**检查**:
```bash
docker exec kyc_nginx nginx -t
docker logs kyc_nginx
```

**修复**:
```bash
# 重新加载配置
docker exec kyc_nginx nginx -s reload
```

---

## 性能检查

```bash
# 查看容器资源使用
docker stats kyc_postgres kyc_web kyc_nginx

# 查看磁盘使用
du -sh /var/lib/docker/volumes/kyc_*

# 查看日志大小
du -sh /var/lib/docker/containers/*/
```

---

## 最终验证

如果以上所有检查都通过，执行：

```bash
# 测试 API 端点
curl -v https://kyc.317073.xyz/api/health

# 测试 Webhook
curl -X POST https://kyc.317073.xyz/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# 查看应用日志
docker logs -f kyc_web
```

---

**创建日期**: 2025-12-02  
**验证脚本**: VPS_VERIFICATION_CHECK.sh  
**关键信息**: VPS IP = 35.212.217.145, 域名 = kyc.317073.xyz
