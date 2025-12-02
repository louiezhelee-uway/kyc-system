#!/bin/bash

# VPS Git 冲突清理脚本
# 用途: 清理 git 冲突并更新代码

echo "========================================"
echo "  清理 Git 冲突"
echo "========================================"
echo ""

# 备份本地 Dockerfile（如果存在）
if [ -f "Dockerfile" ]; then
    echo "✓ 备份本地 Dockerfile..."
    cp Dockerfile Dockerfile.local.backup
    echo "  已保存为 Dockerfile.local.backup"
fi

# 清理冲突的文件
echo "✓ 删除本地 Dockerfile..."
rm -f Dockerfile

# 重新拉取最新代码
echo "✓ 拉取最新代码..."
git pull origin main

if [ $? -eq 0 ]; then
    echo "✅ Git 更新成功！"
else
    echo "❌ Git 更新失败"
    exit 1
fi

echo ""
echo "========================================"
echo "  现在可以运行修复脚本了"
echo "========================================"
echo ""
echo "执行: bash VPS_COMPLETE_FIX.sh"
echo ""
