# 📤 GitHub + 谷歌云部署指南

> 本指南展示如何将项目上传到 GitHub，然后在谷歌云 Compute Engine 上部署

---

## 🚀 快速开始 (5 分钟)

### 步骤 1: 在 GitHub 上创建新仓库

#### 方式 A: 使用 GitHub Web 界面 (最简单)

1. 访问 [GitHub](https://github.com/new)
2. 填写仓库信息：
   - **Repository name**: `kyc-system` (或任何名称)
   - **Description**: `KYC 自动化验证系统 - Sumsub 集成`
   - **Public/Private**: 选择 Public (方便他人访问) 或 Private
   - **Initialize repository**: 不勾选 (我们有本地代码)
3. 点击 **Create repository**
4. 复制显示的 HTTPS URL，例如: `https://github.com/YOUR_USERNAME/kyc-system.git`

#### 方式 B: 使用 GitHub CLI (如果已安装)

```bash
# 登录 GitHub
gh auth login

# 创建新仓库
gh repo create kyc-system --public --source=. --remote=origin --push
```

---

## 📝 步骤 2: 本地设置 Git 并上传代码

在您的本地电脑上运行：

```bash
# 1. 进入项目目录
cd "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"

# 2. 初始化 Git 仓库 (如果还没有)
git init

# 3. 添加 GitHub 远程仓库
git remote add origin https://github.com/YOUR_USERNAME/kyc-system.git

# 4. 添加所有文件
git add .

# 5. 首次提交
git commit -m "Initial commit: KYC 验证系统完整项目"

# 6. 推送到 GitHub (main 分支)
git branch -M main
git push -u origin main

# 完成！检查 GitHub 上是否看到文件
```

### 如果遇到问题？

```bash
# 检查 Git 状态
git status

# 查看远程仓库配置
git remote -v

# 如果需要修改远程地址
git remote set-url origin https://github.com/YOUR_USERNAME/kyc-system.git

# 重新推送
git push -u origin main
```

---

## ✅ 验证上传成功

在浏览器中访问：
```
https://github.com/YOUR_USERNAME/kyc-system
```

应该能看到所有文件，包括：
- ✅ `app/` 目录
- ✅ `docker-compose.yml`
- ✅ `requirements.txt`
- ✅ `deploy-vps.sh`
- ✅ `.env.docker`
- ✅ 所有文档 (*.md 文件)

---

## 🚀 现在可以在谷歌云上部署了！

### 完整部署流程

#### 步骤 1: 创建谷歌云虚拟机

```bash
# 在本地电脑上运行

# 1. 初始化 gcloud
gcloud init

# 2. 创建虚拟机
gcloud compute instances create kyc-app \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-medium \
  --zone=asia-east1-a \
  --scopes=default \
  --boot-disk-size=20GB \
  --tags=http-server,https-server
```

#### 步骤 2: 连接到虚拟机并部署

```bash
# SSH 连接到虚拟机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 在虚拟机上运行以下命令:
# ============================================

# 1. 切换到 root
sudo su -

# 2. 克隆 GitHub 项目
cd /tmp
git clone https://github.com/YOUR_USERNAME/kyc-system.git
cd kyc-system

# 3. 运行部署脚本
bash deploy-vps.sh

# 完成！脚本会自动处理所有设置
```

#### 步骤 3: 验证部署成功

```bash
# 获取虚拟机外部 IP
EXTERNAL_IP=$(gcloud compute instances describe kyc-app \
  --zone=asia-east1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

# 测试 API
curl http://$EXTERNAL_IP

# 应该能看到系统首页的 HTML 内容
```

---

## 🔄 更新代码流程

如果将来需要更新代码：

### 本地更新

```bash
# 在本地编辑代码后
cd "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"

# 添加更改
git add .

# 提交
git commit -m "更新说明"

# 推送到 GitHub
git push origin main
```

### 在虚拟机上更新

```bash
# SSH 连接到虚拟机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 拉取最新代码
cd /opt/kyc-app
git pull origin main

# 重启 Docker 容器
docker-compose restart
```

---

## 📊 完整命令清单

### GitHub 设置 (本地)

```bash
# 初始化 Git
cd "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"
git init

# 配置 Git 用户信息 (首次设置)
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# 添加远程仓库
git remote add origin https://github.com/YOUR_USERNAME/kyc-system.git

# 添加所有文件
git add .

# 首次提交
git commit -m "Initial commit"

# 推送
git branch -M main
git push -u origin main
```

### 谷歌云部署 (本地)

```bash
# 初始化 gcloud
gcloud init

# 启用必要 API
gcloud services enable compute.googleapis.com

# 创建虚拟机
gcloud compute instances create kyc-app \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-medium \
  --zone=asia-east1-a \
  --boot-disk-size=20GB \
  --tags=http-server,https-server

# 配置防火墙
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server

gcloud compute firewall-rules create allow-https \
  --allow=tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=https-server

# SSH 连接
gcloud compute ssh kyc-app --zone=asia-east1-a

# 获取外部 IP
gcloud compute instances describe kyc-app \
  --zone=asia-east1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)'
```

### 虚拟机部署 (在虚拟机上)

```bash
# 切换到 root
sudo su -

# 克隆项目
cd /tmp
git clone https://github.com/YOUR_USERNAME/kyc-system.git
cd kyc-system

# 运行部署脚本
bash deploy-vps.sh

# 检查状态
cd /opt/kyc-app
docker-compose ps

# 查看日志
docker-compose logs -f web
```

---

## 🔐 重要提示

### 不要上传的文件

确保 `.gitignore` 包含这些文件（已在项目中）：

```
.env              # 环境变量（包含敏感信息）
.env.local        # 本地环境变量
__pycache__/      # Python 缓存
.venv/            # 虚拟环境
node_modules/     # Node 依赖
*.pyc             # 编译文件
.DS_Store         # macOS 系统文件
```

### 安全设置

1. **永远不要**在代码中包含 API 密钥
2. 使用 `.env` 文件存储敏感信息（不上传到 GitHub）
3. 在虚拟机上手动设置 `.env` 文件

---

## 📝 步骤总结

| 步骤 | 操作 | 时间 |
|------|------|------|
| 1 | 在 GitHub 创建新仓库 | 1 分钟 |
| 2 | 本地 Git 初始化并推送 | 2 分钟 |
| 3 | 创建谷歌云虚拆机 | 2 分钟 |
| 4 | SSH 连接并部署 | 5 分钟 |
| 5 | 验证部署成功 | 1 分钟 |
| **总计** | | **11 分钟** |

---

## 🎯 下一步

### 配置域名 (可选)

```bash
# 获取虚拟机 IP
gcloud compute instances describe kyc-app \
  --zone=asia-east1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)'

# 在域名提供商配置 DNS:
# A 记录 → kyc.example.com → [虚拟机 IP]

# SSH 到虚拆机设置 SSL
gcloud compute ssh kyc-app --zone=asia-east1-a

# 在虚拆机上手动运行 SSL 配置
cd /opt/kyc-app
bash deploy-vps.sh  # 会提示输入域名
```

### 配置自动化备份

```bash
# 在虚拆机上
gcloud compute ssh kyc-app --zone=asia-east1-a

# 查看备份
sudo ls -la /opt/kyc-app/backups/

# 下载备份到本地
gcloud compute scp kyc-app:/opt/kyc-app/backups/backup_*.sql \
  ./backups/ \
  --zone=asia-east1-a
```

### 配置 CI/CD 自动部署 (高级)

可以使用 GitHub Actions 实现自动部署：

```yaml
# .github/workflows/deploy.yml
name: Deploy to Google Cloud

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Deploy to VM
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.GCP_VM_IP }}
          username: root
          key: ${{ secrets.GCP_SSH_KEY }}
          script: |
            cd /opt/kyc-app
            git pull origin main
            docker-compose restart
```

---

## ❓ 常见问题

**Q: 如何更改 GitHub 仓库的隐私设置？**  
A: 在 GitHub 网页上进入 Settings → Change repository visibility

**Q: 如果不小心上传了 `.env` 文件怎么办？**  
A: 
```bash
# 立即从历史中删除
git rm --cached .env
git commit -m "Remove .env file"
git push

# 更新 GitHub 上的文件历史 (可选)
# https://help.github.com/en/github/authenticating-to-github/removing-sensitive-data-from-a-repository
```

**Q: 如何让多个人协作开发？**  
A: 
```bash
# 邀请协作者
# GitHub Settings → Collaborators → Add people

# 其他开发者可以这样克隆
git clone https://github.com/YOUR_USERNAME/kyc-system.git
```

**Q: 怎样回滚到之前的版本？**  
A:
```bash
# 查看提交历史
git log

# 回滚到某个版本
git revert <commit-hash>
git push origin main
```

---

## 📚 相关资源

- [GitHub 快速开始](https://docs.github.com/en/get-started)
- [Git 教程](https://git-scm.com/book/en/v2)
- [Google Cloud 文档](https://cloud.google.com/docs)
- [Docker 部署最佳实践](https://docs.docker.com/develop/dev-best-practices/)

---

## ✅ 检查清单

- [ ] 创建 GitHub 账户 (如果没有)
- [ ] 创建新的 GitHub 仓库
- [ ] 本地 Git 初始化
- [ ] 推送代码到 GitHub
- [ ] 验证文件已上传
- [ ] 创建谷歌云虚拆机
- [ ] SSH 连接虚拆机
- [ ] 克隆 GitHub 项目
- [ ] 运行 `deploy-vps.sh` 脚本
- [ ] 验证部署成功
- [ ] 配置防火墙规则
- [ ] 测试 API 端点
- [ ] 配置自定义域名 (可选)
- [ ] 设置自动备份

---

**版本**: 1.0  
**最后更新**: 2025-11-30  
**适用于**: GitHub + Google Cloud Platform
