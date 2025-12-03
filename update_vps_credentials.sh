#!/bin/bash

# Update VPS credentials with new Sumsub API keys

VPS_IP="35.212.217.145"
VPS_USER="louie"

# New credentials
NEW_TOKEN="prd:BUWAA7ogVIJZ7W9h7A4BaSRx.xm4V4Zef52mLLYJl0oJ1X4v878Ibo2ie"
NEW_SECRET="ypDDepVCvib3Oq3P6tfML91huztzOMuY"

echo "📝 更新 VPS 上的 Sumsub 凭证..."
echo "   IP: $VPS_IP"
echo "   Token: ${NEW_TOKEN:0:30}..."
echo "   Secret: ${NEW_SECRET:0:20}..."

# Update .env file on VPS
ssh $VPS_USER@$VPS_IP << SSH_COMMANDS
cd /opt/kyc-app

# Backup existing .env
cp .env .env.backup.$(date +%s)

# Update credentials
sed -i "s|SUMSUB_APP_TOKEN=.*|SUMSUB_APP_TOKEN=$NEW_TOKEN|g" .env
sed -i "s|SUMSUB_SECRET_KEY=.*|SUMSUB_SECRET_KEY=$NEW_SECRET|g" .env

echo "✅ .env 文件已更新"

# Verify
echo ""
echo "📋 当前凭证:"
grep "SUMSUB_" .env

# Restart containers
echo ""
echo "🔄 重启容器..."
docker-compose restart web

echo ""
echo "✅ 完成！"
echo ""
echo "📌 容器状态:"
docker-compose ps

SSH_COMMANDS
