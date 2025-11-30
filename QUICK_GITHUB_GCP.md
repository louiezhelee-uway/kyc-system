# 🚀 3 分钟快速开始 - GitHub + 谷歌云部署

> 一个脚本搞定一切，从 GitHub 上传到谷歌云部署

---

## 📋 前置条件检查

在开始之前，请确保您已有：

- ✅ **GitHub 账户** (在 https://github.com 免费注册)
- ✅ **Google Cloud 账户** (在 https://console.cloud.google.com 免费申请)
- ✅ **本地安装 Git** (通常 Mac 自带，可运行 `git --version` 检查)
- ✅ **本地安装 gcloud CLI** (从 https://cloud.google.com/sdk/docs/install 安装)

---

## 🚀 快速开始 (3 步)

### 步骤 1️⃣: 运行一键部署脚本

```bash
cd "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"

# 运行脚本 (会引导您完成所有步骤)
bash deploy-github-gcp.sh
```

### 步骤 2️⃣: 按照脚本提示填写信息

脚本会询问您：

```
请输入 GitHub 用户名: YOUR_USERNAME
请输入仓库名称 (默认: kyc-system): kyc-system
请输入谷歌云项目 ID: my-project-123456
请输入虚拆机名称 (默认: kyc-app): kyc-app
请选择区域 (默认: asia-east1-a): asia-east1-a
```

### 步骤 3️⃣: 等待完成 (~10 分钟)

脚本会自动执行以下操作：

```
✅ 配置 Git 用户信息
✅ 上传代码到 GitHub
✅ 创建谷歌云虚拆机
✅ 配置防火墙规则
✅ 在虚拆机上部署应用
✅ 显示访问信息
```

---

## ✅ 完成后您会看到

```
═══════════════════════════════════════════════════
✅ 部署成功
═══════════════════════════════════════════════════

📍 项目信息:
   GitHub 仓库: https://github.com/YOUR_USERNAME/kyc-system.git
   虚拆机名称: kyc-app
   虚拆机 IP:  35.xxx.xxx.xxx

🌐 访问应用:
   http://35.xxx.xxx.xxx
   http://35.xxx.xxx.xxx/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a

📝 查看日志:
   gcloud compute ssh kyc-app --zone=asia-east1-a
   cd /opt/kyc-app && docker-compose logs -f

🔄 后续更新代码:
   1. 本地修改后: git add . && git commit -m '描述' && git push
   2. 虚拆机更新: cd /opt/kyc-app && git pull && docker-compose restart
═══════════════════════════════════════════════════
```

---

## 🎯 不同场景的用法

### 场景 1: 全新部署 (推荐)

```bash
# 直接运行脚本，一步到位
bash deploy-github-gcp.sh
```

### 场景 2: 只上传到 GitHub (不部署到谷歌云)

```bash
# 只执行 GitHub 部分
cd "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"

# 初始化 Git
git init

# 配置 GitHub 远程
git remote add origin https://github.com/YOUR_USERNAME/kyc-system.git

# 推送代码
git add .
git commit -m "Initial commit"
git branch -M main
git push -u origin main
```

### 场景 3: GitHub 已有，只部署虚拆机

```bash
# 跳过 GitHub 部分，使用现有仓库
gcloud compute instances create kyc-app \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-medium \
  --zone=asia-east1-a \
  --boot-disk-size=20GB

# SSH 连接后执行
gcloud compute ssh kyc-app --zone=asia-east1-a

# 在虚拆机上
sudo su -
cd /tmp
git clone https://github.com/YOUR_USERNAME/kyc-system.git
cd kyc-system
bash deploy-vps.sh
```

---

## 🔍 遇到问题？

### 问题 1: "gcloud: command not found"

**原因**: gcloud CLI 未安装  
**解决**:
```bash
# 从官方安装
# https://cloud.google.com/sdk/docs/install

# Mac 用户可以用 brew
brew install google-cloud-sdk
```

### 问题 2: "GitHub 推送失败"

**原因**: 可能是仓库不存在或认证失败  
**解决**:
1. 在 https://github.com/new 手动创建仓库
2. 确保使用了正确的用户名和仓库名
3. 如果是私有仓库，需要 SSH 密钥或 Token 认证

### 问题 3: "SSH 连接失败"

**原因**: 虚拆机还未启动或 gcloud 配置不完整  
**解决**:
```bash
# 先初始化 gcloud
gcloud init

# 等待 2-3 分钟，虚拆机启动需要时间
gcloud compute ssh kyc-app --zone=asia-east1-a --command="whoami"

# 如果仍然失败，查看虚拆机状态
gcloud compute instances list
```

### 问题 4: "权限不足"

**原因**: Google Cloud 项目权限不够  
**解决**:
```bash
# 确保您的谷歌账户有以下权限
# - Compute Instance Admin
# - Service Account Admin
# - Firewall Rules Admin

# 可以在 IAM & Admin 中配置权限
# https://console.cloud.google.com/iam-admin
```

---

## 📊 费用预估

| 服务 | 配置 | 月费用 |
|------|------|--------|
| Compute Engine | e2-medium, 20GB | $12-15 |
| 网络带宽 | 出站流量 1GB | $0.12 |
| 存储 | PostgreSQL 数据库 10GB | $1-2 |
| **总计** | | **$13-17** |

> 注: 新用户通常有 $300 免费额度

---

## 🔐 安全提示

✅ **做的事**:
- 使用 HTTPS 克隆 GitHub 仓库
- 防火墙仅开放必要的端口
- 不上传 `.env` 敏感信息
- 定期备份数据库

❌ **不要做**:
- 不要在代码中硬编码 API 密钥
- 不要公开敏感配置
- 不要使用过于简单的数据库密码
- 不要禁用防火墙

---

## 📱 后续操作

### 配置自定义域名

```bash
# 1. 在域名提供商配置 DNS A 记录指向虚拆机 IP
# yourdomain.com A 35.xxx.xxx.xxx

# 2. SSH 到虚拆机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 3. 编辑 nginx 配置
sudo nano /etc/nginx/sites-available/default
# 修改 server_name 为您的域名

# 4. 重启 nginx
sudo systemctl restart nginx

# 5. (可选) 配置 SSL 证书
sudo apt-get install certbot python3-certbot-nginx
sudo certbot certonly --nginx -d yourdomain.com
```

### 设置自动备份

```bash
# SSH 到虚拆机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 进入项目目录
cd /opt/kyc-app

# 查看备份脚本
cat backup.sh

# 添加到 cron 定时备份 (每天 2 点)
sudo crontab -e
# 添加: 0 2 * * * /opt/kyc-app/backup.sh
```

### 监控和告警

```bash
# 在谷歌云控制台创建监控告警
# https://console.cloud.google.com/monitoring

# 配置项:
# - CPU 使用率 > 80%
# - 磁盘空间 < 10%
# - 内存使用率 > 90%
```

---

## 📚 详细文档

想了解更多？请查看：

- `GITHUB_DEPLOYMENT.md` - GitHub + GCP 详细指南
- `GOOGLE_CLOUD_DEPLOYMENT.md` - GCP 详细配置
- `PRODUCTION_DEPLOYMENT.md` - 生产环境部署
- `TROUBLESHOOTING_403.md` - 常见错误排查

---

## ✨ 总结

| 步骤 | 操作 | 时间 |
|------|------|------|
| 1 | 运行脚本 | 1 分钟 |
| 2 | 填写信息 | 2 分钟 |
| 3 | 等待部署 | 10-15 分钟 |
| **总计** | | **15-20 分钟** |

---

**就这么简单！** 🎉

现在您可以：
- ✅ 在 GitHub 上管理代码
- ✅ 在谷歌云上运行应用
- ✅ 通过公网 IP 访问服务
- ✅ 随时更新和重启应用

祝您部署顺利！如有问题，请查阅详细文档或重新运行脚本。
