#!/bin/bash

# KYC 系统快速启动脚本
# 支持 Docker 和本地开发两种模式

echo "╔════════════════════════════════════════╗"
echo "║   KYC 自动化验证系统 - 快速启动        ║"
echo "╚════════════════════════════════════════╝"
echo ""

# 检查依赖
echo "检查依赖..."

DOCKER_INSTALLED=true
DOCKER_COMPOSE_INSTALLED=true

if ! command -v docker &> /dev/null; then
    DOCKER_INSTALLED=false
fi

if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_INSTALLED=false
fi

# 如果 Docker 未安装，提供替代方案
if [ "$DOCKER_INSTALLED" = false ] || [ "$DOCKER_COMPOSE_INSTALLED" = false ]; then
    echo ""
    echo "⚠️  Docker 未完全安装"
    echo ""
    echo "你有两个选择:"
    echo ""
    echo "1️⃣  安装 Docker (推荐用于生产环境)"
    echo "   • 访问: https://www.docker.com/products/docker-desktop"
    echo "   • 或者: brew install docker docker-compose"
    echo ""
    echo "2️⃣  使用本地开发模式 (推荐用于开发)"
    echo "   • 运行: chmod +x local-dev.sh && ./local-dev.sh"
    echo "   • 需要: Python 3 + PostgreSQL"
    echo ""
    exit 1
fi

echo "✅ Docker 已安装"
echo ""

# 创建 .env 文件
if [ ! -f .env ]; then
    echo "创建 .env 配置文件..."
    cp .env.docker .env
    echo "✅ .env 文件已创建"
    echo ""
    echo "⚠️  请编辑 .env 文件，填入实际的配置:"
    echo "   - SUMSUB_API_KEY"
    echo "   - WEBHOOK_SECRET"
    echo "   - SECRET_KEY"
    echo ""
fi

# 启动服务
echo "启动 Docker 容器..."
docker-compose up -d

echo ""
echo "✅ 启动完成！"
echo ""
echo "════════════════════════════════════════"
echo "服务已启动，请访问:"
echo ""
echo "  🌐 Web 界面:     http://localhost"
echo "  📊 API 接口:     http://localhost/api"
echo "  🗄️  数据库:      localhost:5432"
echo ""
echo "════════════════════════════════════════"
echo ""
echo "常用命令:"
echo "  查看状态:    docker-compose ps"
echo "  查看日志:    docker-compose logs -f web"
echo "  进入容器:    docker-compose exec web bash"
echo "  停止服务:    docker-compose down"
echo ""
echo "详细文档: 查看 DOCKER.md"
echo ""
