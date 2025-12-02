# 🔐 Sumsub WebSDK 集成指南 - 正确方案

## ⚠️ 重要提示

**❌ 错误做法**: `pip install sumsub`  
**原因**: Sumsub 在 PyPI 上没有官方 Python 包！

**✅ 正确做法**: 使用 Sumsub 官方提供的方案
1. **后端**: 用 `requests` 库调用 Sumsub REST API
2. **前端**: 在 HTML 中嵌入 Sumsub JavaScript WebSDK CDN

---

## 架构图

```
┌─ 用户浏览器 ─────────────────────────┐
│                                      │
│  1. 访问验证链接                     │
│  /verify/<token>                     │
│        │                             │
│        ▼                             │
│  2. 获取验证页面 (HTML + JS)        │
│  (包含 Sumsub 访问令牌)             │
│        │                             │
│        ▼                             │
│  3. 加载 Sumsub WebSDK              │
│  <script src="...snsWebSdk.js">     │
│        │                             │
│        ▼                             │
│  4. 初始化 SDK                       │
│  snsWebSdk.init(accessToken)        │
│        │                             │
│        ▼                             │
│  5. 用户上传文件和脸部照片          │
│        │                             │
│        └───────────► Sumsub 服务器   │
│         (HTTPS 直连)                 │
│                                      │
└──────────────────────────────────────┘

┌─ 您的服务器 ──────────────────────────┐
│                                        │
│ Flask 路由:                           │
│  - /verify/<token>                    │
│  - /api/verification/refresh-token    │
│  - /webhook/sumsub                    │
│                                        │
│ Sumsub 服务:                          │
│  - create_verification()              │
│  - _generate_access_token()           │
│  - update_verification_status()       │
│  - generate_pdf_report()              │
│                                        │
└──────────────────────────────────────┘
         ▲                      ▼
         │         REST API   │
         │       (HMAC签名)    │
         └──────────────────────┘
```

---

## ✅ 已完成的工作

### 1. 后端 API 集成 (Python)
文件: `app/services/sumsub_service.py`

```python
# 函数列表
✅ create_verification(order)           # 创建验证
✅ _generate_access_token(applicant_id) # 生成 WebSDK 令牌
✅ _get_signature(method, path, body)   # HMAC-SHA256 签名
✅ update_verification_status(...)      # 更新状态
✅ get_verification_result(...)         # 获取结果
✅ generate_pdf_report(order_id)        # 生成报告
```

**特点**:
- ✅ 使用 `requests` 库（无需 pip sumsub）
- ✅ 完整的 HMAC-SHA256 签名认证
- ✅ 错误处理和日志
- ✅ 异常管理

### 2. 前端 WebSDK 集成 (JavaScript)
文件: `app/templates/verification.html`

```html
<script src="https://cdn.sumsub.com/idensic/js/11.17.0/snsWebSdk.js"></script>

<script>
const snsWebSdkInstance = snsWebSdk
    .init(accessToken, refreshTokenCallback)
    .withConf({ lang: "en", theme: "light" })
    .on("idCheck.onStepCompleted", handleStep)
    .on("idCheck.onComplete", handleComplete)
    .on("idCheck.onError", handleError)
    .build();

snsWebSdkInstance.launch("#sumsub-websdk-container");
</script>
```

**特点**:
- ✅ 官方 CDN 加载
- ✅ 访问令牌初始化
- ✅ 事件监听 (完成/错误)
- ✅ 自动令牌刷新
- ✅ 响应式设计

### 3. 环境变量配置
文件: `.env`

```bash
SUMSUB_APP_TOKEN=your_app_token
SUMSUB_SECRET_KEY=your_secret_key
SUMSUB_API_URL=https://api.sumsub.com
SUMSUB_WEBHOOK_SECRET=your_webhook_secret
APP_DOMAIN=https://kyc.317073.xyz
```

### 4. 数据库模型
文件: `app/models/verification.py`

```python
class Verification(db.Model):
    id                    # UUID
    order_id              # FK to Order
    sumsub_applicant_id   # Sumsub 申请人 ID
    verification_token    # 我们的验证令牌
    access_token          # Sumsub WebSDK 访问令牌 ← 新增
    status               # pending/approved/rejected
    created_at           # 时间戳
    completed_at         # 完成时间

class Report(db.Model):
    id
    verification_id       # FK to Verification
    verification_result   # approved/rejected
    verification_details  # JSON 数据
    pdf_path             # PDF 文件路径
    created_at
```

---

## 完整流程

### 1️⃣ 后端生成访问令牌

```python
# app/routes/verification.py

@verification_bp.route('/<token>')
def show_verification(token):
    # 查找验证记录
    verification = Verification.query.filter_by(
        verification_token=token
    ).first()
    
    # 获取或生成访问令牌
    if not verification.access_token:
        access_token = sumsub_service._generate_access_token(
            verification.sumsub_applicant_id
        )
        verification.access_token = access_token
        db.session.commit()
    
    # 传递给前端
    return render_template(
        'verification.html',
        verification_token=verification.access_token
    )
```

### 2️⃣ 前端加载 WebSDK

```javascript
// HTML 页面加载时
document.addEventListener('DOMContentLoaded', () => {
    snsWebSdk.init(
        "{{ verification_token }}",  // ← 从后端获取
        refreshAccessToken           // ← 令牌过期时调用
    )
    .build()
    .launch("#sumsub-websdk-container");
});
```

### 3️⃣ 用户完成验证

- 用户上传证件
- 进行人脸识别
- 活体检测
- Sumsub 返回结果

### 4️⃣ Sumsub 发送 Webhook

```json
POST /webhook/sumsub

{
    "applicantId": "abc123",
    "reviewStatus": "approved"
}
```

