#!/bin/bash

# VPS 端口冲突解决脚本
# 问题: nginx 无法绑定 80 端口，可能被其他服务占用

echo "========================================"
echo "  VPS 端口冲突解决"
echo "========================================"
echo ""

# Step 1: 查看哪个进程占用了 80 端口
echo "Step 1: 查看占用 80 端口的进程..."
echo ""
lsof -i :80 2>/dev/null || netstat -tuln | grep :80 || echo "无法确定具体进程"
echo ""

# Step 2: 查看占用 443 端口的进程
echo "Step 2: 查看占用 443 端口的进程..."
echo ""
lsof -i :443 2>/dev/null || netstat -tuln | grep :443 || echo "无法确定具体进程"
echo ""

# Step 3: 查看现有的容器和端口
echo "Step 3: 查看 Docker 容器端口映射..."
docker ps -a --format "table {{.Names}}\t{{.Ports}}"
echo ""

# Step 4: 检查是否有其他 nginx 容器
echo "Step 4: 查看所有 nginx 相关容器..."
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -i nginx || echo "未找到其他 nginx 容器"
echo ""

# Step 5: 选项说明
echo "========================================"
echo "  解决方案"
echo "========================================"
echo ""
echo "选项 1: 删除占用端口的其他 nginx 容器"
echo "  docker rm -f $(docker ps -a | grep nginx | grep -v kyc_nginx | awk '{print $1}')"
echo ""
echo "选项 2: 更改 nginx 容器的端口映射 (改为 8080)"
echo "  修改 docker-compose.yml 中 nginx 的 ports:"
echo "    - \"8080:80\"    # 而不是 80:80"
echo "    - \"8443:443\"   # 而不是 443:443"
echo ""
echo "选项 3: 停止占用 80 端口的其他服务 (如 systemd-nginx 等)"
echo "  sudo systemctl stop nginx"
echo "  sudo systemctl stop apache2"
echo ""
echo "选项 4: 完全清空所有容器和卷，重新开始"
echo "  docker-compose down -v"
echo "  docker container prune -f"
echo "  docker volume prune -f"
echo "  docker-compose up -d"
echo ""
echo "========================================"
echo ""
