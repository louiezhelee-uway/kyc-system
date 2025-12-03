# ✅ GitHub 推送完成 - 下一步部署指南

## 当前进度

| 步骤 | 状态 | 描述 |
|------|------|------|
| 1️⃣ SSH 密钥配置 | ✅ 完成 | 已生成 ED25519 密钥并配置 |
| 2️⃣ GitHub 认证 | ✅ 完成 | SSH 连接已验证 |
| 3️⃣ 代码推送 | ✅ 完成 | **1060 个对象已上传到 GitHub** |
| 4️⃣ Google Cloud 部署 | ⏳ 下一步 | 使用 deploy-github-gcp.sh |

---

## 确认代码已上传

访问您的仓库检查：
🔗 **https://github.com/louiezhelee-uway/kyc-system**

应该能看到：
- ✅ `app/` 文件夹（完整应用代码）
- ✅ `docker-compose.yml`（Docker 配置）
- ✅ `requirements.txt`（Python 依赖）
- ✅ 所有文档文件

---

## 部署到 Google Cloud

### 快速开始（一条命令）

```bash
bash deploy-github-gcp.sh
```

脚本会自动：
1. ✅ 检查 gcloud CLI 是否安装
2. ✅ 创建 Google Cloud 虚拟机
3. ✅ 配置防火墙规则
4. ✅ 从 GitHub 克隆代码
5. ✅ 运行 Docker 容器
6. ✅ 获取应用 URL

### 手动部署步骤

如果脚本遇到问题，可以手动执行：

#### 第 1 步：创建虚拟机

```bash
# 初始化 gcloud
gcloud init

# 设置项目 ID
gcloud config set project YOUR-PROJECT-ID

# 创建虚拟机
gcloud compute instances create kyc-app \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --machine-type=e2-medium \
    --zone=asia-east1-a \
    --boot-disk-size=20GB \
    --tags=http-server,https-server
```

#### 第 2 步：配置防火墙

```bash
# HTTP 访问
gcloud compute firewall-rules create allow-http \
    --allow=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server

# HTTPS 访问
gcloud compute firewall-rules create allow-https \
    --allow=tcp:443 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=https-server
```

#### 第 3 步：SSH 连接并部署

```bash
# 连接到虚拟机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 在虚拟机上执行以下命令：
sudo su -

# 更新系统
apt-get update
apt-get install -y git docker.io docker-compose

# 克隆代码
git clone https://github.com/louiezhelee-uway/kyc-system.git kyc-system
cd kyc-system

# 运行部署脚本
bash deploy-vps.sh

# 检查运行状态
docker-compose ps
```

#### 第 4 步：获取 IP 地址

```bash
# 在本地机器上运行
gcloud compute instances describe kyc-app \
    --zone=asia-east1-a \
    --format='value(networkInterfaces[0].accessConfigs[0].natIP)'

# 输出: 1.2.3.4 (您的虚拟机 IP)
```

#### 第 5 步：访问应用

```
http://您的虚拟机IP/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a
```

---

## 部署成本估算

| 资源 | 配置 | 月成本 |
|------|------|--------|
| **虚拟机** | e2-medium（2vCPU, 4GB RAM） | ~$15-20 |
| **网络** | 出站流量 | ~$1-5 |
| **存储** | 20GB SSD | ~$2-3 |
| **总计** | | **~$20-30/月** |

**💡 提示**: 如果需要更便宜的方案，可以使用 `e2-small`（~$10/月）或 `f1-micro`（免费额度）。

---

## 常见问题排查

### 问题 1: gcloud CLI 未安装

```bash
# macOS
brew install google-cloud-sdk

# 初始化
gcloud init
```

### 问题 2: SSH 连接超时

```bash
# 检查防火墙规则
gcloud compute firewall-rules list

# 允许 SSH (22 端口)
gcloud compute firewall-rules create allow-ssh \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0
```

### 问题 3: Docker 相关错误

```bash
# 在虚拟机上检查 Docker
docker version
docker-compose --version

# 重启 Docker 服务
sudo systemctl restart docker

# 查看日志
docker-compose logs -f
```

### 问题 4: 环境变量错误

