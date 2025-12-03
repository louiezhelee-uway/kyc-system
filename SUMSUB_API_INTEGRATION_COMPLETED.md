# Sumsub API 集成完成说明

## 问题回顾

在之前的集成中，Sumsub API 持续返回 403 Cloudflare 挑战。根本原因是 **认证方法错误**。

## 解决方案

### 关键修复

1. **认证头改正**
   - ❌ 错误: `Authorization: Bearer {token}`
   - ✅ 正确: `X-App-Token: {token}`

2. **签名格式修正**
   - ❌ 错误: `POST{path}{body}{timestamp_ms}`
   - ✅ 正确: `{timestamp_s}POST{path}{body}`

3. **时间戳单位修正**
   - ❌ 错误: 毫秒（milliseconds）
   - ✅ 正确: 秒数（seconds - Unix Epoch）

4. **验证等级配置**
   - ❌ 错误: 使用不存在的 `basic-kyc-level`
   - ✅ 正确: 使用实际配置的 `id-and-liveness`

## 认证流程（按官方文档）

### 请求签名生成

```python
timestamp = str(int(time.time()))  # 秒数，不是毫秒
method = "POST"
path = "/resources/accessTokens/sdk"
body = '{"userId":"...","levelName":"id-and-liveness",...}'

signature_string = f"{timestamp}{method}{path}{body}"
signature = hmac.new(
    SECRET_KEY.encode(),
    signature_string.encode(),
    hashlib.sha256
).hexdigest()
```

### 请求头

```
X-App-Token: prd:BUWAA7ogVIJZ7W9h7A4BaSRx.xm4V4Zef52mLLYJl0oJ1X4v878Ibo2ie
X-App-Access-Sig: {signature}
X-App-Access-Ts: {timestamp}
Content-Type: application/json
```

## 完整的 KYC 流程

### 步骤 1: 生成 SDK 访问令牌

```bash
POST https://api.sumsub.com/resources/accessTokens/sdk

{
  "userId": "unique_user_id",
  "levelName": "id-and-liveness",
  "ttlInSecs": 1800,
  "applicantIdentifiers": {
    "email": "user@example.com"
  }
}
```

**响应**:
```json
{
  "token": "_act-jwt-eyJhbGciOiJub25lIn0...",
  "userId": "unique_user_id"
}
```

### 步骤 2: 将用户引导到验证页面

使用返回的 token 生成验证链接：

```
https://api.sumsub.com/sdk/applicant?token={token}
```

用户打开此链接并完成身份验证。

### 步骤 3: 接收 Webhook 通知

当用户完成或拒绝验证时，Sumsub 会向您的 webhook 端点发送通知：

```json
POST /webhook/sumsub/verification

{
  "applicantId": "...",
  "externalUserId": "...",
  "eventType": "applicantReview",
  "reviewResult": {
    "reviewStatus": "approved",
    "...": "..."
  }
}
```

### 步骤 4: 更新系统状态

您的系统接收 webhook 后：
1. 验证 webhook 签名
2. 更新数据库中的验证状态
3. 生成 KYC 报告
4. 通知用户验证结果

## 环境配置

### 必需的环境变量

```bash
SUMSUB_APP_TOKEN=prd:BUWAA7ogVIJZ7W9h7A4BaSRx.xm4V4Zef52mLLYJl0oJ1X4v878Ibo2ie
SUMSUB_SECRET_KEY=ypDDepVCvib3Oq3P6tfML91huztzOMuY
SUMSUB_VERIFICATION_LEVEL=id-and-liveness
SUMSUB_API_URL=https://api.sumsub.com
```

### Docker Compose 配置

```yaml
environment:
  SUMSUB_APP_TOKEN: ${SUMSUB_APP_TOKEN}
  SUMSUB_SECRET_KEY: ${SUMSUB_SECRET_KEY}
  SUMSUB_VERIFICATION_LEVEL: ${SUMSUB_VERIFICATION_LEVEL:-id-and-liveness}
  SUMSUB_API_URL: https://api.sumsub.com
```

## 测试命令

### 测试完整 KYC 流程

```bash
bash test_kyc_complete_flow.sh
```

输出示例：
```
✅ 成功生成访问令牌!

🔗 KYC 验证链接:
  https://api.sumsub.com/sdk/applicant?token=_act-jwt-...
```

## 关键文件

- `app/services/sumsub_service.py` - Sumsub API 集成逻辑
- `app/routes/webhook.py` - Webhook 处理
- `docker-compose.yml` - 容器配置

## 常见问题

### Q: 为什么之前一直是 403?

A: Sumsub 的 Cloudflare 保护会对认证失败的请求返回 403。我们之前使用了错误的认证方法（Bearer token 而不是 X-App-Token）。

### Q: 如何获取验证结果?

A: 通过 webhook。当用户完成验证时，Sumsub 会向您配置的 webhook 端点发送结果通知。

### Q: 访问令牌过期了怎么办?

A: 需要重新生成新的令牌。在前端实现令牌刷新处理器。

### Q: 如何在生产环境中部署?

A: 
1. 在 Sumsub Dashboard 获取生产 API Key
2. 配置环境变量
3. 设置 webhook 端点 HTTPS
4. 配置 SDK Settings 中的域名白名单
5. 部署应用

## 相关文档

- [Sumsub API 文档](https://docs.sumsub.com/reference/authentication)
- [WebSDK 集成指南](https://docs.sumsub.com/docs/get-started-with-web-sdk)
- [Webhook 文档](https://docs.sumsub.com/docs/webhooks)

---

**状态**: ✅ 已修复并测试通过
**日期**: 2025-12-03
**版本**: 1.0
