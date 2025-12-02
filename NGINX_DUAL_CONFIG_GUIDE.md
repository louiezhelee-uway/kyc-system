# KYC 系统部署指南 - 双 Nginx 反向代理架构

## 📋 架构说明

```
┌─────────────────────────────────────────────────────────────┐
│                     互联网用户                                │
├─────────────────────────────────────────────────────────────┤
│                 Google Cloud VM (35.212.217.145)             │
│                                                              │
│  ┌──────────────────┐          ┌──────────────────────────┐ │
│  │ 旧服务           │          │ 新 KYC 服务              │ │
│  │ 80/443           │          │ kyc.317073.xyz           │ │
│  │ (系统 Nginx)     │          │ (HTTPS)                  │ │
│  │                  │          │                          │ │
│  │ 域名: 317073.xyz │          │                          │ │
│  └──────────────────┘          │ ┌────────────────────┐  │ │
│                                │ │ 系统 Nginx (80→8080)│  │ │
│                                │ │ kyc-nginx-config   │  │ │
│                                │ └─────────┬──────────┘  │ │
│                                │           ↓              │ │
│                                │ ┌────────────────────┐  │ │
│                                │ │ Docker Nginx       │  │ │
│                                │ │ 容器 (8080)        │  │ │
│                                │ └─────────┬──────────┘  │ │
│                                │           ↓              │ │
│                                │ ┌────────────────────┐  │ │
│                                │ │ Flask 应用 (5000)  │  │ │
│                                │ │ PostgreSQL (5432)  │  │ │
│                                │ └────────────────────┘  │ │
│                                └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 快速部署步骤

### 第 1 步：在虚拟机上准备

```bash
# SSH 连接到虚拟机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 切换到 root（或使用 sudo）
sudo su -
```

### 第 2 步：克隆最新代码

```bash
# 如果还未克隆
cd /opt
git clone https://github.com/louiezhelee-uway/kyc-system.git kyc-app
cd kyc-app

# 如果已克隆，更新到最新版本
cd /opt/kyc-app
git pull origin main
```

### 第 3 步：运行部署脚本

```bash
# 确保脚本有执行权限
chmod +x deploy-kyc-nginx.sh

# 运行部署脚本（需要 root 权限）
sudo bash deploy-kyc-nginx.sh
```

脚本会自动执行以下操作：
- ✅ 复制 Nginx 配置文件
- ✅ 创建符号链接
- ✅ 测试 Nginx 配置
- ✅ 重启 Nginx 服务
- ✅ 启动/验证 Docker 容器

### 第 4 步：验证部署

```bash
# 测试 HTTP 到 HTTPS 重定向
curl -v http://kyc.317073.xyz/

# 查看 Nginx 日志
tail -f /var/log/nginx/access.log

# 查看 Docker 容器状态
docker-compose ps
```

---

## 📝 详细说明

### 🔧 Docker Compose 配置变更

**原来的配置**（会与系统 Nginx 冲突）：
```yaml
nginx:
  ports:
    - "80:80"      # ❌ 与系统 Nginx 冲突
    - "443:443"
```

**新的配置**（避免端口冲突）：
```yaml
nginx:
  ports:
    - "8080:80"    # ✅ 容器内 80，映射到宿主机 8080
```

### 🔐 系统 Nginx 配置特点

**kyc-nginx-config.conf 功能**：

1. **HTTP 到 HTTPS 重定向**
   ```nginx
   server {
       listen 80;
       server_name kyc.317073.xyz;
       return 301 https://$server_name$request_uri;
   }
   ```

2. **HTTPS 终止和反向代理**
   ```nginx
   server {
       listen 443 ssl http2;
       proxy_pass http://localhost:8080;
   }
   ```

3. **SSL 证书配置**
   - 使用现有的 Let's Encrypt 证书
   - 路径：`/etc/letsencrypt/live/317073.xyz/`
   - 支持 TLS 1.2 和 1.3

4. **安全头部**
   - HSTS（强制 HTTPS）
   - 防止 XSS、点击劫持等

### 📊 端口分配

| 服务 | 端口 | 说明 |
|------|------|------|
| 系统 Nginx | 80/443 | 接收用户请求，终止 SSL |
| Docker Nginx | 8080 | 反向代理到 Flask |
| Flask 应用 | 5000 | 实际应用逻辑 |
| PostgreSQL | 5432 | 数据库（容器内部） |

---

## 🧪 测试和验证

### 测试 1：检查 Nginx 状态

```bash
# 查看 Nginx 是否运行
sudo systemctl status nginx

# 查看 Nginx 版本
nginx -v

# 验证配置文件
sudo nginx -t
```

### 测试 2：测试反向代理

```bash
# 本地测试（在虚拟机上）
curl -v http://localhost:8080/          # Docker Nginx
curl -v http://kyc.317073.xyz/          # 系统 Nginx

# 从本地机器测试
curl -v https://kyc.317073.xyz/
```

### 测试 3：查看日志

```bash
# Nginx 访问日志
tail -f /var/log/nginx/access.log

# Nginx 错误日志
tail -f /var/log/nginx/error.log

# Docker 日志
docker-compose logs -f web

