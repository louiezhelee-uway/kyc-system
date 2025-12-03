#!/bin/bash

# SSL 证书修复脚本
# 为 kyc.317073.xyz 生成新的 SSL 证书并更新 Nginx 配置

set -e

echo "🔐 开始为 kyc.317073.xyz 配置 SSL 证书..."

# 检查是否为 root
if [[ $EUID -ne 0 ]]; then
   echo "❌ 此脚本需要 root 权限。请使用 sudo 运行："
   echo "   sudo bash fix-ssl-certificate.sh"
   exit 1
fi

# 步骤 1：停止 Nginx（certbot 需要使用 443 端口）
echo ""
echo "🛑 停止 Nginx 服务..."
systemctl stop nginx
echo "✅ Nginx 已停止"

# 步骤 2：使用 certbot 生成证书
echo ""
echo "📜 使用 certbot 生成 SSL 证书..."
if certbot certonly \
    -d kyc.317073.xyz \
    --standalone \
    --non-interactive \
    --agree-tos \
    --register-unsafely-without-email \
    2>/dev/null; then
    echo "✅ SSL 证书生成成功"
else
    echo "⚠️  certbot 可能需要邮箱地址，请手动运行："
    echo "   sudo certbot certonly -d kyc.317073.xyz --standalone"
    exit 1
fi

# 步骤 3：更新 Nginx 配置文件
echo ""
echo "🔧 更新 Nginx 配置文件..."
NGINX_CONFIG="/etc/nginx/sites-available/kyc"

if [ ! -f "$NGINX_CONFIG" ]; then
    echo "❌ 找不到 Nginx 配置文件: $NGINX_CONFIG"
    exit 1
fi

# 检查是否已经使用了正确的证书
if grep -q "kyc.317073.xyz" "$NGINX_CONFIG"; then
    echo "✅ 配置文件已经使用正确的证书路径"
else
    echo "📝 替换证书路径..."
    # 备份原文件
    cp "$NGINX_CONFIG" "$NGINX_CONFIG.bak"
    
    # 替换证书路径
    sed -i 's|/etc/letsencrypt/live/317073.xyz/fullchain.pem|/etc/letsencrypt/live/kyc.317073.xyz/fullchain.pem|g' "$NGINX_CONFIG"
    sed -i 's|/etc/letsencrypt/live/317073.xyz/privkey.pem|/etc/letsencrypt/live/kyc.317073.xyz/privkey.pem|g' "$NGINX_CONFIG"
    
    echo "✅ 配置文件已更新（备份保存到 $NGINX_CONFIG.bak）"
fi

# 步骤 4：测试 Nginx 配置
echo ""
echo "🧪 测试 Nginx 配置..."
if nginx -t > /dev/null 2>&1; then
    echo "✅ Nginx 配置语法正确"
else
    echo "❌ Nginx 配置有错误，请查看上面的信息"
    echo "恢复备份文件..."
    [ -f "$NGINX_CONFIG.bak" ] && cp "$NGINX_CONFIG.bak" "$NGINX_CONFIG"
    exit 1
fi

# 步骤 5：启动 Nginx
echo ""
echo "🚀 启动 Nginx 服务..."
systemctl start nginx
echo "✅ Nginx 已启动"

# 步骤 6：验证 Nginx 状态
echo ""
echo "📊 验证状态..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx 服务运行中"
else
    echo "❌ Nginx 服务启动失败"
    exit 1
fi

# 步骤 7：显示证书信息
echo ""
echo "📜 证书信息："
openssl x509 -in /etc/letsencrypt/live/kyc.317073.xyz/fullchain.pem -text -noout | grep -A 2 "Subject:"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✨ SSL 证书配置完成！"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🧪 测试访问："
echo "   curl -v https://kyc.317073.xyz/"
echo ""
echo "📍 证书路径："
echo "   /etc/letsencrypt/live/kyc.317073.xyz/"
echo ""
echo "⏰ 证书有效期："
echo "   3 个月（certbot 会自动续期）"
echo ""
echo "🔄 证书自动续期："
echo "   sudo systemctl enable certbot.timer"
echo "   sudo systemctl start certbot.timer"
echo ""
