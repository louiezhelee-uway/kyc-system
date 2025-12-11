# 闲鱼 KYC 集成 - 完整实现代码

根据上述方案，以下是完整的实现代码。

---

## 1. Xianyu TOP API 服务层

**文件：`app/routes/xianyu_service.py`**

```python
"""
闲鱼 TOP API 调用封装
处理所有与闲鱼平台的 API 交互
"""
import os
import requests
import time
import hmac
import hashlib
from datetime import datetime

class XianyuTopAPI:
    """闲鱼 TOP API 调用封装"""
    
    # TOP API 正式地址（线上环境）
    API_URL = "https://gw.api.taobao.com/router/rest"
    # TOP API 预发环境（仅用于开发时与闲鱼联调）
    API_PRE_URL = "https://pre-gw.api.taobao.com/top/router/rest"
    
    def __init__(self, use_pre_env=False):
        self.app_key = os.getenv('XIANYU_APP_KEY')
        self.app_secret = os.getenv('XIANYU_APP_SECRET')
        self.use_pre_env = use_pre_env
        self.api_url = self.API_PRE_URL if use_pre_env else self.API_URL
        
        if not self.app_key or not self.app_secret:
            raise ValueError("缺少闲鱼 App Key 或 App Secret 配置")
    
    def _generate_sign(self, params):
        """
        生成 TOP API 签名
        算法：MD5(AppSecret + 排序参数字符串 + AppSecret)
        """
        # 按 key 排序参数
        sorted_items = sorted(params.items())
        
        # 拼接字符串：key1value1key2value2key3value3...
        param_str = ''.join([f"{k}{v}" for k, v in sorted_items])
        
        # 前后加 AppSecret
        sign_str = self.app_secret + param_str + self.app_secret
        
        # MD5 转大写
        sign = hashlib.md5(sign_str.encode()).hexdigest().upper()
        return sign
    
    def call_api(self, method, params, access_token):
        """
        调用 TOP API
        
        Args:
            method: API 方法名，如 'alibaba.idle.isv.order.query'
            params: 业务参数字典
            access_token: 用户 accessToken（买家或卖家）
        
        Returns:
            dict: API 返回的数据，或 None 如果出错
        """
        
        # 基础参数
        api_params = {
            'method': method,
            'app_key': self.app_key,
            'v': '2.0',
            'format': 'json',
            'timestamp': str(int(time.time() * 1000)),  # 毫秒级时间戳
            'access_token': access_token,
        }
        
        # 合并业务参数
        api_params.update(params)
        
        # 生成签名
        api_params['sign'] = self._generate_sign(api_params)
        
        try:
            print(f"📡 调用 TOP API: {method}")
            # 调用 API
            response = requests.post(self.api_url, params=api_params, timeout=30)
            
            result = response.json()
            
            # 检查错误
            if 'error_response' in result:
                error = result['error_response']
                print(f"❌ TOP API 错误 [{error.get('code')}]: {error.get('msg')}")
                return None
            
            print(f"✅ TOP API 调用成功")
            # 返回数据
            return result
        
        except Exception as e:
            print(f"❌ TOP API 调用异常: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def query_order(self, biz_order_id, buyer_access_token):
        """
        查询订单详情
        API: alibaba.idle.isv.order.query
        
        文档：https://open.taobao.com/api.htm?spm=a219a.7386797.0.0.6e57669ansov9L
        """
        params = {
            'biz_order_id': biz_order_id
        }
        
        result = self.call_api(
            'alibaba.idle.isv.order.query',
            params,
            buyer_access_token
        )
        
        if result:
            # 提取订单信息
            order_info = result.get('alibaba_idle_isv_order_query_response', {}).get('module')
            return order_info
        
        return None
    
    def ship_order(self, biz_order_id, ship_mail_no, logistics_company, seller_access_token):
        """
        物流发货
        API: alibaba.idle.isv.order.ship
        
        文档：https://open.taobao.com/api.htm?docId=55351&docType=2
        """
        params = {
            'biz_order_id': biz_order_id,
            'ship_mail_no': ship_mail_no,
            'logistics_company': logistics_company,
        }
        
        result = self.call_api(
            'alibaba.idle.isv.order.ship',
            params,
            seller_access_token
        )
        
        return result is not None
    
    def virtual_delivery(self, biz_order_id, seller_access_token):
        """
        虚拟发货（无物流发货）
        API: alibaba.idle.isv.goosefish.virtual.delivery
        
        用于虚拟商品或不需要物流的场景
        """
        params = {
            'biz_order_id': biz_order_id
        }
        
        result = self.call_api(
            'alibaba.idle.isv.goosefish.virtual.delivery',
            params,
            seller_access_token
        )
        
        return result is not None
    
    def close_order(self, biz_order_id, close_reason, seller_access_token):
        """
        关闭订单（未发货）
        API: alibaba.idle.isv.order.close
        
        用于订单验证失败、无库存等情况
        """
        params = {
            'biz_order_id': biz_order_id,
            'close_reason': close_reason
        }
        
        result = self.call_api(
            'alibaba.idle.isv.order.close',
            params,
            seller_access_token
        )
        
        return result is not None
    
    def get_user_info(self, buyer_access_token):
        """
        获取用户基础信息
        API: alibaba.idle.goosefish.user.info.query
        
        返回：昵称、头像、性别等
        """
        params = {}
        
        result = self.call_api(
            'alibaba.idle.goosefish.user.info.query',
            params,
            buyer_access_token
        )
        
        if result:
            user_info = result.get('alibaba_idle_goosefish_user_info_query_response', {}).get('data')
            return user_info
        
        return None
    
    def get_user_age_info(self, buyer_access_token):
        """
        获取用户年龄信息
        API: alibaba.idle.isv.open.user.age.info.query
        
        返回：
        - certified: 是否完成实名认证
        - adult18: 是否满18岁
        - adult16: 是否满16岁
        """
        params = {}
        
        result = self.call_api(
            'alibaba.idle.isv.open.user.age.info.query',
            params,
            buyer_access_token
        )
        
        if result:
            age_info = result.get('alibaba_idle_isv_open_user_age_info_query_response', {}).get('data')
            return age_info
        
        return None
    
    def get_user_alipay_bind_status(self, buyer_access_token):
        """
        查询用户是否绑定支付宝
        API: alibaba.idle.isv.open.user.bind.account.query
        """
        params = {}
        
        result = self.call_api(
            'alibaba.idle.isv.open.user.bind.account.query',
            params,
            buyer_access_token
        )
        
        if result:
            bind_info = result.get('alibaba_idle_isv_open_user_bind_account_query_response', {}).get('data')
            return bind_info
        
        return None


# 创建全局实例
xianyu_api = XianyuTopAPI(use_pre_env=False)
```

