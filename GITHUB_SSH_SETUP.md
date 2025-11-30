# GitHub SSH 配置 + 代码推送完全指南

## 问题诊断

您遇到的错误：
- ❌ HTTPS: `Failed to connect to github.com port 443` - 连接超时
- ❌ SSH: `Permission denied (publickey)` - SSH 密钥未配置

## 解决方案

### 方案 A: 使用 SSH 密钥（推荐）⭐⭐⭐

#### 第 1 步：生成 SSH 密钥

```bash
# 生成新的 SSH 密钥（如果没有的话）
ssh-keygen -t ed25519 -C "您的GitHub邮箱@example.com" -f ~/.ssh/github_key

# 按 Enter 跳过密码短语（或设置一个密码）
# 生成完成后会看到：
# /Users/louie/.ssh/github_key
# /Users/louie/.ssh/github_key.pub
```

#### 第 2 步：添加公钥到 GitHub

```bash
# 复制公钥内容
cat ~/.ssh/github_key.pub

# 输出内容类似：
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJx3... 您的邮箱@example.com
```

然后按照步骤：
1. 访问 [GitHub SSH Keys 设置](https://github.com/settings/keys)
2. 点击 **New SSH key**
3. Title 输入：`MacBook` 或 `My Mac`
4. 将上面复制的内容粘贴到 **Key** 字段
5. 点击 **Add SSH key**

#### 第 3 步：配置 SSH 配置文件

```bash
# 编辑 ~/.ssh/config
cat > ~/.ssh/config << 'EOF'
Host github.com
    User git
    IdentityFile ~/.ssh/github_key
    AddKeysToAgent yes
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
EOF

# 设置正确的权限
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/github_key
chmod 644 ~/.ssh/github_key.pub
```

#### 第 4 步：测试 SSH 连接

```bash
# 测试连接
ssh -T git@github.com

# 成功输出：
# Hi louiezhelee-uway! You've successfully authenticated, but GitHub does not provide shell access.
```

#### 第 5 步：推送代码到 GitHub

```bash
cd "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"

# 确保远程地址是 SSH 格式（已在脚本中设置）
git remote -v

# 应该看到：
# origin  git@github.com:louiezhelee-uway/kyc-system.git (fetch)
# origin  git@github.com:louiezhelee-uway/kyc-system.git (push)

# 如果不是，重新设置：
# git remote set-url origin git@github.com:louiezhelee-uway/kyc-system.git

# 拉取远程代码
git pull origin main --allow-unrelated-histories

# 如果有冲突，保留本地版本：
# git checkout --ours .
# git add .
# git commit -m "Merge remote changes"

# 推送到 GitHub
git push -u origin main

# 成功输出：
# Enumerating objects: 150, done.
# Counting objects: 100% (150/150), done.
# Delta compression using up to 8 threads
# Compressing objects: 100% (120/120), done.
# Writing objects: 100% (150/150), 2.50 MiB, done.
# Total 150 (delta 95), reused 0 (delta 0)
# To github.com:louiezhelee-uway/kyc-system.git
#  * [new branch]      main -> main
# Branch 'main' set up to track remote branch 'main' from 'origin'.
```

✅ **完成！代码已推送到 GitHub**

---

### 方案 B: 使用 GitHub CLI 工具（最简单）⭐⭐⭐⭐⭐

如果上面的方式太复杂，用 GitHub CLI 自动处理一切：

```bash
# 安装 GitHub CLI（如果还没有）
brew install gh

# 认证到 GitHub
gh auth login
# 选择：
# ? What is your preferred protocol for Git operations?
# > HTTPS
# ? Authenticate Git with your GitHub credentials?
# > Yes

# 一行命令推送代码
cd "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"
git push origin main

# 如果有冲突，先拉取：
git pull origin main --allow-unrelated-histories
git push origin main
```

---

### 方案 C: 使用 HTTPS + Personal Access Token

如果网络限制不支持 SSH，可以用 Token：

```bash
# 1. 生成 Personal Access Token：
#    访问 https://github.com/settings/tokens
#    点击 Generate new token (classic)
#    选择 repo 权限
#    复制 token（例如：ghp_1234567890abcdefghijklmnop）

# 2. 配置 Git 使用 token
git config --global credential.helper osxkeychain

# 3. 重新设置远程地址为 HTTPS
cd "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC"
git remote set-url origin https://github.com/louiezhelee-uway/kyc-system.git

# 4. 推送时会提示输入用户名和密码
# 用户名：louiezhelee-uway
# 密码：粘贴上面的 token
git push origin main
```

---

## 快速检查清单

完成以下任意一个方案后，检查：

- [ ] 访问 [您的仓库](https://github.com/louiezhelee-uway/kyc-system)
- [ ] 确认代码文件已上传（至少 50+ 个文件）
- [ ] 查看 commit 历史，最新的 commit 是您的更新
- [ ] 检查 `app/`、`docker-compose.yml`、`requirements.txt` 等关键文件存在

## 验证推送成功

```bash
# 检查最新的 commit
git log --oneline | head -5

# 查看远程分支
git branch -r

# 应该看到：
# origin/main
```

---

## 下一步

代码推送到 GitHub 后，可以运行部署脚本：

```bash
# 使用 deploy-github-gcp.sh 一键部署到谷歌云
bash "/Users/louie/Library/Mobile Documents/com~apple~CloudDocs/Documents/project X/Project_KYC/deploy-github-gcp.sh"
```

---

## 遇到问题？

| 错误信息 | 解决方案 |
|---------|--------|
| `Permission denied (publickey)` | 检查 SSH 密钥是否添加到 GitHub（方案 A） |
| `Could not resolve hostname github.com` | 网络问题，检查网络连接 |
| `fatal: unable to access HTTPS` | 用 SSH 或 Token 方式（方案 A 或 C） |
| `Your branch is ahead of 'origin/main'` | 运行 `git push origin main` |
| `rejected ... (fetch first)` | 运行 `git pull origin main --allow-unrelated-histories` |

