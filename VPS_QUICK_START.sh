#!/bin/bash

# VPS Docker 快速启动脚本
# 用途: 诊断问题并启动所有容器
# 使用: bash VPS_QUICK_START.sh

set -e

echo "========================================"
echo "  KYC 系统 VPS 快速启动脚本"
echo "========================================"
echo ""

# Step 1: 检查 docker 和 docker-compose
echo "✓ Step 1: 检查 Docker 安装..."
docker --version
docker-compose --version
echo ""

# Step 2: 检查项目目录
echo "✓ Step 2: 检查项目结构..."
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 错误: 未找到 docker-compose.yml"
    echo "   请确保在项目根目录运行此脚本"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    echo "❌ 错误: 未找到 Dockerfile"
    exit 1
fi

if [ ! -f "run.py" ]; then
    echo "❌ 错误: 未找到 run.py"
    exit 1
fi

echo "✓ docker-compose.yml 存在"
echo "✓ Dockerfile 存在"
echo "✓ run.py 存在"
echo ""

# Step 3: 验证 docker-compose.yml 语法
echo "✓ Step 3: 验证 docker-compose.yml 语法..."
docker-compose config > /dev/null && echo "✓ 配置有效" || {
    echo "❌ 配置错误!"
    docker-compose config
    exit 1
}
echo ""

# Step 4: 显示当前容器状态
echo "✓ Step 4: 当前 Docker 容器状态..."
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true
echo ""

# Step 5: 拉取最新代码
echo "✓ Step 5: 更新代码..."
git status
read -p "  继续使用当前代码? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "正在拉取最新代码..."
    git pull origin main
fi
echo ""

# Step 6: 停止旧容器
echo "✓ Step 6: 停止旧容器..."
docker-compose down || true
sleep 2
echo ""

# Step 7: 清理未使用的镜像（可选）
echo "✓ Step 7: 清理 Docker 资源..."
echo "  删除不用的容器和镜像..."
docker container prune -f > /dev/null 2>&1 || true
docker image prune -f > /dev/null 2>&1 || true
echo ""

# Step 8: 构建和启动容器
echo "✓ Step 8: 构建并启动容器..."
echo "  这可能需要 2-5 分钟..."
docker-compose up -d --build
sleep 10
echo ""

# Step 9: 检查容器状态
echo "✓ Step 9: 检查容器启动状态..."
echo ""
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Step 10: 检查容器日志
echo "✓ Step 10: 检查应用日志..."
echo ""
echo "--- PostgreSQL 日志 ---"
docker logs --tail 5 kyc_postgres 2>&1 || echo "（容器未启动）"
echo ""

echo "--- Flask 应用日志 ---"
docker logs --tail 10 kyc_web 2>&1 || echo "（容器未启动）"
echo ""

echo "--- Nginx 日志 ---"
docker logs --tail 5 kyc_nginx 2>&1 || echo "（容器未启动）"
echo ""

# Step 11: 等待数据库就绪
echo "✓ Step 11: 等待数据库就绪..."
for i in {1..30}; do
    if docker exec kyc_postgres pg_isready -U kyc_user > /dev/null 2>&1; then
        echo "✓ 数据库已连接"
        break
    fi
    echo "  等待... ($i/30)"
    sleep 1
done
echo ""

# Step 12: 创建数据库表
echo "✓ Step 12: 初始化数据库..."
docker exec kyc_web python -c "
from app import create_app, db
with create_app().app_context():
    db.create_all()
    print('✓ 数据库表已创建')
" 2>&1 || echo "⚠️  数据库初始化可能失败，检查日志"
echo ""

# Step 13: 最终验证
echo "========================================"
echo "  启动完成！进行最终验证..."
echo "========================================"
echo ""

# 测试 API 连接
echo "✓ 测试 Flask API..."
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Flask 应用响应正常"
else
    echo "⚠️  Flask 应用暂未响应，请检查日志"
fi
echo ""

# 测试数据库
echo "✓ 测试数据库连接..."
if docker exec kyc_postgres psql -U kyc_user -d kyc_db -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ 数据库连接正常"
else
    echo "⚠️  数据库连接失败，请检查日志"
fi
echo ""

# 显示重要信息
echo "========================================"
echo "  🎉 启动成功！"
echo "========================================"
echo ""
echo "重要信息："
echo "  • Flask 应用: http://localhost:5000"
echo "  • 数据库: kyc_db (postgresql://kyc_user@postgres:5432)"
echo "  • Nginx: http://kyc.317073.xyz (需要配置 DNS)"
echo ""
echo "常用命令:"
echo "  查看日志: docker-compose logs -f"
echo "  停止服务: docker-compose down"
echo "  重启服务: docker-compose restart"
echo "  进入数据库: docker exec -it kyc_postgres psql -U kyc_user -d kyc_db"
echo ""
echo "故障排查:"
echo "  1. 检查日志: docker-compose logs web postgres nginx"
echo "  2. 检查网络: docker network ls"
echo "  3. 检查磁盘: df -h"
echo "  4. 检查内存: docker stats"
echo ""
