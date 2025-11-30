# 🚀 谷歌云部署指南 (Compute Engine)

> 本指南展示如何在谷歌云平台 (Google Cloud Platform) 的 Compute Engine 上部署 KYC 验证系统

---

## 📋 前置要求

### 账户和权限
- ✅ 谷歌云平台账户
- ✅ 激活的计费账户
- ✅ 已创建的项目
- ✅ 必要的 IAM 权限 (Compute Admin)

### 本地工具
- ✅ `gcloud` CLI 工具 ([安装指南](https://cloud.google.com/sdk/docs/install))
- ✅ Git (用于克隆代码)

---

## 🎯 快速部署 (15 分钟)

### 步骤 1: 初始化 Google Cloud

```bash
# 初始化 gcloud
gcloud init

# 设置项目 ID
gcloud config set project YOUR_PROJECT_ID

# 启用必要的 API
gcloud services enable compute.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### 步骤 2: 创建 Compute Engine 虚拟机

#### 方式 A: 使用 gcloud 命令行

```bash
# 创建虚拟机实例
gcloud compute instances create kyc-app \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-medium \
  --zone=asia-east1-a \
  --scopes=default \
  --boot-disk-size=20GB \
  --tags=http-server,https-server \
  --enable-display-device=false

# 等待实例创建完成
echo "实例创建中，请稍候..."
sleep 30
```

#### 方式 B: 使用 Google Cloud Console (Web)

1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 导航到 **Compute Engine > 虚拟机实例**
3. 点击 **创建实例**
4. 配置：
   - **名称**: kyc-app
   - **区域**: asia-east1 (根据需要选择)
   - **机器类型**: e2-medium (2 vCPU, 4GB 内存)
   - **启动磁盘**: Ubuntu 22.04 LTS, 20GB
   - **允许的流量**: HTTP, HTTPS
5. 点击 **创建**

### 步骤 3: 配置防火墙规则

```bash
# 创建防火墙规则允许 HTTP
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server

# 创建防火墙规则允许 HTTPS
gcloud compute firewall-rules create allow-https \
  --allow=tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=https-server

# 创建防火墙规则允许 SSH
gcloud compute firewall-rules create allow-ssh \
  --allow=tcp:22 \
  --source-ranges=YOUR_IP/32 \
  --target-tags=ssh-server
```

### 步骤 4: 连接到虚拟机

```bash
# 方式 1: 使用 gcloud SSH
gcloud compute ssh kyc-app --zone=asia-east1-a

# 方式 2: 使用普通 SSH (需要先获取外部 IP)
EXTERNAL_IP=$(gcloud compute instances describe kyc-app \
  --zone=asia-east1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

ssh -i ~/.ssh/gcloud_rsa ubuntu@$EXTERNAL_IP
```

### 步骤 5: 在虚拟机上部署应用

连接到虚拟机后，运行以下命令：

```bash
# 1. 切换到 root
sudo su -

# 2. 克隆项目
cd /tmp
git clone https://github.com/YOUR_USERNAME/kyc-system.git
cd kyc-system

# 3. 运行部署脚本
bash deploy-vps.sh

# 部署脚本会自动:
# ✅ 更新系统
# ✅ 安装 Docker 和 Docker Compose
# ✅ 设置环境变量
# ✅ 生成 SSL 证书 (可选)
# ✅ 启动所有服务
# ✅ 配置防火墙
# ✅ 设置自动备份
```

### 步骤 6: 配置域名 (可选)

如果您有自己的域名：

```bash
# 1. 获取虚拟机的外部 IP
gcloud compute instances describe kyc-app \
  --zone=asia-east1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)'

# 2. 在你的域名提供商配置 DNS:
#    A 记录 → kyc.example.com → [上面的 IP 地址]

# 3. 在虚拟机上配置 SSL (部署脚本会引导)
```

---

## 🏗️ 架构对比

### VPS (现有部署方式)
```
传统服务器
│
├─ Ubuntu 虚拟机
├─ Docker
├─ PostgreSQL
├─ Nginx
└─ Flask 应用
```

### 谷歌云 Compute Engine (新方式)
```
Google Cloud Platform
│
├─ Compute Engine 虚拟机 (Ubuntu 22.04)
│  ├─ Docker (完全相同)
│  ├─ PostgreSQL (完全相同)
│  ├─ Nginx (完全相同)
│  └─ Flask 应用 (完全相同)
│
├─ Cloud Storage (可选备份)
├─ Cloud SQL (可选数据库)
└─ Cloud Monitoring (可选监控)
```

---

## 📊 成本估算

### e2-medium 机器

| 组件 | 成本 |
|------|------|
| Compute Engine (e2-medium) | ~$20-30/月 |
| 磁盘存储 (20GB) | ~$0.80/月 |
| 网络流量 | ~$0.12/GB |
| **总计** | **~$20-35/月** |

> 💡 提示: 首次注册有 $300 免费额度，可免费使用 12 个月

---

## 🔧 部署后配置

### 1. 验证部署成功

```bash
# SSH 到虚拟机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 检查服务状态
sudo docker-compose -f /opt/kyc-app/docker-compose.yml ps

# 查看日志
sudo docker-compose -f /opt/kyc-app/docker-compose.yml logs -f web
```

### 2. 测试 API

```bash
# 获取虚拟机外部 IP
EXTERNAL_IP=$(gcloud compute instances describe kyc-app \
  --zone=asia-east1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

# 测试首页
curl http://$EXTERNAL_IP

# 测试 Webhook
curl -X POST http://$EXTERNAL_IP/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "test_001",
    "buyer_name": "Test User",
    "buyer_email": "test@example.com",
    "order_amount": 99.99
  }'
```

### 3. 配置环境变量

连接到虚拟机后编辑 `.env` 文件：

```bash
sudo nano /opt/kyc-app/.env
```

必填项：
```env
# Sumsub
SUMSUB_API_KEY=your_api_key_here
SUMSUB_API_URL=https://api.sumsub.com

# Database
DATABASE_URL=postgresql://kyc_user:password@db:5432/kyc_db
SECRET_KEY=your_secret_key_here

# Webhook
WEBHOOK_SECRET=your_webhook_secret_here

# Application
BASE_URL=https://yourdomain.com  # 或使用虚拟机 IP
ENVIRONMENT=production
```

编辑完成后重启服务：

```bash
sudo docker-compose -f /opt/kyc-app/docker-compose.yml restart
```

---

## 🔐 安全最佳实践

### 1. 使用 Cloud IAM 权限

```bash
# 创建服务账户
gcloud iam service-accounts create kyc-app-sa \
  --display-name="KYC Application"

# 分配最小权限 (仅计算实例管理)
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:kyc-app-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/compute.instanceAdmin.v1
```

### 2. 启用防火墙

```bash
# 检查防火墙状态
gcloud compute firewall-rules list --filter="name~'allow-*'"

# 限制 SSH 访问
gcloud compute firewall-rules update allow-ssh \
  --source-ranges=YOUR_IP/32
```

### 3. 启用 VPC 和私有网络

```bash
# 创建专用网络 (可选)
gcloud compute networks create kyc-network \
  --subnet-mode=custom

# 创建子网
gcloud compute networks subnets create kyc-subnet \
  --network=kyc-network \
  --region=asia-east1 \
  --range=10.0.0.0/24
```

### 4. 定期备份

部署脚本已配置每日备份：

```bash
# 查看备份
ssh root@kyc-app 'ls -la /opt/kyc-app/backups/'

# 手动备份
gcloud compute ssh kyc-app --zone=asia-east1-a \
  -- 'sudo bash /opt/kyc-app/backup.sh'

# 下载备份到本地
gcloud compute scp kyc-app:/opt/kyc-app/backups/backup_*.sql \
  ./backups/ --zone=asia-east1-a
```

---

## 📈 性能优化

### 1. 选择合适的机器类型

| 机器类型 | vCPU | 内存 | 适用场景 |
|---------|------|------|---------|
| e2-micro | 0.25-2 | 1GB | 开发/测试 |
| e2-small | 0.5-2 | 2GB | 小型应用 |
| **e2-medium** | 1-2 | **4GB** | **推荐** |
| e2-standard-2 | 2 | 8GB | 高并发 |
| n2-standard-2 | 2 | 8GB | 计算密集 |

### 2. 启用自动扩展

创建 Instance Template 和 Instance Group：

```bash
# 创建实例模板
gcloud compute instance-templates create kyc-template \
  --machine-type=e2-medium \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud

# 创建托管实例组
gcloud compute instance-groups managed create kyc-group \
  --base-instance-name=kyc \
  --template=kyc-template \
  --size=1 \
  --zone=asia-east1-a

# 设置自动扩展 (最多 3 个实例)
gcloud compute instance-groups managed set-autoscaling kyc-group \
  --max-num-replicas=3 \
  --min-num-replicas=1 \
  --target-cpu-utilization=0.75 \
  --zone=asia-east1-a
```

### 3. 使用 Cloud Load Balancing

```bash
# 创建负载均衡器健康检查
gcloud compute health-checks create http kyc-health-check \
  --port=80 \
  --request-path=/health

# 创建后端服务
gcloud compute backend-services create kyc-backend \
  --protocol=HTTP \
  --health-checks=kyc-health-check \
  --global

# 添加后端实例
gcloud compute backend-services add-backend kyc-backend \
  --instance-group=kyc-group \
  --zone=asia-east1-a \
  --global
```

---

## 🔍 监控和日志

### 1. 使用 Cloud Logging

```bash
# 查看实时日志
gcloud logging read --limit 50 --format json

# 查看应用日志
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_id=kyc-app" \
  --limit 50 --format json
```

### 2. 启用 Cloud Monitoring

```bash
# 创建监控告警
gcloud monitoring policies create \
  --display-name="KYC App CPU Usage" \
  --condition-name="HighCPU" \
  --condition-threshold-value=0.8
```

### 3. SSH 到虚拟机查看日志

```bash
# 连接到虚拟机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 查看 Docker 日志
sudo docker-compose -f /opt/kyc-app/docker-compose.yml logs web

# 查看系统日志
sudo journalctl -u docker -f

# 查看应用特定错误
sudo docker logs $(sudo docker ps -f name=kyc-app_web -q)
```

---

## 🌐 配置自定义域名

### 1. 购买域名 (如果还没有)

推荐服务商：
- Google Domains
- Cloudflare
- Namecheap

### 2. 配置 DNS 记录

```bash
# 获取虚拟机外部 IP
gcloud compute instances describe kyc-app \
  --zone=asia-east1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)'

# 在域名提供商添加 A 记录:
# 记录类型: A
# 主机名: kyc (或 @)
# 值: [虚拟机外部 IP]
# TTL: 3600
```

### 3. 配置 SSL/HTTPS

部署脚本会自动配置 Let's Encrypt SSL，只需在提示时输入域名：

```bash
# 如果需要手动重新配置：
sudo certbot certonly --standalone \
  -d yourdomain.com \
  -n --agree-tos --email your@email.com

# 更新 Nginx 配置
sudo nano /opt/kyc-app/nginx.conf

# 重新加载 Nginx
sudo docker-compose -f /opt/kyc-app/docker-compose.yml restart nginx
```

---

## 📱 手机应用配置

在手机应用中配置 Webhook URL：

```
webhook_url: https://yourdomain.com/webhook/taobao/order
或
webhook_url: http://[虚拟机外部IP]/webhook/taobao/order
```

---

## ⚠️ 故障排查

### 问题 1: 无法连接到虚拟机

```bash
# 检查虚拟机状态
gcloud compute instances describe kyc-app --zone=asia-east1-a

# 重启虚拟机
gcloud compute instances reset kyc-app --zone=asia-east1-a

# 检查防火墙规则
gcloud compute firewall-rules list --filter="name~'allow-*'"
```

### 问题 2: 服务无法启动

```bash
# SSH 到虚拟机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 检查 Docker 服务
sudo systemctl status docker

# 查看详细日志
sudo docker-compose -f /opt/kyc-app/docker-compose.yml logs --tail=50
```

### 问题 3: 磁盘空间不足

```bash
# 检查磁盘使用情况
df -h

# 扩展磁盘大小
gcloud compute disks resize kyc-app \
  --size=50GB \
  --zone=asia-east1-a

# 重启虚拟机以应用更改
gcloud compute instances reset kyc-app --zone=asia-east1-a
```

### 问题 4: 数据库连接错误

```bash
# SSH 到虚拟机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 检查数据库容器
sudo docker-compose -f /opt/kyc-app/docker-compose.yml ps

# 查看数据库日志
sudo docker-compose -f /opt/kyc-app/docker-compose.yml logs db

# 重启数据库
sudo docker-compose -f /opt/kyc-app/docker-compose.yml restart db
```

---

## 🗑️ 清理资源

如果不再需要，删除资源以避免产生费用：

```bash
# 删除虚拟机实例
gcloud compute instances delete kyc-app --zone=asia-east1-a

# 删除防火墙规则
gcloud compute firewall-rules delete allow-http
gcloud compute firewall-rules delete allow-https
gcloud compute firewall-rules delete allow-ssh

# 删除磁盘 (如果未自动删除)
gcloud compute disks delete kyc-app --zone=asia-east1-a

# 删除实例模板 (如果已创建)
gcloud compute instance-templates delete kyc-template
```

---

## 📚 完整命令速查表

```bash
# 创建虚拟机
gcloud compute instances create kyc-app \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-medium \
  --zone=asia-east1-a \
  --boot-disk-size=20GB \
  --tags=http-server,https-server

# 连接到虚拟机
gcloud compute ssh kyc-app --zone=asia-east1-a

# 获取外部 IP
gcloud compute instances describe kyc-app --zone=asia-east1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)'

