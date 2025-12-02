#!/bin/bash

###############################################################################
# KYC 验证链接查询工具
# 功能: 查询、创建测试订单、查看验证链接状态
# 使用: bash CHECK_VERIFICATION_LINKS.sh
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
VPS_HOST="${VPS_HOST:-localhost}"
VPS_PORT="${VPS_PORT:-5000}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-kyc_user}"
DB_NAME="${DB_NAME:-kyc_db}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    KYC 验证链接查询工具                                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 菜单
show_menu() {
    echo -e "${YELLOW}请选择操作:${NC}"
    echo ""
    echo "  1) 查询所有订单和验证记录"
    echo "  2) 查询最新 5 条验证链接"
    echo "  3) 创建测试订单（生成新的验证链接）"
    echo "  4) 查询特定订单的验证链接"
    echo "  5) 查看验证状态统计"
    echo "  6) 导出所有验证链接"
    echo "  7) 检查 Sumsub API 连接"
    echo "  0) 退出"
    echo ""
}

# 1. 查询所有订单和验证
query_all() {
    echo -e "${BLUE}📊 正在查询所有订单和验证记录...${NC}\n"
    
    docker exec kyc_postgres psql -U "$DB_USER" -d "$DB_NAME" << EOF
-- 订单和验证信息
SELECT 
    o.id as 订单ID,
    o.taobao_order_id as 淘宝订单ID,
    o.buyer_name as 买家,
    o.buyer_email as 邮箱,
    v.status as 验证状态,
    v.verification_link as 验证链接,
    o.created_at as 创建时间
FROM orders o
LEFT JOIN verifications v ON o.id = v.order_id
ORDER BY o.created_at DESC;
EOF
}

# 2. 查询最新 5 条验证链接
query_latest() {
    echo -e "${BLUE}🔗 最新 5 条验证链接:${NC}\n"
    
    docker exec kyc_postgres psql -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT 
    v.id as ID,
    o.taobao_order_id as 订单ID,
    o.buyer_name as 买家,
    v.verification_link as 验证链接,
    v.status as 状态,
    v.created_at as 创建时间
FROM verifications v
JOIN orders o ON v.order_id = o.id
ORDER BY v.created_at DESC
LIMIT 5;
EOF
}

# 3. 创建测试订单
create_test_order() {
    echo -e "${YELLOW}🧪 创建测试订单...${NC}\n"
    
    local order_id="test_$(date +%s)"
    local buyer_name="测试用户_$(date +%s)"
    local buyer_email="test+$(date +%s)@example.com"
    
    echo -e "${BLUE}订单信息:${NC}"
    echo "  订单ID: $order_id"
    echo "  买家: $buyer_name"
    echo "  邮箱: $buyer_email"
    echo ""
    
    echo -e "${BLUE}正在创建...${NC}\n"
    
    # 发送 webhook 创建订单
    response=$(curl -s -X POST "http://${VPS_HOST}:${VPS_PORT}/webhook/taobao/order" \
        -H "Content-Type: application/json" \
        -d "{
            \"order_id\": \"$order_id\",
            \"buyer_id\": \"buyer_123\",
            \"buyer_name\": \"$buyer_name\",
            \"buyer_email\": \"$buyer_email\",
            \"buyer_phone\": \"13800138000\",
            \"platform\": \"taobao\",
            \"order_amount\": 1000,
            \"timestamp\": $(date +%s)
        }")
    
    echo -e "${GREEN}✅ 响应:${NC}"
    echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
    echo ""
    
    # 提取验证链接
    verification_link=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('verification_link', ''))" 2>/dev/null || echo "")
    
    if [ -n "$verification_link" ]; then
        echo -e "${GREEN}✅ 验证链接已生成!${NC}"
        echo -e "${BLUE}链接:${NC} $verification_link"
        echo ""
    fi
}

