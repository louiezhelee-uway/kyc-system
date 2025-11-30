#!/bin/bash
set -e

echo "========================================"
echo "KYC 系统启动脚本"
echo "========================================"

# 等待 PostgreSQL 准备好
echo "⏳ 等待 PostgreSQL 服务准备好..."
while ! pg_isready -h postgres -U kyc_user -d kyc_db 2>/dev/null; do
  echo "  继续等待..."
  sleep 2
done
echo "✅ PostgreSQL 已准备好"

# 运行数据库迁移
echo ""
echo "⏳ 运行数据库迁移..."
if command -v flask &> /dev/null; then
  flask db upgrade || echo "⚠️  迁移脚本不存在，跳过"
else
  echo "⚠️  Flask 命令不可用，跳过迁移"
fi

# 创建报告目录
echo ""
echo "⏳ 创建报告目录..."
mkdir -p app/reports
echo "✅ 报告目录已创建"

# 启动应用
echo ""
echo "✅ 启动 Flask 应用..."
echo "========================================"

exec gunicorn \
  --bind 0.0.0.0:5000 \
  --workers 4 \
  --worker-class sync \
  --timeout 120 \
  --access-logfile - \
  --error-logfile - \
  --log-level info \
  run:app
