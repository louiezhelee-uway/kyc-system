# 🚀 VPS 快速修复指南（仅需 5 分钟）

## 目标
修复 VPS 上的 docker-compose.yml 冲突和 YAML 语法错误，使 Flask 应用正常运行。

---

## 📋 快速步骤（推荐方式）

在您的 Mac 上运行：

```bash
# 连接到 VPS
gcloud compute ssh kyc-app --zone=asia-east1-a
```

在 VPS 上运行（逐行复制粘贴）：

```bash
# 成为 root 用户
sudo su -

# 进入应用目录
cd /opt/kyc-app

# 放弃本地更改，拉取最新代码
git checkout -- docker-compose.yml
git pull origin main --force

# 验证 YAML
docker-compose config > /dev/null && echo "✅ YAML OK" || echo "❌ YAML Error"

# 重启容器
docker-compose down
docker-compose up -d --build
sleep 20

# 查看状态
docker-compose ps
```

---

## ✅ 验证成功

```bash
# 查看日志（应该看到 "Running on http://0.0.0.0:5000"）
docker-compose logs web | tail -10

# 测试 API
curl https://kyc.317073.xyz/api/health

# 应该返回类似：
# {"status": "ok"} 或类似的 JSON 响应
```

---

## 📊 预期输出

### docker-compose ps 的输出

```
NAME            STATUS
kyc_postgres    Up 20 seconds (healthy)
kyc_web         Up 19 seconds
kyc_nginx       Up 19 seconds
```

### Flask 日志的输出

```
 * Running on http://0.0.0.0:5000
 * Debug mode: off
```

### API 测试的输出

```bash
curl -v https://kyc.317073.xyz/api/health

# 应该看到：
# > GET /api/health HTTP/2
# < HTTP/2 200
# < content-type: application/json
```

---

## 🆘 如果失败？

### 问题: git pull 仍然失败

```bash
git reset --hard origin/main
git pull origin main
```

### 问题: YAML 仍然有错误

```bash
rm docker-compose.yml
curl -s https://raw.githubusercontent.com/louiezhelee-uway/kyc-system/main/docker-compose.yml -o docker-compose.yml
docker-compose config > /dev/null && echo "OK"
```

### 问题: Flask 容器一直重启

```bash
# 查看详细日志
docker-compose logs web

# 检查数据库连接
docker-compose logs postgres
```

### 问题: 502 Bad Gateway

这通常只是启动缓慢。等待 30 秒后再试：

```bash
sleep 30
curl https://kyc.317073.xyz/api/health
```

---

## 📚 更多帮助

- 详细指南: 查看 `VPS_DOCKER_FIX_GUIDE.md`
- 自动脚本: 可以运行 `bash fix-vps-docker.sh`（如果已上传到 VPS）

---

## 💡 技术背景

**问题**: VPS 上的 docker-compose.yml 与 GitHub 上的版本不同
**原因**: 文件中存在 YAML 行断裂和缩进错误
**解决**: 用最新的正确版本替换

**更改内容**:
- ✅ Commit 3379caa: 修复了 docker-compose.yml 的 YAML 语法
- ✅ Commit 6dbab77: 添加了修复指南和脚本

---

**预期结果**: 所有 3 个 Docker 容器正常运行，Flask 应用响应请求！ 🎉
