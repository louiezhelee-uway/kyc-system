# 🎯 GitHub + 谷歌云 - 快速参考卡

## 一句话总结

> 运行 `bash deploy-github-gcp.sh`，一键搞定 GitHub 上传 + 谷歌云部署 ✨

---

## 🚀 一键部署

```bash
bash deploy-github-gcp.sh
```

脚本会自动：
1. ✅ 推送代码到 GitHub
2. ✅ 创建谷歌云虚拆机
3. ✅ 配置防火墙
4. ✅ 部署应用

---

## 📋 前置条件 (2 分钟)

```bash
# 1. 检查 Git
git --version

# 2. 检查 gcloud
gcloud --version

# 3. 初始化 gcloud
gcloud init
```

---

## 👤 GitHub 账户设置

```bash
# 1. 注册账户
# https://github.com/signup

# 2. 在本地配置 Git 用户
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# 3. 创建 GitHub 仓库
# https://github.com/new
```

---

## ☁️ 谷歌云账户设置

```bash
# 1. 创建账户和项目
# https://console.cloud.google.com/

# 2. 获取项目 ID
gcloud projects list

# 3. 初始化 gcloud
gcloud init
gcloud auth login
```

---

## 📊 部署流程概览

```
本地代码
    ↓
GitHub (代码管理)
    ↓
谷歌云虚拆机
    ↓
Docker 容器 (应用运行)
    ↓
PostgreSQL (数据存储)
    ↓
Nginx (反向代理)
    ↓
互联网用户
```

---

## 🔗 常用命令

### GitHub 相关

```bash
# 查看状态
git status

# 添加文件
git add .

# 提交
git commit -m "描述"

# 推送
git push origin main

# 拉取最新
git pull origin main

# 查看提交历史
git log

# 回滚
git revert <commit-hash>
```

### 谷歌云相关

```bash
# 列出虚拆机
gcloud compute instances list

# 连接虚拆机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 停止虚拆机
gcloud compute instances stop kyc-app --zone=asia-east1-a

# 启动虚拆机
gcloud compute instances start kyc-app --zone=asia-east1-a

# 删除虚拆机
gcloud compute instances delete kyc-app --zone=asia-east1-a

# 获取 IP
gcloud compute instances describe kyc-app \
  --zone=asia-east1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)'
```

### Docker 相关

```bash
# SSH 到虚拆机后
gcloud compute ssh kyc-app --zone=asia-east1-a

# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启容器
docker-compose restart

# 停止容器
docker-compose down

# 启动容器
docker-compose up -d
```

---

## 🎯 完整部署流程 (20 分钟)

### 1️⃣ 准备 (2 分钟)

```bash
# 检查前置条件
git --version
gcloud --version

# 配置 Git
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# 初始化 gcloud
gcloud init
```

### 2️⃣ 运行部署脚本 (1 分钟)

```bash
cd "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"
bash deploy-github-gcp.sh
```

### 3️⃣ 回答问题 (1 分钟)

脚本会问：
- GitHub 用户名
- 仓库名称
- 谷歌云项目 ID
- 虚拆机名称
- 区域

### 4️⃣ 等待部署 (15 分钟)

脚本会自动：
- 上传到 GitHub ✅
- 创建虚拆机 ✅
- 配置防火墙 ✅
- 部署应用 ✅

### 5️⃣ 验证成功 (1 分钟)

```bash
# 获取虚拆机 IP
gcloud compute instances describe kyc-app \
  --zone=asia-east1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)'

# 在浏览器访问
# http://[IP]
# http://[IP]/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
```

---

## 🔄 代码更新流程

### 本地更新

```bash
# 1. 编辑代码
# 2. 提交
git add .
git commit -m "更新描述"

# 3. 推送
git push origin main
```

### 虚拆机更新

```bash
# SSH 连接
gcloud compute ssh kyc-app --zone=asia-east1-a

# 拉取最新代码
cd /opt/kyc-app
git pull origin main

# 重启应用
docker-compose restart

# 查看日志
docker-compose logs -f
```

---

## ❓ 快速问题

| 问题 | 答案 |
|------|------|
| 脚本在哪? | `/Project_KYC/deploy-github-gcp.sh` |
| 怎么运行? | `bash deploy-github-gcp.sh` |
| 需要多久? | 15-20 分钟 |
| 费用多少? | ~$15/月 |
| 怎么停止? | `gcloud compute instances stop kyc-app` |
| 怎么删除? | `gcloud compute instances delete kyc-app` |
| 怎么更新? | Git push → 虚拆机 git pull |
| 怎么查日志? | `docker-compose logs -f` |

---

## 📂 重要文件

| 文件 | 用途 |
|------|------|
| `deploy-github-gcp.sh` | 一键部署脚本 ⭐ |
| `GITHUB_DEPLOYMENT.md` | GitHub + GCP 详细指南 |
| `QUICK_GITHUB_GCP.md` | 快速开始指南 |
| `deploy-vps.sh` | VPS 部署脚本 |
| `docker-compose.yml` | Docker 配置 |
| `.env.docker` | 环境变量模板 |

---

## 🔐 安全检查

- [ ] 不要在代码中硬编码 API 密钥
- [ ] `.env` 文件不要上传到 GitHub
- [ ] 定期更新依赖包
- [ ] 配置防火墙只开放必要端口
- [ ] 使用 HTTPS (如果有域名)
- [ ] 定期备份数据库

---

## 📞 需要帮助?

1. 查看 `GITHUB_DEPLOYMENT.md` (完整指南)
2. 查看 `QUICK_GITHUB_GCP.md` (快速开始)
3. 查看 `TROUBLESHOOTING_403.md` (常见问题)
4. 查看日志: `docker-compose logs -f`

---

## ✨ 部署完成后

- ✅ GitHub 地址: https://github.com/YOUR_USERNAME/kyc-system
- ✅ 应用地址: http://虚拆机IP
- ✅ 验证页面: http://虚拆机IP/verify/{token}
- ✅ 可以随时 git push 更新代码
- ✅ 可以随时使用 Docker 管理应用

---

**现在就开始:** `bash deploy-github-gcp.sh` 🚀
