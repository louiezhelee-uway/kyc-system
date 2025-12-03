import requests
import os
import uuid
import hmac
import hashlib
import time
from datetime import datetime
from app import db
from app.models import Order, Verification
from app.utils import token_generator
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Sumsub SDK Configuration
SUMSUB_APP_TOKEN = os.getenv('SUMSUB_APP_TOKEN')
SUMSUB_SECRET_KEY = os.getenv('SUMSUB_SECRET_KEY')
SUMSUB_API_URL = os.getenv('SUMSUB_API_URL', 'https://api.sumsub.com')

def _get_session():
    """
    Create a requests session with retry strategy and proper headers
    """
    session = requests.Session()
    
    # Configure retry strategy
    retry_strategy = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["HEAD", "GET", "OPTIONS", "POST", "PUT"]
    )
    
    adapter = HTTPAdapter(max_retries=retry_strategy)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    
    return session

def _get_signature(method: str, path: str, body: str = ''):
    """
    Generate HMAC-SHA256 signature for Sumsub API requests
    Format: {method}{path}{body}{timestamp}
    """
    if not SUMSUB_SECRET_KEY:
        raise Exception('SUMSUB_SECRET_KEY is not configured')
    
    ts = str(int(time.time() * 1000))  # Milliseconds, not seconds
    request_body = body if body else ''
    signature_raw = f"{method}{path}{request_body}{ts}"
    
    signature = hmac.new(
        SUMSUB_SECRET_KEY.encode(),
        signature_raw.encode(),
        hashlib.sha256
    ).hexdigest()
    
    return ts, signature

def _get_request_headers(ts: str, signature: str) -> dict:
    """
    Build request headers for Sumsub API with Cloudflare bypass
    """
    return {
        'Authorization': f'Bearer {SUMSUB_APP_TOKEN}',
        'X-App-Access-Sig': signature,
        'X-App-Access-Ts': ts,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Sec-Ch-Ua': '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
        'Sec-Ch-Ua-Mobile': '?0',
        'Sec-Ch-Ua-Platform': '"Windows"',
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'same-site',
    }

def create_verification(order: Order) -> Verification:
    """
    Create a new verification with Sumsub API
    """
    try:
        # Generate unique applicant ID
        external_user_id = f"order_{order.id}"
        
        # Prepare applicant data
        payload = {
            'externalUserId': external_user_id,
            'email': order.buyer_email,
            'phone': order.buyer_phone,
            'firstName': order.buyer_name,
            'lastName': '',
            'country': 'CN',
        }
        
        # Create applicant in Sumsub
        path = '/resources/applicants'
        import json
        body = json.dumps(payload)
        ts, signature = _get_signature('POST', path, body)
        
        headers = _get_request_headers(ts, signature)
        
        url = f'{SUMSUB_API_URL}{path}'
        
        # Use session with retry strategy
        session = _get_session()
        response = session.post(
            url,
            json=payload,
            headers=headers,
            timeout=15,
            allow_redirects=False
        )
        session.close()
        
        # Detailed error diagnostics
        if response.status_code not in [200, 201]:
            error_msg = f'Sumsub API error - Status: {response.status_code}'
            
            # Check if it's Cloudflare challenge
            if 'cf-mitigated' in response.headers:
                error_msg += f'\n⚠️ Cloudflare challenge detected: {response.headers.get("cf-mitigated")}'
                error_msg += f'\nServer: {response.headers.get("Server")}'
                error_msg += f'\nCF-Ray: {response.headers.get("cf-ray")}'
            
            # Check response content
            try:
                error_data = response.json()
                error_msg += f'\nAPI Error: {error_data}'
            except:
                error_msg += f'\nResponse: {response.text[:300]}'
            
            raise Exception(error_msg)
        
        sumsub_applicant = response.json()
        sumsub_applicant_id = sumsub_applicant.get('id')
        
        if not sumsub_applicant_id:
            raise Exception('Failed to get applicant ID from Sumsub response')
        
        # Generate access token for web SDK
        access_token = _generate_access_token(sumsub_applicant_id)
        
        # Create verification link
        verification_token = token_generator.generate_verification_token()
        
        # Web SDK verification link
        verification_link = f"{SUMSUB_API_URL.replace('/api', '')}/sdk/applicant?token={access_token}"
        
        # Create verification record
        verification = Verification(
            order_id=order.id,
            sumsub_applicant_id=sumsub_applicant_id,
            verification_link=verification_link,
            verification_token=verification_token,
            status='pending'
        )
        
        db.session.add(verification)
        db.session.flush()
        
        return verification
        
    except Exception as e:
        raise Exception(f'Failed to create verification: {str(e)}')