### 5️⃣ 后端处理 Webhook

```python
@app.route('/webhook/sumsub', methods=['POST'])
def sumsub_webhook():
    # 验证签名
    verify_webhook_signature(request)
    
    # 更新验证状态
    applicant_id = request.json['applicantId']
    status = request.json['reviewStatus']
    
    sumsub_service.update_verification_status(
        applicant_id, status
    )
    
    # 如果通过，生成报告
    if status == 'approved':
        sumsub_service.generate_pdf_report(order_id)
    
    return {'success': True}
```

---

## Flask 路由完整实现

```python
# app/routes/verification.py

from flask import Blueprint, render_template, request, jsonify
from app.services import sumsub_service
from app.models import Order, Verification
from app import db

verification_bp = Blueprint('verification', __name__, url_prefix='/verify')

@verification_bp.route('/<token>')
def show_verification(token):
    """显示 Sumsub WebSDK 验证页面"""
    verification = Verification.query.filter_by(
        verification_token=token
    ).first()
    
    if not verification:
        return "验证链接无效", 404
    
    order = Order.query.get(verification.order_id)
    
    return render_template(
        'verification.html',
        order=order,
        verification_token=verification.access_token
    )

@verification_bp.route('/api/refresh-token', methods=['POST'])
def refresh_token():
    """刷新过期的访问令牌"""
    data = request.json
    order_id = data.get('order_id')
    
    verification = Verification.query.filter_by(
        order_id=order_id
    ).first()
    
    if not verification:
        return {'error': 'Not found'}, 404
    
    try:
        # 重新生成访问令牌
        new_token = sumsub_service._generate_access_token(
            verification.sumsub_applicant_id
        )
        
        verification.access_token = new_token
        db.session.commit()
        
        return {'access_token': new_token}
    except Exception as e:
        return {'error': str(e)}, 500
```

---

## Webhook 处理

```python
# app/routes/webhook.py

import hmac
import hashlib

@app.route('/webhook/sumsub', methods=['POST'])
def sumsub_webhook():
    """处理 Sumsub 验证结果 Webhook"""
    
    # 验证签名
    webhook_secret = os.getenv('SUMSUB_WEBHOOK_SECRET')
    x_signature = request.headers.get('X-Signature')
    body = request.get_data()
    
    expected_sig = hmac.new(
        webhook_secret.encode(),
        body,
        hashlib.sha256
    ).hexdigest()
    
    if x_signature != expected_sig:
        return {'error': 'Invalid signature'}, 403
    
    try:
        data = request.json
        applicant_id = data.get('applicantId')
        status = data.get('reviewStatus')
        
        # 更新验证状态
        verification = Verification.query.filter_by(
            sumsub_applicant_id=applicant_id
        ).first()
        
        if verification:
            sumsub_service.update_verification_status(
                applicant_id, status
            )
            
            # 通过则生成报告
            if status == 'approved':
                sumsub_service.generate_pdf_report(
                    verification.order_id
                )
        
        return {'success': True}
    except Exception as e:
        print(f"Webhook error: {e}")
        return {'error': str(e)}, 500
```

---

## 测试检查清单

```bash
# 1. 检查环境变量
echo $SUMSUB_APP_TOKEN
echo $SUMSUB_SECRET_KEY

# 2. 启动应用
docker-compose up -d

# 3. 测试后端 API
curl -X POST http://localhost:5000/api/test-sumsub \
  -H "Content-Type: application/json" \
  -d '{"buyer_email": "test@test.com"}'

# 4. 访问验证页面
# 从返回的响应获取 verification_token
# 访问 http://localhost:5000/verify/<token>

# 5. 检查 WebSDK 是否加载
# 在浏览器开发者工具中查看网络请求
# 应该看到 snsWebSdk.js 加载成功

# 6. 查看日志
docker-compose logs -f web
```

---

## 常见问题

### Q: WebSDK 不加载怎么办？
**A**: 检查浏览器控制台是否有 CORS 错误。Sumsub CDN 可能被 GFW 阻止（中国）。

**解决**: 使用代理或更新 CDN 地址。

### Q: 访问令牌过期了怎么办？
**A**: 前端自动调用 `/verify/api/refresh-token` 获取新令牌。

### Q: 如何验证 Webhook 的真伪？
**A**: 检查 `X-Signature` 头：

```python
expected = hmac.new(secret.encode(), body, sha256).hexdigest()
if received_sig != expected:
    return 403  # 非法请求
```

### Q: 生产环境用哪个 Sumsub 端点？
**A**: 使用 `https://api.sumsub.com`（生产）

开发: `https://test-api.sumsub.com`

---

## 所需的 Python 依赖

```
requests>=2.28.0          # HTTP 客户端（用于 API）
python-dotenv>=0.20.0    # 环境变量
Flask>=2.3.0
Flask-SQLAlchemy>=3.0.0
reportlab>=3.6.0         # PDF 生成
```

**无需安装 `sumsub` 包！**

---

## 文件清单

- ✅ `app/services/sumsub_service.py` - 后端 API 客户端
- ✅ `app/templates/verification.html` - 前端 WebSDK
- ✅ `app/routes/verification.py` - 验证路由
- ✅ `app/routes/webhook.py` - Webhook 处理
- ✅ `app/models/verification.py` - 数据库模型
- ✅ `.env` - 环境变量
- ✅ `requirements.txt` - Python 依赖

---

**系统状态**: ✅ 完全就绪  
**集成方式**: ✅ JavaScript WebSDK + Python REST API  
**认证方式**: ✅ HMAC-SHA256  
**前端**: ✅ CDN 加载，无需本地构建  
**后端**: ✅ 无需 pip sumsub 包  

