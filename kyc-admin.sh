#!/bin/bash

# 🔐 KYC 管理后台快速脚本
# 用于快速生成验证链接和查询状态
# 
# 用法：
#   ./kyc-admin.sh generate <用户号> <订单号> [买家名] [电话] [邮箱]
#   ./kyc-admin.sh check <订单号>
#   ./kyc-admin.sh login <密钥>

set -e

# 配置
API_BASE="https://kyc.317073.xyz/admin-manual"
ADMIN_SECRET_KEY="${ADMIN_SECRET_KEY:-your-key-here}"
COOKIES_FILE="/tmp/kyc_cookies.txt"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数：打印帮助
print_help() {
    cat << EOF
🔐 KYC 管理后台快速脚本

用法：
  bash kyc-admin.sh <命令> [参数]

命令：
  generate  生成验证链接
  check     查询验证状态
  login     手动登录
  help      显示帮助信息

示例：
  # 生成链接
  bash kyc-admin.sh generate user_12345 order_001 "小王" "13800138000" "buyer@example.com"

  # 只需最基本的参数
  bash kyc-admin.sh generate user_12345 order_001

  # 查询状态
  bash kyc-admin.sh check order_001

  # 设置密钥（三种方式）
  export ADMIN_SECRET_KEY="your-secret-key"
  bash kyc-admin.sh generate user_12345 order_001

  或直接在脚本中修改 ADMIN_SECRET_KEY 变量

EOF
}

# 函数：检查密钥
check_secret() {
    if [ "$ADMIN_SECRET_KEY" == "your-key-here" ]; then
        echo -e "${RED}❌ 错误：请设置 ADMIN_SECRET_KEY${NC}"
        echo "方法 1: export ADMIN_SECRET_KEY='your-actual-key'"
        echo "方法 2: 编辑脚本修改 ADMIN_SECRET_KEY 变量"
        exit 1
    fi
}

# 函数：生成验证链接
generate_link() {
    local user_id="$1"
    local order_id="$2"
    local buyer_name="${3:-}"
    local buyer_phone="${4:-}"
    local buyer_email="${5:-}"

    if [ -z "$user_id" ] || [ -z "$order_id" ]; then
        echo -e "${RED}❌ 错误：用户号和订单号不能为空${NC}"
        print_help
        exit 1
    fi

    check_secret

    echo -e "${BLUE}📝 生成验证链接${NC}"
    echo "  用户号: $user_id"
    echo "  订单号: $order_id"
    [ -n "$buyer_name" ] && echo "  买家名: $buyer_name"
    [ -n "$buyer_phone" ] && echo "  电话: $buyer_phone"
    [ -n "$buyer_email" ] && echo "  邮箱: $buyer_email"
    echo

    # 构建 JSON 数据
    local json_data="{
        \"user_id\": \"$user_id\",
        \"order_id\": \"$order_id\""

    [ -n "$buyer_name" ] && json_data="$json_data, \"buyer_name\": \"$buyer_name\""
    [ -n "$buyer_phone" ] && json_data="$json_data, \"buyer_phone\": \"$buyer_phone\""
    [ -n "$buyer_email" ] && json_data="$json_data, \"buyer_email\": \"$buyer_email\""

    json_data="$json_data}"

    # 发送请求
    response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/generate-link" \
        -H "Content-Type: application/json" \
        -H "X-Admin-Key: $ADMIN_SECRET_KEY" \
        -d "$json_data")

    # 解析响应
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [ "$http_code" == "201" ]; then
        echo -e "${GREEN}✅ 验证链接生成成功！${NC}\n"

        # 提取字段
        verification_link=$(echo "$body" | grep -o '"verification_link":"[^"]*' | cut -d'"' -f4)
        verification_token=$(echo "$body" | grep -o '"verification_token":"[^"]*' | cut -d'"' -f4)
        applicant_id=$(echo "$body" | grep -o '"applicant_id":"[^"]*' | cut -d'"' -f4)
        created_at=$(echo "$body" | grep -o '"created_at":"[^"]*' | cut -d'"' -f4)

        echo -e "${GREEN}📌 验证链接${NC}"
        echo "$verification_link"
        echo
        echo -e "${GREEN}🎟️  验证令牌${NC}"
        echo "$verification_token"
        echo
        echo -e "${GREEN}🆔 Applicant ID${NC}"
        echo "$applicant_id"
        echo
        echo -e "${GREEN}⏰ 创建时间${NC}"
        echo "$created_at"
        echo
        echo -e "${YELLOW}💡 提示：复制上面的链接发送给买家${NC}"
    else
        echo -e "${RED}❌ 生成失败 (HTTP $http_code)${NC}"
        echo "$body"
        exit 1
    fi
}

