# 闲鱼小程序 + KYC 系统集成 - 快速指南

根据计划 A：使用闲鱼官方小程序框架

---

## 第一步：在闲鱼开放平台申请凭证

### 1.1 创建应用并获取 Token

**访问地址：** https://open.goofish.com

**操作步骤：**

1. 登录或注册闲鱼开放平台账号
2. 进入"应用管理" → "创建应用"
3. 填写应用信息：
   ```
   应用名称：KYC 验证系统
   应用类型：第三方服务商
   应用描述：与 Sumsub KYC 系统集成的身份验证解决方案
   ```
4. 创建成功后获得：
   ```
   App Key: xxxxxxxx
   App Secret: xxxxxxxx
   ```

### 1.2 申请 TOP API 权限

在"应用管理" → 找到你的应用 → "申请权限"

**需要申请的权限包（勾选以下所有权限）：**

| 权限 | API 名称 | 用途 |
|------|---------|------|
| ✅ | `alibaba.idle.isv.order.query` | 查询订单详情 |
| ✅ | `alibaba.idle.isv.order.ship` | 物流发货 |
| ✅ | `alibaba.idle.isv.goosefish.virtual.delivery` | 虚拟发货 |
| ✅ | `alibaba.idle.isv.order.close` | 关闭订单 |
| ✅ | `alibaba.idle.goosefish.user.info.query` | 获取用户信息 |
| ✅ | `alibaba.idle.isv.open.user.age.info.query` | 查询用户年龄/认证信息 |

**提交后等待闲鱼审核（通常 1-3 天）**

### 1.3 记录凭证

```
App Key: _________________
App Secret: _________________
应用ID: _________________
```

---

## 第二步：配置你的 KYC 后端

### 2.1 更新 VPS 的 .env 文件

```bash
ssh root@35.212.217.145

cd /opt/kyc-app

# 编辑 .env 文件
nano .env
```

**添加以下内容：**

```bash
# 闲鱼配置
XIANYU_APP_KEY=你申请的_App_Key
XIANYU_APP_SECRET=你申请的_App_Secret
```

**保存并退出：** Ctrl+X → Y → Enter

### 2.2 重启容器以加载新的环境变量

```bash
docker-compose down
docker-compose up -d

# 等待容器启动（约10秒）
sleep 10

# 验证环境变量是否加载
docker-compose exec -T web env | grep XIANYU
```

**预期输出：**
```
XIANYU_APP_KEY=你的_key
XIANYU_APP_SECRET=你的_secret
```

### 2.3 提交代码到 Git

```bash
cd /Users/louie/Library/Mobile\ Documents/com~apple~CloudDocs/Documents/project\ X/Project_KYC

# 添加新的实现代码
git add app/routes/xianyu_service.py
git add app/routes/xianyu_message.py

# 修改应用初始化以注册蓝图
git add app/__init__.py

# 提交
git commit -m "feat: 集成闲鱼 TOP API 和小程序 Webhook 处理"

# 推送到 GitHub
git push origin main

# 在 VPS 上拉取更新
ssh root@35.212.217.145
cd /opt/kyc-app
git pull origin main
docker-compose restart web
```

---

## 第三步：测试后端 API 端点

### 3.1 测试 /webhook/xianyu/order/complete 端点

**在 VPS 上运行测试：**

```bash
cd /opt/kyc-app

docker-compose exec -T web python3 << 'EOF'
import requests
import json

# 模拟小程序前端调用

test_payload = {
    "biz_order_id": "3318740388015865620",
    "buyer_id": "buyer_test_123",
    "buyer_access_token": "test_token_xxxx",  # 这是假的，实际由小程序提供
    "buyer_nick": "测试买家",
    "order_amount": 29999,  # 单位：分
    "item_title": "测试商品"
}

try:
    response = requests.post(
        'http://localhost:5000/webhook/xianyu/order/complete',
        json=test_payload,
        timeout=10
    )
    
    print(f"状态码: {response.status_code}")
    print(f"响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
except Exception as e:
    print(f"错误: {e}")

EOF
```

**预期输出：**
```
状态码: 400
响应: {
  "error": "Order not found in Taobao"
}
```

（返回 400 是正常的，因为我们用的是假数据）

### 3.2 验证代码没有语法错误

```bash
cd /opt/kyc-app

docker-compose exec -T web python3 -m py_compile app/routes/xianyu_service.py
docker-compose exec -T web python3 -m py_compile app/routes/xianyu_message.py

# 如果没有输出，说明代码正常
```

