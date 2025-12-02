# 🔧 VPS Docker-Compose 修复步骤

## 问题概览

您的 VPS 上遇到了 git 冲突和 YAML 语法错误：

```
error: Your local changes to the following files would be overwritten by merge:
        docker-compose.yml
Please commit your changes or stash them before you merge.
```

**原因**: VPS 上的 `docker-compose.yml` 与 GitHub 上的版本不同，需要强制更新。

---

## 快速修复（推荐）

### 方案 A: 使用自动化脚本（最简单）

在 VPS 上执行以下命令：

```bash
# SSH 连接到 VPS
gcloud compute ssh kyc-app --zone=asia-east1-a

# 在 VPS 上运行以下命令
sudo su -
cd /opt/kyc-app

# 放弃本地更改
git checkout -- docker-compose.yml

# 强制拉取最新代码
git pull origin main --force

# 验证 YAML 语法
docker-compose config > /dev/null && echo "✅ YAML 正确" || echo "❌ 仍有错误"

# 重启容器
docker-compose down
docker-compose up -d --build

# 等待启动
sleep 15

# 查看状态
docker-compose ps
docker-compose logs web | tail -20
```

### 方案 B: 手动方式（如果 git 出问题）

```bash
cd /opt/kyc-app

# 删除损坏的文件
rm docker-compose.yml

# 从 GitHub 下载新文件
curl -s https://raw.githubusercontent.com/louiezhelee-uway/kyc-system/main/docker-compose.yml -o docker-compose.yml

# 验证
docker-compose config > /dev/null && echo "✅ YAML 正确"

# 重启
docker-compose down
docker-compose up -d --build
sleep 15
docker-compose ps
```

---

## 详细步骤说明

### 第 1 步: SSH 连接到 VPS

```bash
# 在您的 Mac 上执行
gcloud compute ssh kyc-app --zone=asia-east1-a
```

### 第 2 步: 导航到应用目录

```bash
sudo su -
cd /opt/kyc-app
pwd  # 应该显示 /opt/kyc-app
```

### 第 3 步: 放弃本地更改

```bash
# 查看哪些文件有更改
git status

# 放弃对 docker-compose.yml 的更改
git checkout -- docker-compose.yml
```

### 第 4 步: 拉取最新代码

```bash
# 拉取最新版本（这次应该成功）
git pull origin main

# 输出应该显示：
# From https://github.com/louiezhelee-uway/kyc-system
#  * branch            main       -> FETCH_HEAD
# Updating [old-commit]..[new-commit]
# Fast-forward
#  docker-compose.yml | [修改内容]
```

### 第 5 步: 验证 YAML 语法

```bash
# 使用 docker-compose 验证
docker-compose config > /dev/null

# 如果成功，应该没有输出且返回 0
# 如果失败，会显示 ParserError
```

### 第 6 步: 重启 Docker 容器

```bash
# 停止所有容器
docker-compose down

# 重新构建并启动
docker-compose up -d --build

# 等待容器启动（15秒）
sleep 15
```

### 第 7 步: 验证所有容器都在运行

```bash
docker-compose ps

# 应该显示：
# NAME            STATUS
# kyc_postgres    Up X seconds (healthy)
# kyc_web         Up X seconds
# kyc_nginx       Up X seconds
```

### 第 8 步: 检查 Flask 是否正常启动

```bash
# 查看最后 20 行日志
docker-compose logs web | tail -20

# 应该看到类似：
#  * Running on http://0.0.0.0:5000
#  * Debug mode: off
```

### 第 9 步: 测试 API 端点

```bash
# 在 VPS 上本地测试
curl http://localhost:5000/api/health

# 或者从您的 Mac 测试 HTTPS
curl https://kyc.317073.xyz/api/health

# 应该返回 200 OK（如果还在启动可能返回 502）
```

---

## 故障排除

### 问题 1: git pull 仍然失败

```bash
# 强制放弃所有更改
git reset --hard origin/main

# 然后拉取
git pull origin main
```

### 问题 2: docker-compose 命令不存在

```bash
# 检查安装
docker-compose --version

# 如果没安装，安装它
sudo apt-get update
sudo apt-get install -y docker-compose

# 或使用 Docker 内置的 compose
docker compose --version
```

### 问题 3: YAML 仍然有错误

```bash
# 检查文件内容（查找长行）
grep -n "postgresql://" docker-compose.yml

# 如果显示行被断开，手动修复或重新下载
curl -s https://raw.githubusercontent.com/louiezhelee-uway/kyc-system/main/docker-compose.yml -o docker-compose.yml
```

### 问题 4: Flask 容器一直在重启

```bash
# 查看完整日志
docker-compose logs web

# 查看 PostgreSQL 是否健康
docker-compose logs postgres

# 检查网络连接
docker network ls
docker network inspect kyc_kyc_network
```

### 问题 5: 502 Bad Gateway 错误

这通常意味着 Flask 还在启动。稍等 30 秒后重试：

```bash
# 监控日志
docker-compose logs -f web

# 当看到 "Running on http://0.0.0.0:5000" 时，就准备好了
```

---

## 验证修复成功

### 完整检查清单

- [ ] `docker-compose ps` 显示所有 3 个容器都是 "Up"
- [ ] `docker-compose logs postgres` 显示 "database system is ready to accept connections"
- [ ] `docker-compose logs web` 显示 "Running on http://0.0.0.0:5000"
- [ ] `curl http://localhost:5000/api/health` 返回 200
- [ ] `curl https://kyc.317073.xyz/api/health` 返回 200
- [ ] PostgreSQL 数据库可以连接和查询

### 测试数据库连接

```bash
# 在 VPS 上测试数据库
docker-compose exec -T postgres psql -U kyc_user -d kyc_db -c "SELECT COUNT(*) FROM kyc_verification;"

# 应该返回：
#  count
# -------
#      0
```

---

## 下一步

修复完成后，系统应该完全可用！

✅ **立即可用功能**:
- Flask 应用响应请求
- PostgreSQL 数据库可访问
- Nginx 反向代理正常工作
- HTTPS/SSL 完全功能

🎯 **后续工作**:
1. 测试 KYC 验证链接生成
2. 配置 Sumsub API（如果还未配置）
3. 测试 Webhook 集成
4. 监控生产环境

---

**遇到问题?** 提供以下信息来快速诊断：

1. `docker-compose ps` 的输出
2. `docker-compose logs web | tail -50` 的输出
3. `docker-compose config` 是否通过验证
4. VPS 上 `/opt/kyc-app` 目录中的文件列表

