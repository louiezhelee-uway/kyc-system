# WebSDK 集成完成说明

## 概述

KYC 系统现已集成 Sumsub WebSDK，实现了正确的身份验证流程。与之前的直接链接方式不同，现在使用 WebSDK iframe 在您自己的域名（kyc.317073.xyz）上进行验证。

## 问题诊断

### 之前的问题
用户正确指出："这是一个 api.sumsub.com 的链接，不是 317073.xyz 的链接，这样对吗？"

**答案：不对！** 直接使用 `https://api.sumsub.com/sdk/applicant?token=...` 的方式有以下问题：
1. ❌ 用户离开您的平台，跳转到 Sumsub 的域名
2. ❌ 无法在您的平台上维持品牌体验
3. ❌ 无法自定义验证流程
4. ❌ 用户体验不连贯

### 正确的方式
✅ 在您自己的域名上嵌入 WebSDK iframe
✅ 提供统一的品牌体验
✅ 用户始终在您的平台上
✅ 完整的定制能力

## 技术实现

### 1. 验证流程 - 不需要手动创建 Applicant

```python
# 旧方式（不工作）
1. POST /resources/applicants  # 创建 applicant
2. POST /resources/accessTokens/sdk  # 生成令牌

# 新方式（正确）
1. POST /resources/accessTokens/sdk  # 直接生成令牌（自动创建 applicant）
```

### 2. 访问令牌生成

**端点**: `POST https://api.sumsub.com/resources/accessTokens/sdk`

**请求体**:
```json
{
  "userId": "order_{order_id}",
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
  "userId": "order_xxx"
}
```

### 3. 前端 WebSDK 集成

**加载脚本**:
```html
<script src="https://static.sumsub.com/idensic/static/sns-websdk-builder.js"></script>
```

**初始化**:
```javascript
snsWebSdk
  .init(accessToken, () => getNewAccessToken())  // 令牌过期时刷新
  .withConf({
    lang: "zh",  // 中文界面
    theme: "light"
  })
  .withOptions({ 
    addViewportTag: true, 
    adaptIframeHeight: true  // 自适应高度
  })
  .on("idCheck.onStepCompleted", (payload) => {
    // 验证步骤完成
  })
  .on("idCheck.onError", (error) => {
    // 处理错误
  })
  .launch("#sumsub-websdk-container");  // 在 div 中启动 iframe
```

## 系统流程

### 完整端到端流程

```
1. 订单创建
   └─> Order 记录创建

2. Webhook 触发验证
   └─> 调用 create_verification()
       └─> 生成 verification_token
       └─> 创建 Verification 记录

3. 用户访问验证页面
   └─> GET /verify/{verification_token}
       └─> 生成 SDK 访问令牌
       └─> 渲染 verification.html（WebSDK iframe）
       └─> 前端初始化 WebSDK

4. 用户完成验证
   └─> Sumsub WebSDK 处理验证
   └─> Sumsub 发送 Webhook 通知

5. 接收验证结果
   └─> POST /webhook/sumsub/verification
       └─> 更新 Verification 状态
       └─> 生成 PDF 报告

6. 重定向到报告页
   └─> GET /report/{order_id}
       └─> 显示验证结果和报告
```

## 核心改进

### 1. 验证链接架构

**旧方式**:
```
Order → Verification (存储直接链接) → 页面渲染直接链接
https://api.sumsub.com/sdk/applicant?token=...
```

**新方式**:
```
Order → Verification (存储 token) → 页面加载时动态生成令牌 → WebSDK iframe
https://kyc.317073.xyz/verify/{token}
```

### 2. 令牌管理

- **生成时机**: 用户访问验证页面时才生成
- **刷新机制**: WebSDK 过期时自动调用 `/verify/refresh-token` 刷新
- **有效期**: 30 分钟（1800 秒）

### 3. 数据库记录

```python
Verification:
  - id: 验证 ID
  - order_id: 订单 ID
  - sumsub_applicant_id: 用户 ID（order_{order_id}）
  - verification_link: 后端 URL (/verify/{token})
  - verification_token: 用于 URL 的随机令牌
  - status: pending/approved/rejected
  - created_at: 创建时间
  - completed_at: 完成时间
```

## 前端实现

### verification.html 的关键部分

```html
<!-- 1. WebSDK 脚本 -->
<script src="https://static.sumsub.com/idensic/static/sns-websdk-builder.js"></script>

<!-- 2. 容器 div -->
<div id="sumsub-websdk-container"></div>

<!-- 3. 初始化脚本 -->
<script>
  const accessToken = "{{ verification_token_for_sdk }}";
  const verificationToken = "{{ verification_token }}";

  function initializeSDK() {
    snsWebSdk
      .init(accessToken, () => getNewAccessToken())
      .withConf({ lang: "zh", theme: "light" })
      .launch("#sumsub-websdk-container");
  }

  function getNewAccessToken() {
    return fetch('/verify/refresh-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ verification_token: verificationToken })
    })
    .then(res => res.json())
    .then(data => data.token);
  }

  document.addEventListener('DOMContentLoaded', initializeSDK);
</script>
```

