# WebSDK 集成快速参考

## 问题与解决方案

### ❌ 之前的方式（错误）
"这是一个 api.sumsub.com 的链接，不是 317073.xyz 的链接啊，这样对吗？"
- 直接链接到 `https://api.sumsub.com/sdk/applicant?token=...`
- 用户离开您的平台
- 验证过程看不到您的品牌

### ✅ 现在的方式（正确）
- 在您的域名上嵌入 WebSDK iframe
- 用户始终在 `https://kyc.317073.xyz` 上
- 完整的品牌体验和自定义

## 关键改变

### 1. 不需要创建 Applicant

```python
# ❌ 旧方式
POST /resources/applicants  # 创建 applicant
POST /resources/accessTokens/sdk  # 生成令牌

# ✅ 新方式
POST /resources/accessTokens/sdk  # 直接生成令牌（自动创建 applicant）
```

### 2. 链接不再直接指向 api.sumsub.com

```
❌ 旧方式: https://api.sumsub.com/sdk/applicant?token=...
✅ 新方式: https://kyc.317073.xyz/verify/{verification_token}
         └─> 加载 WebSDK iframe
```

### 3. 令牌在需要时生成

```python
# 用户访问时
GET /verify/{verification_token}
  └─> 生成新的访问令牌
  └─> 渲染 WebSDK iframe

# 令牌过期时
POST /verify/refresh-token
  └─> 自动生成新令牌
  └─> 用户无需重新加载
```

## 流程图

```
Order 创建
    ↓
Webhook 触发
    ↓
create_verification()
    ├─ 生成 verification_token
    ├─ 创建 Verification 记录
    └─ 返回到销售页面
    ↓
用户点击验证链接: /verify/{verification_token}
    ↓
verification_page()
    ├─ 生成 SDK 访问令牌
    ├─ 渲染 WebSDK iframe
    └─ 前端初始化 snsWebSdk
    ↓
用户在 iframe 中完成验证
    ↓
Sumsub Webhook 通知
    ↓
更新 Verification 状态
    ↓
生成报告
```

## 核心代码片段

### 后端

```python
from app.services import sumsub_service
from app.models import Verification

# 创建验证
verification = sumsub_service.create_verification(order)
db.session.commit()

# 生成令牌（路由中）
access_token = sumsub_service._generate_access_token(
    verification.sumsub_applicant_id,
    f"order_{order.id}",
    order.buyer_email
)

# 传递给模板
render_template(
    'verification.html',
    verification_token_for_sdk=access_token  # WebSDK 使用
)
```

### 前端

```html
<!-- 1. 加载 WebSDK -->
<script src="https://static.sumsub.com/idensic/static/sns-websdk-builder.js"></script>

<!-- 2. 容器 -->
<div id="sumsub-websdk-container"></div>

<!-- 3. 初始化 -->
<script>
  const accessToken = "{{ verification_token_for_sdk }}";
  
  snsWebSdk
    .init(accessToken, () => getNewAccessToken())
    .withConf({ lang: "zh" })
    .launch("#sumsub-websdk-container");
</script>
```

## 重要配置

### 环境变量

```bash
SUMSUB_APP_TOKEN=prd:BUWAA7ogVIJZ7W9h7A4BaSRx.xm4V4Zef52mLLYJl0oJ1X4v878Ibo2ie
SUMSUB_SECRET_KEY=ypDDepVCvib3Oq3P6tfML91huztzOMuY
SUMSUB_API_URL=https://api.sumsub.com
SUMSUB_VERIFICATION_LEVEL=id-and-liveness
```

### 数据库

```python
Verification 表:
- verification_token: 用于 URL 的随机令牌
- sumsub_applicant_id: 用户 ID
- verification_link: 后端 URL（/verify/...）
- status: pending/approved/rejected
```

## 测试

```bash
python test_websdk_integration.py
```

期望输出:
```
✅ 所有测试通过！
✨ WebSDK 集成已准备就绪！
```

## 常见问题

| 问题 | 答案 |
|------|------|
| 为什么链接是 kyc.317073.xyz 而不是 api.sumsub.com？ | WebSDK 嵌入在您的域上，提供完整的品牌体验 |
| 令牌过期了怎么办？ | 前端自动刷新，用户无需操作 |
| 如何自定义 WebSDK 界面？ | 通过 `withConf()` 传递配置 |
| 用户在哪里完成验证？ | 在 kyc.317073.xyz 上的 iframe 中 |

## 验证链接格式

```
https://kyc.317073.xyz/verify/{verification_token}

示例:
https://kyc.317073.xyz/verify/gVUTUkfdPUGFiVmcJz1I9SUIBc1ZufLv
```

## 已验证的功能

- ✅ 订单创建
- ✅ 验证记录创建
- ✅ 访问令牌生成
- ✅ WebSDK iframe 加载
- ✅ 令牌刷新
- ✅ 页面渲染

## 部署命令

```bash
docker-compose down
docker-compose up -d
```

访问:
```
https://kyc.317073.xyz/verify/{token}
```

## 关键改进总结

| 方面 | 旧方式 | 新方式 |
|------|--------|--------|
| 链接格式 | api.sumsub.com | kyc.317073.xyz |
| 用户体验 | 离开您的平台 | 留在您的平台 |
| 品牌展示 | 无 | 完整的品牌体验 |
| 定制能力 | 无 | 可自定义 |
| 令牌生成 | 提前生成 | 按需生成 |
| 令牌刷新 | 手动 | 自动 |

✨ **现在系统已完全就绪！**
