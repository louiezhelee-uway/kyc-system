#!/bin/bash

# 🚀 GitHub + 谷歌云一键部署脚本
# 自动将项目上传到 GitHub 并部署到谷歌云

set -e  # 任何错误都停止执行

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 标题
echo -e "${BLUE}"
cat << 'EOF'
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║          🚀 GitHub + 谷歌云一键部署脚本                    ║
║                                                             ║
║          将项目上传到 GitHub 并部署到谷歌云             ║
║                                                             ║
╚═════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# ============================================================
# 阶段 1: 检查前置条件
# ============================================================

echo ""
log_info "【阶段 1】检查前置条件..."

# 检查 git
if ! command -v git &> /dev/null; then
    log_error "Git 未安装！请先安装 Git"
    exit 1
fi
log_success "✓ Git 已安装"

# 检查 gcloud
if ! command -v gcloud &> /dev/null; then
    log_warning "gcloud CLI 未安装或未在 PATH 中"
    log_info "请访问: https://cloud.google.com/sdk/docs/install"
    read -p "继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ============================================================
# 阶段 2: GitHub 配置
# ============================================================

echo ""
log_info "【阶段 2】GitHub 配置..."

# 检查 Git 用户配置
if ! git config user.name > /dev/null; then
    log_warning "Git 用户名未配置"
    read -p "请输入 Git 用户名: " git_user
    git config --global user.name "$git_user"
fi

if ! git config user.email > /dev/null; then
    log_warning "Git 邮箱未配置"
    read -p "请输入 Git 邮箱: " git_email
    git config --global user.email "$git_email"
fi

log_success "✓ Git 用户配置完成"

# ============================================================
# 阶段 3: 项目初始化
# ============================================================

echo ""
log_info "【阶段 3】项目 Git 初始化..."

# 获取项目目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

log_info "项目目录: $PROJECT_DIR"

# 初始化 Git 仓库
if [ ! -d ".git" ]; then
    log_info "初始化 Git 仓库..."
    git init
    log_success "✓ Git 仓库已初始化"
else
    log_success "✓ Git 仓库已存在"
fi

# ============================================================
# 阶段 4: 获取 GitHub 仓库信息
# ============================================================

echo ""
log_info "【阶段 4】GitHub 仓库信息..."

read -p "请输入 GitHub 用户名: " github_username
read -p "请输入仓库名称 (默认: kyc-system): " repo_name
repo_name=${repo_name:-kyc-system}

GITHUB_REPO="https://github.com/${github_username}/${repo_name}.git"

log_info "GitHub 仓库: $GITHUB_REPO"

# ============================================================
# 阶段 5: 上传代码到 GitHub
# ============================================================

echo ""
log_info "【阶段 5】上传代码到 GitHub..."

# 检查远程仓库
if ! git remote get-url origin &> /dev/null; then
    log_info "添加远程仓库..."
    git remote add origin "$GITHUB_REPO"
else
    log_info "更新远程仓库..."
    git remote set-url origin "$GITHUB_REPO"
fi

log_success "✓ 远程仓库已配置"

# 添加所有文件
log_info "添加项目文件..."
git add .
log_success "✓ 文件已添加"

# 检查是否有更改
if git diff --cached --quiet; then
    log_warning "没有新的更改需要提交"
else
    # 提交
    log_info "提交代码..."
    git commit -m "Initial commit: KYC verification system"
    log_success "✓ 代码已提交"
fi

# 推送到 GitHub
log_info "推送到 GitHub..."
git branch -M main
git push -u origin main 2>/dev/null || {
    log_error "推送失败！可能的原因："
    log_info "1. 仓库名称不存在"
    log_info "2. 没有推送权限"
    log_info "3. GitHub 认证失败"
    log_info ""
    log_info "请检查："
    log_info "- 确认 https://github.com/${github_username}/${repo_name} 存在"
    log_info "- 如果是私有仓库，需要正确的认证"
    exit 1
}

log_success "✓ 代码已推送到 GitHub"

# ============================================================
# 阶段 6: 谷歌云配置
# ============================================================

echo ""
log_info "【阶段 6】谷歌云配置..."

# 初始化 gcloud
log_info "初始化 gcloud CLI..."
gcloud init --skip-diagnostics || true

# 选择项目
read -p "请输入谷歌云项目 ID: " gcp_project
gcloud config set project "$gcp_project"

log_success "✓ 谷歌云项目已配置: $gcp_project"

# ============================================================
# 阶段 7: 创建虚拆机
# ============================================================

echo ""
log_info "【阶段 7】创建谷歌云虚拆机..."

read -p "请输入虚拆机名称 (默认: kyc-app): " vm_name
vm_name=${vm_name:-kyc-app}

read -p "请选择区域 (默认: asia-east1-a): " vm_zone
vm_zone=${vm_zone:-asia-east1-a}

# 检查虚拆机是否已存在
if gcloud compute instances describe "$vm_name" --zone="$vm_zone" &> /dev/null; then
    log_success "✓ 虚拆机已存在: $vm_name"
