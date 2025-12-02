#!/bin/bash

# VPS Dockerfile 创建脚本
# 如果 git pull 没有拉取到 Dockerfile，直接创建

echo "========================================"
echo "  VPS 上创建 Dockerfile"
echo "========================================"
echo ""

# 检查 Dockerfile 是否存在
if [ -f "Dockerfile" ]; then
    echo "✓ Dockerfile 已存在"
    ls -la Dockerfile
    exit 0
fi

echo "❌ Dockerfile 不存在，正在创建..."
echo ""

# 创建 Dockerfile
cat > Dockerfile << 'EOFDOCKER'
# 使用 Python 3.11 slim 基础镜像 (最小化依赖)
FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量，避免 dialog 等交互式工具
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# 安装系统依赖 (最小化)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# 复制 requirements.txt 并安装 Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 5000

# 启动 Flask 应用
CMD ["python", "run.py"]
EOFDOCKER

echo "✓ Dockerfile 已创建"
echo ""
echo "验证文件内容："
head -10 Dockerfile
echo ""
echo "========================================"
echo "  现在可以运行构建了"
echo "========================================"
echo ""
echo "执行: docker-compose build web --no-cache"
echo ""