---

## 第四步：获取闲鱼官方小程序框架文档

### 4.1 下载官方文档和 SDK

**访问闲鱼开发者中心：** https://open.goofish.com

**获取以下资源：**

1. **小程序 SDK**
   - 路径：文档 → API列表 → 基础 API
   - 下载：`sns-websdk-builder.js` 等

2. **示例代码**
   - 路径：文档 → 快速接入
   - 查看：小程序示例项目

3. **API 文档**
   - 路径：API列表 → 所有 API
   - 关键 API：
     - `Goosefish.tradePay()` - 支付
     - `xy.getStorage()` / `setStorage()` - 本地存储
     - `xy.request()` - 网络请求

### 4.2 理解小程序框架结构

```
闲鱼小程序项目结构（官方框架）
├── index.html          # 入口页面
├── pages/
│   ├── list.html      # 商品列表页
│   ├── detail.html    # 商品详情页
│   └── payment.html   # 支付页面
├── js/
│   ├── app.js         # 应用主文件
│   ├── api.js         # API 调用
│   └── utils.js       # 工具函数
├── css/
│   └── style.css      # 样式
└── manifest.json      # 小程序配置
```

---

## 第五步：集成小程序与后端

### 5.1 小程序中的关键流程

**文件：`js/api.js` 或 `js/payment.js`**

```javascript
// 1. 用户登录并获取 accessToken
async function login() {
  // 调用闲鱼登录 API
  const result = await xy.login();
  
  // 获取 accessToken
  const accessToken = result.accessToken;
  
  // 保存到本地存储（有效期180天）
  xy.setStorage('accessToken', accessToken);
  
  console.log('登录成功，Token 已保存');
}

// 2. 用户点击购买
async function buyProduct(itemId, price) {
  // 从本地存储获取 accessToken
  const accessToken = xy.getStorage('accessToken');
  
  if (!accessToken) {
    // 未登录，先登录
    await login();
  }
  
  // 调用闲鱼支付 API
  try {
    const payResult = await Goosefish.tradePay({
      itemId: itemId,
      price: price,
      // 其他参数...
    });
    
    console.log('支付成功:', payResult);
    
    // 3. 支付成功后，调用你的后端创建订单和 KYC 链接
    await createOrderAndKYC(payResult);
    
  } catch (error) {
    console.error('支付失败:', error);
  }
}

// 3. 调用你的后端 Webhook
async function createOrderAndKYC(payResult) {
  const accessToken = xy.getStorage('accessToken');
  
  try {
    // 调用你的后端接口
    const response = await xy.request({
      url: 'https://kyc.317073.xyz/webhook/xianyu/order/complete',
      method: 'POST',
      data: {
        biz_order_id: payResult.biz_order_id,
        buyer_id: payResult.buyer_id,
        buyer_access_token: accessToken,  # ← 关键：传递 accessToken
        buyer_nick: payResult.buyer_nick,
        order_amount: payResult.order_amount,
        item_title: payResult.item_title
      }
    });
    
    if (response.status === 'success') {
      const kycLink = response.verification_link;
      
      // 显示 KYC 验证链接
      showKYCModal(kycLink);
      
      // 或者直接打开 WebView
      xy.navigateTo({
        url: kycLink
      });
    } else {
      console.error('创建 KYC 失败:', response.error);
    }
    
  } catch (error) {
    console.error('调用后端失败:', error);
  }
}

// 显示 KYC 验证弹窗
function showKYCModal(kycLink) {
  xy.showModal({
    title: '身份验证',
    content: '需要完成身份验证才能继续',
    confirmText: '去验证',
    cancelText: '取消',
    success(res) {
      if (res.confirm) {
        // 打开 WebView 访问验证链接
        xy.openWebView({
          url: kycLink
        });
      }
    }
  });
}
```

### 5.2 小程序配置

**文件：`manifest.json`**

```json
{
  "name": "KYC验证系统",
  "appId": "your_app_id",
  "version": "1.0.0",
  "permissions": [
    "login",        # 用户登录
    "payment",      # 支付功能
    "webView",      # WebView 打开验证页面
    "storage"       # 本地存储
  ],
  "networkRequests": [
    "https://kyc.317073.xyz",    # 你的后端域名
    "https://api.taobao.com",     # 闲鱼 API
    "https://gw.api.taobao.com"   # 闲鱼 TOP API
  ]
}
```

---

## 第六步：本地调试

