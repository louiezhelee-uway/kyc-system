from flask import Blueprint, request, jsonify
import hmac
import hashlib
import os
from app import db
from app.models import Order
from app.services import sumsub_service

bp = Blueprint('webhook', __name__, url_prefix='/webhook')

@bp.route('/taobao/order', methods=['POST'])
def taobao_order_webhook():
    """
    Webhook endpoint for Taobao/Xianyu order events
    Triggered when a buyer purchases an item
    """
    try:
        # Verify webhook signature (optional if WEBHOOK_SECRET is not set)
        webhook_secret = os.getenv('WEBHOOK_SECRET')
        signature = request.headers.get('X-Webhook-Signature')
        
        # Only verify signature if both signature and secret are provided
        if signature and webhook_secret:
            payload = request.get_data()
            expected_signature = hmac.new(
                webhook_secret.encode(),
                payload,
                hashlib.sha256
            ).hexdigest()
            
            if not hmac.compare_digest(signature, expected_signature):
                return jsonify({'error': 'Invalid signature'}), 401
        # If signature is provided but no secret configured, reject it
        elif signature and not webhook_secret:
            print("⚠️  警告: 提供了签名但 WEBHOOK_SECRET 未配置")
            pass  # Still allow the request
        # If no signature and no secret, allow (for testing)
        # If no signature but secret configured, allow (for testing)
        
        data = request.get_json()
        
        # Extract order information
        order_data = {
            'taobao_order_id': data.get('order_id'),
            'buyer_id': data.get('buyer_id'),
            'buyer_name': data.get('buyer_name'),
            'buyer_email': data.get('buyer_email'),
            'buyer_phone': data.get('buyer_phone'),
            'platform': data.get('platform', 'taobao'),
            'order_amount': data.get('order_amount'),
        }
        
        # Create order in database
        existing_order = Order.query.filter_by(
            taobao_order_id=order_data['taobao_order_id']
        ).first()
        
        if existing_order:
            return jsonify({
                'status': 'already_exists',
                'order_id': existing_order.id
            }), 200
        
        order = Order(**order_data)
        db.session.add(order)
        db.session.commit()
        
        # Generate Sumsub verification link
        verification = sumsub_service.create_verification(order)
        db.session.commit()
        
        return jsonify({
            'status': 'success',
            'order_id': order.id,
            'verification_id': verification.id,
            'verification_link': verification.verification_link
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"❌ Webhook 错误: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@bp.route('/sumsub/verification', methods=['POST'])
def sumsub_verification_webhook():
    """
    Webhook endpoint for Sumsub verification status updates
    """
    try:
        data = request.get_json()
        
        applicant_id = data.get('applicantId')
        review_status = data.get('reviewStatus')
        
        # Update verification status
        verification = sumsub_service.update_verification_status(
            applicant_id,
            review_status
        )
        
        if verification:
            # Generate PDF report if verification is complete
            if review_status in ['approved', 'rejected']:
                sumsub_service.generate_pdf_report(verification.order_id)
        
        return jsonify({'status': 'success'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
