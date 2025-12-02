#!/bin/bash

# VPS 完整修复脚本
# 用途: 清理旧配置、修复 .env、重新启动容器
# 使用: bash VPS_COMPLETE_FIX.sh

set -e

echo "========================================"
echo "  KYC 系统 VPS 完整修复"
echo "========================================"
echo ""

# 备份现有配置
echo "Step 1: 备份现有配置..."
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
echo "✓ .env 已备份"
echo ""

# 停止所有容器
echo "Step 2: 停止所有容器..."
docker-compose down || true
sleep 2
echo "✓ 容器已停止"
echo ""

# 清理orphaned容器和卷
echo "Step 3: 清理 orphaned 容器和旧部署..."
docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E "(bold_|zealous_)" | awk '{print $1}' | xargs -r docker rm -f
docker volume prune -f > /dev/null 2>&1 || true
echo "✓ 旧容器已清理"
echo ""

# 修复 .env 文件
echo "Step 4: 修复 .env 配置..."
cat > .env << 'EOF'
# Flask 配置
FLASK_ENV=production
FLASK_APP=run.py
FLASK_DEBUG=0

# 数据库配置 (使用 Docker 服务名 postgres, 不是 localhost)
DATABASE_URL=postgresql://kyc_user:kyc_password@postgres:5432/kyc_db

# Sumsub 生产配置
SUMSUB_APP_TOKEN=prd:1b15gKkFtPh440hQSOXIvjR3.OSJVLkmtJfnWVPS7IpuKCI2Tas4giOCO
SUMSUB_SECRET_KEY=CTHMPDlqphQmvB2fqBC7b6wF5v9iyqoK
SUMSUB_API_URL=https://api.sumsub.com

# Webhook 密钥
WEBHOOK_SECRET=your-webhook-secret-key-here
TAOBAO_WEBHOOK_SECRET=your-taobao-webhook-secret-here

# 应用域名
APP_DOMAIN=https://kyc.317073.xyz

# Python 配置
PYTHONUNBUFFERED=1
EOF

echo "✓ .env 已更新"
echo "  关键修改: DATABASE_URL 改为 postgres:5432 (Docker 服务名)"
echo "  关键修改: FLASK_ENV 改为 production"
echo "  关键修改: APP_DOMAIN 改为 https://kyc.317073.xyz"
echo ""

# 拉取最新代码
echo "Step 5: 更新代码..."
git pull origin main
echo "✓ 代码已更新"
echo ""

# 构建镜像
echo "Step 6: 构建 Docker 镜像..."
docker-compose build --no-cache web
echo "✓ 镜像已构建"
echo ""

# 启动容器
echo "Step 7: 启动容器..."
docker-compose up -d
sleep 5
echo "✓ 容器已启动"
echo ""

# 检查容器状态
echo "Step 8: 检查容器状态..."
echo ""
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 等待数据库就绪
echo "Step 9: 等待数据库就绪..."
for i in {1..60}; do
    if docker exec kyc_postgres pg_isready -U kyc_user > /dev/null 2>&1; then
        echo "✓ 数据库已就绪 ($i/60)"
        break
    fi
    echo "  等待... ($i/60)"
    sleep 1
done
echo ""

# 初始化数据库表
echo "Step 10: 初始化数据库..."
docker exec kyc_web python -c "
from app import create_app, db
with create_app().app_context():
    db.create_all()
    print('✓ 数据库表已创建')
" 2>&1 || echo "⚠️  表可能已存在"
echo ""

# 显示日志摘要
echo "Step 11: 显示启动日志..."
echo ""
echo "--- PostgreSQL 日志 ---"
docker logs --tail 5 kyc_postgres
echo ""
echo "--- Flask 日志 ---"
docker logs --tail 10 kyc_web
echo ""
echo "--- Nginx 日志 ---"
docker logs --tail 5 kyc_nginx
echo ""

# 最终验证
echo "========================================"
echo "  修复完成！"
echo "========================================"
echo ""
echo "✅ 关键修改:"
echo "  1. DATABASE_URL: localhost:5432 → postgres:5432"
echo "  2. FLASK_ENV: development → production"
echo "  3. APP_DOMAIN: http://localhost:5000 → https://kyc.317073.xyz"
echo "  4. 清理了旧的 orphaned 容器"
echo "  5. 重新构建了 Web 镜像"
echo ""
echo "🧪 下一步:"
echo "  运行验证脚本:"
echo "  $ bash VPS_VERIFICATION_CHECK.sh"
echo ""