---

## 2. 闲鱼消息处理端点

**文件：`app/routes/xianyu_message.py`**

```python
"""
闲鱼消息处理端点
处理来自小程序前端的订单创建和状态变更
"""
from flask import Blueprint, request, jsonify
from app import db
from app.models import Order
from app.services import sumsub_service
from app.routes.xianyu_service import xianyu_api

bp = Blueprint('xianyu_message', __name__, url_prefix='/webhook/xianyu')

@bp.route('/order/complete', methods=['POST'])
def create_order_from_xianyu():
    """
    接收来自小程序前端的订单创建请求
    
    前端在订单支付成功后调用此接口
    
    请求格式：
    {
      "biz_order_id": "3318740388015865620",
      "buyer_id": "buyer_xxx",
      "buyer_access_token": "token_xxxx",  # 关键：买家的 accessToken
      "buyer_nick": "测试买家",
      "order_amount": 29999,  # 单位：分
      "item_title": "测试商品"
    }
    """
    try:
        data = request.get_json()
        
        biz_order_id = data.get('biz_order_id')
        buyer_access_token = data.get('buyer_access_token')
        
        if not biz_order_id or not buyer_access_token:
            return jsonify({'error': '缺少必需参数: biz_order_id, buyer_access_token'}), 400
        
        # ① 调用 TOP API 查询完整订单信息
        print(f"📋 查询订单详情: {biz_order_id}")
        order_info = xianyu_api.query_order(biz_order_id, buyer_access_token)
        
        if not order_info:
            print(f"❌ 订单查询失败: {biz_order_id}")
            return jsonify({'error': 'Order not found in Taobao'}), 404
        
        print(f"✅ 订单信息获取成功")
        print(f"   买家: {order_info.get('buyer_nick')}")
        print(f"   金额: {order_info.get('payment')} 分")
        
        # ② 获取买家年龄信息（检查是否成年且实名认证）
        print(f"🔍 检查买家身份信息...")
        age_info = xianyu_api.get_user_age_info(buyer_access_token)
        
        if age_info:
            if not age_info.get('certified'):
                print(f"⚠️ 买家未完成实名认证")
                return jsonify({
                    'error': '买家未完成实名认证',
                    'error_code': 'NOT_CERTIFIED'
                }), 403
            
            if not age_info.get('adult18'):
                print(f"⚠️ 买家未满18岁")
                return jsonify({
                    'error': '买家未满18岁，无法进行身份验证',
                    'error_code': 'AGE_NOT_ENOUGH'
                }), 403
            
            print(f"✅ 买家身份验证通过")
        
        # ③ 检查订单是否已存在
        existing_order = Order.query.filter_by(
            taobao_order_id=biz_order_id
        ).first()
        
        if existing_order:
            print(f"⚠️ 订单已存在: {biz_order_id}")
            verification_link = None
            if existing_order.verification:
                verification_link = existing_order.verification.verification_link
            
            return jsonify({
                'status': 'already_exists',
                'order_id': existing_order.id,
                'verification_link': verification_link
            }), 200
        
        # ④ 创建订单记录
        print(f"💾 创建订单记录...")
        order = Order(
            taobao_order_id=biz_order_id,
            buyer_id=order_info.get('encryption_buyer_id'),  # 加密的买家ID
            buyer_name=order_info.get('buyer_nick'),
            buyer_email=data.get('buyer_email', ''),  # 前端可能包含
            buyer_phone=data.get('buyer_phone', ''),   # 前端可能包含
            platform='xianyu',
            order_amount=str(int(order_info.get('payment', 0)) / 100)  # 转换：分→元
        )
        db.session.add(order)
        db.session.commit()
        
        print(f"✅ 订单已创建: ID={order.id}")
        
        # ⑤ 生成 KYC 验证链接
        print(f"🔗 生成 KYC 验证链接...")
        verification = sumsub_service.create_verification(order)
        db.session.commit()
        
        print(f"✅ KYC 链接已生成: {verification.verification_link}")
        
        # ⑥ 返回验证链接给前端
        return jsonify({
            'status': 'success',
            'order_id': order.id,
            'verification_token': verification.verification_token,
            'verification_link': verification.verification_link
        }), 201
    
    except Exception as e:
        db.session.rollback()
        print(f"❌ 订单创建异常: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@bp.route('/order/status', methods=['POST'])
def order_status_sync():
    """
    处理闲鱼订单状态变更消息
    
    消息类型：idle_autotrade_OrderStateSync
    
    这个是可选的，用于监听订单状态变化
    聚石塔会推送此消息给后端
    
    消息格式：
    {
      "order_id": 12345678,
      "order_status": 2,  # 1:创建 2:付款 3:发货 4:完成 5:退款 6:关闭
      "order_sub_status": "init",
      "x_global_biz_code": "virtual|autoRecharge|service"
    }
    """
    try:
        data = request.get_json()
        
        order_id = data.get('order_id')
        order_status = data.get('order_status')
        order_sub_status = data.get('order_sub_status')
        biz_code = data.get('x_global_biz_code')
        
        print(f"📬 收到订单状态更新: {order_id} -> {order_status} ({order_sub_status})")
        print(f"   业务标识: {biz_code}")
        
        # 状态映射
        status_map = {
            1: "订单已创建",
            2: "订单已付款",
            3: "已发货",
            4: "交易成功",
            5: "已退款",
            6: "交易关闭"
        }
        
        print(f"   状态说明: {status_map.get(order_status, 'Unknown')}")
        
        # 这里可以根据状态做相应处理
        # 例如：
        # - status == 2: 买家已付款，触发 KYC
        # - status == 4: 交易完成，确认发货
        # - status == 5: 退款申请，更新订单状态
        
        return jsonify({'status': 'received'}), 200
    
    except Exception as e:
        print(f"❌ 消息处理异常: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@bp.route('/verification/complete', methods=['POST'])
def verification_complete():
    """
    KYC 验证完成后的回调
    
    Sumsub 验证完成 → 我们的后端更新订单状态 → 
    调用此接口通知发货或关闭订单
    
    参数：
    {
      "order_id": 订单 ID,
      "verification_status": "approved" | "rejected",
      "seller_access_token": 卖家的 accessToken
    }
    """
    try:
        data = request.get_json()
        
        order_id = data.get('order_id')
        verification_status = data.get('verification_status')  # approved / rejected
        seller_access_token = data.get('seller_access_token')  # 卖家 token
        
        if not order_id or not verification_status:
            return jsonify({'error': '缺少必需参数'}), 400
        
        order = Order.query.get(order_id)
        if not order:
            return jsonify({'error': 'Order not found'}), 404
        
        print(f"📢 KYC 验证完成: {order.taobao_order_id} -> {verification_status}")
        
        # ① 验证通过 → 发货
        if verification_status == 'approved':
            print(f"✅ 验证通过，执行发货...")
            
            if seller_access_token:
                # 调用虚拟发货 API
                success = xianyu_api.virtual_delivery(
                    order.taobao_order_id,
                    seller_access_token
                )
                
                if success:
                    print(f"✅ 虚拟发货成功")
                else:
                    print(f"❌ 虚拟发货失败")
            else:
                print(f"⚠️ 没有提供卖家 token，无法自动发货")
        
        # ② 验证拒绝 → 关闭订单
        elif verification_status == 'rejected':
            print(f"❌ 验证拒绝，关闭订单...")
            
            if seller_access_token:
                success = xianyu_api.close_order(
                    order.taobao_order_id,
                    'KYC verification failed',
                    seller_access_token
                )
                
                if success:
                    print(f"✅ 订单已关闭")
                else:
                    print(f"❌ 订单关闭失败")
            else:
                print(f"⚠️ 没有提供卖家 token，无法自动关闭订单")
        
        return jsonify({'status': 'success'}), 200
    
    except Exception as e:
        print(f"❌ 异常: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500
```

