#!/bin/bash

# 🚀 KYC 管理后台 - VPS 快速部署脚本
# 
# 用法：
#   bash deploy-admin.sh
#
# 这个脚本会：
# 1. 更新代码
# 2. 检查环境变量
# 3. 重启 Docker 容器
# 4. 验证服务状态

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
PROJECT_PATH="/opt/kyc-app"
DOMAIN="kyc.317073.xyz"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🚀 KYC 管理后台 - VPS 快速部署              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo

# 步骤 1: 检查项目目录
echo -e "${YELLOW}📂 检查项目目录...${NC}"
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}❌ 项目目录不存在: $PROJECT_PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 项目目录存在${NC}"
echo

# 步骤 2: 进入项目目录
cd "$PROJECT_PATH"
echo -e "${YELLOW}📍 当前目录: $(pwd)${NC}"
echo

# 步骤 3: 更新代码
echo -e "${YELLOW}📦 更新代码...${NC}"
if git pull origin main; then
    echo -e "${GREEN}✅ 代码更新成功${NC}"
else
    echo -e "${RED}⚠️  代码更新失败，继续执行...${NC}"
fi
echo

# 步骤 4: 检查 .env 文件
echo -e "${YELLOW}🔐 检查环境变量...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env 文件不存在！${NC}"
    echo "请创建 .env 文件并包含以下内容："
    echo "  ADMIN_SECRET_KEY=your-secret-key"
    exit 1
fi

# 检查 ADMIN_SECRET_KEY
if grep -q "ADMIN_SECRET_KEY" ".env"; then
    secret=$(grep "ADMIN_SECRET_KEY" ".env" | cut -d'=' -f2)
    if [ "$secret" == "your-key-here" ] || [ "$secret" == "" ]; then
        echo -e "${RED}❌ ADMIN_SECRET_KEY 未正确配置！${NC}"
        echo "请编辑 .env 文件，设置正确的密钥"
        exit 1
    fi
    echo -e "${GREEN}✅ ADMIN_SECRET_KEY 已配置${NC}"
else
    echo -e "${RED}❌ 未找到 ADMIN_SECRET_KEY${NC}"
    echo "请在 .env 文件中添加: ADMIN_SECRET_KEY=your-secret-key"
    exit 1
fi
echo

# 步骤 5: 停止现有容器
echo -e "${YELLOW}🛑 停止现有容器...${NC}"
docker-compose down
echo -e "${GREEN}✅ 容器已停止${NC}"
echo

# 步骤 6: 启动新容器
echo -e "${YELLOW}🚀 启动新容器...${NC}"
docker-compose up -d
echo -e "${GREEN}✅ 容器已启动${NC}"
echo

# 步骤 7: 等待服务启动
echo -e "${YELLOW}⏳ 等待服务启动 (10 秒)...${NC}"
sleep 10

# 步骤 8: 检查日志
echo -e "${YELLOW}📋 检查应用日志...${NC}"
echo "────────────────────────────────────────────────"
docker-compose logs web | tail -20
echo "────────────────────────────────────────────────"
echo

# 步骤 9: 验证管理后台蓝图是否注册
echo -e "${YELLOW}🔍 验证管理后台...${NC}"
if docker-compose logs web | grep -q "admin_manual 蓝图已注册"; then
    echo -e "${GREEN}✅ admin_manual 蓝图已成功注册${NC}"
else
    echo -e "${YELLOW}⚠️  未找到 admin_manual 蓝图注册信息${NC}"
    echo "这可能是首次启动，请稍候..."
fi
echo

# 步骤 10: 测试连接
echo -e "${YELLOW}🔗 测试应用连接...${NC}"
if curl -s "https://$DOMAIN/health" | grep -q "healthy"; then
    echo -e "${GREEN}✅ 应用连接正常${NC}"
else
    echo -e "${YELLOW}⚠️  无法连接应用，检查域名和 HTTPS 配置${NC}"
fi
echo

# 完成
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ 部署完成！                                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo
echo -e "${BLUE}📌 后续步骤:${NC}"
echo "  1. 访问管理后台:"
echo "     ${YELLOW}https://$DOMAIN/admin-manual/${NC}"
echo
echo "  2. 输入你的 ADMIN_SECRET_KEY 登录"
echo
echo "  3. 开始生成验证链接！"
echo
echo -e "${BLUE}📚 更多信息:${NC}"
echo "  • 管理员指南: ADMIN_MANUAL_GUIDE.md"
echo "  • 完整工作流: COMPLETE_WORKFLOW.md"
echo "  • 部署检查: ADMIN_DEPLOYMENT_CHECKLIST.md"
echo
echo -e "${BLUE}🔍 有用的命令:${NC}"
echo "  查看日志:      docker-compose logs -f web"
echo "  快速脚本:      bash kyc-admin.sh generate user_id order_id"
echo "  检查状态:      bash kyc-admin.sh check order_id"
echo

exit 0
