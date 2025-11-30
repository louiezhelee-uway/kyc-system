# 快速开始指南 - 三种启动方式

你的 KYC 系统已完全集成 Sumsub API。根据你的环境选择启动方式。

## 🎯 快速选择

| 环境 | 方式 | 命令 | 耗时 |
|------|------|------|------|
| 有 Docker | Docker 容器 | `./quick-start.sh` | 30秒 |
| 有 PostgreSQL | 本地开发 | `./local-dev.sh` | 10秒 |
| 无任何依赖 | 测试模式 | `python3 demo.py` | 5秒 |

---

## 1️⃣ **Docker 启动** (推荐生产)

### 前置要求
- Docker Desktop
- Docker Compose

### 安装 Docker

**macOS (Homebrew)**:
```bash
brew install docker docker-compose
open /Applications/Docker.app  # 启动 Docker
```

**或直接下载**:
https://www.docker.com/products/docker-desktop

### 启动应用

```bash
chmod +x quick-start.sh
./quick-start.sh
```

### 访问应用
```
http://localhost
```

---

## 2️⃣ **本地开发启动** (推荐开发)

### 前置要求
- Python 3.11+  ✅ (你已有)
- PostgreSQL 15

### 安装 PostgreSQL

```bash
# 使用 Homebrew
brew install postgresql@15

# 启动 PostgreSQL
brew services start postgresql@15

# 创建数据库
createdb kyc_db
```

### 启动应用

```bash
chmod +x local-dev.sh
./local-dev.sh
```

### 访问应用
```
http://localhost:5000
```

---

## 3️⃣ **测试模式启动** (推荐演示)

无需任何额外依赖！直接在你的 macOS 上运行。

### 运行演示

```bash
python3 demo.py
```

### 运行测试

```bash
python3 tests/test_sumsub_integration.py
```

---

## 📊 当前你的环境状态

✅ **已有**:
- Python 3.12.0
- Sumsub API 凭证

❌ **缺少**:
- Docker (可选)
- PostgreSQL (可选)

---

## 🚀 推荐使用流程

### 第 1 步: 验证集成 (5分钟)
```bash
# 运行系统演示，验证 Sumsub 集成
python3 demo.py
```

### 第 2 步: 完整功能测试 (需要 PostgreSQL)
```bash
# 安装 PostgreSQL
brew install postgresql@15
brew services start postgresql@15

# 启动完整应用
./local-dev.sh
```

### 第 3 步: 生产部署 (需要 Docker)
```bash
# 安装 Docker
brew install docker docker-compose

# 启动 Docker 应用
open /Applications/Docker.app

# 启动容器
./quick-start.sh
```

---

## 💻 命令速查表

### 系统演示和测试
```bash
# 系统演示 (无依赖)
python3 demo.py

# Sumsub 集成测试 (无数据库)
python3 tests/test_sumsub_integration.py

# 完整功能测试 (需要 PostgreSQL)
python3 tests/test_full_integration.py
```

### 应用启动
```bash
# Docker 启动 (推荐生产)
./quick-start.sh

# 本地开发启动 (需要 PostgreSQL)
./local-dev.sh

# 手动启动 Flask
python3 run.py
```

### Docker 管理 (如果用 Docker)
```bash
# 查看运行状态
docker-compose ps

# 查看日志
docker-compose logs -f web

# 停止服务
docker-compose down

# 进入容器
docker-compose exec web bash
```

### PostgreSQL 管理 (如果用本地开发)
```bash
# 启动 PostgreSQL
brew services start postgresql@15

# 停止 PostgreSQL
brew services stop postgresql@15

# 进入 PostgreSQL
psql -U $(whoami) -d kyc_db

# 创建数据库
createdb kyc_db
```

---

## 📚 重要文档

| 文档 | 用途 |
|------|------|
| `README.md` | 项目概览 |
| `SUMSUB_INTEGRATION.md` | Sumsub 集成详细指南 |
| `QUICK_START.md` | 快速启动 (30秒) |
| `PRODUCTION_DEPLOYMENT.md` | 生产部署指南 |
| `CHECKLIST.md` | 完成清单 |

---

## 🔧 故障排除

### 问题: `docker: command not found`
**解决**: 
```bash
brew install docker
# 然后启动 Docker Desktop
open /Applications/Docker.app
```

### 问题: `psql: command not found`
**解决**:
```bash
brew install postgresql@15
brew services start postgresql@15
```

### 问题: `python3: command not found`
**解决**: Python 已安装，如遇到路径问题：
```bash
/Library/Frameworks/Python.framework/Versions/3.12/bin/python3 demo.py
```

### 问题: 端口 5000 已被占用
**解决**:
```bash
# 查找占用进程
lsof -i :5000

# 杀掉进程 (PID 是进程号)
kill -9 <PID>

# 或改变端口
export FLASK_PORT=5001 && python3 run.py
```

### 问题: PostgreSQL 连接失败
**解决**:
```bash
# 检查 PostgreSQL 是否运行
brew services list

# 重启 PostgreSQL
brew services restart postgresql@15

# 检查数据库是否存在
psql -l
```

---

## ✨ 系统就绪检查清单

在运行应用前，验证以下项目:

- [x] Sumsub API 凭证已配置
- [x] HMAC-SHA256 签名实现
- [x] Flask 应用框架完成
- [x] 数据库模型完成
- [x] API 路由完成
- [x] PDF 报告生成完成
- [x] Webhook 处理完成

---

## 🎓 学习路径

### 初学者 (5分钟)
```bash
python3 demo.py  # 查看系统演示
```

### 开发者 (30分钟)
```bash
# 安装 PostgreSQL
brew install postgresql@15
brew services start postgresql@15

# 启动应用
./local-dev.sh

# 测试 API
curl http://localhost:5000
```

### 运维人员 (1小时)
```bash
# 安装 Docker
brew install docker docker-compose

# 启动容器
./quick-start.sh

# 检查状态
docker-compose ps
docker-compose logs -f
```

---

## 📞 获取帮助

### 查看文档
```bash
# 项目概览
cat README.md

# Sumsub 集成指南
cat SUMSUB_INTEGRATION.md

# 生产部署
cat PRODUCTION_DEPLOYMENT.md
```

### 运行测试
```bash
# 系统演示
python3 demo.py

# API 测试
curl -X POST http://localhost:5000/webhook/taobao/order \
  -H "Content-Type: application/json" \
  -d '{"order_id":"test","buyer_name":"Test","buyer_email":"test@example.com","buyer_phone":"13800138000","order_amount":99.99}'
```

---

## ✅ 下一步

1. **选择启动方式**
   - 快速验证: `python3 demo.py`
   - 完整功能: `./local-dev.sh` (需要 PostgreSQL)
   - 生产部署: `./quick-start.sh` (需要 Docker)

2. **查看文档**
   - `cat README.md`
   - `cat SUMSUB_INTEGRATION.md`

3. **配置淘宝/闲鱼 Webhook**
   - 参考: `PRODUCTION_DEPLOYMENT.md`

4. **部署到生产**
   - `./deploy-vps.sh <server_ip>`

---

**项目状态**: ✅ 生产就绪  
**Sumsub 集成**: ✅ 100% 完成  
**最后更新**: 2025-11-25