---

## 3. 注册蓝图

**修改文件：`app/__init__.py`**

在 `create_app()` 函数中添加：

```python
def create_app(config=None):
    # ... 现有代码 ...
    
    # 注册蓝图
    from app.routes import webhook, verification, xianyu_message
    app.register_blueprint(webhook.bp)
    app.register_blueprint(verification.bp)
    app.register_blueprint(xianyu_message.bp)  # ← 新增
    
    return app
```

---

## 4. 环境变量配置

**更新 `.env` 文件**

```bash
# 现有的 Sumsub 配置
SUMSUB_APP_TOKEN=prd:BUWAA7ogVIJZ7W9h7A4BaSRx.xm4V4Zef52mLLYJl0oJ1X4v878Ibo2ie
SUMSUB_SECRET_KEY=ypDDepVCvib3Oq3P6tfML91huztzOMuY

# 新增的闲鱼配置
XIANYU_APP_KEY=your_app_key_here
XIANYU_APP_SECRET=your_app_secret_here
```

---

## 5. 小程序前端示例代码

**小程序前端在订单支付成功后调用：**

```javascript
// 订单支付成功回调
async function onPaymentSuccess(tradePayResult) {
  const biz_order_id = tradePayResult.biz_order_id;
  
  // 获取 accessToken
  const accessToken = getStorage('accessToken');  // 之前登录时保存
  
  // 获取用户信息
  const userInfo = await callTopAPI('alibaba.idle.goosefish.user.info.query', {});
  
  // 调用后端 Webhook 创建订单和 KYC 链接
  const response = await fetch('https://kyc.317073.xyz/webhook/xianyu/order/complete', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      biz_order_id: biz_order_id,
      buyer_id: userInfo.user_id,
      buyer_access_token: accessToken,
      buyer_nick: userInfo.nick_name,
      buyer_email: userInfo.email,  // 如果有
      buyer_phone: userInfo.phone,  // 如果有
      order_amount: tradePayResult.order_amount,
      item_title: tradePayResult.item_title
    })
  });
  
  const result = await response.json();
  
  if (result.status === 'success') {
    // 显示 KYC 验证链接给用户
    const kyc_link = result.verification_link;
    
    // 方式1：打开 WebView
    openWebView(kyc_link);
    
    // 方式2：复制链接并显示
    showToast(`请访问以下链接完成身份验证: ${kyc_link}`);
    
    // 方式3：保存链接到订单详情页
    saveKYCLink(biz_order_id, kyc_link);
  }
}
```

