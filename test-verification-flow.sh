#!/bin/bash

# KYC 验证链接测试脚本
# 这个脚本演示了从订单 Webhook 到买家验证链接的完整流程

set -e

echo "════════════════════════════════════════════════════════════"
echo "🧪 KYC 验证链接完整流程测试"
echo "════════════════════════════════════════════════════════════"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试变量
SERVER_URL="http://localhost:5000"
WEBHOOK_SECRET="your-webhook-secret"  # 需要与服务器配置匹配
TIMESTAMP=$(date +%s)

# 步骤 1: 创建模拟订单数据
echo -e "${BLUE}步骤 1: 创建模拟订单数据${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ORDER_DATA='{
  "order_id": "taobao_'$(date +%s%3N)'",
  "buyer_name": "张三",
  "buyer_email": "zhangsan@example.com",
  "buyer_phone": "13800138000",
  "order_amount": 299.99,
  "timestamp": "'$TIMESTAMP'"
}'

echo "订单数据:"
echo "$ORDER_DATA" | python3 -m json.tool
echo ""

# 步骤 2: 计算 Webhook 签名
echo -e "${BLUE}步骤 2: 计算 Webhook HMAC 签名${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SIGNATURE=$(python3 << 'PYSCRIPT'
import hmac
import hashlib
import json
import sys

order_data = '''ORDER_DATA_PLACEHOLDER'''
webhook_secret = '''WEBHOOK_SECRET_PLACEHOLDER'''

# 生成 HMAC 签名
signature = hmac.new(
    webhook_secret.encode(),
    order_data.encode(),
    hashlib.sha256
).hexdigest()

print(signature)
PYSCRIPT
)

# 替换占位符
SIGNATURE=$(python3 << PYSCRIPT
import hmac
import hashlib

order_data = '$ORDER_DATA'
webhook_secret = '$WEBHOOK_SECRET'

signature = hmac.new(
    webhook_secret.encode(),
    order_data.encode(),
    hashlib.sha256
).hexdigest()

print(signature)
PYSCRIPT
)

echo "HMAC-SHA256 签名: $SIGNATURE"
echo ""

# 步骤 3: 发送 Webhook 请求
echo -e "${BLUE}步骤 3: 发送 Webhook 请求到服务器${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

WEBHOOK_ENDPOINT="$SERVER_URL/webhook/taobao/order"

echo -e "${YELLOW}请求 URL:${NC} $WEBHOOK_ENDPOINT"
echo -e "${YELLOW}请求头:${NC}"
echo "  - Content-Type: application/json"
echo "  - X-Signature: $SIGNATURE"
echo ""
echo -e "${YELLOW}请求体:${NC}"
echo "$ORDER_DATA" | python3 -m json.tool
echo ""

echo "发送 curl 命令..."
echo ""
echo "curl -X POST '$WEBHOOK_ENDPOINT' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -H 'X-Signature: $SIGNATURE' \\"
echo "  -d '$ORDER_DATA'"
echo ""