# 重启虚拟机
gcloud compute instances reset kyc-app --zone=asia-east1-a

# 停止虚拟机
gcloud compute instances stop kyc-app --zone=asia-east1-a

# 启动虚拟机
gcloud compute instances start kyc-app --zone=asia-east1-a

# 删除虚拟机
gcloud compute instances delete kyc-app --zone=asia-east1-a

# 创建防火墙规则
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server

# 查看所有虚拟机
gcloud compute instances list

# 查看所有防火墙规则
gcloud compute firewall-rules list
```

---

## ✅ 部署检查清单

- [ ] 创建谷歌云项目
- [ ] 启用计费
- [ ] 安装 gcloud CLI
- [ ] 创建 Compute Engine 虚拟机
- [ ] 配置防火墙规则
- [ ] 连接到虚拟机
- [ ] 运行部署脚本
- [ ] 配置环境变量
- [ ] 配置域名 (可选)
- [ ] 配置 SSL 证书
- [ ] 测试 Webhook
- [ ] 配置监控告警
- [ ] 设置自动备份
- [ ] 记录虚拟机 IP 和访问方式

---

## 🎯 常见问题

**Q: Compute Engine 和 VPS 有什么区别？**  
A: Compute Engine 本质上就是谷歌云提供的虚拟机 (VPS)，现有的 VPS 部署脚本完全适用。

**Q: 如何降低成本？**  
A: 使用 e2-small 机器型号，启用自动扩展，使用可抢占式虚拟机。

**Q: 如何备份数据？**  
A: 部署脚本已配置每日自动备份，也可使用 Google Cloud Storage 或 Cloud SQL 备份。

**Q: 如何处理高并发？**  
A: 升级机器类型 (n2-standard-2), 启用自动扩展，使用负载均衡器。

---

## 📖 相关资源

- [Google Cloud Compute Engine 文档](https://cloud.google.com/compute/docs)
- [gcloud CLI 参考](https://cloud.google.com/sdk/gcloud)
- [Cloud IAM 最佳实践](https://cloud.google.com/iam/docs/best-practices)
- [VPS 部署指南](PRODUCTION_DEPLOYMENT.md) ← 原始 VPS 部署文档

---

**版本**: 1.0  
**最后更新**: 2025-11-26  
**适用于**: Google Cloud Platform Compute Engine, KYC 系统 1.0+
