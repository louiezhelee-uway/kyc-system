# 闲鱼订单 → KYC 验证完整方案

根据官方文档：
- https://open.goofish.com/doc/development/dev/server.html
- https://open.goofish.com/doc/development/dev/publish.html
- https://open.goofish.com/doc/development/dev/debug.html
- https://open.goofish.com/doc/development/dev/phone.html

---

## 一、架构概述

```
┌──────────────────────────────────────────────────────────────────────┐
│                      完整的闲鱼 KYC 集成流程                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  【聚石塔】（阿里官方数据源）                                         │
│     ├─ 存储：所有淘宝/闲鱼订单数据                                   │
│     └─ 提供：消息推送 + TOP API 查询                                │
│                                                                        │
│  ① 小程序前端 - 用户授权                                             │
│     └─ 用户登录 → 小程序获得 accessToken（有效期180天）             │
│     └─ 保存在小程序本地存储（getStorage）                          │
│                                                                        │
│  ② 小程序前端 - 下单                                                 │
│     └─ 用户购买商品 → 调用闲鱼支付 API                             │
│     └─ 订单支付成功 → 向你的后端发送 Webhook                       │
│     └─ Webhook 中包含：                                             │
│         • biz_order_id（闲鱼订单ID）                              │
│         • buyer_access_token（买家的 accessToken）                │
│         • 其他基础信息                                              │
│                                                                        │
│  ③ 你的后端 - 接收 Webhook                                          │
│     └─ 验证签名 → 解析 accessToken                                 │
│     └─ 用 accessToken 调用 TOP API：                               │
│         alibaba.idle.isv.order.query                              │
│     └─ 获取完整订单信息：买家邮箱、收货地址等                       │
│                                                                        │
│  ④ 你的后端 - 同步到自己的数据库                                     │
│     └─ 在 PostgreSQL 存储订单信息                                  │
│     └─ 关联你自己的业务数据                                         │
│     └─ 创建 KYC 验证记录                                           │
│                                                                        │
│  ⑤ 生成验证链接                                                      │
│     └─ 通过 Sumsub API 生成验证链接                                │
│     └─ 格式：https://kyc.317073.xyz/verify/{token}               │
│                                                                        │
│  ⑥ 发送链接给买家                                                    │
│     └─ 通过小程序弹窗/消息 → 发送验证链接                          │
│     └─ 或通过短信/邮件通知                                         │
│                                                                        │
│  ⑦ 买家完成 KYC                                                      │
│     └─ 访问链接 → WebSDK iframe → 身份验证                        │
│     └─ Sumsub 回调验证结果 → 你的后端                             │
│                                                                        │
│  ⑧ 后端更新订单状态                                                  │
│     └─ 验证通过 → 调用 TOP API 发货：                             │
│         alibaba.idle.isv.order.ship                              │
│     └─ 验证失败 → 调用 TOP API 关闭订单：                         │
│         alibaba.idle.isv.order.close                             │
│                                                                        │
│  ⑨ 聚石塔 - 订单流转                                                 │
│     └─ 订单状态更新 → 推送消息给小程序                             │
│     └─ 小程序更新 UI 展示发货状态                                 │
│                                                                        │
└──────────────────────────────────────────────────────────────────────┘
```

### 数据流向说明

```
聚石塔（主数据源）
    ↓ 消息：idle_autotrade_OrderStateSync
    │ Webhook: /webhook/xianyu/order
    │
你的 PostgreSQL（副本 + 扩展）
    ├─ 存储：订单基础信息（从聚石塔同步）
    ├─ 存储：KYC 验证数据（自己生成）
    ├─ 存储：用户行为日志（自己统计）
    └─ 关联：其他业务数据
    
备注：
• 订单的"唯一真相源" 是聚石塔
• 你的数据库是查询和扩展
• 不是两个独立的订单系统
```

---

## 二、3 个核心要求（官方文档强调）

### ✅ 要求1：数据架构 - 聚石塔为主，自有系统为辅

**官方文档的真实意思：**
> 用户id、订单信息等必须存储在聚石塔内的数据库中，
> 外界可以从聚石塔里获取，至于获取以后自己的平台怎么管理是另外的事情了。

**我们的实现方式：**

1. **聚石塔的角色**（阿里官方数据源）
   - ✅ 存储所有淘宝/闲鱼订单数据（第一真相源）
   - ✅ 提供 TOP API 接口供外界查询
   - ✅ 推送订单状态变更消息

2. **你的系统的角色**（我们的 PostgreSQL）
   - ✅ 从聚石塔同步订单数据（通过消息或 API 查询）
   - ✅ 存储自己扩展的数据：KYC 验证状态、进度等
   - ✅ 关联其他业务逻辑
   - ✅ 长期保留历史记录

3. **具体流程**