```bash
# 检查虚拟机上的 .env 文件
cat /opt/kyc-app/.env

# 如果需要修改，编辑文件
sudo nano /opt/kyc-app/.env

# 重启应用
docker-compose restart
```

---

## 后续更新代码

代码已在 GitHub 上，后续更新很简单：

### 1️⃣ 本地更新代码

```bash
# 在您的 Mac 上
cd "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"

# 编辑代码...

# 提交并推送
git add .
git commit -m "描述您的更改"
git push origin main
```

### 2️⃣ 虚拟机上更新

```bash
# SSH 到虚拟机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 拉取最新代码
cd /opt/kyc-app
sudo git pull origin main

# 重启应用
sudo docker-compose restart

# 查看状态
docker-compose ps
```

---

## 有用的命令

```bash
# 查看虚拟机列表
gcloud compute instances list

# 查看虚拟机详情
gcloud compute instances describe kyc-app --zone=asia-east1-a

# SSH 连接
gcloud compute ssh kyc-app --zone=asia-east1-a

# 复制文件到虚拟机
gcloud compute scp /local/file kyc-app:/remote/path --zone=asia-east1-a

# 从虚拟机复制文件
gcloud compute scp kyc-app:/remote/file /local/path --zone=asia-east1-a

# 删除虚拟机
gcloud compute instances delete kyc-app --zone=asia-east1-a

# 查看防火墙规则
gcloud compute firewall-rules list

# 查看日志
gcloud compute instances serial-port-output kyc-app --zone=asia-east1-a
```

---

## 部署架构图

```
┌─────────────────────────────────────────────────────┐
│                   GitHub (代码存储)                  │
│          louiezhelee-uway/kyc-system               │
│              ↓ git clone / git pull                 │
├─────────────────────────────────────────────────────┤
│              Google Cloud 虚拟机                     │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │          Docker Container (应用)               │  │
│  │                                               │  │
│  │  ┌─────────────────────────────────────────┐ │  │
│  │  │  Flask 应用 (Webhook, KYC, 报告)       │ │  │
│  │  └─────────────────────────────────────────┘ │  │
│  │                                               │  │
│  │  ┌─────────────────────────────────────────┐ │  │
│  │  │      PostgreSQL 数据库                   │ │  │
│  │  │  (订单、验证、报告数据)                 │ │  │
│  │  └─────────────────────────────────────────┘ │  │
│  │                                               │  │
│  │  ┌─────────────────────────────────────────┐ │  │
│  │  │      Nginx 反向代理                      │ │  │
│  │  │  (端口 80, 443)                         │ │  │
│  │  └─────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────┘  │
│                    ↑ HTTP/HTTPS                    │
├─────────────────────────────────────────────────────┤
│                   互联网用户                         │
│            买家访问验证链接获取 KYC                 │
└─────────────────────────────────────────────────────┘
```

---

## 安全建议

1. **环境变量**: 不要在代码中硬编码密钥
   ```bash
   # 在虚拟机上设置环境变量
   export SUMSUB_API_KEY="your-key"
   export DATABASE_URL="postgresql://..."
   ```

2. **防火墙**: 只开放必要的端口
   - HTTP (80)
   - HTTPS (443)
   - SSH (22) - 仅限您的 IP

3. **定期更新**: 保持依赖最新
   ```bash
   # 在虚拟机上
   docker pull ubuntu:22.04
   docker-compose pull
   docker-compose up -d
   ```

4. **备份**: 定期备份数据库
   ```bash
   # 导出数据库
   docker-compose exec db pg_dump -U postgres kyc_db > backup.sql
   ```

---

## 接下来

✅ **已完成**:
- GitHub 仓库创建和代码推送
- 项目结构和文件组织

⏳ **下一步**:
1. 运行部署脚本或手动部署到 Google Cloud
2. 访问应用并测试功能
3. 配置 Sumsub API（如果还未配置）
4. 设置淘宝/闲鱼 Webhook

🎯 **建议顺序**:
1. 先运行 `deploy-github-gcp.sh` 自动部署
2. 如果出错，参考"常见问题排查"部分
3. 访问虚拟机 IP 测试应用

---

如有问题，请随时提问！🚀