else
    log_info "创建虚拆机..."
    gcloud compute instances create "$vm_name" \
        --image-family=ubuntu-2204-lts \
        --image-project=ubuntu-os-cloud \
        --machine-type=e2-medium \
        --zone="$vm_zone" \
        --boot-disk-size=20GB \
        --tags=http-server,https-server \
        --scopes=default || {
        log_error "虚拆机创建失败"
        exit 1
    }
    log_success "✓ 虚拆机已创建: $vm_name"
fi

# ============================================================
# 阶段 8: 配置防火墙
# ============================================================

echo ""
log_info "【阶段 8】配置防火墙规则..."

# 创建 HTTP 规则
if gcloud compute firewall-rules describe allow-http &> /dev/null; then
    log_success "✓ HTTP 防火墙规则已存在"
else
    log_info "创建 HTTP 防火墙规则..."
    gcloud compute firewall-rules create allow-http \
        --allow=tcp:80 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=http-server
    log_success "✓ HTTP 防火墙规则已创建"
fi

# 创建 HTTPS 规则
if gcloud compute firewall-rules describe allow-https &> /dev/null; then
    log_success "✓ HTTPS 防火墙规则已存在"
else
    log_info "创建 HTTPS 防火墙规则..."
    gcloud compute firewall-rules create allow-https \
        --allow=tcp:443 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=https-server
    log_success "✓ HTTPS 防火墙规则已创建"
fi

# ============================================================
# 阶段 9: 获取虚拆机 IP
# ============================================================

echo ""
log_info "【阶段 9】获取虚拆机信息..."

EXTERNAL_IP=$(gcloud compute instances describe "$vm_name" \
    --zone="$vm_zone" \
    --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

log_info "虚拆机名称: $vm_name"
log_info "虚拆机 IP: $EXTERNAL_IP"
log_info "虚拆机区域: $vm_zone"

# ============================================================
# 阶段 10: 在虚拆机上部署
# ============================================================

echo ""
log_info "【阶段 10】在虚拆机上部署应用..."

log_warning "即将通过 SSH 连接到虚拆机并执行部署"
log_info "虚拆机可能需要 1-2 分钟启动"

# 创建部署脚本
DEPLOY_SCRIPT=$(cat << 'DEPLOY_EOF'
#!/bin/bash
set -e

# 等待虚拆机完全启动
sleep 30

# 切换到 root
sudo su - << 'SUDO_EOF'

# 更新系统
apt-get update
apt-get install -y git

# 克隆项目
cd /tmp
git clone https://GITHUB_REPO kyc-system
cd kyc-system

# 运行部署脚本
bash deploy-vps.sh

# 显示状态
docker-compose ps

echo ""
echo "✅ 部署完成！"
echo "应用地址: http://EXTERNAL_IP"

SUDO_EOF
DEPLOY_EOF
)

# 替换变量
DEPLOY_SCRIPT="${DEPLOY_SCRIPT//GITHUB_REPO/$GITHUB_REPO}"
DEPLOY_SCRIPT="${DEPLOY_SCRIPT//EXTERNAL_IP/$EXTERNAL_IP}"

# 通过 SSH 执行脚本
log_info "连接虚拆机 SSH 并执行部署..."
gcloud compute ssh "$vm_name" \
    --zone="$vm_zone" \
    --command="$DEPLOY_SCRIPT" || {
    log_error "SSH 命令执行失败，可能的原因："
    log_info "1. 虚拆机还未完全启动"
    log_info "2. SSH 密钥配置有问题"
    log_info "3. 网络连接问题"
    log_info ""
    log_info "请手动执行以下命令:"
    echo ""
    echo "gcloud compute ssh $vm_name --zone=$vm_zone"
    echo "sudo su -"
    echo "cd /tmp && git clone $GITHUB_REPO kyc-system && cd kyc-system"
    echo "bash deploy-vps.sh"
    exit 1
}

# ============================================================
# 完成
# ============================================================

echo ""
log_success "🎉 部署完成！"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ 部署成功${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "📍 项目信息:"
echo -e "   GitHub 仓库: ${GREEN}${GITHUB_REPO}${NC}"
echo -e "   虚拆机名称: ${GREEN}${vm_name}${NC}"
echo -e "   虚拆机 IP:  ${GREEN}${EXTERNAL_IP}${NC}"
echo ""
echo -e "🌐 访问应用:"
echo -e "   ${GREEN}http://${EXTERNAL_IP}${NC}"
echo -e "   ${GREEN}http://${EXTERNAL_IP}/verify/a3f8c2e91d7b4e5f6c8a9b0c1d2e3f4a${NC}"
echo ""
echo -e "📝 查看日志:"
echo -e "   ${GREEN}gcloud compute ssh ${vm_name} --zone=${vm_zone}${NC}"
echo -e "   ${GREEN}cd /opt/kyc-app && docker-compose logs -f${NC}"
echo ""
echo -e "🔄 后续更新代码:"
echo -e "   1. 本地修改代码后:"
echo -e "      ${GREEN}git add . && git commit -m '更新描述' && git push${NC}"
echo -e "   2. 虚拆机上更新:"
echo -e "      ${GREEN}cd /opt/kyc-app && git pull && docker-compose restart${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
