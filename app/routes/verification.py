from flask import Blueprint, render_template, jsonify, redirect, request
from app import db
from app.models import Order, Verification
from app.services import sumsub_service
import os

bp = Blueprint('verification', __name__, url_prefix='/verify')

@bp.route('/<verification_token>', methods=['GET'])
def verification_page(verification_token):
    """
    Display KYC verification page with Sumsub WebSDK iframe
    Generates fresh access token on page load
    """
    try:
        verification = Verification.query.filter_by(
            verification_token=verification_token
        ).first()
        
        if not verification:
            return render_template('error.html', message='Verification link not found'), 404
        
        if verification.status == 'expired':
            return render_template('error.html', message='Verification link has expired'), 410
        
        if verification.status in ['approved', 'rejected']:
            return redirect(f'/report/{verification.order_id}')
        
        order = verification.order
        
        # Generate fresh access token for WebSDK
        try:
            access_token = sumsub_service._generate_access_token(
                verification.sumsub_applicant_id,
                f"order_{order.id}",
                order.buyer_email
            )
        except Exception as e:
            return render_template('error.html', message=f'Failed to generate verification token: {str(e)}'), 500
        
        return render_template(
            'verification.html',
            order=order,
            verification=verification,
            verification_token=verification_token,
            verification_token_for_sdk=access_token
        ), 200
        
    except Exception as e:
        return render_template('error.html', message=str(e)), 500

@bp.route('/status/<verification_token>', methods=['GET'])
def check_status(verification_token):
    """
    Check verification status (AJAX endpoint)
    """
    try:
        verification = Verification.query.filter_by(
            verification_token=verification_token
        ).first()
        
        if not verification:
            return jsonify({'error': 'Not found'}), 404
        
        return jsonify({
            'status': verification.status,
            'completed_at': verification.completed_at.isoformat() if verification.completed_at else None
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@bp.route('/refresh-token', methods=['POST'])
def refresh_token():
    """
    Refresh WebSDK access token when expired
    Called by frontend JavaScript when token expires
    """
    try:
        # Get verification token from request (passed by frontend)
        data = request.get_json()
        verification_token = data.get('verification_token')
        
        if not verification_token:
            return jsonify({'error': 'verification_token required'}), 400
        
        verification = Verification.query.filter_by(
            verification_token=verification_token
        ).first()
        
        if not verification:
            return jsonify({'error': 'Verification not found'}), 404
        
        order = verification.order
        
        # Generate fresh access token
        access_token = sumsub_service._generate_access_token(
            verification.sumsub_applicant_id,
            f"order_{order.id}",
            order.buyer_email
        )
        
        return jsonify({
            'token': access_token,
            'expires_in': 1800
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
