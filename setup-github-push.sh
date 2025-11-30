#!/bin/bash

# 🚀 GitHub 推送自动化脚本
# 自动配置 SSH 密钥并推送代码到 GitHub

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
║          🚀 GitHub 推送自动化脚本                         ║
║                                                             ║
║          自动配置 SSH 并推送代码到 GitHub                 ║
║                                                             ║
╚═════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# 获取项目目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo ""
log_info "项目目录: $PROJECT_DIR"

# ============================================================
# 检查 SSH 密钥
# ============================================================

echo ""
log_info "【第 1 步】检查 SSH 密钥..."

SSH_KEY_PATH="$HOME/.ssh/github_key"

if [ -f "$SSH_KEY_PATH" ]; then
    log_success "✓ SSH 密钥已存在"
else
    log_warning "SSH 密钥不存在，正在生成..."
    
    # 读取用户邮箱
    read -p "请输入您的 GitHub 邮箱: " github_email
    
    # 生成密钥
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$github_email" -f "$SSH_KEY_PATH" -N ""
    
    log_success "✓ SSH 密钥已生成: $SSH_KEY_PATH"
    
    # 显示公钥
    echo ""
    log_warning "【重要】请复制以下公钥到 GitHub"
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
    cat "$SSH_KEY_PATH.pub"
    echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
    echo ""
    log_info "访问此链接添加公钥: https://github.com/settings/keys"
    log_info "1. 点击 'New SSH key'"
    log_info "2. Title 输入: 'MacBook'"
    log_info "3. 粘贴上面的公钥到 'Key' 字段"
    log_info "4. 点击 'Add SSH key'"
    echo ""
    read -p "完成后按 Enter 继续..."
fi

# ============================================================
# 配置 SSH 配置文件
# ============================================================

echo ""
log_info "【第 2 步】配置 SSH 配置..."

SSH_CONFIG="$HOME/.ssh/config"

if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    log_info "创建 SSH 配置文件..."
    
    # 备份旧配置
    if [ -f "$SSH_CONFIG" ]; then
        cp "$SSH_CONFIG" "$SSH_CONFIG.backup"
    fi
    
    # 创建新配置
    cat >> "$SSH_CONFIG" << 'SSH_EOF'

# GitHub Configuration
Host github.com
    User git
    IdentityFile ~/.ssh/github_key
    AddKeysToAgent yes
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
SSH_EOF
    
    chmod 600 "$SSH_CONFIG"
    log_success "✓ SSH 配置已创建"
else
    log_success "✓ SSH 配置已存在"
fi

# ============================================================
# 测试 SSH 连接
# ============================================================

echo ""
log_info "【第 3 步】测试 SSH 连接..."

if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    log_success "✓ SSH 连接成功"
else
    log_warning "⚠️  SSH 连接失败，可能原因："
    log_info "1. 公钥还未添加到 GitHub"
    log_info "2. SSH 代理未启动"
    log_info ""
    log_info "尝试启动 SSH 代理..."
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY_PATH" 2>/dev/null || true
    
    log_info "请重新尝试或访问: https://github.com/settings/keys"
    read -p "已添加公钥? 按 Enter 继续..."
fi

# ============================================================
# 配置 Git 用户信息
# ============================================================

echo ""
log_info "【第 4 步】配置 Git 用户信息..."

if ! git config user.name > /dev/null 2>&1; then
    read -p "请输入 Git 用户名: " git_user
    git config --global user.name "$git_user"
fi

if ! git config user.email > /dev/null 2>&1; then
    read -p "请输入 Git 邮箱: " git_email
    git config --global user.email "$git_email"
fi

git_user=$(git config user.name)
git_email=$(git config user.email)

log_success "✓ Git 用户配置完成"
log_info "  用户名: $git_user"
log_info "  邮箱: $git_email"

# ============================================================
# 设置远程仓库
# ============================================================

echo ""
log_info "【第 5 步】设置远程仓库..."

read -p "请输入 GitHub 用户名 (默认: louiezhelee-uway): " github_username
github_username=${github_username:-louiezhelee-uway}

read -p "请输入仓库名称 (默认: kyc-system): " repo_name
repo_name=${repo_name:-kyc-system}

GITHUB_REPO="git@github.com:${github_username}/${repo_name}.git"

# 检查远程仓库
if git remote get-url origin &> /dev/null; then
    log_info "更新远程仓库..."
    git remote set-url origin "$GITHUB_REPO"
else
    log_info "添加远程仓库..."
    git remote add origin "$GITHUB_REPO"
fi

log_success "✓ 远程仓库已配置: $GITHUB_REPO"

# ============================================================
# 同步代码
# ============================================================

echo ""
log_info "【第 6 步】同步代码..."

log_info "拉取远程代码..."
git fetch origin main 2>/dev/null || {
    log_warning "⚠️  无法拉取远程代码（可能是新仓库）"
}

# 检查是否有未提交的更改
if ! git diff --quiet HEAD 2>/dev/null; then
    log_info "存在未提交的更改，正在处理..."
    
    git add .
    git commit -m "Auto-commit: Sync with remote repository" 2>/dev/null || {
        log_warning "⚠️  没有新的更改需要提交"
    }
fi

# 拉取并合并远程更改
log_info "合并远程更改..."
git pull origin main --allow-unrelated-histories 2>/dev/null || {
    log_warning "⚠️  拉取失败，可能是新仓库或分支不存在"
}

# ============================================================
# 推送代码
# ============================================================

echo ""
log_info "【第 7 步】推送代码到 GitHub..."

log_info "正在推送..."
if git push -u origin main 2>&1; then
    log_success "✓ 代码已推送到 GitHub"
else
    log_warning "⚠️  推送失败，尝试强制推送..."
    git push -u origin main --force 2>&1 || {
        log_error "推送失败！"
        echo ""
        log_info "请手动执行以下命令调试："
        echo "git push -u origin main -v"
        exit 1
    }
fi

# ============================================================
# 完成
# ============================================================

echo ""
log_success "🎉 GitHub 推送完成！"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ 推送成功${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "📍 仓库信息:"
echo -e "   GitHub: ${GREEN}https://github.com/${github_username}/${repo_name}${NC}"
echo -e "   远程地址: ${GREEN}${GITHUB_REPO}${NC}"
echo ""
echo -e "📝 下一步:"
echo -e "   1. 访问: ${GREEN}https://github.com/${github_username}/${repo_name}${NC}"
echo -e "   2. 检查代码是否已上传"
echo -e "   3. 运行部署脚本: ${GREEN}bash deploy-github-gcp.sh${NC}"
echo ""
echo -e "🔄 后续更新:"
echo -e "   ${GREEN}git add . && git commit -m '更新描述' && git push${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