# 实际发送请求（如果服务器运行）
if command -v curl &> /dev/null; then
    echo -e "${YELLOW}⏳ 等待服务器响应...${NC}"
    
    # 尝试发送请求
    RESPONSE=$(curl -s -X POST "$WEBHOOK_ENDPOINT" \
      -H 'Content-Type: application/json' \
      -H "X-Signature: $SIGNATURE" \
      -d "$ORDER_DATA" 2>&1 || echo '{"error": "连接失败"}')
    
    echo ""
    echo -e "${BLUE}服务器响应:${NC}"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    
    # 步骤 4: 提取验证令牌
    echo ""
    echo -e "${BLUE}步骤 4: 从响应中提取验证链接${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    VERIFICATION_TOKEN=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('verification_token', 'N/A'))" 2>/dev/null || echo "N/A")
    VERIFICATION_LINK=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('verification_link', 'N/A'))" 2>/dev/null || echo "N/A")
    
    echo ""
    echo -e "${GREEN}✅ 验证令牌:${NC} $VERIFICATION_TOKEN"
    echo -e "${GREEN}✅ 买家验证链接:${NC} $VERIFICATION_LINK"
    echo ""
    
    # 步骤 5: 访问验证页面
    echo -e "${BLUE}步骤 5: 访问验证页面${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ "$VERIFICATION_TOKEN" != "N/A" ]; then
        VERIFY_PAGE_URL="$SERVER_URL/verify/$VERIFICATION_TOKEN"
        echo -e "${YELLOW}验证页面 URL:${NC} $VERIFY_PAGE_URL"
        echo ""
        
        # 测试验证页面
        VERIFY_RESPONSE=$(curl -s -X GET "$VERIFY_PAGE_URL" 2>&1 || echo "连接失败")
        
        if echo "$VERIFY_RESPONSE" | grep -q "<!DOCTYPE html>\|<html"; then
            echo -e "${GREEN}✅ 验证页面成功加载${NC}"
            echo ""
            
            # 显示验证页面信息
            echo -e "${BLUE}验证页面包含以下信息:${NC}"
            if echo "$VERIFY_RESPONSE" | grep -q "订单号"; then
                echo "  ✓ 订单号信息"
            fi
            if echo "$VERIFY_RESPONSE" | grep -q "开始验证"; then
                echo "  ✓ 验证按钮"
            fi
            if echo "$VERIFY_RESPONSE" | grep -q "身份"; then
                echo "  ✓ 身份验证说明"
            fi
        else
            echo -e "${RED}❌ 验证页面加载失败${NC}"
        fi
    fi
    
    # 步骤 6: 查询验证状态
    echo ""
    echo -e "${BLUE}步骤 6: 查询验证状态 API${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ "$VERIFICATION_TOKEN" != "N/A" ]; then
        STATUS_URL="$SERVER_URL/verify/status/$VERIFICATION_TOKEN"
        echo -e "${YELLOW}状态查询 URL:${NC} $STATUS_URL"
        echo ""
        
        STATUS_RESPONSE=$(curl -s -X GET "$STATUS_URL" 2>&1 || echo '{"error": "连接失败"}')
        echo -e "${BLUE}状态响应:${NC}"
        echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STATUS_RESPONSE"
    fi
    
else
    echo -e "${RED}❌ curl 未安装${NC}"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ 测试完成${NC}"
echo "════════════════════════════════════════════════════════════"

# 步骤 7: 显示所有关键 URL
echo ""
echo -e "${BLUE}📋 关键 URL 汇总:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Webhook 端点:"
echo "   POST $SERVER_URL/webhook/taobao/order"
echo ""
echo "2. 买家验证页面:"
echo "   GET $SERVER_URL/verify/{verification_token}"
echo ""
echo "3. 查询验证状态:"
echo "   GET $SERVER_URL/verify/status/{verification_token}"
echo ""
echo "4. 获取验证报告:"
echo "   GET $SERVER_URL/report/{order_id}"
echo ""
echo "5. 下载 PDF 报告:"
echo "   GET $SERVER_URL/report/{order_id}/download"
echo ""
echo "════════════════════════════════════════════════════════════"

# 步骤 8: 显示完整流程
echo ""
echo -e "${BLUE}🔄 完整流程:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  [淘宝/闲鱼] 订单创建"
echo "    ↓"
echo "2️⃣  [系统] 接收 Webhook 通知"
echo "    ↓"
echo "3️⃣  [系统] 验证 HMAC 签名"
echo "    ↓"
echo "4️⃣  [系统] 创建 Order 记录"
echo "    ↓"
echo "5️⃣  [系统] 生成验证令牌"
echo "    ↓"
echo "6️⃣  [系统] 调用 Sumsub API 创建 Applicant"
echo "    ↓"
echo "7️⃣  [系统] 生成 Sumsub Web SDK 链接"
echo "    ↓"
echo "8️⃣  [系统] 创建 Verification 记录"
echo "    ↓"
echo "9️⃣  [系统] 发送买家验证链接"
echo "    ↓"
echo "🔟 [买家] 访问验证页面和 Sumsub SDK"
echo "    ↓"
echo "1️⃣1️⃣ [系统] 接收 Sumsub 回调"
echo "    ↓"
echo "1️⃣2️⃣ [系统] 更新验证状态"
echo "    ↓"
echo "1️⃣3️⃣ [系统] 生成 PDF 报告"
echo ""
echo "════════════════════════════════════════════════════════════"
