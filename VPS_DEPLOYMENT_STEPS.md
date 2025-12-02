# VPS 部署执行步骤 - 一步步指南

## 🎯 目标
在 Google Cloud VPS 上完整部署 KYC 系统，使用双 Nginx 架构：
- 旧服务保持运行在端口 80（317073.xyz）
- 新服务运行在 Docker，通过系统 Nginx 反向代理到 kyc.317073.xyz

---

## 📋 准备工作清单

在开始前，请确认：
- ✅ 已有 Google Cloud 账户和项目
- ✅ 已安装 gcloud CLI
- ✅ 已创建 VPS 实例（kyc-app）
- ✅ VPS IP 地址：**35.212.217.145**
- ✅ 已配置 DNS：kyc.317073.xyz → 35.212.217.145

---

## 🚀 执行步骤（3 个阶段）

### 阶段 1️⃣：连接到 VPS

```bash
# 在您的 Mac 上执行
gcloud compute ssh kyc-app --zone=asia-east1-a
```

**预期输出**：
```
Welcome to Ubuntu 22.04.1 LTS (GNU/Linux 5.15.0-1021-gcp x86_64)
...
louie@kyc-app:~$
```

成功连接后，您会进入 VPS 的命令行。

---

### 阶段 2️⃣：克隆/更新代码

```bash
# 切换到 root 用户（简化权限管理）
sudo su -

# 创建应用目录
mkdir -p /opt/kyc-app

# 如果这是第一次部署
cd /opt
git clone https://github.com/louiezhelee-uway/kyc-system.git kyc-app
cd kyc-app

# 如果已经克隆过，更新到最新版本
cd /opt/kyc-app
git pull origin main
```

**验证代码已更新**：
```bash
# 检查关键文件是否存在
ls -la deploy-kyc-nginx.sh
ls -la docker-compose.yml
ls -la kyc-nginx-config.conf

# 应该看到：
# -rwxr-xr-x  deploy-kyc-nginx.sh
# -rw-r--r--  docker-compose.yml
# -rw-r--r--  kyc-nginx-config.conf
```

---

### 阶段 3️⃣：自动部署（一键执行）

```bash
# 确保还在 /opt/kyc-app 目录
cd /opt/kyc-app

# 确保脚本有执行权限
chmod +x deploy-kyc-nginx.sh

# 运行部署脚本
bash deploy-kyc-nginx.sh
```

**脚本会自动执行**：
1. ✅ 检查目录结构
2. ✅ 复制 Nginx 配置到 `/etc/nginx/sites-available/kyc`
3. ✅ 创建符号链接到 `/etc/nginx/sites-enabled/kyc`
4. ✅ 测试 Nginx 配置语法
5. ✅ 重启 Nginx 服务
6. ✅ 启动 Docker 容器
7. ✅ 验证所有服务运行

**脚本完成后的输出应该包含**：
```
✨ 部署完成！
════════════════════════════════════════════════════════════
📍 架构说明:
   旧服务: http://317073.xyz (端口 80)
   新服务: https://kyc.317073.xyz (系统 Nginx → Docker 8080 → Flask 5000)
```

---

## ✅ 部署后验证

### 验证 1：检查 Nginx 状态

```bash
# 检查 Nginx 是否运行
sudo systemctl status nginx

# 应该看到：
# ● nginx.service - A high performance web server...
#      Active: active (running) since ...
```

### 验证 2：检查 Docker 容器

```bash
cd /opt/kyc-app
docker-compose ps

# 应该看到 3 个容器都在运行：
# NAME          STATUS
# kyc_postgres  Up (healthy)
# kyc_web       Up
# kyc_nginx     Up
```

### 验证 3：测试本地连接（在 VPS 上）

```bash
# 测试 Docker Nginx（端口 8080）
curl -v http://localhost:8080/

# 预期：404 Not Found（说明 Nginx 响应正常）
```

### 验证 4：从本地机器测试（在您的 Mac 上）

```bash
# 打开新的终端窗口（不要关闭 VPS 连接）

# 测试 HTTP 到 HTTPS 重定向
curl -v http://kyc.317073.xyz/

# 预期：301 Moved Permanently with Location: https://kyc.317073.xyz/

# 测试 HTTPS（如果证书已正确配置）
curl -v https://kyc.317073.xyz/

# 预期：200 OK 或 404（从 Flask 应用返回）
```

---

## 🔍 实时检查日志

### 查看 Nginx 日志

```bash
# 在 VPS 上
tail -f /var/log/nginx/access.log

# 新请求会实时显示
```

### 查看 Flask 应用日志

```bash
# 在 VPS 上
cd /opt/kyc-app
docker-compose logs -f web

# 可以看到 Flask 应用的请求日志
```