---

## 完整流程总结

```
┌─ 小程序前端 ──────────┐
│ 用户登录 → 获得 Token   │
│ 用户下单 → 支付成功    │
└────────────┬──────────┘
             │
             ↓ 发送请求
    POST /webhook/xianyu/order/complete
    {biz_order_id, buyer_access_token, ...}
             │
             ↓ 后端处理
    ┌─────────────────────┐
    │ ① 调用 TOP API      │
    │    查询订单详情      │
    │                     │
    │ ② 验证买家身份      │
    │    (18岁+实名)      │
    │                     │
    │ ③ 创建订单记录      │
    │    存到 PostgreSQL   │
    │                     │
    │ ④ 调用 Sumsub API   │
    │    生成验证链接      │
    └────────────┬────────┘
                 │
                 ↓ 返回
    {verification_link: "https://kyc.317073.xyz/verify/xxx"}
                 │
                 ↓ 小程序前端
    ┌──────────────────────────┐
    │ 显示验证链接给用户        │
    │ 用户点击 → 打开 WebView   │
    └────────────┬─────────────┘
                 │
                 ↓ 用户访问验证页面
    https://kyc.317073.xyz/verify/xxx
                 │
                 ↓ WebSDK iframe
    ┌──────────────────────────┐
    │ 完成身份验证              │
    │ (拍照、活体检测等)         │
    └────────────┬─────────────┘
                 │
                 ↓ Sumsub 回调
    POST /webhook/sumsub/verification
    {applicant_id, verification_status, ...}
                 │
                 ↓ 我们的后端
    ┌──────────────────────────┐
    │ 更新验证状态              │
    │ 如果通过 → 调用发货 API   │
    │ 如果拒绝 → 调用关闭 API   │
    └────────────┬─────────────┘
                 │
                 ↓ 聚石塔更新
    ┌──────────────────────────┐
    │ 订单进入发货/关闭状态      │
    │ 推送状态消息              │
    └──────────────────────────┘
```

---

## 部署步骤

1. **提交代码到 Git**
   ```bash
   git add app/routes/xianyu_service.py
   git add app/routes/xianyu_message.py
   git commit -m "feat: 集成闲鱼 TOP API 和订单处理"
   git push origin main
   ```

2. **VPS 上拉取并重启**
   ```bash
   cd /opt/kyc-app
   git pull origin main
   docker-compose restart web
   ```

3. **在闲鱼开放平台**
   - 申请 TOP API 权限
   - 配置应用信息
   - 获取 App Key 和 Secret

4. **配置环境变量**
   ```bash
   # .env 中添加
   XIANYU_APP_KEY=xxx
   XIANYU_APP_SECRET=xxx
   ```

5. **测试**
   ```bash
   # 从小程序前端调用 Webhook
   POST /webhook/xianyu/order/complete
   ```

完成！

