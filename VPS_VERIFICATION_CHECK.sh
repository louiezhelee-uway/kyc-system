#!/bin/bash

# VPS 部署验证脚本
# 使用方式: bash VPS_VERIFICATION_CHECK.sh

echo "====================================="
echo "  KYC 系统 VPS 部署验证"
echo "====================================="
echo ""

# 1. 检查 Docker 容器
echo "1️⃣  检查 Docker 容器状态..."
echo ""
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep kyc
echo ""

# 2. 检查 PostgreSQL 连接
echo "2️⃣  检查 PostgreSQL 数据库..."
echo ""
docker exec kyc_postgres psql -U kyc_user -d kyc_db -c "SELECT version();" 2>&1 | head -3
echo ""

# 3. 检查表是否存在
echo "3️⃣  检查数据库表..."
echo ""
docker exec kyc_postgres psql -U kyc_user -d kyc_db -c "\dt" 2>&1 | grep -E "(order|verification|report)"
echo ""

# 4. 检查 Flask 应用日志
echo "4️⃣  Flask 应用最近日志..."
echo ""
docker logs --tail 20 kyc_web 2>&1 | tail -10
echo ""

# 5. 测试 Flask 健康检查
echo "5️⃣  测试 Flask 应用连接..."
echo ""
curl -s http://localhost:5000/health 2>&1 || echo "❌ Flask 连接失败"
echo ""

# 6. 检查 Nginx 配置
echo "6️⃣  检查 Nginx 状态..."
echo ""
docker exec kyc_nginx nginx -t 2>&1 | grep -i success || echo "❌ Nginx 配置错误"
echo ""

# 7. 测试 HTTPS
echo "7️⃣  测试 HTTPS 连接..."
echo ""
curl -k -s -o /dev/null -w "HTTP Status: %{http_code}\n" https://kyc.317073.xyz/health
echo ""

# 8. 检查环境变量
echo "8️⃣  检查环境变量..."
echo ""
docker exec kyc_web env | grep -E "(SUMSUB|DATABASE|WEBHOOK)" | grep -v "=your"
echo ""

# 9. 检查磁盘空间
echo "9️⃣  检查磁盘使用..."
echo ""
df -h | grep -E "(Filesystem|/$|/app)"
echo ""

# 10. 显示总结
echo "====================================="
echo "✅ 验证完成！查看上述输出确认部署状态"
echo "====================================="
echo ""
echo "常见问题："
echo "  - Flask 容器无法启动: 检查 docker-compose.yml 中的 command 配置"
echo "  - PostgreSQL 连接失败: 检查 DATABASE_URL 环境变量"
echo "  - HTTPS 连接失败: 检查 SSL 证书是否存在"
echo ""
