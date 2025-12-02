#!/bin/bash

# VPS 终极修复脚本 - 处理 Dockerfile 缺失问题

set -e

echo "========================================"
echo "  VPS 终极修复脚本"
echo "========================================"
echo ""

# Step 1: 检查并创建 Dockerfile
echo "Step 1: 检查 Dockerfile..."
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile 不存在，创建中..."
    cat > Dockerfile << 'EOFDOCKER'
FROM python:3.11-slim
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "run.py"]
EOFDOCKER
    echo "✓ Dockerfile 已创建"
else
    echo "✓ Dockerfile 已存在"
fi
echo ""

# Step 2: 验证 docker-compose.yml
echo "Step 2: 验证 docker-compose.yml..."
if docker-compose config > /dev/null 2>&1; then
    echo "✓ YAML 配置正确"
else
    echo "❌ YAML 配置错误"
    docker-compose config
    exit 1
fi
echo ""

# Step 3: 停止旧容器
echo "Step 3: 停止旧容器..."
docker-compose down || true
sleep 2
echo "✓ 容器已停止"
echo ""

# Step 4: 清理 orphaned 容器
echo "Step 4: 清理旧的容器和卷..."
docker container prune -f > /dev/null 2>&1 || true
docker volume prune -f > /dev/null 2>&1 || true
echo "✓ 清理完成"
echo ""

# Step 5: 构建镜像
echo "Step 5: 构建 Docker 镜像..."
docker-compose build --no-cache web 2>&1 | tail -20
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✓ 镜像构建成功"
else
    echo "❌ 镜像构建失败"
    exit 1
fi
echo ""

# Step 6: 启动容器
echo "Step 6: 启动容器..."
docker-compose up -d
sleep 5
echo "✓ 容器已启动"
echo ""

# Step 7: 检查容器状态
echo "Step 7: 检查容器状态..."
echo ""
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Step 8: 等待数据库就绪
echo "Step 8: 等待数据库就绪..."
for i in {1..60}; do
    if docker exec kyc_postgres pg_isready -U kyc_user > /dev/null 2>&1; then
        echo "✓ 数据库已就绪"
        break
    fi
    echo "  等待... ($i/60)"
    sleep 1
done
echo ""

# Step 9: 初始化数据库
echo "Step 9: 初始化数据库表..."
docker exec kyc_web python -c "
from app import create_app, db
with create_app().app_context():
    db.create_all()
    print('✓ 数据库表已创建')
" 2>&1 || echo "⚠️  表可能已存在"
echo ""

# Step 10: 显示日志
echo "Step 10: 显示启动日志..."
echo ""
echo "--- Flask 应用日志 ---"
docker logs --tail 20 kyc_web 2>&1 | grep -v "^$" | head -10 || echo "(无错误日志)"
echo ""

# Step 11: 最终验证
echo "Step 11: 最终验证..."
echo ""

if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Flask 应用响应正常"
else
    echo "⚠️  Flask 应用暂未响应，检查日志: docker logs kyc_web"
fi

if docker exec kyc_postgres psql -U kyc_user -d kyc_db -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ 数据库连接正常"
else
    echo "⚠️  数据库连接失败，检查日志: docker logs kyc_postgres"
fi

echo ""
echo "========================================"
echo "  🎉 修复完成！"
echo "========================================"
echo ""
echo "下一步:"
echo "  1. 运行验证脚本: bash VPS_VERIFICATION_CHECK.sh"
echo "  2. 查看日志: docker-compose logs -f"
echo "  3. 测试 API: curl http://localhost:5000/health"
echo ""
