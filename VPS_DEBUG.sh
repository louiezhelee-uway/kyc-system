#!/bin/bash

# VPS 部署诊断和修复脚本 v2
# 用途: 诊断并修复路径和文件问题

set -e

echo "========================================"
echo "  VPS 部署诊断和修复 v2"
echo "========================================"
echo ""

# Step 1: 检查当前工作目录
echo "Step 1: 检查工作目录..."
echo "当前目录: $(pwd)"
echo "工作目录内容:"
ls -la | head -15
echo ""

# Step 2: 检查关键文件是否存在
echo "Step 2: 检查关键文件..."
files=("Dockerfile" "docker-compose.yml" "requirements.txt" "run.py")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file 存在"
    else
        echo "❌ $file 不存在"
    fi
done
echo ""

# Step 3: 检查 Dockerfile 内容
if [ -f "Dockerfile" ]; then
    echo "Step 3: Dockerfile 内容..."
    head -5 Dockerfile
    echo ""
fi

# Step 4: 显示 docker-compose.yml 中 web 的构建配置
echo "Step 4: docker-compose.yml 构建配置..."
grep -A 5 "build:" docker-compose.yml || echo "❌ 未找到构建配置"
echo ""

# Step 5: 检查 docker-compose 配置
echo "Step 5: 验证 docker-compose.yml 语法..."
docker-compose config > /dev/null && echo "✓ YAML 语法正确" || {
    echo "❌ YAML 语法错误"
    docker-compose config 2>&1 | head -20
}
echo ""

# Step 6: 显示 docker-compose 的完整 web 服务配置
echo "Step 6: docker-compose web 服务完整配置..."
docker-compose config | grep -A 30 "web:" || echo "❌ 无法获取配置"
echo ""

# Step 7: 尝试构建
echo "Step 7: 尝试构建镜像..."
docker-compose build --no-cache web 2>&1 | tail -30 || true
echo ""
