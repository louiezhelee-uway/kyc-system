#!/bin/bash

# VPS Flask 应用诊断脚本

echo "========================================"
echo "  VPS Flask 应用诊断"
echo "========================================"
echo ""

# Step 1: 检查容器状态
echo "Step 1: 检查容器状态..."
echo ""
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Step 2: 查看 Flask 容器日志
echo "Step 2: Flask 容器日志..."
echo ""
docker logs --tail 50 kyc_web 2>&1
echo ""

# Step 3: 进入容器检查
echo "Step 3: 检查 Flask 应用文件..."
echo ""
docker exec kyc_web ls -la /app 2>&1 | head -15
echo ""

# Step 4: 检查 Python 和依赖
echo "Step 4: 检查 Python 和依赖..."
echo ""
docker exec kyc_web python --version 2>&1
echo ""

# Step 5: 尝试手动运行 Flask
echo "Step 5: 测试 Flask 应用启动..."
echo ""
docker exec kyc_web python -c "
try:
    from app import create_app
    app = create_app()
    print('✓ Flask 应用创建成功')
    print('✓ 应用上下文:', app.name)
except Exception as e:
    print(f'❌ Flask 应用错误: {e}')
    import traceback
    traceback.print_exc()
" 2>&1
echo ""

# Step 6: 检查数据库连接
echo "Step 6: 检查数据库连接..."
echo ""
docker exec kyc_web python -c "
import os
from sqlalchemy import create_engine
db_url = os.getenv('DATABASE_URL', 'postgresql://kyc_user:kyc_password@postgres:5432/kyc_db')
print(f'数据库 URL: {db_url}')
try:
    engine = create_engine(db_url)
    with engine.connect() as conn:
        result = conn.execute('SELECT 1')
        print('✓ 数据库连接成功')
except Exception as e:
    print(f'❌ 数据库连接失败: {e}')
" 2>&1
echo ""

# Step 7: 直接测试 Flask 端口
echo "Step 7: 测试 Flask 应用端口..."
echo ""
if docker exec kyc_web curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✓ Flask 应用在容器内响应正常"
    docker exec kyc_web curl -s http://localhost:5000/health
else
    echo "❌ Flask 应用在容器内不响应"
fi
echo ""

# Step 8: 测试从主机访问
echo "Step 8: 从主机测试 Flask..."
echo ""
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✓ Flask 应用从主机可访问"
    curl -s http://localhost:5000/health
else
    echo "❌ Flask 应用从主机无法访问"
    echo "尝试检查网络连接..."
    docker network ls | grep kyc
fi
echo ""

# Step 9: 重启 Flask 容器
echo "Step 9: 重启 Flask 容器..."
echo ""
docker-compose restart web
sleep 5
echo "✓ 容器已重启，等待 5 秒..."
echo ""

# Step 10: 再次测试
echo "Step 10: 重启后测试..."
echo ""
sleep 2
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Flask 应用现在响应正常"
else
    echo "⚠️  Flask 应用仍未响应"
    echo "请检查: docker logs kyc_web"
fi
echo ""