# Flask 应用日志
docker-compose logs -f web | grep -A 5 -B 5 "ERROR"
```

---

## 🔧 手动配置步骤（如果不使用脚本）

### 步骤 1：复制配置文件

```bash
sudo cp /opt/kyc-app/kyc-nginx-config.conf /etc/nginx/sites-available/kyc
```

### 步骤 2：创建符号链接

```bash
sudo ln -s /etc/nginx/sites-available/kyc /etc/nginx/sites-enabled/kyc
```

### 步骤 3：禁用默认配置（可选但推荐）

```bash
sudo rm /etc/nginx/sites-enabled/default
```

### 步骤 4：测试配置

```bash
sudo nginx -t
```

预期输出：
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 步骤 5：重启 Nginx

```bash
sudo systemctl restart nginx
```

### 步骤 6：启动 Docker 容器

```bash
cd /opt/kyc-app
docker-compose up -d
docker-compose ps
```

---

## ⚙️ 配置文件位置

| 文件 | 位置 | 说明 |
|------|------|------|
| Nginx 站点配置 | `/etc/nginx/sites-available/kyc` | 主配置文件 |
| Nginx 启用链接 | `/etc/nginx/sites-enabled/kyc` | 符号链接 |
| Nginx 主配置 | `/etc/nginx/nginx.conf` | 主 Nginx 配置 |
| SSL 证书 | `/etc/letsencrypt/live/317073.xyz/` | Let's Encrypt 证书 |
| Docker 配置 | `/opt/kyc-app/docker-compose.yml` | Docker 容器编排 |
| 应用代码 | `/opt/kyc-app/app/` | Flask 应用 |
| Docker 日志 | 容器内 | 使用 `docker-compose logs` |

---

## 🔄 常见操作

### 重新加载 Nginx 配置（不重启）

```bash
sudo nginx -s reload
# 或
sudo systemctl reload nginx
```

### 停止 Nginx

```bash
sudo systemctl stop nginx
```

### 重启 Nginx

```bash
sudo systemctl restart nginx
```

### 查看 Nginx 进程

```bash
ps aux | grep nginx
```

### 查看监听的端口

```bash
sudo netstat -tlnp | grep nginx
# 或
sudo lsof -i :80
sudo lsof -i :8080
```

---

## 🚨 故障排查

### 问题 1：Nginx 无法启动

```bash
# 检查语法错误
sudo nginx -t

# 查看错误日志
sudo tail -f /var/log/nginx/error.log

# 检查端口是否被占用
sudo lsof -i :80
sudo lsof -i :8080
```

### 问题 2：访问 kyc.317073.xyz 返回 404

```bash
# 检查 Docker 容器是否运行
docker-compose ps

# 检查容器日志
docker-compose logs web

# 检查 Nginx 反向代理配置
sudo cat /etc/nginx/sites-enabled/kyc
```

### 问题 3：SSL 证书错误

```bash
# 检查证书文件是否存在
ls -la /etc/letsencrypt/live/317073.xyz/

# 查看证书信息
openssl x509 -in /etc/letsencrypt/live/317073.xyz/fullchain.pem -text -noout

# 如果证书不存在，需要使用 certbot 创建
sudo certbot certonly -d kyc.317073.xyz
```

### 问题 4：Docker Nginx 无法连接到 Flask

```bash
# 检查容器网络
docker network ls
docker network inspect kyc_network

# 检查容器 IP
docker-compose ps
docker inspect kyc_web | grep IPAddress
```

---

## 📈 性能监控

### 查看 Nginx 连接数

```bash
# 活跃连接
netstat -an | grep ESTABLISHED | wc -l

# 监听端口
ss -tlnp | grep nginx
```

### 查看 Docker 资源使用

```bash
# 查看所有容器的资源使用
docker stats

# 查看特定容器
docker stats kyc_web kyc_postgres kyc_nginx
```

---

## 🔒 安全建议

1. **定期更新证书**
   ```bash
   # Certbot 自动续期设置
   sudo systemctl enable certbot.timer
   sudo systemctl start certbot.timer
   ```

2. **限制访问**
   ```bash
   # 在 Nginx 配置中添加
   allow 203.0.113.0/24;
   deny all;
   ```

3. **启用 WAF**
   ```bash
   # 可以使用 ModSecurity 等 WAF
   ```

4. **监控日志**
   ```bash
   # 定期检查访问日志中的异常
   grep ERROR /var/log/nginx/error.log
   ```

---

## 📚 相关命令速查

```bash
# 部署相关
bash deploy-kyc-nginx.sh           # 运行部署脚本
git pull origin main               # 更新代码

# Nginx 相关
sudo nginx -t                      # 测试配置
sudo systemctl restart nginx       # 重启 Nginx
sudo systemctl status nginx        # 查看状态
tail -f /var/log/nginx/access.log # 查看日志

# Docker 相关
docker-compose ps                  # 查看容器状态
docker-compose logs -f web         # 查看应用日志
docker-compose restart             # 重启容器
docker-compose down && up -d       # 清除并重新启动

# 测试相关
curl -v http://kyc.317073.xyz/    # 测试连接
curl -v https://kyc.317073.xyz/   # 测试 HTTPS
```

---

## ✨ 部署完成！

现在您的 KYC 系统应该已经：
- ✅ 在 Docker 容器中运行（端口 5000 Flask + 8080 Nginx）
- ✅ 通过系统 Nginx 进行 HTTPS 反向代理
- ✅ 通过 kyc.317073.xyz 域名访问
- ✅ 保留旧服务在端口 80（317073.xyz）
- ✅ SSL/TLS 加密通信

如有问题，请检查日志：
```bash
sudo tail -f /var/log/nginx/error.log
docker-compose logs -f
```