# 函数：查询状态
check_status() {
    local order_id="$1"

    if [ -z "$order_id" ]; then
        echo -e "${RED}❌ 错误：订单号不能为空${NC}"
        print_help
        exit 1
    fi

    check_secret

    echo -e "${BLUE}🔍 查询验证状态${NC}"
    echo "  订单号: $order_id"
    echo

    # 发送请求
    response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/check-status" \
        -H "Content-Type: application/json" \
        -H "X-Admin-Key: $ADMIN_SECRET_KEY" \
        -d "{\"order_id\": \"$order_id\"}")

    # 解析响应
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}✅ 查询成功${NC}\n"

        # 使用 jq 解析（如果可用）
        if command -v jq &> /dev/null; then
            echo "$body" | jq '.'
        else
            # 没有 jq，显示原始 JSON
            echo "$body" | python3 -m json.tool
        fi

        # 提取关键信息
        status=$(echo "$body" | grep -o '"verification_status":"[^"]*' | cut -d'"' -f4)
        report_status=$(echo "$body" | grep -o '"report_status":"[^"]*' | cut -d'"' -f4)

        echo
        echo -e "${BLUE}📊 状态摘要${NC}"
        
        case "$status" in
            pending)
                echo -e "  验证状态: ${YELLOW}⏳ 等待中${NC}"
                ;;
            approved)
                echo -e "  验证状态: ${GREEN}✅ 已通过${NC}"
                ;;
            rejected)
                echo -e "  验证状态: ${RED}❌ 已拒绝${NC}"
                ;;
            expired)
                echo -e "  验证状态: ${YELLOW}⏰ 已过期${NC}"
                ;;
        esac

        case "$report_status" in
            available)
                echo -e "  报告状态: ${GREEN}📥 可用${NC}"
                echo -e "  ${YELLOW}💡 提示：使用上面的 report_urls 下载报告${NC}"
                ;;
            downloading)
                echo -e "  报告状态: ${YELLOW}📥 生成中${NC}"
                echo -e "  ${YELLOW}💡 提示：1-5 秒后再查询${NC}"
                ;;
            not_available)
                echo -e "  报告状态: ${RED}❌ 不可用${NC}"
                ;;
        esac
    else
        echo -e "${RED}❌ 查询失败 (HTTP $http_code)${NC}"
        echo "$body"
        exit 1
    fi
}

# 函数：登录
login() {
    local secret_key="$1"

    if [ -z "$secret_key" ]; then
        echo -e "${RED}❌ 错误：密钥不能为空${NC}"
        exit 1
    fi

    echo -e "${BLUE}🔐 尝试登录${NC}"
    echo "  密钥: $(echo "$secret_key" | cut -c1-8)..."
    echo

    response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/login" \
        -H "Content-Type: application/json" \
        -d "{\"secret_key\": \"$secret_key\"}" \
        -c "$COOKIES_FILE")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}✅ 登录成功！${NC}"
        echo "Cookie 已保存到: $COOKIES_FILE"
    else
        echo -e "${RED}❌ 登录失败 (HTTP $http_code)${NC}"
        echo "$body"
        exit 1
    fi
}

# 主程序
main() {
    if [ $# -eq 0 ]; then
        print_help
        exit 0
    fi

    case "$1" in
        generate)
            generate_link "$2" "$3" "$4" "$5" "$6"
            ;;
        check)
            check_status "$2"
            ;;
        login)
            login "$2"
            ;;
        help|--help|-h)
            print_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $1${NC}"
            print_help
            exit 1
            ;;
    esac
}

# 运行
main "$@"
