#!/bin/bash

# 🚀 立即开始 - 快速启动指南
# 这是你需要做的所有事情，从现在到开始使用管理后台

echo "╔════════════════════════════════════════════════════════╗"
echo "║  🚀 KYC 隐秘管理后台 - 立即开始指南               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo

echo "📋 你现在已经拥有：" 
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "✅ 后端代码（4 个文件）"
echo "   • app/routes/admin_manual.py"
echo "   • app/templates/admin_manual.html"
echo "   • app/templates/admin_login.html"
echo "   • app/__init__.py（已修改）"
echo
echo "✅ 工具脚本（2 个文件）"
echo "   • kyc-admin.sh - Shell 快速脚本"
echo "   • deploy-admin.sh - 一键部署脚本"
echo
echo "✅ 完整文档（7 个文件）"
echo "   • QUICK_REFERENCE.md - 30 秒快速入门 ⭐"
echo "   • COMPLETE_WORKFLOW.md - 详细工作流说明"
echo "   • ADMIN_MANUAL_GUIDE.md - 完整 API 文档"
echo "   • ADMIN_DEPLOYMENT_CHECKLIST.md - 部署指南"
echo "   • ADMIN_BACKEND_SUMMARY.md - 项目总结"
echo "   • .env.admin - 环境变量示例"
echo "   • ADMIN_COMPLETION.txt - 完成总结"
echo

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ 最快上手（10 分钟）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

echo "📖 第 1 步：阅读快速参考卡（5 分钟）"
echo "   打开并快速浏览: QUICK_REFERENCE.md"
echo "   （或者现在就继续，跳过这一步）"
echo

echo "🔐 第 2 步：配置密钥（1 分钟）"
echo "   SSH 到 VPS:"
echo "   ssh user@kyc.317073.xyz"
echo "   cd /opt/kyc-app"
echo
echo "   编辑 .env 文件并添加:"
echo "   ADMIN_SECRET_KEY=your-super-secret-key-here"
echo
echo "   生成强密钥（随选其一）:"
echo "   • openssl rand -base64 32"
echo "   • python3 -c \"import secrets; print(secrets.token_urlsafe(32))\""
echo

echo "🚀 第 3 步：部署（2 分钟）"
echo "   在 VPS 上运行:"
echo "   bash deploy-admin.sh"
echo
echo "   这会自动:"
echo "   • 更新代码"
echo "   • 检查环境变量"
echo "   • 重启容器"
echo "   • 验证服务"
echo

echo "🌐 第 4 步：访问管理后台（1 分钟）"
echo "   打开浏览器:"
echo "   https://kyc.317073.xyz/admin-manual/"
echo
echo "   输入你的 ADMIN_SECRET_KEY 登录"
echo "   → 完成！你现在可以生成验证链接了！"
echo

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 开始处理订单"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

echo "方式 1️⃣：使用网页界面（最简单）"
echo "   1. 访问 https://kyc.317073.xyz/admin-manual/"
echo "   2. 输入用户号和订单号"
echo "   3. 点击\"生成链接\""
echo "   4. 复制链接发送给买家"
echo

echo "方式 2️⃣：使用 Shell 脚本（最快）"
echo "   bash kyc-admin.sh generate user_123 order_001 \"小王\""
echo

echo "方式 3️⃣：使用 API（最灵活）"
echo "   curl -X POST https://kyc.317073.xyz/admin-manual/generate-link \\"
echo "     -H \"X-Admin-Key: your-key\" \\"
echo "     -d '{\"user_id\":\"user_123\",\"order_id\":\"order_001\"}'"
echo

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 详细文档"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

echo "如果需要更多信息，查看这些文档:"
echo
echo "⭐ 快速开始"
echo "   QUICK_REFERENCE.md ........... 30 秒快速参考"
echo
echo "📖 详细指南"
echo "   COMPLETE_WORKFLOW.md ......... 完整工作流（3 种使用方式）"
echo "   ADMIN_MANUAL_GUIDE.md ........ 详细 API 文档和说明"
echo
echo "🔧 技术细节"
echo "   ADMIN_DEPLOYMENT_CHECKLIST.md  部署和故障排除"
echo "   ADMIN_BACKEND_SUMMARY.md ...... 项目完成总结"
echo

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "❓ 常见问题速解"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

echo "Q: 忘记了密钥？"
echo "A: cat /opt/kyc-app/.env | grep ADMIN_SECRET_KEY"
echo

echo "Q: 无法访问管理后台？"
echo "A: 检查 URL 是 HTTPS（不是 HTTP）"
echo "   清除浏览器 Cookie"
echo "   重启容器: docker-compose restart web"
echo

echo "Q: 如何更换密钥？"
echo "A: 编辑 .env 文件，改变 ADMIN_SECRET_KEY 的值"
echo "   重启容器: docker-compose restart web"
echo

echo "Q: 批量处理多个订单？"
echo "A: 使用 Shell 脚本，可以写一个循环"
echo "   详见: COMPLETE_WORKFLOW.md"
echo

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 下一步行动（选择一个）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

echo "1️⃣  立即部署（现在就开始）"
echo "   ssh user@kyc.317073.xyz"
echo "   cd /opt/kyc-app"
echo "   nano .env  # 添加 ADMIN_SECRET_KEY=..."
echo "   bash deploy-admin.sh"
echo

echo "2️⃣  先阅读文档（更有把握）"
echo "   打开并阅读: QUICK_REFERENCE.md (5 分钟)"
echo "   然后执行上面的部署命令"
echo

echo "3️⃣  了解更多细节（深入学习）"
echo "   打开: COMPLETE_WORKFLOW.md"
echo "   了解所有功能和使用方式"
echo

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "✅ 你已经准备好了！"
echo "   代码 ✓  文档 ✓  脚本 ✓"
echo
echo "⏱️  预计部署时间: 3-5 分钟"
echo "🎯 管理后台 URL: https://kyc.317073.xyz/admin-manual/"
echo

echo "祝你使用愉快！🚀"
echo