```python
# 当收到闲鱼消息时：
消息 = {
    'biz_order_id': '12345678',
    'order_status': 2,  # 已付款
    'encryption_buyer_id': 'xxx'  # 加密买家ID
}

# 第一步：调用 TOP API 查询完整数据
full_order = query_taobao_api(
    'alibaba.idle.isv.order.query',
    biz_order_id=消息['biz_order_id'],
    access_token=買家_accessToken
)
# 返回：买家邮箱、收货地址、订单详情等

# 第二步：存储到自己的 PostgreSQL
我的订单 = {
    'taobao_order_id': full_order['biz_order_id'],
    'buyer_name': full_order['buyer_nick'],
    'buyer_email': full_order['buyer_email'],  # ← 从聚石塔获取
    'buyer_phone': get_phone_from_xianyu(full_order),
    'order_amount': full_order['payment'],
    'kyc_status': 'pending',  # ← 自己的数据
    'kyc_token': 'xxxxx',     # ← 自己生成的
    'created_at': now()
}
db.session.add(我的订单)
db.session.commit()

# 第三步：生成 KYC 链接并返回给小程序前端
kyc_link = f"https://kyc.317073.xyz/verify/{我的订单.kyc_token}"
return kyc_link
```

**关键点：**
- 🔄 订单数据的"一致性"：你的数据是聚石塔数据的一份副本 + 扩展
- 📌 唯一真相源：聚石塔是主，你的系统是从
- 🔐 安全性：用户数据最初存在聚石塔，你的系统存储业务副本
- ✅ 符合规范：完全满足阿里的要求

---

### ✅ 要求2：TOP API 权限申请

**需要申请的权限包：**

| API | 用途 | 权限包 |
|-----|------|--------|
| `alibaba.idle.isv.order.query` | 查询订单状态 | ✅ 已有 |
| `alibaba.idle.isv.order.ship` | 虚拟发货 | ❌ 需要申请 |
| `alibaba.idle.isv.order.close` | 关闭订单 | ❌ 需要申请 |
| `alibaba.idle.goosefish.user.info.query` | 获取用户信息 | ❌ 需要申请 |
| `alibaba.idle.isv.open.user.age.info.query` | 查询用户年龄/认证 | ❌ 需要申请 |

**在闲鱼开放平台操作：**
1. 登录 https://open.goofish.com
2. 进入"应用管理" → 找到你的应用
3. 点击"申请权限"
4. 勾选上述 API 并提交申请
5. 等待闲鱼审核（通常1-3天）

---

### ✅ 要求3：消息接收配置

**文档原文：**
> 消息不支持预发联调，只能发布到线上后进行验证

**消息类型：**
- `idle_autotrade_OrderStateSync` - 正向订单消息（我们需要这个）
- `idle_autotrade_RefundSync` - 逆向退款消息

**我们需要：**
在 VPS 上创建消息处理端点

---

## 三、具体操作步骤

### 步骤 1：在闲鱼开放平台配置应用

#### 1.1 创建应用（如未创建）
```
平台：https://open.goofish.com
路径：应用管理 → 创建应用
名称：KYC 验证系统
类型：第三方服务商
```

#### 1.2 获取应用凭证
```
应用信息中可获得：
- App Key: xxxxxxxx
- App Secret: xxxxxxxx
```

#### 1.3 申请必需权限
```
应用管理 → 申请权限
勾选：
✅ alibaba.idle.isv.order.query
✅ alibaba.idle.isv.order.ship
✅ alibaba.idle.isv.order.close
✅ alibaba.idle.goosefish.user.info.query
✅ alibaba.idle.isv.open.user.age.info.query

提交审批，等待通过
```

#### 1.4 配置消息回调（消息订阅）
```
应用管理 → 消息配置
需要订阅的消息：
- idle_autotrade_OrderStateSync（订单状态变更）

回调地址：https://kyc.317073.xyz/webhook/xianyu/order
（注意：消息配置在线上环境发布后才能测试）
```

---

### 步骤 2：更新我们的 VPS 代码

#### 2.1 核心问题：如何获得买家的 accessToken？

**官方文档的 API 调用规则：**
- 订单查询 API：需要 **买家的 accessToken**
- 发货 API：需要 **卖家的 accessToken**
- 用户信息 API：需要 **当前登录用户的 accessToken**

**你的系统如何获得买家的 accessToken？**

**✅ 方案 A：小程序前端传递（推荐）**

流程：
```
小程序前端流程：
① 用户在小程序中登录 → 获得 accessToken（有效期180天）
② 小程序存储到本地：getStorage('accessToken')
③ 用户下单时 → 调用闲鱼 Goosefish.tradePay() API
④ 订单创建成功 → 回调中获得订单ID
⑤ 前端调用你的 Webhook：
   POST /webhook/xianyu/order/complete
   {
     "biz_order_id": "12345678",
     "buyer_id": "buyer_xxx",
     "buyer_access_token": "token_xxxx",  # ← 关键！
     "buyer_nick": "买家昵称",
     "order_amount": "299.99"
   }
⑥ 签名验证通过 → 后端用 accessToken 查询 TOP API
```

