# KYC 部署架构 - 快速参考

## 🎯 系统架构总结

```
用户请求 kyc.317073.xyz:80/443
         ↓
    系统 Nginx (端口 80/443)
    ├─ HTTP → HTTPS 301 重定向
    ├─ SSL/TLS 终止
    └─ 反向代理到 localhost:8080
         ↓
    Docker Nginx (端口 8080)
    ├─ 负载均衡
    └─ 反向代理到 Flask
         ↓
    Flask 应用 (端口 5000)
    ├─ 处理 /verify/ 请求
    ├─ 处理 /api/ 请求
    ├─ 处理 /webhook/ 请求
    └─ 连接 PostgreSQL 数据库
         ↓
    PostgreSQL (端口 5432)
    └─ 存储数据
```

## 📋 端口分配表

| 服务 | 容器 | 宿主机 | 说明 |
|------|------|--------|------|
| 系统 Nginx | N/A | 80 / 443 | 接收外部请求 |
| Docker Nginx | 80 | 8080 | 内部反向代理 |
| Flask | 5000 | 5000 | 应用逻辑 |
| PostgreSQL | 5432 | 5432 | 数据库 |

## 🚀 部署命令（一键执行）

```bash
# SSH 连接
gcloud compute ssh kyc-app --zone=asia-east1-a

# 进入应用目录
cd /opt/kyc-app

# 拉取最新代码
git pull origin main

# 运行部署脚本（需要 sudo）
sudo bash deploy-kyc-nginx.sh
```

## ✅ 部署验证清单

- [ ] 代码已更新到最新版本
- [ ] deploy-kyc-nginx.sh 执行成功
- [ ] Nginx 配置测试通过（nginx -t）
- [ ] Nginx 服务运行中（systemctl status nginx）
- [ ] Docker 容器运行中（docker-compose ps）
- [ ] 系统可通过 https://kyc.317073.xyz 访问

## 🧪 快速测试命令

```bash
# 1. 测试 Nginx 配置
sudo nginx -t

# 2. 检查 Nginx 状态
sudo systemctl status nginx

# 3. 查看 Nginx 进程
ps aux | grep nginx

# 4. 检查端口监听
sudo lsof -i :80
sudo lsof -i :8080

# 5. 测试本地 Docker Nginx
curl -v http://localhost:8080/

# 6. 测试通过系统 Nginx
curl -v http://kyc.317073.xyz/
curl -v https://kyc.317073.xyz/

# 7. 查看 Docker 容器
docker-compose ps

# 8. 查看应用日志
docker-compose logs -f web

# 9. 查看 Nginx 访问日志
tail -f /var/log/nginx/access.log

# 10. 查看 Nginx 错误日志
tail -f /var/log/nginx/error.log
```

## 📂 关键文件位置

```
/opt/kyc-app/                          # 应用根目录
├── docker-compose.yml                 # Docker 配置（已修改：8080:80）
├── kyc-nginx-config.conf              # 系统 Nginx 配置文件
├── deploy-kyc-nginx.sh                # 部署脚本
├── Dockerfile                         # Flask 容器定义
├── app/                               # 应用代码
│   ├── routes/
│   ├── models/
│   ├── services/
│   └── templates/
└── ...

/etc/nginx/                            # 系统 Nginx 目录
├── nginx.conf                         # 主配置
├── sites-available/
│   ├── default                        # 默认配置
│   └── kyc                            # 👈 KYC 应用配置（由脚本复制）
└── sites-enabled/
    └── kyc                            # 👈 启用链接（由脚本创建）

/etc/letsencrypt/                      # SSL 证书目录
└── live/
    └── 317073.xyz/
        ├── fullchain.pem              # 完整证书链
        └── privkey.pem                # 私钥
```

## 🔧 如何修改配置

### 修改 Nginx 配置后

```bash
# 1. 编辑配置文件
sudo nano /etc/nginx/sites-available/kyc

# 2. 测试语法
sudo nginx -t

# 3. 重新加载（无需重启）
sudo nginx -s reload
# 或
sudo systemctl reload nginx
```

### 修改 Flask 应用后

```bash
# 1. 更新代码
cd /opt/kyc-app
git pull origin main

# 2. 重启容器
docker-compose restart web

# 3. 查看日志
docker-compose logs -f web
```

### 修改 docker-compose.yml 后

```bash
# 1. 停止容器
docker-compose down

# 2. 更新文件（如果是通过 git 拉取）
git pull origin main

# 3. 重新构建和启动
docker-compose up -d --build

# 4. 查看状态
docker-compose ps
```

## 🆘 常见问题速解

| 问题 | 解决方案 |
|------|--------|
| Nginx 无法启动 | `sudo nginx -t` 检查语法；`sudo systemctl status nginx` 查看错误 |
| 502 Bad Gateway | 检查 Docker 容器是否运行：`docker-compose ps` |
| SSL 证书错误 | 检查证书文件：`ls /etc/letsencrypt/live/317073.xyz/` |
| 端口被占用 | `sudo lsof -i :80` 或 `sudo lsof -i :8080` 查看占用进程 |
| 无法访问应用 | 检查防火墙规则和 DNS 解析 |

## 📞 获取帮助

查看详细文档：
- 📘 NGINX_DUAL_CONFIG_GUIDE.md - 完整部署指南
- 📘 DEPLOYMENT_NEXT_STEPS.md - 初始部署步骤
- 📘 docker-compose.yml - Docker 配置说明
- 📘 kyc-nginx-config.conf - Nginx 配置说明

## ✨ 重要提示

✅ **优点**：
- 新旧服务独立运行
- 不需要修改旧服务
- kyc 子域名独立 SSL 证书
- 支持平滑迁移

⚠️ **注意事项**：
- Docker Nginx 容器 8080 端口必须绑定
- 系统 Nginx 必须运行（用于 HTTPS 终止）
- SSL 证书路径需要正确配置
- 定期备份 PostgreSQL 数据库

---

**最后更新**: 2025-12-02
**状态**: 🚀 就绪部署