def _generate_access_token(applicant_id: str) -> str:
    """
    Generate access token for Sumsub Web SDK
    """
    try:
        path = f'/resources/applicants/{applicant_id}/tokens'
        
        ts, signature = _get_signature('POST', path, '')
        headers = _get_request_headers(ts, signature)
        
        payload = {
            'ttlInSecs': 1800,
            'redirectUrl': os.getenv('APP_DOMAIN', 'http://localhost:5000') + '/verification/complete'
        }
        
        session = _get_session()
        response = session.post(
            f'{SUMSUB_API_URL}{path}',
            json=payload,
            headers=headers,
            timeout=15,
            allow_redirects=False
        )
        session.close()
        
        if response.status_code not in [200, 201]:
            raise Exception(f'Token generation failed: {response.text}')
        
        token_data = response.json()
        return token_data.get('token')
        
    except Exception as e:
        raise Exception(f'Failed to generate access token: {str(e)}')

def update_verification_status(sumsub_applicant_id: str, review_status: str) -> Verification:
    """
    Update verification status based on Sumsub webhook
    """
    try:
        verification = Verification.query.filter_by(
            sumsub_applicant_id=sumsub_applicant_id
        ).first()
        
        if not verification:
            raise Exception('Verification not found')
        
        # Map Sumsub status to our status
        status_map = {
            'approved': 'approved',
            'rejected': 'rejected',
            'pending': 'pending',
            'review': 'pending'
        }
        
        verification.status = status_map.get(review_status, 'pending')
        verification.completed_at = datetime.utcnow() if review_status != 'pending' else None
        db.session.commit()
        
        return verification
        
    except Exception as e:
        raise Exception(f'Failed to update verification: {str(e)}')

def get_verification_result(sumsub_applicant_id: str) -> dict:
    """
    Get verification result from Sumsub API
    """
    try:
        path = f'/resources/applicants/{sumsub_applicant_id}/review'
        ts, signature = _get_signature('GET', path)
        headers = _get_request_headers(ts, signature)
        
        session = _get_session()
        response = session.get(
            f'{SUMSUB_API_URL}{path}',
            headers=headers,
            timeout=15,
            allow_redirects=False
        )
        session.close()
        
        if response.status_code != 200:
            raise Exception(f'Failed to get review: {response.text}')
        
        return response.json()
        
    except Exception as e:
        raise Exception(f'Failed to get verification result: {str(e)}')

def generate_pdf_report(order_id: str):
    """
    Generate PDF report for completed verification
    """
    from app.services import report_service
    from app.models import Report
    
    try:
        order = Order.query.filter_by(id=order_id).first()
        
        if not order:
            raise Exception('Order not found')
        
        verification = order.verification
        
        if not verification:
            raise Exception('Verification not found')
        
        # Get verification result from Sumsub
        verification_result = get_verification_result(verification.sumsub_applicant_id)
        
        # Generate PDF
        pdf_path = report_service.generate_report_pdf(order, verification_result)
        
        # Create report record
        report = Report(
            order_id=order_id,
            verification_result=verification.status,
            verification_details=verification_result,
            pdf_path=pdf_path
        )
        
        db.session.add(report)
        db.session.commit()
        
        return report
        
    except Exception as e:
        raise Exception(f'Failed to generate PDF report: {str(e)}')