**✅ 方案 B：聚石塔消息 + 后续授权**

流程：
```
① 聚石塔发送消息：订单已付款
② 你的后端收到消息，但没有 accessToken
③ 需要邀请买家授权：
   https://open.api.goofish.com/authorize?response_type=token&client_id=xxxx
④ 买家授权后获得 accessToken
⑤ 再调用 TOP API 查询订单详情
⑥ 存储到自己的 PostgreSQL
```

**我的建议：** 使用方案 A
- 流程更简洁
- 不需要额外的授权步骤
- accessToken 已经有了（买家登录时产生）
- 180天有效期足够长

#### 2.2 修改后的消息处理端点

---

## 四、测试流程（按照官方文档）

### 阶段 1：本地调试

```bash
# 1. 在闲鱼开放平台配置调试白名单
# 应用管理 → 编辑 → 添加调试者花名 → 审批发布

# 2. 配置调试 IP 和端口
# 应用管理 → 调试 → 输入你的本地 IP 和端口
# 有效期：24小时

# 3. 在闲鱼 APP 中扫码测试
# 要求 APP 版本 ≥ 7.14.50
```

### 阶段 2：体验版测试

```bash
# 1. 创建变更
# 应用管理 → 发布集成 → 创建变更

# 2. 填写变更信息
# - 版本号：1.0.0
# - 小程序入口：https://kyc.317073.xyz
# - 对接闲鱼运营：（联系闲鱼商务）
# - 计划发布时间：选择日期
# - 变更内容：KYC 验证集成
# - 测试截图：上传测试结果

# 3. 自测部分
# - 使用体验版链接：加上 ?nbsn=PREVIEW&nbsource=debug&nbsv=1.0.0
# - 完整流程测试

# 4. 提交测试
# - 上传自测结果文档
# - 闲鱼团队进行排序测试
```

### 阶段 3：线上发布

```bash
# 1. 通过闲鱼测试后
# 状态变更为"测试通过" → 手动推进"发起线上部署"

# 2. 等待闲鱼部署
# 闲鱼团队将代码部署到线上

# 3. 上线验证
# 消息支持开始真实推送
```

---

## 五、重要限制和注意事项

### ⚠️ 文件打包规范

如果涉及小程序前端代码：
- ❌ 不支持自定义字体
- ❌ 不支持大图资源（>500KB）
- ❌ 不支持 gz 文件
- ❌ 不能以 .XXX 开头命名
- ❌ 不能有注释：`<!-- comment -->`
- ❌ 不支持汉语命名的文件

### ⚠️ 消息相关

- 消息可能延迟
- 消息不支持预发环境测试
- 必须发布到线上后才能验证真实消息

### ⚠️ 数据安全

根据文档第一条：
> 用户id、订单信息等必须存储在聚石塔内的数据库中

我们当前在 Google Cloud，所以：
- ✅ 可以接收消息
- ✅ 可以返回验证链接
- ⚠️ 不应长期存储用户信息
- ⚠️ 可能需要迁移到聚石塔

---

## 六、下一步行动清单

```
优先级 1（必需）：
[ ] 联系闲鱼商务了解聚石塔要求
[ ] 在开放平台申请 TOP API 权限
[ ] 配置消息订阅（idle_autotrade_OrderStateSync）
[ ] 创建测试应用和 AppKey/AppSecret

优先级 2（推荐）：
[ ] 开发消息处理端点（已提供代码）
[ ] 集成 TOP API 查询订单接口
[ ] 实现买家邮箱获取流程
[ ] 编写本地调试脚本

优先级 3（线上）：
[ ] 配置调试白名单和 IP
[ ] 提交体验版测试
[ ] 准备自测文档
[ ] 联调闲鱼测试团队
```

---

## 七、参考资源

- [闲鱼开放平台首页](https://open.goofish.com)
- [服务端接入文档](https://open.goofish.com/doc/development/dev/server.html)
- [发布集成流程](https://open.goofish.com/doc/development/dev/publish.html)
- [调试指南](https://open.goofish.com/doc/development/dev/debug.html)
- [手机号授权](https://open.goofish.com/doc/development/dev/phone.html)
- [TOP API 文档](https://open.taobao.com)
- [聚石塔指南](https://open.taobao.com/doc.htm?docId=982&docType=1)

---

**最后，最关键的问题：**

> ❓ 我们的系统是否需要部署在阿里聚石塔上？

这需要直接联系闲鱼商务或技术支持确认。如果必须，需要重新部署架构。

