# ✅ Docker-Compose YAML 修复指南

## 问题诊断
您的 VPS 上 `docker-compose.yml` 存在 YAML 解析错误，导致：
```
ERROR: yaml.parser.ParserError: while parsing a block mapping
  in "./docker-compose.yml", line 29, column 5
expected <block end>, but found '<scalar>'
```

**原因**: 文件中某些长行被错误地换行了，破坏了 YAML 缩进结构。

## 解决方案

### 方案 A: 拉取最新代码（推荐）

在 VPS 上执行：

```bash
cd /opt/kyc-app

# 拉取最新的修复
git pull origin main

# 验证 YAML 语法
docker-compose config > /dev/null && echo "✅ YAML 正确" || echo "❌ 仍有错误"

# 重建容器
docker-compose down
docker-compose up -d --build

# 等待容器启动
sleep 10

# 查看日志
docker-compose logs web | tail -30
```

### 方案 B: 手动修复（如果 git pull 失败）

在 VPS 上：

```bash
cd /opt/kyc-app

# 备份旧文件
cp docker-compose.yml docker-compose.yml.bak

# 删除旧文件
rm docker-compose.yml

# 使用 curl 从 GitHub 下载新文件
curl -s https://raw.githubusercontent.com/louiezhelee-uway/kyc-system/main/docker-compose.yml -o docker-compose.yml

# 验证
docker-compose config > /dev/null && echo "✅ YAML 正确"

# 重启
docker-compose down
docker-compose up -d --build
```

## 验证修复是否成功

### 步骤 1: 检查容器状态
```bash
docker-compose ps
```

应该看到：
- `kyc_postgres` - UP (healthy) ✅
- `kyc_web` - UP ✅
- `kyc_nginx` - UP ✅

### 步骤 2: 检查 Flask 日志
```bash
docker-compose logs web | tail -20
```

应该看到：
```
 * Running on http://0.0.0.0:5000
 * Debug mode: off
```

### 步骤 3: 测试 API
```bash
# 在 VPS 本地测试
curl http://localhost:5000/api/health

# 或者从您的 Mac 测试
curl https://kyc.317073.xyz/api/health
```

应该返回 `200 OK`（如果返回 502，说明 Flask 还在启动）。

## 提交信息

- **Commit ID**: 3379caa
- **修改内容**: 修复 docker-compose.yml 的 YAML 语法错误
- **已推送到**: GitHub main 分支

---

**下一步**: 应用此修复后，系统应该完全正常运行！🚀
