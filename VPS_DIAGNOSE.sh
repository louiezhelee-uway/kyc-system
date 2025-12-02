#!/bin/bash

# VPS 故障诊断脚本
# 用途: 诊断 Docker 容器启动失败的原因
# 使用: bash VPS_DIAGNOSE.sh

echo "========================================"
echo "  KYC 系统 VPS 故障诊断"
echo "========================================"
echo ""

echo "📋 系统信息"
echo "======================================"
uname -a
echo "内存: $(free -h | grep Mem)"
echo "磁盘: $(df -h / | tail -1)"
echo ""

echo "🐳 Docker 信息"
echo "======================================"
docker --version
docker-compose --version
docker info | grep -E "(Docker Root Dir|Storage Driver|Cgroup Driver)" || true
echo ""

echo "🔍 检查 docker-compose.yml"
echo "======================================"
if [ -f "docker-compose.yml" ]; then
    echo "✓ 文件存在"
    echo "文件大小: $(wc -c < docker-compose.yml) bytes"
    echo "行数: $(wc -l < docker-compose.yml)"
    
    echo ""
    echo "验证 YAML 语法..."
    if docker-compose config > /dev/null 2>&1; then
        echo "✓ YAML 语法正确"
    else
        echo "❌ YAML 语法错误!"
        docker-compose config
    fi
else
    echo "❌ docker-compose.yml 不存在"
    exit 1
fi
echo ""

echo "🔍 检查 Dockerfile"
echo "======================================"
if [ -f "Dockerfile" ]; then
    echo "✓ 文件存在"
    echo "文件大小: $(wc -c < Dockerfile) bytes"
else
    echo "❌ Dockerfile 不存在"
fi
echo ""

echo "🔍 检查关键应用文件"
echo "======================================"
files=("run.py" "requirements.txt" "app/__init__.py" "app/models/__init__.py")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "❌ $file 缺失"
    fi
done
echo ""

echo "🐳 Docker 镜像"
echo "======================================"
docker images | grep -E "(kyc|postgres|nginx|python)" || echo "（无相关镜像）"
echo ""

echo "🐳 Docker 容器"
echo "======================================"
docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
if [ $(docker ps -a | wc -l) -le 1 ]; then
    echo "（无容器运行）"
fi
echo ""

echo "🔍 Docker 网络"
echo "======================================"
docker network ls | grep -E "(kyc|bridge)" || echo "（无 kyc 网络）"
echo ""

echo "🔍 Docker 卷"
echo "======================================"
docker volume ls | grep -i kyc || echo "（无 kyc 卷）"
echo ""

echo "🔍 检查 Git 仓库"
echo "======================================"
if [ -d ".git" ]; then
    echo "✓ Git 仓库存在"
    echo "当前分支: $(git branch --show-current)"
    echo "最近提交: $(git log -1 --oneline)"
else
    echo "❌ Git 仓库不存在"
fi
echo ""

echo "🔍 检查环境变量"
echo "======================================"
if [ -f ".env" ]; then
    echo "✓ .env 文件存在"
    echo "内容:"
    grep -v "^#" .env | grep -v "^$" | head -10
else
    echo "⚠️  .env 文件不存在（某些环境变量可能未设置）"
fi
echo ""

echo "🔍 最近的 Docker 事件"
echo "======================================"
docker events --since 10m 2>&1 | head -20 &
sleep 2
kill %1 2>/dev/null || true
echo ""

echo "========================================"
echo "  诊断完成"
echo "========================================"
echo ""
echo "建议:"
echo "1. 如果 YAML 语法错误，运行: docker-compose config"
echo "2. 如果镜像缺失，运行: docker-compose build"
echo "3. 如果容器崩溃，运行: docker-compose logs web postgres"
echo "4. 如果网络问题，运行: docker network inspect kyc_network"
echo "5. 尝试重新启动: docker-compose down && docker-compose up -d"
echo ""