### 6.1 配置调试白名单

**在闲鱼开放平台：**
1. 应用管理 → 编辑
2. 调试者白名单 → 添加你的花名/昵称
3. 提交审批

### 6.2 配置调试 IP 和端口

**本地调试步骤：**

```bash
# 1. 在本地启动后端开发服务
python run.py

# 2. 获取你的本地 IP（用于局域网访问）
ifconfig | grep "inet "

# 3. 在闲鱼开发平台配置
# 应用管理 → 调试 → 输入：
# IP: 你的本地IP (例如 192.168.1.100)
# 端口: 5000
# 有效期: 24小时
```

### 6.3 在闲鱼 APP 中测试

```
1. 安装闲鱼 APP（版本 ≥ 7.14.50）
2. 在闲鱼中扫描你的小程序链接
3. 按照登录 → 选购 → 支付 → KYC 的流程测试
4. 查看后端日志是否有调用记录
```

---

## 第七步：体验版测试（线上测试前）

### 7.1 提交体验版

**在闲鱼开放平台：**

1. 应用管理 → 发布集成 → 创建变更
2. 填写变更信息：
   ```
   版本号：1.0.0
   小程序入口：https://kyc.317073.xyz
   对接闲鱼运营：[联系人]
   计划发布时间：[选择日期]
   变更内容：集成 KYC 身份验证
   ```
3. 上传测试包（小程序代码）
4. 提交自测结果

### 7.2 体验版链接

体验版链接格式（用于测试）：
```
https://kyc.317073.xyz?nbsn=PREVIEW&nbsource=debug&nbsv=1.0.0
```

### 7.3 自测清单

- [ ] 用户能否正常登录
- [ ] 能否正常浏览商品列表
- [ ] 能否正常下单和支付
- [ ] 支付成功后是否收到 KYC 链接
- [ ] 能否正常打开 WebView 访问验证页面
- [ ] 能否完成身份验证
- [ ] 验证成功后订单状态是否更新

---

## 第八步：线上发布

### 8.1 通过测试后发起线上部署

1. 状态变更为"测试通过"
2. 手动推进"发起线上部署"
3. 等待闲鱼部署（通常 1-2 天）

### 8.2 线上发布检查清单

- [ ] App Key/Secret 已配置
- [ ] 所有 API 权限已获批
- [ ] 后端服务正常运行
- [ ] 小程序代码已提交
- [ ] 域名 SSL 证书有效
- [ ] 消息回调地址已配置

---

## 故障排查

### 问题：后端收不到小程序的请求

**可能原因：**
1. ❌ 小程序 manifest.json 未配置 `https://kyc.317073.xyz`
2. ❌ 防火墙阻止了请求
3. ❌ accessToken 传递错误

**解决方案：**
```javascript
// 在小程序中添加调试日志
console.log('发送请求到:', url);
console.log('请求体:', JSON.stringify(data));

// 查看浏览器控制台（开发者工具）是否有错误
```

### 问题：TOP API 返回 401

**可能原因：**
1. ❌ accessToken 过期或无效
2. ❌ App Key/Secret 错误
3. ❌ 权限未获批

**解决方案：**
```bash
# 检查 VPS 上的环境变量
docker-compose exec -T web env | grep XIANYU

# 查看后端日志
docker-compose logs web | tail -100
```

### 问题：小程序链接打不开

**可能原因：**
1. ❌ 域名未配置 CNAME
2. ❌ SSL 证书过期
3. ❌ 小程序未发布

**解决方案：**
```bash
# 测试域名是否可访问
curl -I https://kyc.317073.xyz/verify/test_token

# 应该返回 HTTP 200
```

---

## 关键时间点

| 阶段 | 预计时间 | 备注 |
|------|---------|------|
| 申请凭证 | 1-3天 | 等待闲鱼审核 |
| 申请权限 | 1-3天 | 等待闲鱼审核 |
| 本地开发 | 3-5天 | 开发小程序集成 |
| 本地调试 | 1-2天 | 验证流程 |
| 提交体验版 | 1天 | 提交测试 |
| 闲鱼测试 | 3-5天 | 等待测试团队 |
| 线上发布 | 1-2天 | 部署到生产 |

**总预计时间：2-3 周**

---

## 联系方式

如需帮助，可以：

1. 📧 联系闲鱼技术支持
2. 📞 咨询对接商务
3. 💬 查看官方文档：https://open.goofish.com/doc/

---

**准备好开始了吗？祝你成功！** 🚀

