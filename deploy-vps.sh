#!/bin/bash

# KYC 系统 VPS 部署脚本
# 用于在新的 Linux VPS 上快速部署完整的系统

set -e

echo "╔════════════════════════════════════════╗"
echo "║   KYC 系统 VPS 自动化部署              ║"
echo "╚════════════════════════════════════════╝"
echo ""

# 色彩
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ 此脚本必须以 root 权限运行${NC}"
    echo "请运行: sudo bash deploy-vps.sh"
    exit 1
fi

echo -e "${BLUE}步骤 1: 更新系统${NC}"
apt-get update
apt-get upgrade -y
echo -e "${GREEN}✅ 系统已更新${NC}\n"

echo -e "${BLUE}步骤 2: 安装依赖${NC}"
apt-get install -y curl wget git

# 安装 Docker
if ! command -v docker &> /dev/null; then
    echo "安装 Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
else
    echo "Docker 已安装"
fi

# 安装 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "安装 Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose 已安装"
fi

# 启动 Docker
systemctl start docker
systemctl enable docker
echo -e "${GREEN}✅ Docker 已安装并启动${NC}\n"

echo -e "${BLUE}步骤 3: 创建应用目录${NC}"
APP_DIR="/opt/kyc-app"
if [ ! -d "$APP_DIR" ]; then
    mkdir -p $APP_DIR
fi
echo -e "${GREEN}✅ 应用目录: $APP_DIR${NC}\n"

echo -e "${BLUE}步骤 4: 拉取代码${NC}"
cd $APP_DIR

# 检查是否已克隆
if [ ! -d ".git" ]; then
    echo "请输入 Git 仓库地址 (例如: https://github.com/username/kyc.git):"
    read REPO_URL
    git clone $REPO_URL .
else
    echo "更新现有代码..."
    git pull
fi
echo -e "${GREEN}✅ 代码已拉取${NC}\n"

echo -e "${BLUE}步骤 5: 配置环境变量${NC}"
if [ ! -f ".env" ]; then
    cp .env.docker .env
    echo -e "${YELLOW}⚠️  请编辑 .env 文件，填入实际的配置值${NC}"
    echo "编辑命令: nano $APP_DIR/.env"
    echo ""
    echo "必填项:"
    echo "  - SUMSUB_API_KEY"
    echo "  - WEBHOOK_SECRET"
    echo "  - SECRET_KEY"
    echo ""
    read -p "编辑完成后按 Enter 继续..."
else
    echo "✅ .env 文件已存在"
fi
echo -e "${GREEN}✅ 配置完成${NC}\n"

echo -e "${BLUE}步骤 6: 生成 SSL 证书${NC}"
echo "请输入你的域名 (例如: kyc.example.com):"
read DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${YELLOW}⚠️  跳过 SSL 证书生成${NC}"
else
    # 安装 Certbot
    if ! command -v certbot &> /dev/null; then
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    # 生成证书
    certbot certonly --standalone -d $DOMAIN -n --agree-tos --email admin@$DOMAIN
    
    if [ $? -eq 0 ]; then
        # 复制证书到应用目录
        mkdir -p $APP_DIR/certs
        cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $APP_DIR/certs/cert.pem
        cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $APP_DIR/certs/key.pem
        
        # 更新 nginx.conf
        sed -i "s/server_name _;/server_name $DOMAIN;/" $APP_DIR/nginx.conf
        
        echo -e "${GREEN}✅ SSL 证书已生成${NC}"
    else
        echo -e "${YELLOW}⚠️  SSL 证书生成失败，请手动配置${NC}"
    fi
fi
echo ""

echo -e "${BLUE}步骤 7: 启动服务${NC}"
cd $APP_DIR
docker-compose up -d
sleep 5

# 检查服务状态
if [ $(docker-compose ps | grep -c "Up") -ge 3 ]; then
    echo -e "${GREEN}✅ 所有服务已启动${NC}"
else
    echo -e "${YELLOW}⚠️  某些服务未启动，请检查日志${NC}"
    docker-compose logs
fi
echo ""

echo -e "${BLUE}步骤 8: 配置防火墙${NC}"
if command -v ufw &> /dev/null; then
    echo "启用防火墙规则..."
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw enable -y
    echo -e "${GREEN}✅ 防火墙已配置${NC}"
else
    echo -e "${YELLOW}⚠️  UFW 未安装，请手动配置防火墙${NC}"
fi
echo ""

echo -e "${BLUE}步骤 9: 配置定时备份${NC}"
BACKUP_DIR=$APP_DIR/backups
mkdir -p $BACKUP_DIR

# 创建备份脚本
cat > $APP_DIR/backup.sh << 'BACKUP_SCRIPT'
#!/bin/bash
BACKUP_DIR="/opt/kyc-app/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p $BACKUP_DIR
docker-compose exec -T postgres pg_dump -U kyc_user kyc_db > $BACKUP_DIR/backup_$TIMESTAMP.sql
# 保留最近 7 天的备份
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete
BACKUP_SCRIPT

chmod +x $APP_DIR/backup.sh

# 添加到 crontab (每天凌晨 2 点备份)
(crontab -l 2>/dev/null | grep -v "backup.sh"; echo "0 2 * * * $APP_DIR/backup.sh") | crontab -
echo -e "${GREEN}✅ 备份已配置 (每天凌晨 2 点)${NC}\n"

echo "╔════════════════════════════════════════╗"
echo "║   🎉 部署完成！                         ║"
echo "╚════════════════════════════════════════╝"
echo ""

echo -e "${BLUE}系统信息:${NC}"
echo "应用目录: $APP_DIR"
echo "域名: ${DOMAIN:-未配置}"
echo ""

echo -e "${BLUE}访问地址:${NC}"
if [ -z "$DOMAIN" ]; then
    echo "  http://$(hostname -I | awk '{print $1}')"
else
    echo "  https://$DOMAIN"
fi
echo ""

echo -e "${BLUE}常用命令:${NC}"
echo "  查看状态: docker-compose -f $APP_DIR/docker-compose.yml ps"
echo "  查看日志: docker-compose -f $APP_DIR/docker-compose.yml logs -f web"
echo "  停止服务: docker-compose -f $APP_DIR/docker-compose.yml down"
echo "  重启服务: docker-compose -f $APP_DIR/docker-compose.yml restart"
echo ""

echo -e "${BLUE}下一步:${NC}"
echo "1. 检查服务状态: docker-compose ps"
echo "2. 查看日志: docker-compose logs -f web"
echo "3. 配置 DNS 指向服务器 IP"
echo "4. 配置 Webhook"
echo ""

echo -e "${YELLOW}⚠️  重要事项:${NC}"
echo "1. 确保防火墙已启用正确的端口"
echo "2. 配置 DNS 记录"
echo "3. 定期检查备份"
echo "4. 监控系统资源使用"
echo ""
