#!/bin/bash

# test_sumsub_api_direct.sh - 直接测试 Sumsub API 凭证

echo "════════════════════════════════════════════════════════"
echo "🔧 直接测试 Sumsub API 凭证"
echo "════════════════════════════════════════════════════════"

SUMSUB_APP_TOKEN="prd:5egHoatccEUC4LTnBZvBDlGH.jZLquVQyveNPaQzEYMBCshQtv2WpLsoR"
SUMSUB_SECRET_KEY="X2EytNeEicET8jno0Vr6iHbKhOE0cpKQ"
API_URL="https://api.sumsub.com"
PATH="/resources/applicants"

# 生成签名
TS=$(date +%s%3N)  # 毫秒时间戳
BODY='{"externalUserId":"test_'$(date +%s)'","email":"test@example.com","phone":"+86-13800000000","firstName":"Test","lastName":"","country":"CN"}'

echo "📝 请求信息:"
echo "  Token: ${SUMSUB_APP_TOKEN:0:20}..."
echo "  Secret: ${SUMSUB_SECRET_KEY:0:20}..."
echo "  时间戳: $TS"
echo "  请求体大小: ${#BODY} 字符"

# 生成签名
SIG_RAW="POST${PATH}${BODY}${TS}"
SIG=$(echo -n "$SIG_RAW" | openssl dgst -sha256 -hmac "$SUMSUB_SECRET_KEY" -hex | cut -d' ' -f2)

echo ""
echo "🔐 签名生成:"
echo "  原文长度: ${#SIG_RAW}"
echo "  签名结果: $SIG"

# 发送请求
echo ""
echo "🚀 发送 API 请求..."
curl -v -X POST "$API_URL$PATH" \
  -H "Authorization: Bearer $SUMSUB_APP_TOKEN" \
  -H "X-App-Access-Sig: $SIG" \
  -H "X-App-Access-Ts: $TS" \
  -H "Content-Type: application/json" \
  -d "$BODY" 2>&1 | tee /tmp/sumsub_response.txt

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 测试完成"
echo "════════════════════════════════════════════════════════"