### 查看完整的 Docker 日志

```bash
# 所有容器
docker-compose logs

# 特定容器
docker-compose logs postgres
docker-compose logs web
docker-compose logs nginx
```

---

## 📊 检查系统资源

```bash
# 查看 Docker 容器资源使用
docker stats

# 查看磁盘使用
df -h

# 查看内存使用
free -h

# 查看网络连接
ss -tlnp | grep LISTEN
```

---

## 🆘 故障排查快速指南

如果部署出现问题，按以下顺序检查：

### 问题 1：Nginx 无法启动

```bash
# 检查配置语法
sudo nginx -t

# 查看详细错误
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log

# 检查端口是否被占用
sudo lsof -i :80
sudo lsof -i :8080
```

### 问题 2：Docker 容器无法启动

```bash
# 查看容器日志
docker-compose logs

# 检查特定容器
docker-compose logs web

# 查看容器状态细节
docker-compose ps -a
```

### 问题 3：无法访问应用

```bash
# 确认 DNS 解析正确
nslookup kyc.317073.xyz
dig kyc.317073.xyz

# 确认连接能到达 VPS
telnet kyc.317073.xyz 80
curl -v http://kyc.317073.xyz/ -H "Host: kyc.317073.xyz"

# 检查防火墙规则
gcloud compute firewall-rules list
```

### 问题 4：SSL 证书错误

```bash
# 检查证书文件
ls -la /etc/letsencrypt/live/317073.xyz/

# 查看证书信息
openssl x509 -in /etc/letsencrypt/live/317073.xyz/fullchain.pem -text -noout

# 如果不存在，使用 certbot 创建
sudo certbot certonly -d kyc.317073.xyz --webroot
```

---

## 🔄 部署后常见操作

### 更新应用代码

```bash
cd /opt/kyc-app

# 拉取最新代码
git pull origin main

# 重启 Flask 应用
docker-compose restart web

# 查看状态
docker-compose logs -f web
```

### 重启 Nginx

```bash
# 重新加载配置（不中断连接）
sudo nginx -s reload

# 或完全重启
sudo systemctl restart nginx
```

### 重启所有容器

```bash
cd /opt/kyc-app
docker-compose restart
```

### 完全停止和启动

```bash
cd /opt/kyc-app

# 停止所有容器
docker-compose down

# 启动所有容器
docker-compose up -d

# 查看状态
docker-compose ps
```

---

## 📞 快速参考命令

```bash
# 进入 VPS
gcloud compute ssh kyc-app --zone=asia-east1-a

# 部署
sudo su -
cd /opt/kyc-app
bash deploy-kyc-nginx.sh

# 验证
docker-compose ps
sudo systemctl status nginx
curl -v http://kyc.317073.xyz/

# 日志
tail -f /var/log/nginx/access.log
docker-compose logs -f web

# 重启
docker-compose restart
sudo systemctl restart nginx
```

---

## ✨ 预期的最终状态

部署完成后，您应该能够：

✅ **访问旧服务**
```
http://317073.xyz  → 现有服务（保持不变）
```

✅ **访问新服务**
```
https://kyc.317073.xyz  → KYC 应用
```

✅ **系统架构**
```
用户 → kyc.317073.xyz → 系统 Nginx (80/443) 
      → Docker Nginx (8080) → Flask (5000) → PostgreSQL
```

✅ **容器状态**
```
kyc_postgres ✓ Running (healthy)
kyc_web      ✓ Running
kyc_nginx    ✓ Running
```

---

## 💡 成功标志

如果看到以下信息，说明部署成功：

1. ✅ `docker-compose ps` 显示 3 个容器都在 `Up` 状态
2. ✅ `sudo systemctl status nginx` 显示 `active (running)`
3. ✅ `curl https://kyc.317073.xyz/` 能访问（可能返回 404，说明应用已响应）
4. ✅ `docker-compose logs web` 中看到 Flask 启动日志
5. ✅ `/var/log/nginx/access.log` 中有访问记录

---

## 🎯 下一步

部署完成后：

1. **测试 KYC 功能**
   - 访问验证链接
   - 测试 Webhook
   - 查看报告生成

2. **配置环境变量**（如需要）
   ```bash
   sudo nano /opt/kyc-app/.env
   # 编辑 SUMSUB_API_KEY 等
   docker-compose restart
   ```

3. **监控系统**
   - 定期检查日志
   - 监控容器资源
   - 备份数据库

4. **定期更新**
   ```bash
   cd /opt/kyc-app
   git pull origin main
   docker-compose restart
   ```

---

**祝您部署顺利！如有任何问题，请查看相关文档或检查日志。**

🚀 **KYC 系统已准备就绪！**
