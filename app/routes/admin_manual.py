"""
隐秘管理后台 - 手动生成验证链接
仅供管理员使用，需要密钥认证
"""

from flask import Blueprint, request, jsonify, render_template, session
from app.models import Order, Verification
from app.services import sumsub_service
from app.services.sumsub_report_downloader import SumsubReportDownloader
from app import db
import os
from datetime import datetime

bp = Blueprint('admin_manual', __name__, url_prefix='/admin-manual')

# 隐秘密钥 - 从环境变量读取，确保只有管理员知道
ADMIN_SECRET_KEY = os.getenv('ADMIN_SECRET_KEY', 'your-secret-key-change-this')

def check_admin_auth():
    """检查管理员认证"""
    # 方法1: 检查 session
    if 'admin_authenticated' in session and session['admin_authenticated']:
        return True
    
    # 方法2: 检查请求头
    auth_key = request.headers.get('X-Admin-Key')
    if auth_key == ADMIN_SECRET_KEY:
        session['admin_authenticated'] = True
        return True
    
    return False


@bp.route('/', methods=['GET'])
def admin_dashboard():
    """
    管理后台首页
    需要密钥认证访问
    """
    if not check_admin_auth():
        # 显示隐秘的登录界面
        return render_template('admin_login.html'), 401
    
    return render_template('admin_manual.html'), 200


@bp.route('/login', methods=['POST'])
def admin_login():
    """
    登录端点 - 验证管理员密钥
    
    POST Body:
    {
        "secret_key": "your-secret-key"
    }
    """
    try:
        data = request.get_json()
        secret_key = data.get('secret_key', '')
        
        if secret_key == ADMIN_SECRET_KEY:
            session['admin_authenticated'] = True
            return jsonify({
                'success': True,
                'message': '认证成功'
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': '密钥错误'
            }), 403
    
    except Exception as e:
        return jsonify({'error': str(e)}), 400


@bp.route('/logout', methods=['POST'])
def admin_logout():
    """登出"""
    session.pop('admin_authenticated', None)
    return jsonify({'success': True}), 200