# 4. 查询特定订单的验证链接
query_specific() {
    echo -e "${BLUE}🔍 查询特定订单的验证链接${NC}\n"
    
    read -p "请输入订单ID: " order_id
    
    docker exec kyc_postgres psql -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT 
    o.id as 订单ID,
    o.taobao_order_id as 淘宝订单,
    o.buyer_name as 买家,
    v.verification_token as 验证令牌,
    v.verification_link as Sumsub验证链接,
    v.sumsub_applicant_id as Applicant_ID,
    v.status as 状态,
    v.created_at as 创建时间,
    v.completed_at as 完成时间
FROM orders o
LEFT JOIN verifications v ON o.id = v.order_id
WHERE o.taobao_order_id = '$order_id'
   OR o.id = '$order_id';
EOF
}

# 5. 查看验证状态统计
query_statistics() {
    echo -e "${BLUE}📈 验证状态统计:${NC}\n"
    
    docker exec kyc_postgres psql -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT 
    COALESCE(status, '未验证') as 状态,
    COUNT(*) as 数量,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as 百分比
FROM (
    SELECT v.status FROM verifications v
    UNION ALL
    SELECT NULL FROM orders o WHERE NOT EXISTS (SELECT 1 FROM verifications v WHERE v.order_id = o.id)
) sub
GROUP BY status
ORDER BY 数量 DESC;
EOF
}

# 6. 导出所有验证链接
export_links() {
    echo -e "${BLUE}💾 导出所有验证链接...${NC}\n"
    
    local output_file="verification_links_$(date +%Y%m%d_%H%M%S).csv"
    
    docker exec kyc_postgres psql -U "$DB_USER" -d "$DB_NAME" \
        -c "COPY (
            SELECT 
                o.taobao_order_id as 订单ID,
                o.buyer_name as 买家,
                o.buyer_email as 邮箱,
                v.verification_link as 验证链接,
                v.verification_token as 验证令牌,
                v.status as 状态,
                v.created_at as 创建时间
            FROM orders o
            LEFT JOIN verifications v ON o.id = v.order_id
            ORDER BY o.created_at DESC
        ) TO STDOUT WITH CSV HEADER;" > "$output_file"
    
    echo -e "${GREEN}✅ 导出成功!${NC}"
    echo -e "${BLUE}文件:${NC} $output_file"
    echo -e "${BLUE}行数:${NC} $(wc -l < "$output_file")"
    echo ""
}

# 7. 检查 Sumsub API 连接
check_sumsub_connection() {
    echo -e "${BLUE}🔗 检查 Sumsub API 连接...${NC}\n"
    
    echo -e "${YELLOW}1. 检查 Flask 应用连接...${NC}"
    
    health=$(curl -s -w "\n%{http_code}" "http://${VPS_HOST}:${VPS_PORT}/health")
    http_code=$(echo "$health" | tail -n1)
    body=$(echo "$health" | head -n-1)
    
    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}✅ Flask 应用正常${NC}"
        echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
    else
        echo -e "${RED}❌ Flask 应用不响应 (HTTP $http_code)${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}2. 查看 Flask 日志...${NC}"
    docker logs --tail=20 kyc_web
    
    echo ""
    echo -e "${YELLOW}3. 检查环境变量...${NC}"
    docker exec kyc_web env | grep -i sumsub || echo "未找到 SUMSUB 环境变量"
}

# 主循环
while true; do
    show_menu
    read -p "$(echo -e ${BLUE}请选择:${NC}) " choice
    echo ""
    
    case $choice in
        1) query_all ;;
        2) query_latest ;;
        3) create_test_order ;;
        4) query_specific ;;
        5) query_statistics ;;
        6) export_links ;;
        7) check_sumsub_connection ;;
        0)
            echo -e "${GREEN}👋 再见!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ 无效的选择${NC}"
            ;;
    esac
    
    echo ""
    read -p "按 Enter 继续..."
    clear
done
