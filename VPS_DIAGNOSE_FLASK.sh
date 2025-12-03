#!/bin/bash

# VPS_DIAGNOSE_FLASK.sh - 诊断 Flask 容器问题

cd /opt/kyc-app || exit 1

echo "════════════════════════════════════════════════════════"
echo "🔍 诊断 Flask 容器问题"
echo "════════════════════════════════════════════════════════"

# 1. 检查容器状态
echo ""
echo "📊 容器状态:"
docker-compose ps

# 2. 查看 Flask 容器日志
echo ""
echo "📋 Flask 容器日志 (最后 50 行):"
docker-compose logs web | tail -50

# 3. 进入容器检查环境变量
echo ""
echo "🔧 检查环境变量:"
docker-compose exec -T web env | grep -E "SUMSUB|DATABASE|FLASK"

# 4. 测试数据库连接
echo ""
echo "🗄️  测试数据库连接:"
docker-compose exec -T web python -c "
import os
from app import db, create_app
app = create_app()
with app.app_context():
    try:
        result = db.session.execute('SELECT 1')
        print('✅ 数据库连接成功')
    except Exception as e:
        print(f'❌ 数据库连接失败: {e}')
" 2>&1 || echo "⚠️  执行失败"

# 5. 测试 Flask 应用启动
echo ""
echo "🚀 测试 Flask 应用:"
docker-compose exec -T web python -c "
try:
    from app import create_app
    app = create_app()
    print('✅ Flask 应用创建成功')
    with app.app_context():
        print('✅ 应用上下文正常')
except Exception as e:
    print(f'❌ Flask 应用错误: {e}')
    import traceback
    traceback.print_exc()
" 2>&1

# 6. 查看容器进程
echo ""
echo "📌 容器进程:"
docker-compose exec -T web ps aux | grep -E "python|flask"

# 7. 尝试直接访问健康检查
echo ""
echo "🏥 尝试访问健康检查:"
curl -v http://localhost:5000/health 2>&1 | head -20 || echo "连接失败"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 诊断完成"
echo "════════════════════════════════════════════════════════"