@bp.route('/generate-link', methods=['POST'])
def generate_verification_link():
    """
    手动生成验证链接
    
    POST Body:
    {
        "user_id": "user_12345",           // 用户号（闲鱼/淘宝ID）
        "order_id": "order_67890",         // 订单号
        "buyer_name": "购买者名称",        // 可选
        "buyer_phone": "13800138000",      // 可选
        "buyer_email": "buyer@example.com" // 可选
    }
    
    Response:
    {
        "success": true,
        "verification_token": "token_xxx",
        "verification_link": "https://kyc.317073.xyz/verify/token_xxx",
        "order_id": "order_67890",
        "applicant_id": "123456789",
        "created_at": "2025-12-08T10:30:00",
        "expires_at": "2025-12-15T10:30:00"
    }
    """
    
    # 检查认证
    if not check_admin_auth():
        return jsonify({'error': '未认证'}), 401
    
    try:
        data = request.get_json()
        
        # 验证必填字段
        user_id = data.get('user_id', '').strip()
        order_id = data.get('order_id', '').strip()
        buyer_name = data.get('buyer_name', '').strip()
        buyer_phone = data.get('buyer_phone', '').strip()
        buyer_email = data.get('buyer_email', '').strip()
        
        if not user_id or not order_id:
            return jsonify({
                'error': '缺少必填字段: user_id, order_id'
            }), 400
        
        print(f"\n📝 管理员手动生成链接")
        print(f"  👤 用户号: {user_id}")
        print(f"  📦 订单号: {order_id}")
        
        # 检查订单是否已存在
        existing_order = Order.query.filter_by(
            taobao_order_id=order_id
        ).first()
        
        if existing_order:
            print(f"  ⚠️  订单已存在: {existing_order.id}")
            order = existing_order
            
            # 检查是否已有进行中的验证
            active_verification = Verification.query.filter_by(
                order_id=order.id,
                status='pending'
            ).first()
            
            if active_verification:
                return jsonify({
                    'success': True,
                    'verification_token': active_verification.verification_token,
                    'verification_link': f"https://kyc.317073.xyz/verify/{active_verification.verification_token}",
                    'order_id': order.taobao_order_id,
                    'applicant_id': active_verification.sumsub_applicant_id,
                    'status': 'pending',
                    'created_at': active_verification.created_at.isoformat(),
                    'message': '该订单已有进行中的验证链接'
                }), 200
        else:
            # 创建新订单记录
            order = Order(
                taobao_order_id=order_id,
                taobao_user_id=user_id,
                buyer_name=buyer_name,
                buyer_phone=buyer_phone,
                buyer_email=buyer_email,
                source='manual_admin',  # 标记为管理员手动创建
                webhook_payload=None
            )
            db.session.add(order)
            db.session.commit()
            print(f"  ✅ 创建新订单: {order.id}")
        
        # 生成验证链接
        verification_link = sumsub_service.create_verification(order)
        
        if not verification_link:
            return jsonify({
                'error': '生成验证链接失败'
            }), 500
        
        # 查询新创建的验证记录
        verification = Verification.query.filter_by(
            order_id=order.id,
            status='pending'
        ).order_by(Verification.created_at.desc()).first()
        
        print(f"  ✅ 验证链接生成成功")
        print(f"  🔗 Applicant ID: {verification.sumsub_applicant_id}")
        print(f"  🎟️  验证令牌: {verification.verification_token}")
        
        return jsonify({
            'success': True,
            'verification_token': verification.verification_token,
            'verification_link': f"https://kyc.317073.xyz/verify/{verification.verification_token}",
            'order_id': order.taobao_order_id,
            'applicant_id': verification.sumsub_applicant_id,
            'user_id': user_id,
            'buyer_name': buyer_name,
            'created_at': verification.created_at.isoformat(),
            'expires_at': verification.expires_at.isoformat() if verification.expires_at else None
        }), 201
    
    except Exception as e:
        print(f"  ❌ 错误: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@bp.route('/check-status', methods=['POST'])
def check_verification_status():
    """
    查询验证状态
    
    POST Body:
    {
        "order_id": "order_67890"  // 或 verification_token
    }
    
    Response:
    {
        "order_id": "order_67890",
        "verification_status": "approved",  // pending, approved, rejected, expired
        "verified_at": "2025-12-08T10:30:00",
        "applicant_id": "123456789",
        "report_urls": {
            "en": {
                "pdf": "https://kyc.317073.xyz/report/sumsub/download/token/kyc_report_xxx_en.pdf",
                "json": "https://kyc.317073.xyz/report/sumsub/download/token/kyc_report_xxx_en.json"
            },
            "zh": {
                "pdf": "https://kyc.317073.xyz/report/sumsub/download/token/kyc_report_xxx_zh.pdf"
            }
        },
        "buyer_info": {
            "name": "购买者名称",
            "phone": "13800138000",
            "email": "buyer@example.com"
        }
    }
    """
    
    # 检查认证
    if not check_admin_auth():
        return jsonify({'error': '未认证'}), 401
    
    try:
        data = request.get_json()
        order_id = data.get('order_id', '').strip()
        verification_token = data.get('verification_token', '').strip()
        
        if not order_id and not verification_token:
            return jsonify({
                'error': '需要提供 order_id 或 verification_token'
            }), 400
        
        # 查询验证记录
        if verification_token:
            verification = Verification.query.filter_by(
                verification_token=verification_token
            ).first()
        else:
            order = Order.query.filter_by(
                taobao_order_id=order_id
            ).first()
            
            if not order:
                return jsonify({
                    'error': '订单不存在'
                }), 404
            
            # 获取最新的验证记录
            verification = Verification.query.filter_by(
                order_id=order.id
            ).order_by(Verification.created_at.desc()).first()
        
        if not verification:
            return jsonify({
                'error': '验证记录不存在'
            }), 404
        
        order = Order.query.get(verification.order_id)
        
        # 构建响应
        response = {
            'order_id': order.taobao_order_id,
            'user_id': order.taobao_user_id,
            'verification_status': verification.status,
            'applicant_id': verification.sumsub_applicant_id,
            'verification_token': verification.verification_token,
            'created_at': verification.created_at.isoformat(),
            'verified_at': verification.updated_at.isoformat() if verification.updated_at else None,
            'buyer_info': {
                'name': order.buyer_name,
                'phone': order.buyer_phone,
                'email': order.buyer_email
            }
        }
        
        # 如果已批准，添加报告链接
        if verification.status == 'approved':
            reports = SumsubReportDownloader.list_reports_for_verification(verification.id)
            
            if reports:
                report_urls = {}
                for report in reports:
                    lang = report['lang']
                    fmt = report['format']
                    
                    if lang not in report_urls:
                        report_urls[lang] = {}
                    
                    report_urls[lang][fmt] = f"https://kyc.317073.xyz/report/sumsub/download/{verification.verification_token}/{report['filename']}"
                
                response['report_urls'] = report_urls
                response['report_status'] = 'available'
            else:
                response['report_status'] = 'downloading'
                response['report_message'] = '报告生成中，请稍候'
        else:
            response['report_status'] = 'not_available'
            response['report_message'] = f'验证未完成 (状态: {verification.status})'
        
        print(f"\n✅ 查询验证状态")
        print(f"  订单号: {order.taobao_order_id}")
        print(f"  状态: {verification.status}")
        print(f"  报告: {response.get('report_status', 'N/A')}")
        
        return jsonify(response), 200
    
    except Exception as e:
        print(f"  ❌ 错误: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@bp.route('/list-orders', methods=['GET'])
def list_manual_orders():
    """
    列出通过管理后台手动创建的订单
    
    Query params:
        status: pending, approved, rejected, all (默认: all)
        limit: 100 (默认)
        offset: 0 (默认)
    """
    
    # 检查认证
    if not check_admin_auth():
        return jsonify({'error': '未认证'}), 401
    
    try:
        status = request.args.get('status', 'all')
        limit = int(request.args.get('limit', 100))
        offset = int(request.args.get('offset', 0))
        
        # 查询管理员手动创建的订单
        query = Order.query.filter_by(source='manual_admin')
        
        # 如果指定状态，筛选验证记录
        if status != 'all':
            # 需要 join Verification 表
            from sqlalchemy import and_
            query = query.join(Verification).filter(
                Verification.status == status
            ).order_by(Verification.created_at.desc())
        else:
            query = query.order_by(Order.created_at.desc())
        
        total = query.count()
        orders = query.limit(limit).offset(offset).all()
        
        # 构建响应
        items = []
        for order in orders:
            verification = Verification.query.filter_by(
                order_id=order.id
            ).order_by(Verification.created_at.desc()).first()
            
            items.append({
                'order_id': order.taobao_order_id,
                'user_id': order.taobao_user_id,
                'buyer_name': order.buyer_name,
                'buyer_phone': order.buyer_phone,
                'buyer_email': order.buyer_email,
                'verification_status': verification.status if verification else 'none',
                'verification_token': verification.verification_token if verification else None,
                'created_at': order.created_at.isoformat(),
                'updated_at': verification.updated_at.isoformat() if verification else None
            })
        
        return jsonify({
            'total': total,
            'limit': limit,
            'offset': offset,
            'items': items
        }), 200
    
    except Exception as e:
        print(f"  ❌ 错误: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500
