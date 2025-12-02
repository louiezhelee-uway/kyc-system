#!/bin/bash

# KYC 系统部署脚本 - 配置 Nginx 反向代理
# 使用方法: bash deploy-kyc-nginx.sh

set -e

echo "🚀 开始部署 KYC Nginx 反向代理配置..."

# 检查是否为 root
if [[ $EUID -ne 0 ]]; then
   echo "❌ 此脚本需要 root 权限。请使用 'sudo bash deploy-kyc-nginx.sh' 运行"
   exit 1
fi

# 步骤 1: 检查 KYC 代码目录
if [ ! -d "/opt/kyc-app" ]; then
    echo "❌ /opt/kyc-app 目录不存在。请先克隆代码："
    echo "   cd /opt"
    echo "   sudo git clone https://github.com/louiezhelee-uway/kyc-system.git kyc-app"
    exit 1
fi

echo "✅ 找到 KYC 应用目录: /opt/kyc-app"

# 步骤 2: 复制 Nginx 配置
echo ""
echo "📋 正在复制 Nginx 配置文件..."
cp /opt/kyc-app/kyc-nginx-config.conf /etc/nginx/sites-available/kyc
echo "✅ 配置文件已复制到 /etc/nginx/sites-available/kyc"

# 步骤 3: 创建符号链接
echo ""
echo "🔗 正在创建 sites-enabled 符号链接..."
if [ -L /etc/nginx/sites-enabled/kyc ]; then
    rm /etc/nginx/sites-enabled/kyc
    echo "   已删除旧的符号链接"
fi
ln -s /etc/nginx/sites-available/kyc /etc/nginx/sites-enabled/kyc
echo "✅ 符号链接已创建"

# 步骤 4: 禁用默认配置（可选）
echo ""
echo "⚙️  管理默认 Nginx 配置..."
if [ -L /etc/nginx/sites-enabled/default ]; then
    read -p "是否禁用默认 Nginx 配置? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm /etc/nginx/sites-enabled/default
        echo "✅ 默认配置已禁用"
    fi
fi

# 步骤 5: 测试 Nginx 配置
echo ""
echo "🧪 正在测试 Nginx 配置..."
if nginx -t > /dev/null 2>&1; then
    echo "✅ Nginx 配置语法正确"
else
    echo "❌ Nginx 配置有错误:"
    nginx -t
    exit 1
fi

# 步骤 6: 重启 Nginx
echo ""
echo "🔄 正在重启 Nginx 服务..."
systemctl restart nginx
echo "✅ Nginx 已重启"

# 步骤 7: 验证 Nginx 状态
echo ""
echo "📊 验证 Nginx 状态..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx 服务运行中"
else
    echo "❌ Nginx 服务未运行"
    systemctl status nginx
    exit 1
fi

# 步骤 8: 启动 Docker 容器（如果还未启动）
echo ""
echo "🐳 检查 Docker 容器状态..."
cd /opt/kyc-app

if docker-compose ps | grep -q "kyc_nginx"; then
    echo "✅ Docker 容器已运行"
else
    echo "🔄 正在启动 Docker 容器..."
    docker-compose up -d
    echo "✅ Docker 容器已启动"
fi

# 步骤 9: 显示完成信息
echo ""
echo "════════════════════════════════════════════════════════════"
echo "✨ 部署完成！"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📍 架构说明:"
echo "   旧服务: http://317073.xyz (端口 80)"
echo "   新服务: https://kyc.317073.xyz (系统 Nginx → Docker 8080 → Flask 5000)"
echo ""
echo "🧪 测试命令:"
echo "   # 测试 HTTP 重定向到 HTTPS"
echo "   curl -v http://kyc.317073.xyz/"
echo ""
echo "   # 测试 HTTPS（如果证书已配置）"
echo "   curl -v https://kyc.317073.xyz/"
echo ""
echo "   # 查看 Nginx 日志"
echo "   tail -f /var/log/nginx/access.log"
echo ""
echo "📋 Nginx 配置文件位置:"
echo "   - 站点配置: /etc/nginx/sites-available/kyc"
echo "   - 已启用: /etc/nginx/sites-enabled/kyc"
echo ""
echo "🔄 重新加载配置（无需重启）:"
echo "   sudo nginx -s reload"
echo ""
echo "🛑 停止/重启 Nginx:"
echo "   sudo systemctl stop nginx"
echo "   sudo systemctl restart nginx"
echo ""