## 后端实现

### 关键函数

#### 1. create_verification() - 创建验证记录

```python
def create_verification(order: Order) -> Verification:
    """
    创建验证记录
    注意：不需要手动创建 applicant，令牌生成时会自动创建
    """
    user_id = f"order_{order.id}"
    verification_token = token_generator.generate_verification_token()
    
    verification = Verification(
        order_id=order.id,
        sumsub_applicant_id=user_id,
        verification_token=verification_token,
        status='pending'
    )
    db.session.add(verification)
    db.session.flush()
    return verification
```

#### 2. _generate_access_token() - 生成 SDK 访问令牌

```python
def _generate_access_token(applicant_id: str, user_id: str, email: str = None) -> str:
    """生成 WebSDK 访问令牌"""
    path = '/resources/accessTokens/sdk'
    
    payload = {
        'userId': user_id,
        'levelName': 'id-and-liveness',
        'ttlInSecs': 1800,
    }
    
    if email:
        payload['applicantIdentifiers'] = {'email': email}
    
    # 签名和请求...
    ts, signature = _get_signature('POST', path, json.dumps(payload))
    headers = _get_request_headers(ts, signature)
    
    response = requests.post(
        f'{SUMSUB_API_URL}{path}',
        json=payload,
        headers=headers
    )
    
    return response.json().get('token')
```

#### 3. verification_page() - 渲染验证页面

```python
@bp.route('/<verification_token>', methods=['GET'])
def verification_page(verification_token):
    """显示 WebSDK 验证页面"""
    verification = Verification.query.filter_by(
        verification_token=verification_token
    ).first()
    
    order = verification.order
    
    # 生成新的访问令牌
    access_token = sumsub_service._generate_access_token(
        verification.sumsub_applicant_id,
        f"order_{order.id}",
        order.buyer_email
    )
    
    return render_template(
        'verification.html',
        order=order,
        verification_token=verification_token,
        verification_token_for_sdk=access_token
    )
```

## 测试结果

✅ **所有测试通过**

```
1. 订单创建: ✓
2. 验证创建: ✓
3. 令牌生成: ✓
4. 验证页面: ✓
5. 令牌刷新: ✓
```

### 测试命令

```bash
python test_websdk_integration.py
```

## 部署到 VPS

### 1. 更新代码

```bash
cd /app
git pull
```

### 2. 更新依赖

```bash
pip install -r requirements.txt
```

### 3. 重启服务

```bash
docker-compose down
docker-compose up -d
```

### 4. 验证

访问验证链接:
```
https://kyc.317073.xyz/verify/{verification_token}
```

应该看到:
- 订单信息（买家名称、邮箱等）
- WebSDK iframe
- 验证表单

## 安全特性

### 1. 令牌有效期
- WebSDK 令牌: 30 分钟
- 自动刷新: 令牌过期时前端自动调用 `/verify/refresh-token` 获取新令牌

### 2. 签名验证
- 所有 API 请求都使用 HMAC-SHA256 签名
- 时间戳防重放攻击
- X-App-Token 和 X-App-Access-Sig 验证

### 3. 访问控制
- 验证链接只能通过正确的 verification_token 访问
- 每个订单只有一个验证记录
- 验证完成后重定向到报告页

## 常见问题

### Q: 为什么要在用户访问时生成令牌，而不是提前生成？

A: 这样设计的好处:
- 令牌在生成后立即使用，减少泄露风险
- 可以在生成时添加 IP 地址、用户代理等额外校验
- 更灵活的令牌管理策略

### Q: 令牌过期了怎么办？

A: 前端 WebSDK 会在检测到令牌过期时自动调用刷新端点获取新令牌，用户无需重新加载页面。

### Q: 可以自定义 WebSDK 的样式吗？

A: 可以，通过 `withConf()` 传递配置:
```javascript
.withConf({
  lang: "zh",
  theme: "light",  // 或 "dark"
  customization: {
    // 自定义样式...
  }
})
```

## 后续优化

### 可选的改进项

1. **异步处理**: 使用 Celery 处理后台任务
2. **缓存**: Redis 缓存验证结果，减少数据库查询
3. **监控**: 添加验证流程的监控和告警
4. **分析**: 跟踪用户的验证成功率和平均时长

## 参考文档

- Sumsub 官方文档: https://docs.sumsub.com/
- WebSDK 集成指南: https://docs.sumsub.com/docs/get-started-with-web-sdk
- API 认证: https://docs.sumsub.com/docs/api-authentication

## 总结

✨ **现在已实现完整的 WebSDK 集成**

- 用户在您的域名上完成验证
- 统一的品牌体验
- 完整的定制能力
- 安全的令牌管理
- 自动的令牌刷新

系统已准备就绪！🎉
