#!/bin/bash

# KYC System VPS Docker-Compose 修复脚本
# 用于修复 docker-compose.yml 的 git 冲突和 YAML 语法错误

set -e  # 如果任何命令失败则退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

print_step() {
    echo -e "${YELLOW}➤ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查是否在正确的目录
if [ ! -f "docker-compose.yml" ]; then
    print_error "Error: docker-compose.yml 不存在"
    echo "请确保您在 /opt/kyc-app 目录中运行此脚本"
    exit 1
fi

# 开始修复
print_header "KYC System VPS Docker-Compose 修复工具"

# 步骤 1: 放弃本地更改
print_step "第 1 步: 放弃本地对 docker-compose.yml 的更改"
git checkout -- docker-compose.yml
print_success "本地更改已放弃"

# 步骤 2: 拉取最新代码
print_step "第 2 步: 从 GitHub 拉取最新代码"
if git pull origin main --force 2>&1; then
    print_success "代码已拉取"
else
    print_error "git pull 失败，尝试从 GitHub 直接下载文件"
    curl -s https://raw.githubusercontent.com/louiezhelee-uway/kyc-system/main/docker-compose.yml -o docker-compose.yml
    print_success "文件已下载"
fi

# 步骤 3: 验证 YAML 语法
print_step "第 3 步: 验证 docker-compose.yml YAML 语法"
if docker-compose config > /dev/null 2>&1; then
    print_success "YAML 语法正确！"
else
    print_error "YAML 仍有错误，进行修复..."
    # 如果语法仍然错误，尝试从原始源重新下载
    rm docker-compose.yml
    if curl -s https://raw.githubusercontent.com/louiezhelee-uway/kyc-system/main/docker-compose.yml -o docker-compose.yml; then
        if docker-compose config > /dev/null 2>&1; then
            print_success "YAML 已修复！"
        else
            print_error "YAML 仍然有错误，请手动检查"
            exit 1
        fi
    else
        print_error "无法从 GitHub 下载文件"
        exit 1
    fi
fi

# 步骤 4: 停止并删除现有容器
print_step "第 4 步: 停止并删除现有容器"
docker-compose down 2>/dev/null || true
print_success "容器已停止"

# 步骤 5: 重新构建并启动容器
print_step "第 5 步: 重新构建并启动 Docker 容器"
if docker-compose up -d --build; then
    print_success "容器已启动"
else
    print_error "容器启动失败"
    docker-compose logs
    exit 1
fi

# 步骤 6: 等待容器启动
print_step "第 6 步: 等待容器启动..."
sleep 15
print_success "容器应该已启动"

# 步骤 7: 检查容器状态
print_step "第 7 步: 检查 Docker 容器状态"
echo ""
docker-compose ps
echo ""

# 步骤 8: 检查 Flask 日志
print_step "第 8 步: 检查 Flask 容器日志"
echo ""
echo "===== Flask 容器日志（最后 20 行）====="
docker-compose logs web | tail -20
echo ""

# 步骤 9: 验证 PostgreSQL
print_step "第 9 步: 验证 PostgreSQL 连接"
if docker-compose exec -T postgres psql -U kyc_user -d kyc_db -c "SELECT VERSION();" 2>/dev/null | head -1; then
    print_success "PostgreSQL 连接成功！"
else
    print_error "PostgreSQL 连接失败，但容器可能仍在启动中"
fi

# 完成
echo ""
print_header "修复完成！"
echo ""
echo "检查清单:"
echo "  ☐ docker-compose ps 显示所有容器都是 UP"
echo "  ☐ Flask 容器日志显示 'Running on http://0.0.0.0:5000'"
echo "  ☐ PostgreSQL 显示 'healthy'"
echo ""
echo "下一步:"
echo "  1. 等待 30 秒让所有服务完全启动"
echo "  2. 测试: curl https://kyc.317073.xyz/api/health"
echo "  3. 如果返回 502，等待更长时间后重试"
echo ""
print_success "脚本执行完毕！"
